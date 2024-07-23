// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Polymarket {
    struct Market {
        string question;
        string[] outcomes;
        uint256[] outcomeBalances;
        bool isResolved;
        uint256 winningOutcome;
        mapping(address => mapping(uint256 => uint256)) bets;
    }

    Market[] public markets;

    event MarketCreated(uint256 marketId, string question, string[] outcomes);
    event BetPlaced(uint256 marketId, uint256 outcome, address bettor, uint256 amount);
    event MarketResolved(uint256 marketId, uint256 winningOutcome);

    function createMarket(string memory question, string[] memory outcomes) public {
        Market storage newMarket = markets.push();
        newMarket.question = question;
        newMarket.outcomes = outcomes;
        newMarket.outcomeBalances = new uint256[](outcomes.length);
        newMarket.isResolved = false;

        emit MarketCreated(markets.length - 1, question, outcomes);
    }

    function placeBet(uint256 marketId, uint256 outcome) public payable {
        require(marketId < markets.length, "Market does not exist");
        require(outcome < markets[marketId].outcomes.length, "Invalid outcome");
        require(!markets[marketId].isResolved, "Market already resolved");

        markets[marketId].outcomeBalances[outcome] += msg.value;
        markets[marketId].bets[msg.sender][outcome] += msg.value;

        emit BetPlaced(marketId, outcome, msg.sender, msg.value);
    }

    function resolveMarket(uint256 marketId, uint256 winningOutcome) public {
        require(marketId < markets.length, "Market does not exist");
        require(winningOutcome < markets[marketId].outcomes.length, "Invalid outcome");
        require(!markets[marketId].isResolved, "Market already resolved");

        markets[marketId].isResolved = true;
        markets[marketId].winningOutcome = winningOutcome;

        emit MarketResolved(marketId, winningOutcome);
    }

    function claimWinnings(uint256 marketId) public {
        require(marketId < markets.length, "Market does not exist");
        require(markets[marketId].isResolved, "Market not resolved yet");

        uint256 winningOutcome = markets[marketId].winningOutcome;
        uint256 userBet = markets[marketId].bets[msg.sender][winningOutcome];
        require(userBet > 0, "No winnings to claim");

        uint256 totalWinningBets = markets[marketId].outcomeBalances[winningOutcome];
        uint256 userWinnings = (address(this).balance * userBet) / totalWinningBets;

        markets[marketId].bets[msg.sender][winningOutcome] = 0;
        payable(msg.sender).transfer(userWinnings);
    }

    function getMarket(uint256 marketId) public view returns (
        string memory question,
        string[] memory outcomes,
        uint256[] memory outcomeBalances,
        bool isResolved,
        uint256 winningOutcome
    ) {
        require(marketId < markets.length, "Market does not exist");

        Market storage market = markets[marketId];
        return (
            market.question,
            market.outcomes,
            market.outcomeBalances,
            market.isResolved,
            market.winningOutcome
        );
    }
}