// SPDX-License-Identifier: MIT
/*

  /$$$$$$                            /$$                       /$$     /$$           /$$ /$$                    
 /$$__  $$                          | $$                      | $$    |__/          | $$|__/                    
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$   /$$  /$$$$$$ | $$ /$$ /$$$$$$$   /$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$|_  $$_/  | $$ |____  $$| $$| $$| $$__  $$ /$$__  $$
| $$      | $$  \__/| $$$$$$$$| $$  | $$| $$$$$$$$| $$  \ $$  | $$    | $$  /$$$$$$$| $$| $$| $$  \ $$| $$  \ $$
| $$    $$| $$      | $$_____/| $$  | $$| $$_____/| $$  | $$  | $$ /$$| $$ /$$__  $$| $$| $$| $$  | $$| $$  | $$
|  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$|  $$$$$$$| $$| $$| $$  | $$|  $$$$$$$
 \______/ |__/       \_______/ \_______/ \_______/|__/  |__/   \___/  |__/ \_______/|__/|__/|__/  |__/ \____  $$
                                                                                                       /$$  \ $$
                                                                                                      |  $$$$$$/
                                                                                                       \______/

*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract Credentialing is Ownable {

    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error DriverAddressIsNotLinkedToCoupon();    
    error DataNotAvailable();
    error NotAnAdmin();
    error SameDataAlreadyStored();
    error AccessNotGranted();
    error AlreadyLinked();
    error errorInEdit();
    error oldLicenseMatchesEditedLicense();
    error LicenseNumberAlreadyExist();

    // type - Address
    address[] private adminAddresses;
    address[] private users;

    // type - uint
    uint constant private Status_Success = 200;

    // type - string
    string[] private licenseArray;

    // type - Event
    event DataCredentialized(bytes32 indexed _unlockKey, address indexed _driver, uint indexed _status);
    event DataCredentialEdited(address indexed _driver, uint indexed _NoOfTimesEdited, uint indexed _status);
    event DataLicenseEdited(address indexed _driver, string indexed _licenseNumber, uint indexed _status, uint _NoOfTimesEdited);
    event DataEdited  (address indexed _driver, bool indexed _updatedBoth, uint indexed _status, uint _NoOfTimesEdited);

    // type - Mapping
    mapping(address => mapping(string => bool)) private storeCredentails;
    mapping(address => bool) private admins;
    mapping(address => CredentializeData) private allInfo;
    mapping(address => mapping(string => bool)) private whetherIpfsAndAddressLinked;
    mapping(address => bytes32) private unlockKey;
    mapping(address => mapping(bytes32 => bool)) private accessKey;
    mapping(address => bool) private accessForRead;
    mapping(address => mapping(string => bool)) private linkLicenseNumberBool;
    mapping(address => mapping(string => bool)) private linkLicenseBool;
    mapping(address => string) private returnLicenseKey; // ipfs => license key
    mapping(address => string) private returnIPFSKey; // ipfs => license key
    mapping(address => bool) private isRegisteredDriver;
    mapping(string => bool) private sameLicenseCheck;

    // type - Modifier
    modifier onlyAdmin () {
    if (_msgSender() != owner() && !admins[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }

    // type - Struct
    struct CredentializeData{
        address driverAddress;
        string licenseKey;
        string[] ipfsURL;
        uint count;
    }

    // /**
    //  * @notice Used for verification
    //  * @param _registrationContract - Pass the registration contract address
    //  */
    // constructor(address _registrationContract) {
    //     admins[msg.sender] = true;
    //     registrationConc = _registrationContract;
    // }

    // /**
    //  * @notice admin can call this function to register a driver
    //  * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
    //  * @param _ad add address of admins to the contract.
    //  */
    // function addAdmin(address _ad) external onlyAdmin{
    //     admins[_ad] = true;
    //     adminAddresses.push(_ad);
    // }

    /**
     * @notice enter the credentialing details for the driver
     * @dev only one of the registered admins can call this function
     * @param _driverAddress - Pass the driver wallet address.
     * @param _licenseNumber - Pass the driver license number.
     * @param _ipfsUrl - Pass the ipfs url respective to the driver.
     */
    function driverCredential(address _driverAddress, string memory _licenseNumber, string memory _ipfsUrl) external onlyAdmin{
        require(!isRegisteredDriver[_driverAddress],"This driver is already registered");
        users.push(_driverAddress);
        isRegisteredDriver[_driverAddress] = true;
        bytes32 packedData = keccak256(abi.encodePacked(_driverAddress));
        if(storeCredentails[_driverAddress][_ipfsUrl]){
            revert SameDataAlreadyStored();
        }
        if(linkLicenseNumberBool[_driverAddress][_licenseNumber]){
            revert AlreadyLinked();
        }
        if(sameLicenseCheck[_licenseNumber]){
            revert LicenseNumberAlreadyExist();
        }
        allInfo[_driverAddress].driverAddress = _driverAddress;
        allInfo[_driverAddress].licenseKey = _licenseNumber;
        allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
        allInfo[_driverAddress].count += 1;
        storeCredentails[_driverAddress][_ipfsUrl] = true;
        whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
        unlockKey[_driverAddress] = packedData;
        accessKey[_driverAddress][packedData] = true;
        linkLicenseNumberBool[_driverAddress][_licenseNumber] = true;
        returnLicenseKey[_driverAddress] = _licenseNumber;
        sameLicenseCheck[_licenseNumber] = true;
        returnIPFSKey[_driverAddress] = _ipfsUrl;
        linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]] = true;
        licenseArray.push(_licenseNumber);
        emit DataCredentialized(packedData, _driverAddress, Status_Success);
    }

    /**
     * editCredential - Edit the credential for the users.
     * @param _driverAddress - Enter the driver wallet address.
     * @param _ipfsUrl - Enter the new IPFS url. 
     */
    function editCredential(address _driverAddress, string memory _ipfsUrl) external onlyAdmin{
        require(isRegisteredDriver[_driverAddress], "The address is not registered yet");
        bytes32 encodeOldIPFS = keccak256(abi.encodePacked(returnIPFSKey[_driverAddress]));
        bytes32  encodeNewIPFS = keccak256(abi.encodePacked(_ipfsUrl));
        if(encodeNewIPFS == encodeOldIPFS){
            revert errorInEdit();
        }
        if(linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]]){
            allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
            whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
            returnIPFSKey[_driverAddress] = _ipfsUrl;
            allInfo[_driverAddress].count += 1;
            emit DataCredentialEdited(_driverAddress, allInfo[_driverAddress].count, Status_Success);
        }else{
            revert("Initial credentialize is not done");
        }
    }

     /**
     * editLicense - Edit the credential for the users.
     * @param _driverAddress - Enter the driver wallet address.
     * @param _licenseNumber - Enter the new license key.
     */
    function editLicense(address _driverAddress, string memory _licenseNumber) external onlyAdmin{
        require(isRegisteredDriver[_driverAddress], "The address is not registered yet");
        if(sameLicenseCheck[_licenseNumber]){
            revert LicenseNumberAlreadyExist();
        }
        bytes32 encodeOldLicense = keccak256(abi.encodePacked(returnLicenseKey[_driverAddress]));
        bytes32  encodeNewLicense = keccak256(abi.encodePacked(_licenseNumber));
        if(encodeNewLicense == encodeOldLicense){
            revert errorInEdit();
        }
        if(linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]]){
            allInfo[_driverAddress].licenseKey = _licenseNumber;
            returnLicenseKey[_driverAddress] = _licenseNumber;
            linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]] = true;
            allInfo[_driverAddress].count += 1;
            emit DataLicenseEdited(_driverAddress, _licenseNumber, Status_Success, allInfo[_driverAddress].count);
        }else{
            revert("Initial credentialize is not done");
        }
    }

     /**
     * @notice editCredentialAndLicense
     * @param _driverAddress - Enter the driver wallet address.
     * @param _licenseNumber - Enter the new license key.
     */
    function editCredentialAndLicense(address _driverAddress, string memory _licenseNumber, string memory _ipfsUrl) external onlyAdmin{
        require(isRegisteredDriver[_driverAddress], "The address is not registered yet");
        if(sameLicenseCheck[_licenseNumber]){
            revert LicenseNumberAlreadyExist();
        }
        bytes32 encodeOldLicense = keccak256(abi.encodePacked(returnLicenseKey[_driverAddress]));
        bytes32 encodeNewLicense = keccak256(abi.encodePacked(_licenseNumber));
        bytes32 encodeOldIPFS = keccak256(abi.encodePacked(returnIPFSKey[_driverAddress]));
        bytes32 encodeNewIPFS = keccak256(abi.encodePacked(_ipfsUrl));
        if(encodeNewLicense != encodeOldLicense && linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]]){
          allInfo[_driverAddress].licenseKey = _licenseNumber;
          returnLicenseKey[_driverAddress] = _licenseNumber;
          linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]] = true;
          allInfo[_driverAddress].count += 1;
        }
        else if(encodeNewIPFS != encodeOldIPFS && linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]]){
          allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
          whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
          returnIPFSKey[_driverAddress] = _ipfsUrl;
          allInfo[_driverAddress].count += 1;
        }
        else if(encodeNewLicense == encodeOldLicense){
            revert errorInEdit();
        }
        else if(encodeNewIPFS == encodeOldIPFS){
            revert errorInEdit();
        }
        else {
            revert("Initial credentialize is not done");
        }
        // emit DataEdited(_driverAddress, true, Status_Success, allInfo[_driverAddress].count);
        // if(linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]]){
        //     allInfo[_driverAddress].licenseKey = _licenseNumber;
        //     returnLicenseKey[_driverAddress] = _licenseNumber;
        //     allInfo[_driverAddress].ipfsURL.push(_ipfsUrl);
        //     returnIPFSKey[_driverAddress] = _ipfsUrl;
        //     whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl] = true;
        //     linkLicenseBool[_driverAddress][returnLicenseKey[_driverAddress]] = true;
        //     allInfo[_driverAddress].count += 1;
        //     emit DataBothEdited(_driverAddress, true, Status_Success, allInfo[_driverAddress].count);
        // }
        
    }
    
    /**
     * getReadAccess - The driver is expected give access to read the URLS.
     * @param _driverAddress - Enter the driver address.
     */
    function getReadAccess(address _driverAddress) external returns(bool status){
        require(isRegisteredDriver[_driverAddress], "The address is not registered yet");
        require(msg.sender == _driverAddress);
        if(accessKey[_driverAddress][unlockKey[_driverAddress]]){
            accessForRead[msg.sender] = true;
            status = true;
            return status;
        }else{
            status = false;
            return status;
        }
    }

    /**
     * viewAllIpfsURL - If permission is granted then the user can view the IPFS urls.
     * @param _driverAddress - Enter the driver address.
     */
    function viewAllIpfsURL(address _driverAddress) external view returns(string[] memory allUrls){
        if(accessForRead[_driverAddress]){
            return allInfo[_driverAddress].ipfsURL;
        }else{
            revert ("Access not provided by the driver yet");
        }
    }
    
    /**
     * @notice returns number of times credentials
     * @param _driverAddress pass the bytes32 value from the event.
     */
    function viewCredentialAddedTimes(address _driverAddress) external view 
    returns( uint totalNumberOfTimesEdited){
        return allInfo[_driverAddress].count;
    }

    /**
     * whetherAddressAndIpfsLinked - Checks wether the address and ipfs is linked.
     * @param _driverAddress - Enter the driver wallet address.
     * @param _ipfsUrl - Pass the ipfs url respective to the driver.
     */
    function whetherAddressAndIpfsLinked(address _driverAddress, string memory _ipfsUrl) external view 
    returns (bool linked){
        if(whetherIpfsAndAddressLinked[_driverAddress][_ipfsUrl]){
            return true;
        }else{
            return false;
        }
    }

    /**
     * @notice showLicenseKey
     * @param _driverAddress - Enter the driver address to get the license key.
     */
    function showLicenseKey(address _driverAddress) external view returns(string memory associatedLicenseKey){
        return returnLicenseKey[_driverAddress];
    }

    /**
     * @notice checks if the input driver address is registered or not
     * @param _driverAddress address of the driver which is to be checked if registered or not
     * @return driverRegistrationStatus bool true if driver registered. false if not.
     */
    function isDriverRegistered(address _driverAddress) external view returns(bool driverRegistrationStatus) {
        return isRegisteredDriver[_driverAddress];
    }

    /**
     * @notice returns the address of all Drivers
     * @dev returns an address[]
     * @return allDrivers address array that contains address of all Drivers
     */
    function getAllDrivers() external view returns(address[] memory allDrivers){
        return users;
    }

    /**
     *  @notice returns the total no of registered drivers
     *  @dev returns a uint256 value
     *  @return driversCount number of registered drivers
     */
    function getNoOfDrivers() external view returns (uint driversCount){
        return users.length;
    }

}

