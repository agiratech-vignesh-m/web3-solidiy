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
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './Credentialing.sol';

contract Coupon is ERC721, Ownable{
    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error URIQueryForNonexistentToken();    
    error NotAnAdmin();
    error IdIsAlreadyTaken();
    error IdIsAlreadyLinked();
    error IdIsNotYetCreated();
    error CheckTheDateOfCoupon();
    error AlreadyRedeemed();
    error AccessDenied();
    error CouponDoesNotExist();
    error idIsNotCreatedByAdmin();

    // type - Address
    address[] private adminAddresses; 
    address private credentialConc;

    // type - Events
    event CouponCreated(uint indexed _tokenId, string indexed _ifpsURL, uint indexed _status);
    event Redeemed(address indexed _ad, uint indexed _couponId, uint indexed _status, uint tokenId);
    event EndDateUpdate(uint indexed _couponId, uint indexed _newEndDate, uint indexed _status);
    event EndDateUpdateAndMetadataUpdate(uint indexed _couponId, bool indexed _combinedEdit, uint indexed _status);
    event UpdatedMetaInformation(string indexed _couponStr, uint indexed _couponId, uint indexed _status);
    event DeactivateCouponState(string indexed _CouponNo, bool indexed _boolStatus, uint indexed _status);
    event DeactivateCouponsBulkState(string[] indexed _CouponNo, bool indexed _boolStatus, uint indexed _status);
    event ReactivateCouponState(string indexed _CouponNo, bool indexed _boolStatus, uint indexed _status);
    event ReactivateCouponsBulkState(string[] indexed _CouponNo, bool indexed _boolStatus, uint indexed _status);

    // type - Unit
    uint[] private tokenIds;
    uint private idCreate;
    uint private incrementToken;
    uint constant private Status_Success = 200;
    uint256 private autoGenerateId = 10000;
    uint256 private autoGenerateNftId = 100;

    // type - String
    string constant private status_1 = "Coupon is Live";
    string constant private status_2 = "Coupon Expired";
    string constant private status_3 = "Coupon not created";
    string constant private status_4 = "Coupon is deactivated";
    string[] private allCouponStrings;

    // type - Mapping
    mapping (address => bool) private admins;
    mapping(uint => bool) private idCheck;
    mapping(uint => TokenSpecification) private couponInformation;
    // mapping(address => TokenSpecification) private linkAccountWithCoupon;
    mapping(address => mapping(uint => bool)) private linkConfirmation;
    mapping(address => uint) private totalCouponCountPerAddress;
    mapping(address => uint[]) private allCouponIdToUser;
    mapping(uint => uint[]) private couponLinkedIds;
    mapping(address => mapping(uint => bool)) private verifyDriverAddressWithID;
    mapping(string => uint) private showCouponStringAndCouponId;
    mapping(string => mapping(uint => bool)) private linkCouponStringAndCouponId;
    mapping(string => mapping(uint => bool)) private couponHealth;
    mapping(uint256 => string) private holdUri;

    // type - struct
    struct TokenSpecification{
        string couponName;
        uint _tokenId;
        string[] _tokenURL;
        string _tokenURIOfIPFS;
        uint _startDate;
        uint _endDate;
    }

    struct OnlyLive{
        string _couponNameOfLive;
        string _status;
    }

    // type - modifier
    modifier onlyAdmin () {
    if (_msgSender() != owner() && !admins[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }

    // -------------------------------------------------------x

    // WRITE ACTIONS

    // -------------------------------------------------------x

    /**
     * @notice Used for verification
     * @param _credentialContract - Pass the registration contract address
     */
    constructor(address _credentialContract) ERC721("Excelsior Coupons", "EC"){
        admins[msg.sender] = true;
        adminAddresses.push(msg.sender);
        credentialConc = _credentialContract;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

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
     * @notice Admin creates the coupon for the users. 
     * @param _couponId - Enter the coupon id.
     * @param _ipfsUrl - Enter the ipfs url.
     * @param _start - Enter the start date.
     * @param _end - Enter the end date.
     */
    function createCoupon(string memory _couponId, string memory _ipfsUrl, uint _start, uint _end) external onlyAdmin{
        if(linkCouponStringAndCouponId[_couponId][autoGenerateId]){
            revert IdIsAlreadyLinked();
        }
        uint incrementCreationId = 1;
        autoGenerateId = autoGenerateId + incrementCreationId;
        couponInformation[autoGenerateId].couponName = _couponId;
        couponInformation[autoGenerateId]._tokenId = autoGenerateId;
        couponInformation[autoGenerateId]._tokenURL.push(_ipfsUrl);
        couponInformation[autoGenerateId]._tokenURIOfIPFS = _ipfsUrl;
        couponInformation[autoGenerateId]._startDate = _start;
        couponInformation[autoGenerateId]._endDate = _end;
        tokenIds.push(autoGenerateId);
        idCheck[autoGenerateId] = true;
        showCouponStringAndCouponId[_couponId] = autoGenerateId;
        linkCouponStringAndCouponId[_couponId][autoGenerateId] = true;
        couponHealth[_couponId][showCouponStringAndCouponId[_couponId]] = true;
        allCouponStrings.push(_couponId);
        emit CouponCreated(autoGenerateId, _ipfsUrl, Status_Success);
    }

    /**
     * @notice Admin will redeem the coupon to users.
     * @param _driverAddress - Pass the drivers wallet address.
     * @param _couponId - Pass the coupon id
     */
    function redeemCoupon(address _driverAddress, string memory _couponId) external onlyAdmin{
        /**
         * whether the id is available
         * checking time is not lesser or greater
         * checking whether the same id is already redeemed by the user.
         */
        Credentialing regDriver = Credentialing(credentialConc);
        require(regDriver.isDriverRegistered(_driverAddress), "The address is not registered in the registration contract");
        incrementToken += 1;
        idCreate = autoGenerateNftId + incrementToken;
        if(!idCheck[showCouponStringAndCouponId[_couponId]]){
            revert CouponDoesNotExist();
        }
        if(block.timestamp < couponInformation[showCouponStringAndCouponId[_couponId]]._startDate){
            revert CheckTheDateOfCoupon();
        }
        if(block.timestamp > couponInformation[showCouponStringAndCouponId[_couponId]]._endDate){
            revert CheckTheDateOfCoupon();
        }
        if(linkConfirmation[_driverAddress][showCouponStringAndCouponId[_couponId]]){
            revert AlreadyRedeemed();
        }
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            holdUri[idCreate] = couponInformation[showCouponStringAndCouponId[_couponId]]._tokenURIOfIPFS;
            _mint(_driverAddress, idCreate);
            // linkAccountWithCoupon[_driverAddress]._tokenId = couponInformation[showCouponStringAndCouponId[_couponId]]._tokenId;
            // linkAccountWithCoupon[_driverAddress]._tokenURL = couponInformation[showCouponStringAndCouponId[_couponId]]._tokenURL;
            // linkAccountWithCoupon[_driverAddress]._startDate = couponInformation[showCouponStringAndCouponId[_couponId]]._startDate;
            // linkAccountWithCoupon[_driverAddress]._endDate =couponInformation[showCouponStringAndCouponId[_couponId]]._endDate;
            totalCouponCountPerAddress[_driverAddress] += 1;
            allCouponIdToUser[_driverAddress].push(showCouponStringAndCouponId[_couponId]);
            linkConfirmation[_driverAddress][showCouponStringAndCouponId[_couponId]] = true;
            verifyDriverAddressWithID[_driverAddress][showCouponStringAndCouponId[_couponId]] = true;
            couponLinkedIds[showCouponStringAndCouponId[_couponId]].push(idCreate);
            emit Redeemed(_driverAddress, showCouponStringAndCouponId[_couponId], Status_Success, idCreate);
        }else{
            revert("coupon is deactivated");
        }
    }

    /**
     * @notice Admins can edit the endDate.
     * @param _couponId - Enter the coupon Id.
     * @param _updateEndDate - Enter the updated End Date.
     */
    function editEndDate(string memory _couponId, uint _updateEndDate) external onlyAdmin {
        if(!idCheck[showCouponStringAndCouponId[_couponId]]){
            revert IdIsNotYetCreated();
        }
        require(_updateEndDate > couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,"enter date that is greater than current end date");
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            couponInformation[showCouponStringAndCouponId[_couponId]]._endDate = _updateEndDate;
            emit EndDateUpdate(showCouponStringAndCouponId[_couponId], _updateEndDate, Status_Success);
        }else{
            revert("Coupon is deactivated");
        }
    }

    /**
     * @notice editCouponMetadata
     * @param _couponId - Pass the coupon string
     * @param _updatedIPFS - Pass the updated IPFS
     */
    function editCouponMetadata(string memory _couponId, string memory _updatedIPFS) external onlyAdmin{
        if(!idCheck[showCouponStringAndCouponId[_couponId]]){
            revert IdIsNotYetCreated();
        }
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            couponInformation[showCouponStringAndCouponId[_couponId]]._tokenURL.push(_updatedIPFS);
            holdUri[idCreate] = _updatedIPFS;
            emit UpdatedMetaInformation(_couponId, showCouponStringAndCouponId[_couponId], Status_Success);
        }else{
            revert("Coupon is deactivated");
        }
    }

    /**
     * @notice editEndDateAndMetadataIPFS
     * @param _couponId - Enter the coupon Id.
     * @param _updateEndDate - Enter the updated End Date.
     */
    function editEndDateAndMetadataIPFS(string memory _couponId, uint _updateEndDate, string memory _updatedIPFS) external onlyAdmin {
        if(!idCheck[showCouponStringAndCouponId[_couponId]]){
            revert IdIsNotYetCreated();
        }
        require(_updateEndDate > couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,"enter date that is greater than current end date");
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            couponInformation[showCouponStringAndCouponId[_couponId]]._endDate = _updateEndDate;
            couponInformation[showCouponStringAndCouponId[_couponId]]._tokenURL.push(_updatedIPFS);
            holdUri[idCreate] = _updatedIPFS;
            emit EndDateUpdateAndMetadataUpdate(showCouponStringAndCouponId[_couponId], true, Status_Success);
        }else{
            revert("Coupon is deactivated");
        }
    }

    /**
     * @notice DeactivateCoupon
     * @param _couponId - Enter the coupon id // eg get50% or get100%
     */
    function DeactivateCoupon(string memory _couponId) external onlyAdmin{
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            couponHealth[_couponId][showCouponStringAndCouponId[_couponId]] = false;
            emit DeactivateCouponState(_couponId, false, 200);
        }else{
            revert("Coupon does not exist");
        }
    }

    /**
     * notice DeactivateCouponBulk
     * @param _couponId - Enter array of names for the coupon // eg ["get50","get100"]
     */
    function DeactivateCouponsBulk(string[] memory _couponId) external onlyAdmin{
        for(uint i = 0; i < _couponId.length; i++){
            if(couponHealth[_couponId[i]][showCouponStringAndCouponId[_couponId[i]]]){
                couponHealth[_couponId[i]][showCouponStringAndCouponId[_couponId[i]]] = false;
                emit DeactivateCouponsBulkState(_couponId, false, 200);
            }else{
                revert("Coupon does not exist");
            }
        }
    }

    /**
     * @notice ReactivateCoupon
     * @param _couponId - Enter the coupon id // eg get50% or get100%
     */
    function ReactivateCoupon(string memory _couponId) external onlyAdmin{
        if(!couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            couponHealth[_couponId][showCouponStringAndCouponId[_couponId]] = true;
            emit ReactivateCouponState(_couponId, true, 200);
        }else{
            revert("Either Coupon is already live or end-date is expired");
        }
    }

    /**
     * @notice ReactivateCouponsBulk
     * @param _couponId - Enter the coupon id // eg get50% or get100%
     */
    function ReactivateCouponsBulk(string[] memory _couponId) external onlyAdmin{
        for(uint i = 0; i < _couponId.length; i++){
            if(!couponHealth[_couponId[i]][showCouponStringAndCouponId[_couponId[i]]]){
                couponHealth[_couponId[i]][showCouponStringAndCouponId[_couponId[i]]] = true;
                emit ReactivateCouponsBulkState(_couponId, true, 200);
            }else{
                revert("Either Coupon is already live or end-date is expired");
            }
        }
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

    // -------------------------------------------------------x

    // READ ACTIONS

    // -------------------------------------------------------x
    /**
     * @notice View all created coupons and respective details.
     */
    function viewAllCreatedTokens() external view returns(TokenSpecification[] memory tokenspec){
        TokenSpecification[] memory tokens = new TokenSpecification[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++){
            TokenSpecification memory tokenspecs;
            tokenspecs._tokenId = couponInformation[tokenIds[i]]._tokenId;
            tokenspecs._tokenURL = couponInformation[tokenIds[i]]._tokenURL;
            tokenspecs._startDate = couponInformation[tokenIds[i]]._startDate;
            tokenspecs._endDate = couponInformation[tokenIds[i]]._endDate;
            tokens[i] = tokenspecs;
        }
        return tokens;
    }    

    /**
     * @notice This is to know, whether the coupon is live or not.
     * @param _couponId - Enter the coupon id to know the status of the token.
     */
    function viewCouponStatus(string memory _couponId) public view returns(bool status){
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            if(block.timestamp > couponInformation[showCouponStringAndCouponId[_couponId]]._startDate && 
            block.timestamp < couponInformation[showCouponStringAndCouponId[_couponId]]._endDate){
                status = true;
                return status;
            }else{
                status = false;
                return status;
            }
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
    function viewCouponValidityToUser(address _ad, string memory _couponId) external view returns(
        uint couponId,
        uint startDate,
        uint endDate,
        string memory couponStatus
    ){
        if(couponHealth[_couponId][showCouponStringAndCouponId[_couponId]]){
            if(linkConfirmation[_ad][showCouponStringAndCouponId[_couponId]] && viewCouponStatus(_couponId)){
                return (
                couponInformation[showCouponStringAndCouponId[_couponId]]._tokenId,
                couponInformation[showCouponStringAndCouponId[_couponId]]._startDate,
                couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,
                status_1);
            }
            if(linkConfirmation[_ad][showCouponStringAndCouponId[_couponId]] && viewCouponStatus(_couponId) == false){
                return(
                couponInformation[showCouponStringAndCouponId[_couponId]]._tokenId,
                couponInformation[showCouponStringAndCouponId[_couponId]]._startDate,
                couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,
                status_2);
            }
            for(uint i = 0; i < tokenIds.length; i++){
                if(showCouponStringAndCouponId[_couponId] != tokenIds[i]){
                    return(
                    couponInformation[showCouponStringAndCouponId[_couponId]]._tokenId,
                    couponInformation[showCouponStringAndCouponId[_couponId]]._startDate,
                    couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,
                    status_3);
                }
            }
        }else{
            return(
                couponInformation[showCouponStringAndCouponId[_couponId]]._tokenId,
                couponInformation[showCouponStringAndCouponId[_couponId]]._startDate,
                couponInformation[showCouponStringAndCouponId[_couponId]]._endDate,
                status_4);
        }
    }

    /**
     * @notice returns only live coupon name and status
     */
    function viewLiveCouponsOnly() external view returns(OnlyLive[] memory data){
        uint256 livecouponCount = 0;
        for(uint j = 0; j < allCouponStrings.length; j++){
            if(block.timestamp > couponInformation[showCouponStringAndCouponId[allCouponStrings[j]]]._startDate && 
            block.timestamp < couponInformation[showCouponStringAndCouponId[allCouponStrings[j]]]._endDate && couponHealth[allCouponStrings[j]][showCouponStringAndCouponId[allCouponStrings[j]]]){
                livecouponCount++;
            }   
        }
        OnlyLive[] memory liveStatus = new OnlyLive[](livecouponCount);
        uint256 currentIndex = 0;
        for(uint k = 0; k < allCouponStrings.length; k++){
            string memory couponString = allCouponStrings[k];
            uint256 couponId = showCouponStringAndCouponId[couponString];
                if(block.timestamp > couponInformation[couponId]._startDate && 
                block.timestamp < couponInformation[couponId]._endDate && couponHealth[allCouponStrings[k]][showCouponStringAndCouponId[allCouponStrings[k]]]){
                    liveStatus[currentIndex] = OnlyLive(couponString, "Live");
                    currentIndex++;
                }
        }
        return liveStatus;       
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
    function allCouponIds() external view returns(uint[] memory allCreatedIds){
        return tokenIds;
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
     * @param _couponId - Pass the coupon id
     */
    function returnsAllNFTsIds(string memory _couponId) external view returns(uint[] memory couponRelatedIds){
        return couponLinkedIds[showCouponStringAndCouponId[_couponId]];
    }

    /**
     * @notice Whether the coupon is created or not
     * @param _couponId - Pass the coupon id
     */
    function couponCreatedOrNotCreatedStatus(string memory _couponId) external view returns(bool status){
        return idCheck[showCouponStringAndCouponId[_couponId]];
    }

    /**
     * @notice Verify the driver address.
     * @param _driverAddress - Pass the driver wallet address
     * @param _couponId - Pass the coupon id
     */
    function verifyDriverAd(address _driverAddress, string memory _couponId) external view returns(bool){
        return verifyDriverAddressWithID[_driverAddress][showCouponStringAndCouponId[_couponId]];
    }

    /**
     * @notice showCouponLinkedId
     * @param _coupon - Pass the coupon id.
     */
    function showCouponLinkedId(string memory _coupon) external view returns(uint tokenId){
        return showCouponStringAndCouponId[_coupon];
    }

    /**
     * @notice couponLiveOrNotLive
     * @param _couponId - Pass the string coupon id
     */
    function couponLiveOrNotLive(string memory _couponId) external view returns(bool couponStatus){
        return couponHealth[_couponId][showCouponStringAndCouponId[_couponId]];
    }

    /**
        * Read function, get the concatenated uri -> base uri + tokenUri.
        * @param _id pass the token id.
    */
    function tokenURI (uint256 _id) public view virtual override returns (string memory) {
        if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
        return holdUri[_id];
    }
}