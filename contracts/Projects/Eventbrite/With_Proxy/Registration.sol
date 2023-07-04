// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Registration is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    // error
    error addressMismatching();

    // state variables
    uint private autoGenerateId;
    uint[] private autoIds;
    address[] private allUserAddresses;
    UserAddressAndIdDetails[] private userDetails;

    // Events
    event UserRegistered(uint indexed _userId, address indexed _userAddress, uint indexed _status);

    // structs

     struct UserInformation{
        string firstName;
        string lastName;
        string email;
        uint phoneNumber;
        address walletAddress;
    }

    struct UserAddressAndIdDetails {
        address userAddress;
        uint userId;
    }

    // mappings

    mapping(address => mapping(uint => bool)) private checkUserAddressAndIdLinked;
    mapping(address => mapping(uint => UserInformation)) private userInfostruct;
    mapping(uint => address) private linkIdToUserAddress;


    function initialize() external initializer{
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        autoGenerateId = 1000;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addUser( UserInformation memory _userInfo) public {
        UserInformation memory ui = _userInfo;

        if (msg.sender != ui.walletAddress){
            revert addressMismatching();
        }    

        uint incrementCreationId = 1;
        autoGenerateId = autoGenerateId + incrementCreationId;
        autoIds.push(autoGenerateId);

        userInfostruct[ui.walletAddress][autoGenerateId].firstName = ui.firstName;
        userInfostruct[ui.walletAddress][autoGenerateId].lastName = ui.lastName;
        userInfostruct[ui.walletAddress][autoGenerateId].email = ui.email;
        userInfostruct[ui.walletAddress][autoGenerateId].phoneNumber = ui.phoneNumber;
        userInfostruct[ui.walletAddress][autoGenerateId].walletAddress = ui.walletAddress;
        
        allUserAddresses.push(ui.walletAddress);
        linkIdToUserAddress[autoGenerateId] = ui.walletAddress;
        
        checkUserAddressAndIdLinked[ui.walletAddress][autoGenerateId] = true;

        userDetails.push(UserAddressAndIdDetails(ui.walletAddress, autoGenerateId));
        emit UserRegistered(autoGenerateId, ui.walletAddress, 200);
    }

    function getAllIds() public view returns (uint[] memory autoId){
        return autoIds;
    }

    function checkUserVerification(address _userAddress, uint _userID) external view returns(bool){
        return checkUserAddressAndIdLinked[_userAddress][_userID];
    }

    function getUserDetails( address _userAddress, uint256 _userId) external view returns(
        string memory firstName,
        string memory lastName,
        string memory email,
        uint256 phoneNumber,
        address walletAddress
        ){
        return (
        userInfostruct[_userAddress][_userId].firstName,
        userInfostruct[_userAddress][_userId].lastName,
        userInfostruct[_userAddress][_userId].email,
        userInfostruct[_userAddress][_userId].phoneNumber,  
        userInfostruct[_userAddress][_userId].walletAddress
        );

    }

    function getUserDetailsStruct( address _userAddress, uint256 _userId) external view returns(
        UserInformation memory _userDetails){
        return (
        userInfostruct[_userAddress][_userId]
        );
    }

//     function getAllUserDetails() external view returns (UserInformation[] memory _allUderDetails)
//     {    
//     UserInformation[] memory userDetails = new UserInformation[](autoIds.length);
//     for (uint i = 0; i < autoIds.length; i++) {
//         UserInformation memory userInfo;
            
//         userInfo.firstName = userInfostruct[autoIds[i]].firstName;
//         userInfostruct[autoIds[i]].lastName;
//         userInfostruct[autoIds[i]].email;
//         userInfostruct[autoIds[i]].phoneNumber;
//         userInfostruct[autoIds[i]].walletAddress;
//         userDetails[i] = userInfo;
//     }
//     return userDetails;
// }

    // Get all user details

    function getAllUserDetails() external view returns (UserInformation[] memory) {
        UserInformation[] memory userDetail = new UserInformation[](autoIds.length);
        for (uint i = 0; i < autoIds.length; i++) {
            userDetail[i] = userInfostruct[linkIdToUserAddress[autoIds[i]]][autoIds[i]];
        }
        return userDetail;
    }

    // Listing all ID and address
    
    function getAllUserAddresses() external view returns (address[] memory userAddresses){
        return allUserAddresses;
    }

    // function getAllUserAddressesAndIds() public view returns (address[] memory userAddresses, uint[] memory userId){
    //     return (allUserAddresses, autoIds);
    // }

    // Get all address

    // method 1

    // function getAllUserAddressesAndIds() public view returns (address[] memory userAddresses, uint[] memory userId){
    //     return (allUserAddresses, autoIds);
    // }

    function getAllUserAddressesAndIds() external view returns (UserAddressAndIdDetails[] memory usersAddressesAndId){
    return userDetails;
    }

    //UUPS
}