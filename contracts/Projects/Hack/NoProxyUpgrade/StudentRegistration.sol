// SPDX-License-Identifier: MIT
/*

  /$$$$$$   /$$                     /$$                       /$$     /$$$$$$$                      /$$             /$$                          /$$     /$$                          
 /$$__  $$ | $$                    | $$                      | $$    | $$__  $$                    |__/            | $$                         | $$    |__/                          
| $$  \__//$$$$$$   /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$  | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$  /$$$$$$   /$$  /$$$$$$  /$$$$$$$       
|  $$$$$$|_  $$_/  | $$  | $$ /$$__  $$ /$$__  $$| $$__  $$|_  $$_/  | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/|_  $$_/   /$$__  $$|____  $$|_  $$_/  | $$ /$$__  $$| $$__  $$      
 \____  $$ | $$    | $$  | $$| $$  | $$| $$$$$$$$| $$  \ $$  | $$    | $$__  $$| $$$$$$$$| $$  \ $$| $$|  $$$$$$   | $$    | $$  \__/ /$$$$$$$  | $$    | $$| $$  \ $$| $$  \ $$      
 /$$  \ $$ | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$  | $$ /$$| $$  \ $$| $$_____/| $$  | $$| $$ \____  $$  | $$ /$$| $$      /$$__  $$  | $$ /$$| $$| $$  | $$| $$  | $$      
|  $$$$$$/ |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/  |  $$$$/| $$     |  $$$$$$$  |  $$$$/| $$|  $$$$$$/| $$  | $$      
 \______/   \___/   \______/  \_______/ \_______/|__/  |__/   \___/  |__/  |__/ \_______/ \____  $$|__/|_______/    \___/  |__/      \_______/   \___/  |__/ \______/ |__/  |__/      
                                                                                          /$$  \ $$                                                                                   
                                                                                         |  $$$$$$/                                                                                   
                                                                                          \______/                                                                                    

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StudentRegistration is Ownable{

    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    error idAlreadyTaken();

   
    mapping(address => mapping(uint256 => bool)) private studentLinkToID;
    mapping(address => mapping(uint256 => StudentInformation)) private studentInfostruct;
    mapping(uint256 => uint256) private idToId;
    mapping(uint256 => string) private idTopassword;
    mapping(uint256 => bool) private idVerification;
    mapping(uint => address) private idToUserAddress;

    uint[] private allIds;
    address[] private pushStudents;


    event StudentRegistered(string indexed mailId, string indexed status);

    struct StudentInformation{
        string firstName;
        string lastName;
        uint256 phoneNo;
        string mailID;
        address walletAddress;
        uint256 studentID;
        string password;
    }


    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    // }

    // function _authorizeUpgrade(address) internal override onlyOwner {}


    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    
    
    
    function addStudent(StudentInformation memory _studentInfo) external{
        StudentInformation memory si = _studentInfo;
        if(msg.sender != si.walletAddress){ revert inputConnectedWalletAddress();}
        if(studentLinkToID[msg.sender][si.studentID] == true){ revert addressAlreadyRegistered();}
        for(uint i = 0; i < allIds.length; i++){
            if(si.studentID == allIds[i]){
                revert idAlreadyTaken();
            }
        }
        studentLinkToID[msg.sender][si.studentID] = true;
        studentInfostruct[msg.sender][si.studentID].firstName = si.firstName;
        studentInfostruct[msg.sender][si.studentID].lastName = si.lastName;
        studentInfostruct[msg.sender][si.studentID].phoneNo = si.phoneNo;
        studentInfostruct[msg.sender][si.studentID].mailID = si.mailID;
        studentInfostruct[msg.sender][si.studentID].walletAddress = si.walletAddress;
        studentInfostruct[msg.sender][si.studentID].studentID = si.studentID;
        studentInfostruct[msg.sender][si.studentID].password = si.password;
        idToUserAddress[si.studentID] = si.walletAddress;
        idVerification[si.studentID] = true;
        idToId[si.studentID] = si.studentID;
        idTopassword[si.studentID] = si.password;
        allIds.push(studentInfostruct[msg.sender][si.studentID].studentID);
        pushStudents.push(msg.sender);
        emit StudentRegistered(studentInfostruct[msg.sender][si.studentID].mailID, "Student is Registered Successfully");
    }

    function verifyStudent(address _studentAddress, uint256 _studentId) public view returns(bool condition){
        if(studentLinkToID[_studentAddress][_studentId]){
            return true;
        }else{
            return false;
        }
    }

    function verifyStudentWithId(uint _studentId) public view returns(bool status){
        if(idVerification[_studentId]){
            status = true;
            return status;
        }else{
            return false;
        }
    }

    function getAllStudentAddress() external view returns(address[] memory){
        return pushStudents;
    }  

    function viewStudentInformation( address _studentAddress, uint256 _id) external view returns(
    uint256 phno, 
    string memory mailid, 
    address walletad, 
    uint256 studentid,
    string memory password ){
        require(verifyStudent(_studentAddress,_id) == true, "Student not listed!!");
        return (
        studentInfostruct[_studentAddress][_id].phoneNo,
        studentInfostruct[_studentAddress][_id].mailID,
        studentInfostruct[_studentAddress][_id].walletAddress,
        studentInfostruct[_studentAddress][_id].studentID,
        studentInfostruct[_studentAddress][_id].password);
    }   

    function loginVerify(uint256 _studentID, string memory _password) external view returns (bool verificationStatus){
        if((_studentID == idToId[_studentID]) && (equal(_password,idTopassword[_studentID]))){
            verificationStatus = true;
            return verificationStatus;
        }else{
            verificationStatus = false;
            return verificationStatus;
        }
    }

    function getStudentAddress(uint _studentID) external view returns(address studentAddress){
        return idToUserAddress[_studentID];
    }

}