// SPDX-License-Identifier: MIT
/*
 ________       __            __
|        \     |  \          |  \
| $$$$$$$$ ____| $$ __    __ | $$  ______    ______   _______
| $$__    /      $$|  \  |  \| $$ /      \  |      \ |       \
| $$  \  |  $$$$$$$| $$  | $$| $$|  $$$$$$\  \$$$$$$\| $$$$$$$\
| $$$$$  | $$  | $$| $$  | $$| $$| $$  | $$ /      $$| $$  | $$
| $$_____| $$__| $$| $$__/ $$| $$| $$__/ $$|  $$$$$$$| $$  | $$
| $$     \\$$    $$ \$$    $$| $$ \$$    $$ \$$    $$| $$  | $$
 \$$$$$$$$ \$$$$$$$  \$$$$$$  \$$  \$$$$$$   \$$$$$$$ \$$   \$$
*/
pragma solidity ^0.8.9;
import "./StudentRegistration.sol";
import "../USDT.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Eduloan is Ownable{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();

    address public USDT;
    uint public usdtBalance;
    uint public interestRate;
    address public l1Approver;
    address public l2Approver;
    address private studentRegistrationContract;
    bool onboarded = true;

    mapping(uint => string) private studentIpfsURLtoL1;
    mapping(uint => string) private studentIpfsURLtoL2;
    mapping(uint => string) private studentRewardDocsUpload;
    mapping(uint => bool) private l1DocUpload;
    mapping(uint => bool) private l2DocUpload;
    mapping(uint => bool) private rewardDocUpload;
    mapping(uint => bool) private l1ApprovalDecision;
    mapping(uint => bool) private l2ApprovalDecision;
    mapping(uint => bool) private rewardApprovalDecision;
    mapping(uint => Dashboard) private studentLoanInfo;
    mapping(uint => LoanInstalments) private loanDuration;
    mapping(uint => DashboardMilestones) private milestone;
    mapping(uint => bool) private l2LoanSanctionStatus;

    struct Dashboard{
       uint studentGeneratedID;
       uint loanDuration;
       string profileStatus;
       uint loanReleasedAmount;
       string rewardStatus;
       uint rewardAmountReceived;
       string repaymentStatus;
       uint repaidAmount;
       uint remainingAmount;
       uint principalPlusInterest;
       uint monthlyInstallments;
    }

    struct DashboardMilestones{
        bool l1approvalStatus;
        bool l2approvalStatus;
        bool fundRelease;
    }

    struct LoanInstalments{
        uint loanInstalment;
    }

    modifier onlyL1(){
        require(l1Approver == msg.sender, "only L1Approver can call this function");
        _;
    }

    modifier onlyL2(){
        require(l2Approver == msg.sender, "only L2Approver can call this function");
        _;
    }

    // function initialize(address _l1Address, address _l2Address, address _studentContractAddress, address _usdt,uint _rate) external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //   l1Approver = _l1Address;
    //   l2Approver = _l2Address;
    //   interestRate = _rate;
    //   studentRegistrationContract = _studentContractAddress;
    //   USDT = _usdt;
    //   usdtBalance = IERC20(USDT).balanceOf(address(this));
    //    __Ownable_init();
    // }

    constructor(address _l1Address, address _l2Address, address _studentContractAddress, address _usdt, uint _rate){
        l1Approver = _l1Address;
        l2Approver = _l2Address;
        interestRate = _rate;
        studentRegistrationContract = _studentContractAddress;
        USDT = _usdt;
        usdtBalance = IERC20(USDT).balanceOf(address(this));
    }

    // function _authorizeUpgrade(address) internal override onlyOwner {}
    function updateUSDTBalance() internal {
        usdtBalance = IERC20(USDT).balanceOf(address(this));
    }

    function studentUploadtoL1(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        studentIpfsURLtoL1[_studentID] = _ipfsURL;
        studentLoanInfo[_studentID].studentGeneratedID = _studentID;
        studentLoanInfo[_studentID].profileStatus = "Live";
        l1DocUpload[_studentID] = true;
    }

    function l1Verify(uint _studentID, bool _status) external onlyL1{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l1DocUpload[_studentID], "Student has not yet uploaded the docs for L1 verification!!!");
        l1ApprovalDecision[_studentID] = _status;
        if(_status == true){
            milestone[_studentID].l1approvalStatus = true;
        }
    }

    function studentUploadtoL2(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        require(l1ApprovalDecision[_studentID] == true, "Student has not received L1 approval or verification failed");
        studentIpfsURLtoL2[_studentID] = _ipfsURL;
        l2DocUpload[_studentID] = true;
    }

    function l2Verify(uint _studentID, bool _status) external onlyL2{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2DocUpload[_studentID], "Student has not yet uploaded the docs for L2 verification!!!");
        l2ApprovalDecision[_studentID] = _status;
        if(_status == true){
            milestone[_studentID].l2approvalStatus = true;
        }
    }

    function l2SanctionedLoan(uint _studentID, uint _loanDuration, address _collegeWalletAddress, uint _amount) external onlyL2{
        //loanDuration is expected as integer eg: 2 years or 3 years
        require(l2ApprovalDecision[_studentID], "L2Verification failed!!");
        uint conversion = _amount * (10**18);
        studentLoanInfo[_studentID].loanDuration = _loanDuration * 2;
        studentLoanInfo[_studentID].loanReleasedAmount = conversion;
        require(IERC20(USDT).transfer(_collegeWalletAddress, conversion),"Transaction Failed!!!");
        uint calculatedInterest = _loanDuration * interestRate;
        uint conversionWithInterest = conversion * calculatedInterest / 100;
        studentLoanInfo[_studentID].principalPlusInterest = conversion + conversionWithInterest;
        loanDuration[_studentID].loanInstalment = conversionWithInterest / studentLoanInfo[_studentID].loanDuration;
        l2LoanSanctionStatus[_studentID] = true;
        if(l2LoanSanctionStatus[_studentID] == true){
            milestone[_studentID].fundRelease = true;
        }
        studentLoanInfo[_studentID].monthlyInstallments = studentLoanInfo[_studentID].principalPlusInterest / studentLoanInfo[_studentID].loanDuration;
        studentLoanInfo[_studentID].repaymentStatus = "Pending";
        updateUSDTBalance();
    }

    function l1ReadIpfsURL(uint _studentID) external view returns(string memory ipfs_url){
        return studentIpfsURLtoL1[_studentID];
    }

    function l2ReadIpfsURL(uint _studentID) external view returns(string memory ipfs_url){
        return studentIpfsURLtoL2[_studentID];
    }

    function l2ReadRewardIpfsURL(uint _studentID) external view returns(string memory ipfs_url){
        return studentRewardDocsUpload[_studentID];
    }

    function vault(uint _amount) external onlyL2{
        require(_amount > 0, "Please enter an value above than 0");
        uint conversion = _amount * (10**18);
        IERC20(USDT).transferFrom(msg.sender, address(this), conversion);
        updateUSDTBalance();
    }

    function configureInterestRate(uint _newRate) external onlyL2 {
        interestRate = _newRate;
    }

    function studentUploadForReward(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID], "Loan not sanctioned");
        studentRewardDocsUpload[_studentID] = _ipfsURL;
        rewardDocUpload[_studentID] = true;
    }

    function rewardVerify(uint _studentID, bool _status) external onlyL2{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID] && rewardDocUpload[_studentID], "Loan not sanctioned");
        rewardApprovalDecision[_studentID] = _status;
    }

    function l2RewardSanction(uint _studentID, uint _amount) external onlyL2{
        uint conversion = _amount * (10**18);
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        IERC20(USDT).transfer(stud.getStudentAddress(_studentID), conversion);
        studentLoanInfo[_studentID].rewardStatus = "Rewarded";
        studentLoanInfo[_studentID].rewardAmountReceived += conversion; 
        updateUSDTBalance();
    }

    function repayLoan(uint _studentID, uint _amount) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID], "L2 has not sanctioned the Loan");
        uint conversion = _amount; //* (10**18);
        // while(!(studentLoanInfo[_studentID].remainingAmount < studentLoanInfo[_studentID].monthlyInstallments)){
        //     if(conversion < studentLoanInfo[_studentID].monthlyInstallments) {
        //     revert("Enter the correct instalment amount!!");
        // }
        // }
        if(conversion == studentLoanInfo[_studentID].monthlyInstallments || 
        studentLoanInfo[_studentID].remainingAmount < studentLoanInfo[_studentID].monthlyInstallments) {
            IERC20(USDT).transferFrom(msg.sender, address(this), conversion);
        }
        studentLoanInfo[_studentID].repaidAmount += conversion;
        studentLoanInfo[_studentID].remainingAmount = studentLoanInfo[_studentID].principalPlusInterest - studentLoanInfo[_studentID].repaidAmount;
        if(studentLoanInfo[_studentID].remainingAmount == 0){
            studentLoanInfo[_studentID].repaymentStatus = "All dues are paid";
        }
        updateUSDTBalance();
    }

    // function dashboardView(uint _studentID) external view returns(uint student_Id, 
    // uint loan_Duration,
    // string memory profile_status,
    // uint loan_releasedAmount,
    // string memory reward_status,
    // uint reward_amountReceived,
    // string memory repayment_status,
    // uint repaid_amount,
    // uint remaining_amount,
    // uint principal_AmountPlusInterest,
    // uint monthlyInstallment){
    //     return (studentLoanInfo[_studentID].studentGeneratedID,
    //     studentLoanInfo[_studentID].loanDuration,
    //     studentLoanInfo[_studentID].profileStatus,
    //     studentLoanInfo[_studentID].loanReleasedAmount,
    //     studentLoanInfo[_studentID].rewardStatus,
    //     studentLoanInfo[_studentID].rewardAmountReceived,
    //     studentLoanInfo[_studentID].repaymentStatus,
    //     studentLoanInfo[_studentID].repaidAmount,
    //     studentLoanInfo[_studentID].remainingAmount,
    //     studentLoanInfo[_studentID].principalPlusInterest,
    //     studentLoanInfo[_studentID].monthlyInstallments);
    // }

    function dashboardView(uint _studentID) external view returns(Dashboard memory dashboardInfo){
        return studentLoanInfo[_studentID];
    }

    function readMilestone(uint _studentID) external view returns (bool onboardStatus,
    bool L1ApprovalStatus,
    bool L2ApprovalStatus,
    bool FundReleaseStatus
    ){
        return (onboarded, 
        milestone[_studentID].l1approvalStatus,
        milestone[_studentID].l2approvalStatus,
        milestone[_studentID].fundRelease);
    }
}