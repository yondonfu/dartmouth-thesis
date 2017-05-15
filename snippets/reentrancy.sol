
contract Attacker {
  bool attackModeOn;

  function Attacker() {
    attackModeOn = true;
  }

  function() {
    // Store address of vulnerable contract here
    VulnerableContract v;

    if (attackModeOn) {
      // Reentrancy call
      v.withdraw();
    }
  }
}

contract VulnerableContract {
  mapping (address => uint) public balances;

  function withdraw() {
    uint amount = balances[msg.sender];

    // Vulnerable to reentrancy
    // call.value() forwards gas, allowing receiver's fallback function to perform more computation
    if (!(msg.sender.call.value(amount))) throw;

    // Note that state is updated AFTER the external call
    balances[msg.sender] = 0;
  }
}

contract NotSoVulnerableContract {
  mapping (address => uint) public balances;

  function withdraw() {
    uint amount = balances[msg.sender];

    // Note that state is updated BEFORE the external call
    balances[msg.sender] = 0;

    // Note that send is used instead of call.value()
    // Gas is not forwarded, receiver only gets 21k gas only enough for event logging
    if (!msg.sender.send(amount)) throw;
  }
}

contract AnotherNotSoVulnerableContract {
  mapping (address => uint) public balances;
  mapping (address => bool) public mutexes;

  function withdraw() {
    // Check if sender is currently locked by a mutex
    if (mutexes[msg.sender]) throw;

    // Lock sender mutex
    mutexes[msg.sender] = true;

    uint amount = balances[msg.sender];

    if (!msg.sender.send(amount)) throw;

    balances[msg.sender] = 0;

    // Unlock sender mutex
    mutexes[msg.sender] = false;
  }
}
