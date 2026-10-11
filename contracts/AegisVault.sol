// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

/**
 * @title AegisVault
 * @notice Production-grade ERC-4626 Tokenized Yield Vault with fee accrual and safety controls.
 */
contract AegisVault is IERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    IERC20 public immutable asset;
    address public owner;
    address public feeRecipient;
    uint256 public managementFeeBasisPoints; // 100 = 1%
    bool public paused;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private _locked;

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event FeeHarvested(address indexed recipient, uint256 feeAssets);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseToggled(bool isPaused);

    modifier onlyOwner() {
        require(msg.sender == owner, "AegisVault: caller is not the owner");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "AegisVault: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    modifier whenNotPaused() {
        require(!paused, "AegisVault: contract is paused");
        _;
    }

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _feeRecipient,
        uint256 _feeBps
    ) {
        require(address(_asset) != address(0), "Invalid asset");
        require(_feeBps <= 1000, "Fee too high: max 10%");
        asset = _asset;
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        feeRecipient = _feeRecipient;
        managementFeeBasisPoints = _feeBps;
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = _totalSupply;
        uint256 total = totalAssets();
        return (supply == 0 || total == 0) ? assets : (assets * supply) / total;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = _totalSupply;
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function deposit(uint256 assets, address receiver) public nonReentrant whenNotPaused returns (uint256 shares) {
        require(assets > 0, "Cannot deposit 0");
        require(receiver != address(0), "Zero address receiver");

        shares = convertToShares(assets);
        require(shares > 0, "Shares returned 0");

        require(asset.transferFrom(msg.sender, address(this), assets), "Transfer failed");

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address shareOwner) public nonReentrant returns (uint256 shares) {
        require(assets > 0, "Cannot withdraw 0");
        shares = convertToShares(assets);

        if (msg.sender != shareOwner) {
            uint256 allowed = _allowances[shareOwner][msg.sender];
            require(allowed >= shares, "Insufficient allowance");
            _allowances[shareOwner][msg.sender] = allowed - shares;
        }

        _burn(shareOwner, shares);
        require(asset.transfer(receiver, assets), "Asset transfer failed");

        emit Withdraw(msg.sender, receiver, shareOwner, assets, shares);
    }

    function harvestFees() external onlyOwner nonReentrant {
        if (managementFeeBasisPoints == 0 || feeRecipient == address(0)) return;
        uint256 total = totalAssets();
        uint256 fee = (total * managementFeeBasisPoints) / 10000;
        if (fee > 0) {
            require(asset.transfer(feeRecipient, fee), "Fee transfer failed");
            emit FeeHarvested(feeRecipient, fee);
        }
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PauseToggled(_paused);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // --- IERC20 Implementation ---
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAccount, address spender) external view override returns (uint256) {
        return _allowances[ownerAccount][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: allowance exceeded");
        unchecked {
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(_balances[account] >= amount, "Burn exceeds balance");
        unchecked {
            _balances[account] -= amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0) && recipient != address(0), "Zero address");
        require(_balances[sender] >= amount, "Transfer exceeds balance");
        unchecked {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }
}
