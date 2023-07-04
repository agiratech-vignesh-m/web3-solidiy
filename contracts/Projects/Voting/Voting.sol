// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
// By importing Strings.sol, you gain access to functions such as concatenation, integer to string conversion, and string manipulation, which can be useful when working with string data in your smart contracts.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {
    // error messages
    error alreadyVoted();
    error notEnoughBalanceToCastVote();
    error notEnoughBalanceToCreateProposal();

    // state variables
    address public AME_VOTING_TOKEN;
    //address public AME_VOTING_TOKEN = 0xE99a27f464e0d4338f9617121b6ba9821e000c05;
    // address for polygonMumbai = 0x167678e8e8eCE47df4b89Fb42029f19D00fF3E48
    // address for ameChainTestnet = 0xE99a27f464e0d4338f9617121b6ba9821e000c05

    uint private proposalNotStarted = 0;
    uint private proposalInProgress = 1;
    uint private proposalPassed = 2;
    uint private proposalfailed = 3;
    uint private proposalDrawn = 4;
    uint public MIN_TOK_CREATEPROPOSAL;
    uint public MIN_TOK_VOTE;
    // uint public MIN_TOK_CREATEPROPOSAL = 1000000000000000000000000;
    // uint public MIN_TOK_VOTE = 1000000000000000000;
    uint[] private allIds;
    uint public ascending = 1;
    uint public descending = 2;
    uint private generateVotingId = 0;

    struct proposalDetails {
        string title;
        string description;
        uint setQuorum;
        uint proposalId;
        uint timestamp;
        uint startDate;
        uint endDate;
    }

    struct proposalParams {
        string title;
        string description;
        uint setQuorum;
        uint startDate;
        uint endDate;
    }

    struct votersDecision {
        uint proposalId;
        bool voteStatus;
        uint timestamp;
    }

    struct forVotedData {
        address _add;
        uint _timeStamp;
        uint _balance;
    }

    struct againstVotedData {
        address _add;
        uint _timeStamp;
        uint _balance;
    }

    struct allProposals {
        proposalDetails ps;
        uint forVotes;
        uint againstVotes;
        uint status;
    }

    struct voteResult {
        string notStarted;
        string inprogress;
        string passed;
        string failed;
        string drawn;
    }

    mapping(uint => proposalDetails) private proposal;
    mapping(uint => mapping(address => votersDecision)) private voteState;
    mapping(uint => string) private titleDetails;
    mapping(uint => mapping(address => bool)) private userStatus;
    mapping(uint => uint) private votedFor;
    mapping(uint => uint) private votesAgainst;
    mapping(uint => uint) public totalVotes;
    mapping(uint => address[]) private votedYes;
    mapping(uint => address[]) private votedNo;
    mapping(uint => forVotedData[]) private onlyForVotes;
    mapping(uint => againstVotedData[]) private onlyAgainstVotes;

    event ProposalCreated(
        address indexed _ad,
        uint indexed _proposalId,
        string indexed _title
    );

    event Voted(
        address indexed _ad,
        uint indexed _proposalId,
        bool indexed _vote
    );

    constructor(
        address _ameTokenAddress,
        uint _minTokCreateProposal,
        uint _minTokVoting
    ) {
        AME_VOTING_TOKEN = _ameTokenAddress;
        MIN_TOK_CREATEPROPOSAL = _minTokCreateProposal * 10 ** decimals();
        MIN_TOK_VOTE = _minTokVoting * 10 ** decimals();
    }

    /**
     * createProposal
     * @param _data - title, description, setQuorum(Wei format), endDate(Unix format).
     * @dev - Check the requirement to create a proposal.
     * setQuorum is expected as whole value.
     * startDate and endDate - unix format.
     * proposalId is pushed to array.
     * function emits and event
     */
    function createProposal(proposalParams memory _data) external {
        if (
            IERC20(AME_VOTING_TOKEN).balanceOf(msg.sender) <
            MIN_TOK_CREATEPROPOSAL
        ) {
            revert notEnoughBalanceToCastVote();
        }
        require(
            _data.setQuorum > 0 && _data.setQuorum < 100000000000000000000,
            " percentage value must be within 0 and 100"
        );
        generateVotingId = generateVotingId + 1;
        proposal[generateVotingId].proposalId = generateVotingId;
        // since description data can be huge, the data is hashed and stored in the blockchain.
        string memory local = string(abi.encodePacked(_data.description));
        proposal[generateVotingId].description = local;
        proposal[generateVotingId].title = _data.title;
        proposal[generateVotingId].setQuorum = _data.setQuorum; // geting value as wei
        proposal[generateVotingId].timestamp = block.timestamp;
        proposal[generateVotingId].startDate = _data.startDate;
        proposal[generateVotingId].endDate = _data.endDate;
        titleDetails[generateVotingId] = _data.title;
        allIds.push(generateVotingId);
        emit ProposalCreated(msg.sender, generateVotingId, _data.title);
    }

    /**
     * castVote
     * @param _decision - Enter either true or false.
     * @param _proposalId - Enter the proposal id.
     * @dev - Check the requirement to vote on proposal.
     * Check whether the user already voted.
     * Setting the voting period.
     * Getting the voter decision in bool format.
     * Returns totalVotes, voteState and userStatus.
     * Exceeded voting period.
     */
    function castVote(bool _decision, uint _proposalId) external {
        if (IERC20(AME_VOTING_TOKEN).balanceOf(msg.sender) < MIN_TOK_VOTE) {
            revert notEnoughBalanceToCastVote();
        }
        if (userStatus[_proposalId][msg.sender]) {
            revert alreadyVoted();
        }
        if (
            block.timestamp > proposal[_proposalId].startDate &&
            block.timestamp < proposal[_proposalId].endDate
        ) {
            if (_decision) {
                votedFor[_proposalId] = votedFor[_proposalId] + 1;
                voteState[_proposalId][msg.sender].voteStatus = true;
                voteState[_proposalId][msg.sender].timestamp = block.timestamp;
                onlyForVotes[_proposalId].push(
                    forVotedData(
                        msg.sender,
                        block.timestamp,
                        msg.sender.balance
                    )
                );
                votedYes[_proposalId].push(msg.sender);
                emit Voted(msg.sender, _proposalId, _decision);
            } else {
                votesAgainst[_proposalId] = votesAgainst[_proposalId] + 1;
                voteState[_proposalId][msg.sender].voteStatus = false;
                voteState[_proposalId][msg.sender].timestamp = block.timestamp;
                onlyAgainstVotes[_proposalId].push(
                    againstVotedData(
                        msg.sender,
                        block.timestamp,
                        msg.sender.balance
                    )
                );
                votedNo[_proposalId].push(msg.sender);
                emit Voted(msg.sender, _proposalId, false);
            }
            totalVotes[_proposalId] = totalVotes[_proposalId] + 1;
            voteState[_proposalId][msg.sender].proposalId = _proposalId;
            userStatus[_proposalId][msg.sender] = true;
        } else {
            revert("Either voting is not started or already ended");
        }
    }

    /**
     * getProposalDetails
     * @param _proposalId - pass the proposalId.
     * Returns the proposal details.
     */
    function getProposalDetails(
        uint _proposalId
    )
        public
        view
        returns (
            proposalDetails memory details,
            uint totalVotesForProposal,
            address[] memory accepters,
            address[] memory rejecters
        )
    {
        return (
            proposal[_proposalId],
            totalVotes[_proposalId],
            votedYes[_proposalId],
            votedNo[_proposalId]
        );
    }

    /**
     * getVotingStatus
     * @param _voter - pass the voter wallet address.
     * @param _proposalId - Enter the proposalId.
     * Returns Voters details based on proposals.
     */
    function getVotingStatus(
        address _voter,
        uint _proposalId
    ) public view returns (votersDecision memory votingStatus) {
        return voteState[_proposalId][_voter];
    }

    /**
     * isUserVoted
     * @param _voter - Enter the voter wallet address.
     * @param _proposalId - Enter the proposalId.
     * Check whether the user already voted.
     */
    function isUserVoted(
        address _voter,
        uint _proposalId
    ) external view returns (bool status) {
        return userStatus[_proposalId][_voter];
    }

    /**
     * proposalResult
     * @param _proposalId - Enter the proposalId.
     * Returns the proposalResult based on given conditions.
     */
    function proposalResult(
        uint _proposalId
    ) public view returns (uint result) {
        if (block.timestamp < proposal[_proposalId].startDate) {
            return proposalNotStarted;
        } else if (block.timestamp < proposal[_proposalId].endDate) {
            return proposalInProgress;
        } else if (totalVotes[_proposalId] > 0) {
            /**
             * calculating the percentage of forVotes: (Sample)
             * If quorum = 40 %
             * consider totalVotes for a proposal is 10, how many forVotes needed for the proposal to succeed
             * we need 40% of forVotes to get the proposal succeed.
             * The below formula calculated the % of forVotes =>  5 (forVotes) * 100/ 10 (totalVotes) = 50% enough to make the proposal pass.
             * 50% (forVotes from totalVotes) > 40% (quorum)
             */
            uint percentage = ((votedFor[_proposalId] * (10 ** 18)) *
                (100 * (10 ** 18))) / (totalVotes[_proposalId] * (10 ** 18));
            if (percentage >= proposal[_proposalId].setQuorum) {
                return proposalPassed;
            } else if (votedFor[_proposalId] == votesAgainst[_proposalId]) {
                return proposalDrawn;
            } else {
                return proposalfailed;
            }
        } else {
            return proposalfailed;
        }
    }

    /**
     * allProposalDetailsAscendingOrder
     * Returns the details of all proposal in ascending order.
     */
    function allProposalDetailsAscendingOrder()
        public
        view
        returns (allProposals[] memory proposals)
    {
        allProposals[] memory proposalss = new allProposals[](allIds.length);
        for (uint i = 0; i < allIds.length; i++) {
            allProposals memory proposalInfo;
            proposalInfo.ps = proposal[allIds[i]];
            proposalInfo.forVotes = votedFor[allIds[i]];
            proposalInfo.againstVotes = votesAgainst[allIds[i]];
            proposalInfo.status = proposalResult(allIds[i]);
            proposalss[i] = proposalInfo;
        }
        return proposalss;
    }

    /**
     * allProposalDetailsDescendingOrder
     * Returns the details of all proposal in decending order.
     */
    function allProposalDetailsDescendingOrder()
        public
        view
        returns (allProposals[] memory proposals)
    {
        allProposals[] memory proposalsList = new allProposals[](allIds.length);
        for (uint i = allIds.length; i > 0; i--) {
            allProposals memory proposalInfo;
            proposalInfo.ps = proposal[allIds[i - 1]];
            proposalInfo.forVotes = votedFor[allIds[i - 1]];
            proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
            proposalInfo.status = proposalResult(allIds[i - 1]);
            proposalsList[allIds.length - i] = proposalInfo;
        }
        return proposalsList;
    }

    /**
     * allProposalDetails
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all proposals.
     */
    function allProposalDetails(
        uint _sort
    ) public view returns (allProposals[] memory proposals) {
        allProposals[] memory proposalsList = new allProposals[](allIds.length);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                allProposals memory proposalInfo;
                proposalInfo.ps = proposal[allIds[i]];
                proposalInfo.forVotes = votedFor[allIds[i]];
                proposalInfo.againstVotes = votesAgainst[allIds[i]];
                proposalInfo.status = proposalResult(allIds[i]);
                proposalsList[i] = proposalInfo;
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                allProposals memory proposalInfo;
                proposalInfo.ps = proposal[allIds[i - 1]];
                proposalInfo.forVotes = votedFor[allIds[i - 1]];
                proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                proposalInfo.status = proposalResult(allIds[i - 1]);
                proposalsList[allIds.length - i] = proposalInfo;
            }
        }
        return proposalsList;
    }

    /**
     * activeProposals
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all active proposals.
     */
    function activeProposals(
        uint _sort
    ) public view returns (allProposals[] memory proposals) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < allIds.length; i++) {
            if (time < proposal[allIds[i]].endDate) {
                count++;
            }
        }
        allProposals[] memory proposalsList = new allProposals[](count);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                if (time < proposal[allIds[i]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i]];
                    proposalInfo.forVotes = votedFor[allIds[i]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i]];
                    proposalInfo.status = proposalResult(allIds[i]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                if (time < proposal[allIds[i - 1]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i - 1]];
                    proposalInfo.forVotes = votedFor[allIds[i - 1]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                    proposalInfo.status = proposalResult(allIds[i - 1]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        }
        return proposalsList;
    }

    /**
     * completedProposals
     * @param _sort - Enter "0" or "any" for descending order / Enter "1" for ascending order.
     * Returns the details of all completed proposals.
     */
    function completedProposals(
        uint _sort
    ) public view returns (allProposals[] memory proposals) {
        uint count = 0;
        uint proposalCount = 0;
        uint time = block.timestamp;
        for (uint i = 0; i < allIds.length; i++) {
            if (time > proposal[allIds[i]].endDate) {
                count++;
            }
        }
        allProposals[] memory proposalsList = new allProposals[](count);
        if (_sort == 1) {
            for (uint i = 0; i < allIds.length; i++) {
                if (time > proposal[allIds[i]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i]];
                    proposalInfo.forVotes = votedFor[allIds[i]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i]];
                    proposalInfo.status = proposalResult(allIds[i]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        } else {
            for (uint i = allIds.length; i > 0; i--) {
                if (time > proposal[allIds[i - 1]].endDate) {
                    allProposals memory proposalInfo;
                    proposalInfo.ps = proposal[allIds[i - 1]];
                    proposalInfo.forVotes = votedFor[allIds[i - 1]];
                    proposalInfo.againstVotes = votesAgainst[allIds[i - 1]];
                    proposalInfo.status = proposalResult(allIds[i - 1]);
                    proposalsList[proposalCount] = proposalInfo;
                    proposalCount++;
                }
            }
        }
        return proposalsList;
    }

    /**
     * votingIdState
     * Returns the details of proposal status.
     */
    function votingIdState()
        external
        pure
        returns (voteResult memory showVotingResult)
    {
        voteResult memory vs;
        vs.notStarted = " 0 :: Not Started ";
        vs.inprogress = " 1 :: In Progress ";
        vs.passed = " 2 :: Passed ";
        vs.failed = " 3 :: Failed ";
        vs.drawn = " 4 :: Drawn ";
        return vs;
    }

    /**
     * returnAllForVoteDetails
     * @param _proposalId - Pass the proposalId of the contract.
     * @return onlyForVotes - array of struct is returned.
     */
    function returnAllForVoteDetails(
        uint _proposalId
    ) external view returns (forVotedData[] memory) {
        return onlyForVotes[_proposalId];
    }

    /**
     * returnAllAgainstVoteDetails
     * @param _proposalId - Pass the proposalId of the contract.
     * @return onlyAgainstVotes - array of struct is returned.
     */
    function returnAllAgainstVoteDetails(
        uint _proposalId
    ) external view returns (againstVotedData[] memory) {
        return onlyAgainstVotes[_proposalId];
    }

    function decimals() internal view virtual returns (uint8) {
        return 18;
    }

    function getNativeBalance(address account) public view returns (uint256) {
        return account.balance;
    }
}
