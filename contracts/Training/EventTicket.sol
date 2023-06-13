//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

//Event Ticket

contract EventTicket{

    uint256  numberOfTickets;
    uint256  ticketPrice;
    uint256  totalAmount;
    uint256  startAt;
    uint256  endAt;
    uint256  timeRange;
    string  message = "Buy an event Tickets";

    constructor(uint256 _ticketPrice){
        ticketPrice = _ticketPrice;
        startAt = block.timestamp;
        endAt= block.timestamp + 7 days;
        timeRange = (endAt - startAt) / 60 / 60 / 24;
    }

    function buyTicket(uint256 _value) public returns(uint256 ticketId){
        numberOfTickets++;
        totalAmount += _value;
        ticketId = numberOfTickets;
    }

    function getAmount() public view returns(uint256){
        return totalAmount;
    }
}