// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Registration.sol";
import "./Ticmet.sol";

contract Ticketing is ERC721, Ownable{

    // Errors
    error maxLimitExceeded();
    error maxTicketPurchasedPerUser();

    event NewTicketCreated(string indexed eventName, uint indexed creatorAddress, uint indexed ticketsCount);
    event NFTMinted(uint indexed tokenId);

    address private contractAdmin;
    address private registrationContract;
    address private EVNT;
    address private paymentAddress = 0x71A66921E1429c29C9c234f8d71504C88e503392;

    uint private autoGenerateId = 100;
    uint private nftId = 100000;
    uint private ticketPriceWei;


    uint[] public nftIds;
    uint[] public autoIds;
    uint[] private ticketsCountForEvents;

    mapping(uint => EventInformation) private linkIdToEvent;
    mapping(uint => mapping(uint => bool)) private linkEventIdToTicketQuantity;
    mapping(uint => uint) private eventPubTime;
    mapping(uint => uint) private eventStartTime;
    mapping(uint => uint) private eventEndTime;
    mapping(uint => string) private eventMapName;
    mapping(address => mapping(uint => uint)) adminBalanceAssociatedToEvent;
    mapping(address => mapping(uint => uint)) restrictMaxBuyForUser;
    mapping(uint => uint) perEventCollection;


    struct EventInformation{
        string eventTitle;
        string venue;
        uint startDate;
        uint endDate;
        uint ticketsQuantity;
        uint ticketPrice;
        uint maxTicketPerPerson;
        uint publishTime;
    }

    struct EventStatusForRead{
        string eventTitle;
        string venue;
        uint startDate;
        uint endDate;
        uint ticketsQuantity;
        uint ticketPrice;
        uint maxTicketPerPerson;
        uint publishTime;
        string state;
    }

    modifier onlyAdmin(){
        require(contractAdmin == msg.sender, "only contractAdming can call this function");
        _;
    }
    
    constructor(address _registrationContract, address _evntTokenAddress) ERC721("EventBriteTickets", "EVNT-TIC") {
        contractAdmin = msg.sender;
        registrationContract = _registrationContract;
        EVNT = _evntTokenAddress;
    }

    /**
     * createEvent
     * @param _event - Pass the detailed event information
     */
    function createEvent(EventInformation memory _event) public onlyAdmin{
        uint incrementId = 1;
        autoGenerateId = autoGenerateId + incrementId;
        linkIdToEvent[autoGenerateId].eventTitle = _event.eventTitle;
        linkIdToEvent[autoGenerateId].venue = _event.venue;
        linkIdToEvent[autoGenerateId].startDate = _event.startDate;
        linkIdToEvent[autoGenerateId].endDate = _event.endDate;
        linkIdToEvent[autoGenerateId].ticketsQuantity = _event.ticketsQuantity;
        linkIdToEvent[autoGenerateId].ticketPrice = _event.ticketPrice;
        linkIdToEvent[autoGenerateId].maxTicketPerPerson = _event.maxTicketPerPerson;
        linkIdToEvent[autoGenerateId].publishTime = _event.publishTime;
        eventPubTime[autoGenerateId] = _event.publishTime;
        eventStartTime[autoGenerateId] = _event.startDate;
        eventEndTime[autoGenerateId] = _event.endDate;
        eventMapName[autoGenerateId] = _event.eventTitle;
        linkEventIdToTicketQuantity[autoGenerateId][_event.ticketsQuantity]=true;
        autoIds.push(autoGenerateId);
        emit NewTicketCreated(_event.eventTitle,_event.publishTime,_event.ticketsQuantity);
    }


    /**
     * buyTickets
     * @param _eventId - Pass the event id.
     * @param _ticketCount - Pass the number of tickets needed to buy
     */
    function buyTickets( uint _eventId, uint _ticketCount) public {
        // Registration user = Registration(registrationContract);
        // require(user.verifyUser(msg.sender), "User is not registered");
        Ticmet evnt = Ticmet(EVNT);
        uint ticketPrice = linkIdToEvent[_eventId].ticketPrice;
        uint ticketquantity = linkIdToEvent[_eventId].ticketsQuantity; 
        require(_ticketCount <= ticketquantity, "Ticket limit exceeded"); 
        uint maxTicketPerPerson = linkIdToEvent[_eventId].maxTicketPerPerson;
        if(restrictMaxBuyForUser[msg.sender][_eventId] == linkIdToEvent[_eventId].maxTicketPerPerson){
            revert maxTicketPurchasedPerUser();
        }
        restrictMaxBuyForUser[msg.sender][_eventId] += _ticketCount;
        require(_ticketCount <= maxTicketPerPerson, "Maximum ticket limit exceeded"); 
        uint eventPublishTime = linkIdToEvent[_eventId].publishTime;
        uint eventsStartTime =  linkIdToEvent[_eventId].startDate; 
        require(block.timestamp >= eventPublishTime && 
        block.timestamp <= eventsStartTime, "The Event is not yet published or Event already started");
        ticketPriceWei = ticketPrice * (10 ** 18);
        uint totalPrice = ticketPriceWei * _ticketCount;
        IERC20(evnt).transferFrom(msg.sender, paymentAddress, totalPrice);
        for (uint i = 0; i < _ticketCount; i++) {
            uint incrementNFTId = 1;
            nftId = nftId + incrementNFTId;
            _mint(msg.sender, nftId);
            nftIds.push(nftId);
            emit NFTMinted(nftId);
        }
        linkIdToEvent[_eventId].ticketsQuantity -= _ticketCount;
        adminBalanceAssociatedToEvent[paymentAddress][_eventId] += totalPrice;
        perEventCollection[_eventId] += totalPrice;
    }

    /**
     * getEventsDetailsStruct
     * @param _eventId - Pass the event id
     */
    function getEventsDetailsStruct(uint256 _eventId) external view returns(EventInformation memory _eventDetails){
        return (
        linkIdToEvent[_eventId]
        );
    }


    /**
     * YetToStartEvents
     * @param _sort - Pass the 1 for ascending and 0 or any number for descending
     */
    function YetToStartEvents(uint _sort) external view returns (EventStatusForRead[] memory) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < autoIds.length; i++) {
            if (time < eventStartTime[autoIds[i]]) {
                count++;
            }
        }
        EventStatusForRead[] memory events = new EventStatusForRead[](count);
        if (_sort == 1) {
            for (uint i = 0; i < autoIds.length; i++) {
                if (time < eventStartTime[autoIds[i]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i]];
                    ev.venue = linkIdToEvent[autoIds[i]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i]].publishTime;
                    ev.state = "Yet to start";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }else{
            for (uint i = autoIds.length; i > 0; i--) {
                if (time < eventStartTime[autoIds[i - 1]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i - 1]];
                    ev.venue = linkIdToEvent[autoIds[i - 1]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i - 1]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i - 1]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i - 1]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i - 1]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i - 1]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i - 1]].publishTime;
                    ev.state = "Yet to start";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }
        return events;
    }

    /**
     * LiveEvents
     * @param _sort - Pass the 1 for ascending and 0 or any number for descending
     */
    function LiveEvents(uint _sort) external view returns (EventStatusForRead[] memory) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < autoIds.length; i++) {
            if (time > eventStartTime[autoIds[i]] && time < eventEndTime[autoIds[i]]) {
                count++;
            }
        }
        EventStatusForRead[] memory events = new EventStatusForRead[](count);
        if(_sort == 1){
            for (uint i = 0; i < autoIds.length; i++) {
                if (time > eventStartTime[autoIds[i]] && time < eventEndTime[autoIds[i]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i]];
                    ev.venue = linkIdToEvent[autoIds[i]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i]].publishTime;
                    ev.state = "Live";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }else{
            for (uint i = autoIds.length; i > 0; i--) {
                if (time > eventStartTime[autoIds[i - 1]] && time < eventEndTime[autoIds[i]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i - 1]];
                    ev.venue = linkIdToEvent[autoIds[i - 1]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i - 1]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i - 1]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i - 1]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i - 1]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i - 1]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i - 1]].publishTime;
                    ev.state = "Live";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }
        return events;
    }

    /**
     * ExpiredEvents
     * @param _sort - Pass the 1 for ascending and 0 or any number for descending
     */
    function ExpiredEvents(uint _sort) external view returns (EventStatusForRead[] memory) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < autoIds.length; i++) {
            if (time > eventEndTime[autoIds[i]]) {
                count++;
            }
        }
        EventStatusForRead[] memory events = new EventStatusForRead[](count);
        if(_sort == 1){
            for (uint i = 0; i < autoIds.length; i++) {
                if (time > eventEndTime[autoIds[i]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i]];
                    ev.venue = linkIdToEvent[autoIds[i]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i]].publishTime;
                    ev.state = "Expired";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }else{
            for (uint i = autoIds.length; i > 0; i--) {
                if (time > eventEndTime[autoIds[i - 1]]) {
                    EventStatusForRead memory ev;
                    ev.eventTitle = eventMapName[autoIds[i - 1]];
                    ev.venue = linkIdToEvent[autoIds[i - 1]].venue;
                    ev.startDate = linkIdToEvent[autoIds[i - 1]].startDate;
                    ev.endDate = linkIdToEvent[autoIds[i - 1]].endDate;
                    ev.ticketsQuantity = linkIdToEvent[autoIds[i - 1]].ticketsQuantity;
                    ev.ticketPrice = linkIdToEvent[autoIds[i - 1]].ticketPrice;
                    ev.maxTicketPerPerson = linkIdToEvent[autoIds[i - 1]].maxTicketPerPerson;
                    ev.publishTime =  linkIdToEvent[autoIds[i - 1]].publishTime;
                    ev.state = "Expired";
                    events[proposalCount] = ev;
                    proposalCount++;
                }
            }
        }
        return events;
    }

    /**
     * viewAllIds - All created Ids
     */
    function viewAllIds() external view returns(uint[] memory allIds){
        return autoIds;
    }

    /**
     * balancePerEventForAdmin
     * @param _ad - admin address
     * @param _eventId - pass the event id
     */
    function balancePerEventForAdmin(address _ad, uint _eventId) public view returns(uint CollectedPayment){
        return adminBalanceAssociatedToEvent[_ad][_eventId];
    }

    /**
     * balancePerEvent
     * @param _eventId - pass the event id
     */
    function balancePerEvent(uint _eventId) public view returns(uint CollectedPaymentPerEvent){
        return perEventCollection[_eventId];
    }
}