// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }    

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping(address => Voter) voters;
    WorkflowStatus workflowStatus;
    Proposal[] proposals;
    uint winningProposalId;

 
    function registerVoter(address _address) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, unicode"L'inscription des électeurs est fermée");
        voters[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    function startProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, unicode"Il faut d'abord inscrire les électeurs");
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, workflowStatus);
    }

    function stopProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions n'est pas encore ouverte");
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, workflowStatus);
    }

    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "La session d'enregistrement des propositions est toujours ouverte");
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, workflowStatus);
    }

    function stopVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, workflowStatus);
    }  

     modifier isRegistered() {
        require(voters[msg.sender].isRegistered, unicode"Vous n'êtes pas inscrit sur la liste de vote");
        _;
    }   
  
    // Ajout de la proposition de l'électeur
    function addproposal(string memory description) public isRegistered {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, unicode"La session d'enregistrement des propositions est fermée"); 
        require(voters[msg.sender].votedProposalId == 0, unicode"Votre proposition a déjà été prise en compte");       
        proposals.push(Proposal(description, 0));
        emit ProposalRegistered(proposals.length);
    }

    // Liste des propositions 
    function getProposals() public view returns(Proposal[] memory)  {
        return proposals;
    }

    // Les électeurs inscrits votent pour leur proposition préférée.
    function voteAProposal(uint _votedProposalId) public isRegistered {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        voters[msg.sender] = Voter(true, true, _votedProposalId);
        proposals[_votedProposalId].voteCount += 1;
        emit Voted(msg.sender, _votedProposalId);
    }

    // Détermination du gagnant
    function countVotes() private {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "La session de vote est toujours ouverte");
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, workflowStatus);
        for (uint i = 0; i <= proposals.length; i++){
            if (proposals[i].voteCount >= winningProposalId){
                winningProposalId = proposals[i].voteCount;
            }
        }
    }   

    // Tout le monde peut voir le gagnant
    function getWinner() public view returns(string memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Le nom du gagnant n'est pas disponible");
        return proposals[winningProposalId].description;
    }
}
