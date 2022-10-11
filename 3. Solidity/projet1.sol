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
    WorkflowStatus workflowStatus = WorkflowStatus.RegisteringVoters;
    Proposal[] proposals;
    uint winningProposalId;

    constructor(){ 
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    // update le statut du workflow
    function updateWorkflowStatus(WorkflowStatus newStatus) private {
        emit WorkflowStatusChange(workflowStatus, newStatus);
        workflowStatus = newStatus;
    }

    // L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function registerVoter(address _address) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Inscription des electeurs fermee");
        voters[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    // L'administrateur du vote commence la session d'enregistrement de la proposition
    function startProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, unicode"Il faut d'abord inscrire les électeurs");
        updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }

    // L'administrateur du vote stoppe la session d'enregistrement de la proposition
    function stopProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions n'est pas encore ouverte");
        updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    // L'administrateur débute la session des votes
    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "La session d'enregistrement des propositions doit etre fermee");
        // Ici je vérifie la présence d'au moins 2 propositions pour pouvoir voter
        if(proposals.length <= 2){
            updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
            revert("Un minimum de 2 propositions est requis pour voter");
        }
        updateWorkflowStatus(WorkflowStatus.VotingSessionStarted);
    }

    // L'administrateur stoppe la session des votes
    function stopVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote doit etre ouverte");
        updateWorkflowStatus(WorkflowStatus.VotingSessionEnded);
    }  

    // Liste des propositions 
    function getProposals() public view returns(Proposal[] memory)  {
        return proposals;
    }

     modifier isRegistered() {
        require(voters[msg.sender].isRegistered, unicode"Vous n'êtes pas inscrit sur la liste de vote");
        _;
    }   
  
    // Ajout de la proposition de l'électeur
    function addproposal(string memory _proposal) public isRegistered {
        require(bytes(_proposal).length > 0, "Aucune proposition renseignee."); 
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions est fermee"); 
        // La proposition est ajoutée si pas déjà présente (éviter les doublons)
        for(uint i = 0; i < proposals.length; i++){
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_proposal))) {
                revert("Une proposition existe deja");
            }
        }
        proposals.push(Proposal(_proposal, 0));
        emit ProposalRegistered(proposals.length);
    }

    // Les électeurs inscrits votent pour leur proposition préférée.
    // proposals(string,uint256)[]: BERNARD,0,DAMIEN,0,LAURENT,0,LEA,0,SANDRINE,0,LUCIE,0
   function vote(uint _votedProposalId) public isRegistered {
        require(_votedProposalId >= 0, "Vote invalide");
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        require(!voters[msg.sender].hasVoted, unicode"Votre vote a déjà été pris en compte");
        voters[msg.sender] = Voter(true, true, _votedProposalId);
        proposals[_votedProposalId].voteCount += 1;
        emit Voted(msg.sender, _votedProposalId);
    }

    // Détermination du gagnant
    function countVotes() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "La session de vote est toujours ouverte");
        updateWorkflowStatus(WorkflowStatus.VotesTallied);
        for (uint i = 0; i <= proposals.length; i++){
            if (proposals[i].voteCount >= winningProposalId){
                winningProposalId = proposals[i].voteCount;
            }
        }
    }   

    // Tout le monde peut voir le gagnant ou de la proposition
    function getWinner() public view returns(Proposal memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Le nom du gagnant n'est pas disponible");
        return proposals[winningProposalId];
    }
}
