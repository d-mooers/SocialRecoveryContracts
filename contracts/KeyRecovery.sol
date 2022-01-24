//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract KeyRecovery {
  struct Context {
    bytes32 secret;
    address[] guardians;
    mapping(address => bytes32) secretShare;
    bytes32[] recoveryShares;
    uint256 K;
    address requester;
    uint256 cooldownTime; // Cool down time so that an account cannot be repeatedly entered into recovery mode
  }

  mapping(address => Context) private recoveryInfo;
  mapping(bytes32 => address) private accountIdentifier;

  uint256 constant RECOVERY_PERIOD = 7 days;

  event RecoveryInitiated(
    address accountToRecover,
    address recoveryRequester,
    address[] guardians
  );

  event ThresholdReached(address accountToRecover, address recoveryRequester);

  modifier newAccount() {
    require(
      uint256(recoveryInfo[msg.sender].secret) == 0,
      "Account already exists in the system"
    );
    _;
  }

  modifier recoveryRequested(address account) {
    require(
      recoveryInfo[account].requester != address(0),
      "Account has not been requested to be recovered"
    );
    _;
  }

  modifier identifierMatches(address account, bytes32 identifier) {
    require(
      accountIdentifier[identifier] == account,
      "Identifier does not match account address"
    );
    _;
  }

  modifier backupExists(address account) {
    require(
      uint256(recoveryInfo[account].secret) != 0,
      "Recovery info does not exist for the account"
    );
    _;
  }

  modifier notOnCooldown(address account) {
    require(
      block.timestamp >= recoveryInfo[account].cooldownTime,
      "It is too soon to request recovery"
    );
    _;
  }

  function getKeyshare(address account, address guardian)
    external
    view
    backupExists(account)
    recoveryRequested(account)
    returns (bytes32 encryptedKeyshare, address requester)
  {
    Context storage context = recoveryInfo[account];
    encryptedKeyshare = context.secretShare[guardian];
    requester = context.requester;
  }

  function addAccount(
    bytes32 secret,
    address[] memory guardians,
    bytes32[] memory keyShares,
    uint256 K,
    string memory identifier
  ) external newAccount {
    require(
      guardians.length == keyShares.length,
      "Key share number discrepency"
    );
    require(
      K <= guardians.length,
      "Threshold must be <= total number of guardians"
    );

    accountIdentifier[keccak256(abi.encodePacked(identifier))] = msg.sender;

    Context storage context = recoveryInfo[msg.sender];
    context.secret = secret;
    context.K = K;
    context.guardians = new address[](guardians.length);
    for (uint8 i = 0; i < guardians.length; i++) {
      context.guardians[i] = guardians[i];
      context.secretShare[guardians[i]] = keyShares[i];
    }
  }

  function initiateRecovery(address account, string calldata identifier)
    external
    backupExists(account)
    identifierMatches(account, keccak256(abi.encodePacked(identifier)))
  {
    Context storage context = recoveryInfo[msg.sender];
    context.requester = msg.sender;
    emit RecoveryInitiated(account, msg.sender, context.guardians);
  }

  function endRecovery() external backupExists(msg.sender) {
    Context storage context = recoveryInfo[msg.sender];
    context.requester = address(0);
    context.cooldownTime = block.timestamp + RECOVERY_PERIOD;
  }

  function postRecoveryShares(address account, bytes32 encryptedShare)
    external
    backupExists(account)
    recoveryRequested(account)
  {
    Context storage context = recoveryInfo[account];
    context.recoveryShares.push(encryptedShare);

    if (context.recoveryShares.length >= context.K) {
      emit ThresholdReached(account, context.requester);
    }
  }

  function getRecoveryShares(address account)
    external
    view
    backupExists(account)
    recoveryRequested(account)
    returns (bytes32[] memory)
  {
    return recoveryInfo[account].recoveryShares;
  }
}
