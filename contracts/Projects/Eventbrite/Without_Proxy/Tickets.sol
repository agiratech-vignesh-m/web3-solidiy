// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Registration.sol";
import "./EVNT.sol";

contract Ticketing is ERC721, Ownable{

    // Errors
    error maxLimitExceeded();

    event NewTicketCreated(string indexed eventName, uint indexed creatorAddress, uint indexed ticketsCount);
    event NFTMinted(uint indexed tokenId);

    address private contractAdmin;
    address private registrationContract;
    address private evntTokenAddress;

    uint private autoGenerateId = 100;
    uint private nftId = 100000;

    uint[] public nftIds;
    uint[] public autoIds;
    uint[] private ticketsCountForEvents;

    mapping(uint => EventInformation) private linkIdToEvent;
    mapping(uint => mapping(uint => bool)) private linkEventIdToTicketQuantity;
    // mapping(uint => mapping(uint => bool)) private linkEventIdToTicketPrice;


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

    modifier onlyAdmin(){
        require(contractAdmin == msg.sender, "only contractAdming can call this function");
        _;
    }
    
    constructor(address _registrationContract, address _evntTokenAddress) ERC721("EventBriteTickets", "EVNT-TIC") {
        contractAdmin = msg.sender;
        registrationContract = _registrationContract;
        evntTokenAddress = _evntTokenAddress;
    }
    //  Id should be mapped with Ticket Quantity -
    // ERC20 need to deploy 
    function createEvent(EventInformation memory _event) public onlyAdmin{
        
        uint incrementId = 1;
        autoGenerateId = autoGenerateId + incrementId;
        linkIdToEvent[autoGenerateId].eventTitle = _event.eventTitle;
        linkIdToEvent[autoGenerateId].venue = _event.venue;
        // linkIdToEvent[autoGenerateId].walletAddress = _event.walletAddress;
        // linkIdToEvent[autoGenerateId].ipfsUrlImage = _event.ipfsUrlImage;
        linkIdToEvent[autoGenerateId].startDate = _event.startDate;
        linkIdToEvent[autoGenerateId].endDate = _event.endDate;
        linkIdToEvent[autoGenerateId].ticketsQuantity = _event.ticketsQuantity;
        linkIdToEvent[autoGenerateId].ticketPrice = _event.ticketPrice;
        linkIdToEvent[autoGenerateId].maxTicketPerPerson = _event.maxTicketPerPerson;
        linkIdToEvent[autoGenerateId].publishTime = _event.publishTime;
        // Linked the EventID to TicketQuantity and Ticketprice
        linkEventIdToTicketQuantity[autoGenerateId][_event.ticketsQuantity]=true;
        // linkEventIdToTicketPrice[autoGenerateId][_event.ticketPrice]=true;

        autoIds.push(autoGenerateId);
       
        emit NewTicketCreated(_event.eventTitle,_event.publishTime,_event.ticketsQuantity);
    }

    // Need to check
    // function approveEVNT(uint256 amount) public {
    //         EventBriteCoin evnt = EventBriteCoin(evntTokenAddress);
    //         evnt.approve(address(this), amount);
    // }

    function buyTickets(uint _userId, uint _eventId, uint _ticketCount) public {
            Registration user = Registration(registrationContract);
            require(user.checkUserVerification(msg.sender, _userId)== true, "User is not registered");

            EventBriteCoin evnt = EventBriteCoin(evntTokenAddress);
            uint ticketPrice = linkIdToEvent[_eventId].ticketPrice;  // Retrieve the ticket price
            require(evnt.balanceOf(msg.sender) >= ticketPrice, "Insufficient EVNT balance"); 
            
            uint ticketquantity = linkIdToEvent[_eventId].ticketsQuantity;  // Retrieve the ticket quantity
            require(_ticketCount <= ticketquantity, "Ticket limit exceeded"); 

            // MaxTicket Per person
            uint maxTicketPerPerson = linkIdToEvent[_eventId].maxTicketPerPerson;  // Retrieve the ticket quantity
            require(_ticketCount <= maxTicketPerPerson, "Maximum ticket limit exceeded"); 

            uint eventPublishTime = linkIdToEvent[_eventId].publishTime;  // Retrieve the ticket quantity
            require(block.timestamp >= eventPublishTime, "The Event is not yet published");

            // It will deduct the EVNT balance from the user
            uint totalPrice = ticketPrice * _ticketCount;
            IERC20(evnt).transferFrom(msg.sender, address(this), totalPrice);

            // _mint(msg.sender, _ticketCount);    
            // Need to add Loop 

            // Will be Minting NFTs as per user request
            for (uint i = 0; i < _ticketCount; i++) {
            uint incrementNFTId = 1;
            nftId = nftId + incrementNFTId;
            _mint(msg.sender, nftId);
            nftIds.push(nftId);
            emit NFTMinted(nftId);
            }

            // It will update the ticket quantity for the event
            linkIdToEvent[_eventId].ticketsQuantity -= _ticketCount;
            // Need to check Wei format

            }

    function getEventsDetailsStruct(uint256 _eventId) external view returns(
        EventInformation memory _eventDetails){
        return (
        linkIdToEvent[_eventId]
        );
    }
}