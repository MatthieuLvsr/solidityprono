// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Betting {
    address payable public owner;

    struct Bet {
        address payable better;
        uint amount;
        uint scoreHome;
        uint scoreAway;
    }

    Bet[] public bets;

    uint public finalScoreHome;
    uint public finalScoreAway;
    bool public bettingOpen = true;
    uint256 randNonce = 1;
    uint256 winnersCount = 5;
    uint256 entranceFees = 10 wei;

    // Événements
    event BettingClosed();
    event BettingOpened();
    event FinalScoreSet(uint scoreHome, uint scoreAway);
    event BetPlaced(address better, uint amount, uint scoreHome, uint scoreAway);
    event GainsDistributed(address better, uint gain);
    event Withdrawal(uint amount, uint when);

    constructor() {
        owner = payable(msg.sender);
    }

    function setWinnersCount(uint256 _count) public {
        require(msg.sender == owner, "You aren't the owner");
        winnersCount = _count;
    }

    function setEntranceFees(uint256 _fees) public {
        require(msg.sender == owner, "You aren't the owner");
        entranceFees = _fees;
    }

    function getEntranceFees() public view returns(uint) {
        return entranceFees;    
    }

    function closeBetting() public {
        require(msg.sender == owner, "You aren't the owner");
        bettingOpen = false;
        emit BettingClosed();
    }

    function OpenBetting() public {
        require(msg.sender == owner, "You aren't the owner");
        bettingOpen = true;
        emit BettingOpened();
    }

    function setFinalScore(uint _scoreHome, uint _scoreAway) public {
        require(msg.sender == owner, "You aren't the owner");
        require(bettingOpen == false, "Bets are still open");
        finalScoreHome = _scoreHome;
        finalScoreAway = _scoreAway;
        emit FinalScoreSet(_scoreHome, _scoreAway);
    }

    function bet(uint _scoreHome, uint _scoreAway) public payable {
        require(_checkBets(msg.sender), "You have already bet today");
        // require(msg.value > 0, "You must bet something");
        require(msg.value == entranceFees, "You must pay the entrance fees");
        require(bettingOpen == true, "Bets are closed");
        bets.push(Bet(payable(msg.sender), msg.value, _scoreHome, _scoreAway));
        emit BetPlaced(msg.sender, msg.value, _scoreHome, _scoreAway);
    }

    function endBets() public {
    require(msg.sender == owner, "You aren't the owner");
    require(bettingOpen == false, "Bets are still open");

    address payable[] memory potentialWinners = new address payable[](bets.length);
    uint numWinners = 0;
    uint totalWinningAmount = 0;

    // Identifier tous les gagnants potentiels
    for (uint i = 0; i < bets.length; i++) {
        if (bets[i].scoreHome == finalScoreHome && bets[i].scoreAway == finalScoreAway) {
            potentialWinners[numWinners] = bets[i].better;
            totalWinningAmount += bets[i].amount;
            numWinners++;
        }
    }

    require(numWinners > 0, "No winning bets");

    uint winnersToSelect = numWinners > 5 ? 5 : numWinners; // Limiter à 5 gagnants si numWinners > 5
    uint[] memory selectedIndexes = new uint[](winnersToSelect);
    uint selectedCount = 0;

    // Sélectionner aléatoirement les gagnants si nécessaire
    while (selectedCount < winnersToSelect) {
        uint randIndex = rand(numWinners); // Assurez-vous que rand ne renvoie jamais un indice en dehors des limites
        bool alreadySelected = false;
        for (uint j = 0; j < selectedCount; j++) {
            if (selectedIndexes[j] == randIndex) {
                alreadySelected = true;
                break;
            }
        }
        if (!alreadySelected) {
            selectedIndexes[selectedCount] = randIndex;
            selectedCount++;
        }
    }

    // Distribuer les gains aux gagnants sélectionnés
    uint cashprize = address(this).balance;
    for (uint i = 0; i < winnersToSelect; i++) {
        address payable winner = potentialWinners[selectedIndexes[i]];
        // Si on réparti en fonction de la mise des gagnants
        // uint gain = (bets[selectedIndexes[i]].amount * cashprize / totalWinningAmount;
        uint gain = (cashprize / winnersToSelect);
        winner.transfer(gain);
        emit GainsDistributed(winner, gain);
    }

    _resetBets();
}


    function _resetBets()private{
        while(bets.length > 0){
            bets.pop();
        }
    }

    function rand(uint256 _mod) public returns (uint256) {
        randNonce++;
        return uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % _mod;
    }

    function _checkBets(address user) private view returns(bool){
        for(uint i = 0; i < bets.length; i++){
            if(bets[i].better == user)return false;
        }
        return true;
    }

    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner");
        uint amount = address(this).balance;
        emit Withdrawal(amount, block.timestamp);
        owner.transfer(amount);
    }
}
