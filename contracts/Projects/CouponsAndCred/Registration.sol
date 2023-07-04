//SPDX-License-Identifier: MIT
/*
 _______                       __              __                          __      __                       ______                        __                                     __     
|       \                     |  \            |  \                        |  \    |  \                     /      \                      |  \                                   |  \    
| $$$$$$$\  ______    ______   \$$  _______  _| $$_     ______   ______  _| $$_    \$$  ______   _______  |  $$$$$$\  ______   _______  _| $$_     ______   ______    _______  _| $$_   
| $$__| $$ /      \  /      \ |  \ /       \|   $$ \   /      \ |      \|   $$ \  |  \ /      \ |       \ | $$   \$$ /      \ |       \|   $$ \   /      \ |      \  /       \|   $$ \  
| $$    $$|  $$$$$$\|  $$$$$$\| $$|  $$$$$$$ \$$$$$$  |  $$$$$$\ \$$$$$$\\$$$$$$  | $$|  $$$$$$\| $$$$$$$\| $$      |  $$$$$$\| $$$$$$$\\$$$$$$  |  $$$$$$\ \$$$$$$\|  $$$$$$$ \$$$$$$  
| $$$$$$$\| $$    $$| $$  | $$| $$ \$$    \   | $$ __ | $$   \$$/      $$ | $$ __ | $$| $$  | $$| $$  | $$| $$   __ | $$  | $$| $$  | $$ | $$ __ | $$   \$$/      $$| $$        | $$ __ 
| $$  | $$| $$$$$$$$| $$__| $$| $$ _\$$$$$$\  | $$|  \| $$     |  $$$$$$$ | $$|  \| $$| $$__/ $$| $$  | $$| $$__/  \| $$__/ $$| $$  | $$ | $$|  \| $$     |  $$$$$$$| $$_____   | $$|  \
| $$  | $$ \$$     \ \$$    $$| $$|       $$   \$$  $$| $$      \$$    $$  \$$  $$| $$ \$$    $$| $$  | $$ \$$    $$ \$$    $$| $$  | $$  \$$  $$| $$      \$$    $$ \$$     \   \$$  $$
 \$$   \$$  \$$$$$$$ _\$$$$$$$ \$$ \$$$$$$$     \$$$$  \$$       \$$$$$$$   \$$$$  \$$  \$$$$$$  \$$   \$$  \$$$$$$   \$$$$$$  \$$   \$$   \$$$$  \$$       \$$$$$$$  \$$$$$$$    \$$$$ 
                    |  \__| $$                                                                                                                                                          
                     \$$    $$                                                                                                                                                          
                      \$$$$$$                                                                                                                                                           
*/

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Registration is Ownable {

    // type - Address
    address[] private admins;
    address[] private users;

    // type - Uint
    uint constant private Status_Success = 200;

    // type - Event
    event DriverRegistered(address indexed _driverAddress, uint indexed _success);
    event AdminAdded(address indexed _address, uint indexed _success);
    
    // type - Mapping
    mapping(address => bool) private isAdmin;
    mapping(address => bool) private isRegisteredDriver;

    // type - Modifier
    modifier onlyAdmin(){
        require(isAdmin[msg.sender], "only an Admin can call this function!!");
        _;
    }

    constructor(){
        admins.push(msg.sender); // contract deployer is added as first admin
        isAdmin[msg.sender] = true; 
    }

    // /**
    //  * @notice admin can call this function to register another wallet address as an extra admin
    //  * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
    //  * @param _newlyAddedAdmin address of the driver who is to be registered
    //  */
    // function addAdmin(address _newlyAddedAdmin) external onlyAdmin {
    //     require(!isAdmin[_newlyAddedAdmin], "This address is already an Admin!!");
    //     admins.push(_newlyAddedAdmin);
    //     isAdmin[_newlyAddedAdmin] = true;
    //     emit AdminAdded(_newlyAddedAdmin, Status_Success);
    // }
    
    /**
     * @notice admin can call this function to register a driver
     * @dev modifier onlyAdmin is used here. only one of the registered admins can call this function
     * @param _newDriver address of the driver who is to be registered
     */
    function registerDriver(address _newDriver) external onlyAdmin {
        require(!isRegisteredDriver[_newDriver],"This driver is already registered");
        users.push(_newDriver);
        isRegisteredDriver[_newDriver] = true;
        emit DriverRegistered(_newDriver, Status_Success);
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
     * @notice returns the address of all admins
     * @dev returns an address[]
     * @return allAdmins address array that contains address of all Admins
     */
    function getAllAdmins() external view returns(address[] memory allAdmins) {
        return admins;
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