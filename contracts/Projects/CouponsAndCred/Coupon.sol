// SPDX-License-Identifier: MIT
/*
  /$$$$$$  /$$$$$$ /$$   /$$/$$$$$$$  /$$$$$$ /$$   /$$      
 /$$__  $$/$$__  $| $$  | $| $$__  $$/$$__  $| $$$ | $$      
| $$  \__| $$  \ $| $$  | $| $$  \ $| $$  \ $| $$$$| $$      
| $$     | $$  | $| $$  | $| $$$$$$$| $$  | $| $$ $$ $$      
| $$     | $$  | $| $$  | $| $$____/| $$  | $| $$  $$$$      
| $$    $| $$  | $| $$  | $| $$     | $$  | $| $$\  $$$      
|  $$$$$$|  $$$$$$|  $$$$$$| $$     |  $$$$$$| $$ \  $$      
 \______/ \______/ \______/|__/      \______/|__/  \__/
*/
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './Registration.sol';
contract CouponContract is ERC721, Ownable{
    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error URIQueryForNonexistentToken();    
    error NotAnAdmin();
    error IdIsAlreadyTake();
    error IdIsNotYetCreated();
    error CheckTheDateOfCoupon();
    error AlreadyRedeemed();
    error AccessDenied();
    error CouponDoesNotExist();
    error idIsNotCreatedByAdmin();
    // type - Address
    address[] private adminAddresses; 
    address private registrationConc;
    // type - Events
    event CouponCreated(uint indexed _tokenId, string indexed _ifpsURL, uint indexed _status);
    event Redeemed(address indexed _ad, uint indexed _couponId, uint indexed _tokenId);
    event EndDateUpdate(address indexed _whoUpdated, uint indexed _couponId, uint indexed _newEndDate);
    // type - Unit
    uint public someValue = 10;
    uint[] private tokenIds;
    uint private idCreate;
    uint private incrementToken;
    uint public couponCreated = 1;
    // type - String
    string private status_1 = "Coupon is Live";
    string private status_2 = "Coupon Expired";
    // type - Mapping
    mapping (address => bool) private admins;
    mapping(uint => bool) private idCheck;
    mapping(uint => tokenSpecification) private couponInformation;
    mapping(address => tokenSpecification) private linkAccountWithCoupon;
    mapping(address => mapping(uint => bool)) private linkConfirmation;
    mapping(address => uint) private totalCouponCountPerAddress;
    mapping(uint => bool) private statusOfUserAndCoupon;
    mapping(address => uint[]) private allCouponIdToUser;
    mapping(uint => uint[]) private couponLinkedIds;
    mapping(address => mapping(uint => bool)) private verifyDriverAddressWithID;
    // type - struct
    struct tokenSpecification{
        uint _tokenId;
        string _tokenURL;
        uint _startDate;
        uint _endDate;
    }
    // type - modifier
    modifier onlyAdmin () {
    if (_msgSender() != owner() && !admins[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }
    /**
     * @notice Used for verification
     * @param _registrationContract - Pass the registration contract address
     */
    constructor(address _registrationContract) ERC721("Digital Credential Coupons", "DC"){
        admins[msg.sender] = true;
        adminAddresses.push(msg.sender);
        registrationConc = _registrationContract;
    }
    /**
     * @notice admin can call this function to register a driver
     * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
     * @param _ad add address of admins to the contract.
     */
    function addAdmin(address _ad) external onlyAdmin{
        admins[_ad] = true;
        adminAddresses.push(_ad);
    }
    /**
     * @notice Admin creates the coupon for the users. 
     * @param _id - Enter the coupon id.
     * @param _ipfsUrl - Enter the ipfs url.
     * @param _start - Enter the start date.
     * @param _end - Enter the end date.
     */
    function createCoupon(uint _id, string memory _ipfsUrl, uint _start, uint _end) external onlyAdmin{
        if(idCheck[_id]){
            revert IdIsAlreadyTake();
        }
        couponInformation[_id]._tokenId = _id;
        couponInformation[_id]._tokenURL = _ipfsUrl;
        couponInformation[_id]._startDate = _start;
        couponInformation[_id]._endDate = _end;
        tokenIds.push(_id);
        idCheck[_id] = true;
        string memory ipfsStringified = string(abi.encodePacked(_ipfsUrl));
        emit CouponCreated(_id, ipfsStringified, couponCreated);
    }
    /**
     * @notice Admin will redeem the coupon to users.
     * @param _driverAddress - Pass the drivers wallet address.
     * @param _id - Pass the coupon id
     */
    function redeemCoupon(address _driverAddress, uint _id) external onlyAdmin{
        /**
         * whether the id is available
         * checking time is not lesser or greater
         * checking whether the same id is already redeemed by the user.
         */
        Registration regDriver = Registration(registrationConc);
        require(regDriver.isDriverRegistered(_driverAddress), "The address is not registered in the registration contract");
        incrementToken += 1;
        idCreate =  _id + incrementToken;
        if(!idCheck[_id]){
            revert CouponDoesNotExist();
        }
        if(block.timestamp < couponInformation[_id]._startDate && block.timestamp > couponInformation[_id]._endDate){
            revert CheckTheDateOfCoupon();
        }
        if(linkConfirmation[_driverAddress][_id]){
            revert AlreadyRedeemed();
        }
        _mint(_driverAddress, idCreate);
        linkAccountWithCoupon[_driverAddress]._tokenId = couponInformation[_id]._tokenId;
        linkAccountWithCoupon[_driverAddress]._tokenURL = couponInformation[_id]._tokenURL;
        linkAccountWithCoupon[_driverAddress]._startDate = couponInformation[_id]._startDate;
        linkAccountWithCoupon[_driverAddress]._endDate =couponInformation[_id]._endDate;
        totalCouponCountPerAddress[_driverAddress] += 1;
        allCouponIdToUser[_driverAddress].push(_id);
        linkConfirmation[_driverAddress][_id] = true;
        verifyDriverAddressWithID[_driverAddress][_id] = true;
        couponLinkedIds[_id].push(idCreate);
        emit Redeemed(_driverAddress, _id, idCreate);
    }
    /**
     * @notice View all created coupons and respective details.
     */
    function viewAllCreatedTokens() external view returns(tokenSpecification[] memory tokenspec){
        tokenSpecification[] memory tokens = new tokenSpecification[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++){
            tokenSpecification memory tokenspecs;
            tokenspecs._tokenId = couponInformation[tokenIds[i]]._tokenId;
            tokenspecs._tokenURL = couponInformation[tokenIds[i]]._tokenURL;
            tokenspecs._startDate = couponInformation[tokenIds[i]]._startDate;
            tokenspecs._endDate = couponInformation[tokenIds[i]]._endDate;
            tokens[i] = tokenspecs;
        }
        return tokens;
    }    
    /**
     * @notice Admin has the feature to remove link
     * @param _id - Coupon id.
     * @param _allAddress - Enter array of user addresses.
     */
    function removeCouponLinkToUser(uint _id, address[] memory _allAddress) external onlyAdmin{
        for(uint i = 0; i < _allAddress.length; i++){
             linkConfirmation[_allAddress[i]][_id] = false;
        }
    }
    /**
     * @notice Admins can edit the endDate.
     * @param _id - Enter the coupon Id.
     * @param _updateEndDate - Enter the updated End Date.
     */
    function editEndDate(uint _id, uint _updateEndDate) external onlyAdmin {
        if(!idCheck[_id]){
            revert IdIsNotYetCreated();
        }
        require(_updateEndDate > couponInformation[_id]._endDate,"enter date that is greater than current end date");
        couponInformation[_id]._endDate = _updateEndDate;
        emit EndDateUpdate(msg.sender, _id, _updateEndDate);
    }
    /**
     * @notice This is to know, whether the coupon is live or not.
     * @param _couponId - Enter the coupon id to know the status of the token.
     */
    function viewCouponStatus(uint _couponId) public view returns(bool status){
        if(block.timestamp > couponInformation[_couponId]._startDate && block.timestamp < couponInformation[_couponId]._endDate){
            status = true;
            return status;
        }else{
            status = false;
            return status;
        }
    }
    /**
     * @notice This is to know, Validity of the redeemed coupon to user.
     * @param _ad - Enter the user address.
     * @param _couponId - Enter the coupon id. 
     */
    function viewCouponValidityToUser(address _ad, uint _couponId) external view returns(
        uint couponId,
        uint startDate,
        uint endDate,
        string memory couponStatus
    ){
        if(linkConfirmation[_ad][_couponId] && viewCouponStatus(_couponId)){
            return (
            couponInformation[_couponId]._tokenId,
            couponInformation[_couponId]._startDate,
            couponInformation[_couponId]._endDate,
            status_1);
        }else{
            return(
            couponInformation[_couponId]._tokenId,
            couponInformation[_couponId]._startDate,
            couponInformation[_couponId]._endDate,
            status_2);
        }
    }
    /**
     * @notice returns all created coupon count.
     */
    function totalCouponsCount() external view returns(uint totalCount){
        return tokenIds.length;
    }
    /**
     * @notice returns all created coupon ids.
     */
    function allCouponIds(uint _value) external view returns(uint[] memory allCreatedIds){
        if(_value == someValue){
            return tokenIds;
        }else{
            revert("error");
        }
        
    }
    /**
     * @notice returns all admin addresses.
     */
    function allAdminAddresses() external view returns(address[] memory allAdminAddress){
        return adminAddresses;
    }
    /**
     * @notice returns total coupons per address.
     */
    function couponsPerAddress(address _ad) external view returns(uint[] memory allCouponIdsOfUsers, uint totalCoupons){
        return (
        allCouponIdToUser[_ad],
        totalCouponCountPerAddress[_ad]);
    }
    /**
     * @notice Check whether the coupon is linked
     * @param _id - Pass the coupon id
     */
    function couponAndRelatedTokenIds(uint _id) external view returns(uint[] memory couponRelatedIds){
        return couponLinkedIds[_id];
    }
    /**
     * @notice Whether the coupon is created or not
     * @param _id - Pass the coupon id
     */
    function couponCreatedOrNotCreatedStatus(uint _id) external view returns(bool status){
        return idCheck[_id];
    }
    /**
     * @notice Verify the driver address.
     * @param _driverAddress - Pass the driver wallet address
     * @param _id - Pass the coupon id
     */
    function verifyDriverAd(address _driverAddress, uint _id) external view returns(bool){
        return verifyDriverAddressWithID[_driverAddress][_id];
    }
}