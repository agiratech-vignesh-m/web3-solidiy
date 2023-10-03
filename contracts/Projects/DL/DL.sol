// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract DreamLighter {
    // errors
    error NotAnAdmin();
    error NotBroker();
    error NotDriver();
    error NotFleetOwner();
    error IdIsAlreadyExist();
    error AddressIsAlreadyExist();
    error BrokerUpdateFailed();
    // State varaibles
    address[] public adminAddress;
    address[] public brokerAddress;
    address[] public driverAddress;
    address[] public fleetOwnerAddress;

    uint256 public brokerCount;
    uint256 public driverCount;
    uint256 public fleetOwnerCount;

    uint256[] public brokerIds;
    uint256[] public driverIds;
    uint256[] public fleetOwnerIds;

    struct Broker {
        uint256 id;
        string firstName;
        string lastName;
        address _address;
    }

    mapping(uint256 => Broker) public brokerStruct;
    mapping(address => bool) public linkBrokersAddress;
    mapping(uint256 => bool) public linkBrokersId;

    struct Driver {
        uint256 id;
        string firstName;
        string LastName;
        address _address;
        uint256 licenseNumber;
        bool flettOwner;
    }

    mapping(uint256 => Driver) public drivers;
    mapping(address => bool) private admins;
    mapping(address => bool) private brokers;

    // mapping(address => bool) private newAdmin;

    event BrokerCreated(
        uint256 indexed id,
        string firstName,
        string lastname,
        address brokerAddress
    );

    modifier onlyAdmin() {
        if (!admins[msg.sender]) {
            revert NotAnAdmin();
        }
        _;
    }

    modifier onlyBroker() {
        // require(brokers[brokerAddress] = true, "Only broker can call this function");
        // _;
        if (!brokers[msg.sender]) {
            revert NotAnAdmin();
        }
        _;
    }

    constructor() {
        admins[msg.sender] = true;
        adminAddress.push(msg.sender);
    }

    function getAdminAddress() public view returns (address[] memory) {
        return adminAddress;
    }

    function addAdmin(address newAdmin) public onlyAdmin {
        require(!admins[newAdmin], "New address is already an admin");

        admins[newAdmin] = true;

        adminAddress.push(newAdmin);
    }

    function editAdmin(address oldAdmin, address newAdmin) public onlyAdmin {
        require(admins[oldAdmin], "Old address is not an admin");
        require(!admins[newAdmin], "New address is already an admin");

        admins[oldAdmin] = false;
        admins[newAdmin] = true;

        // Replace the old admin address with the new admin address in the adminAddress array
        for (uint256 i = 0; i < adminAddress.length; i++) {
            if (adminAddress[i] == oldAdmin) {
                adminAddress[i] = newAdmin;
                break;
            }
        }
    }

    function setBroker(
        uint256 id,
        string memory firstName,
        string memory lastName,
        address _address
    ) public onlyAdmin {
        if (linkBrokersId[id]) {
            revert IdIsAlreadyExist();
        } else if (linkBrokersAddress[_address]) {
            revert AddressIsAlreadyExist();
        }

        brokerStruct[id].id = id;
        brokerStruct[id].firstName = firstName;
        brokerStruct[id].lastName = lastName;
        brokerStruct[id]._address = _address;
        linkBrokersAddress[_address] = true;
        linkBrokersId[id] = true;

        brokerIds.push(id);
        brokerAddress.push(_address);
        emit BrokerCreated(id, firstName, lastName, _address);
    }

    function editBroker(
        uint256 id,
        string memory firstName,
        string memory lastName,
        address _address
    ) public onlyAdmin {
        require(brokerStruct[id].id == id, "Broker does not exist");
        // if (linkBrokersAddress[_address]){
        //     revert AddressIsAlreadyExist();
        // }

        bytes32 encodeOldFirstName = keccak256(
            abi.encodePacked(brokerStruct[id].firstName)
        );
        bytes32 encodeNewFirstName = keccak256(abi.encodePacked(firstName));
        bytes32 encodeOldLastName = keccak256(
            abi.encodePacked(brokerStruct[id].lastName)
        );
        bytes32 encodeNewLastName = keccak256(abi.encodePacked(lastName));

        if (
            encodeOldFirstName != encodeNewFirstName &&
            encodeOldLastName != encodeNewLastName &&
            brokerStruct[id]._address != _address
        ) {
            brokerStruct[id].firstName = firstName;
            brokerStruct[id].lastName = lastName;
            brokerStruct[id]._address = _address;
            // linkBrokersAddress[_address] = true;
        }
        if (
            encodeOldFirstName != encodeNewFirstName &&
            encodeOldLastName != encodeNewLastName
        ) {
            brokerStruct[id].firstName = firstName;
            brokerStruct[id].lastName = lastName;
        }
        if (
            encodeOldFirstName != encodeNewFirstName &&
            brokerStruct[id]._address != _address
        ) {
            brokerStruct[id].firstName = firstName;
            brokerStruct[id]._address = _address;
            // linkBrokersAddress[_address] = true;
        }
        if (
            encodeOldLastName != encodeNewLastName &&
            brokerStruct[id]._address != _address
        ) {
            brokerStruct[id].lastName = lastName;
            brokerStruct[id]._address = _address;
            // linkBrokersAddress[_address] = true;
        }
        if (encodeOldFirstName != encodeNewFirstName) {
            brokerStruct[id].firstName = firstName;
        }
        if (encodeOldLastName != encodeNewLastName) {
            brokerStruct[id].lastName = lastName;
        }

        if (brokerStruct[id]._address != _address) {
            brokerStruct[id]._address = _address;
            // linkBrokersAddress[_address] = true;
        }

        if (
            encodeOldFirstName == encodeNewFirstName &&
            encodeOldLastName == encodeNewLastName &&
            brokerStruct[id]._address == _address
        ) {
            revert BrokerUpdateFailed();
        }

        // brokerIds.push(id);
        // brokerAddress.push(_address);
    }

    // function brokerStatus() public view returns () {
    //     return
    // }

    function getBroker(
        uint256 id
    ) public view returns (uint256, string memory, string memory, address) {
        Broker memory broker = brokerStruct[id];
        return (broker.id, broker.firstName, broker.lastName, broker._address);
    }

    function allBrokerDetails() public view returns (Broker[] memory _details) {
        Broker[] memory detailss = new Broker[](brokerIds.length);
        for (uint i = 0; i < brokerIds.length; i++) {
            Broker memory brokerInfo;
            brokerInfo.id = brokerStruct[brokerIds[i]].id;
            brokerInfo.firstName = brokerStruct[brokerIds[i]].firstName;
            brokerInfo.lastName = brokerStruct[brokerIds[i]].lastName;
            brokerInfo._address = brokerStruct[brokerIds[i]]._address;
            detailss[i] = brokerInfo;
        }
        return detailss;
    }

    // function getAllBrokers() public view returns (Broker[] memory) {
    //         Broker[] memory allBrokers = new Broker[](brokerAddress.length);
    //         for (uint256 i = 0; i < brokerAddress.length; i++) {
    //             address brokerAddr = brokerAddress[i];
    //             allBrokers[i] = brokerStruct[brokerAddr];
    //         }
    //         return allBrokers;
    //     }

    //     function getAllBrokers()

    //     public view returns(
    //         Broker[] memory details
    //     )
    //     {
    //         Broker[] memory fullDetails = new Broker[](
    //             brokerIds.length
    //         );
    //         for (uint i = 0; i < brokerIds.length; i++) {
    //             // Broker memory brokerDetails;
    //             //     candidates[candidateId].candidateId,
    //             //    candidates[candidateId].age,
    //             //    candidates[candidateId].name,
    //             //    candidates[candidateId].image,
    //             //    candidates[candidateId].voteCount,
    //             //    candidates[candidateId]._address,
    //             //    candidates[candidateId].ipfs
    //             address brokerAddress = brokerStruct[_address][i]]._address;
    //             // brokerDetails.id = brokerStruct[_address[i]].id;
    //             // brokerDetails.firstName = brokerStruct[_address[i]].firstName;
    //             // brokerDetails.lastName = brokerStruct[_address[i]].lastName;
    //             // brokerDetails._address = brokerStruct[_address[i]]._address;

    //             // fullDetails[i] = brokerDetails;
    //             allBrokers[i] = brokerStruct[brokerAddress];
    //         }
    //         return allBrokers;
    // }
}

// Get all details in struct
/*
function getAllUserDetails() external view returns (UserInformation[] memory userInfos) {
    userInfos = new UserInformation[](autoIds.length);

    for (uint i = 0; i < autoIds.length; i++) {
        uint userId = autoIds[i];
        address userAddress = linkIdToUserAddress[userId];

        UserInformation memory userInfo = userInfostruct[userAddress][userId];
        userInfos[i] = userInfo;
    }

    return userInfos;
}
*/
