// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// Projet - Système de vote
contract Voting is Ownable {

    // Votant
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    // Liste des votants
    mapping(address => Voter) voters;

    // Proposition de vote
    struct Proposal {
        string description;
        uint voteCount;
    }
    // Liste des propositions
    Proposal[] proposals;

    // Statuts session de vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }   
    // Statut actuel de la session de vote 
    WorkflowStatus workflowStatus = WorkflowStatus.RegisteringVoters;

    // events
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    // Propostions ayant le plus votes (permet d'identifier les potentielles égalités)
    uint nbMaxVotes = 0;
    // Liste du gagnant - eventuellement des gagnants en cas d'égalité
    Proposal[] winningProposals;

    constructor(){ 
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    // Update du statut de la session de vote
    function _updateWorkflowStatus(WorkflowStatus newStatus) private {
        emit WorkflowStatusChange(workflowStatus, newStatus);
        workflowStatus = newStatus;
    }

    // L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function registerVoter(address _address) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Inscription des electeurs fermee");
        voters[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    // Retourne les détails d'un voteur
    function getVoter(address _address) view public returns (Voter memory) {
        return voters[_address];
    }

    // Débuter la session d'enregistrement de la proposition
    function startProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, unicode"Il faut d'abord inscrire les électeurs");
        _updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }

    // Cloturer la session d'enregistrement de la proposition
    function stopProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions n'est pas encore ouverte");
        _updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    // Débuter la session des votes
    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "La session d'enregistrement des propositions doit etre fermee");

        // Ici je vérifie la présence d'au moins 2 propositions pour pouvoir voter
        if(proposals.length <= 2){
            _updateWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
            revert("Un minimum de 2 propositions est requis pour voter");
        }
        _updateWorkflowStatus(WorkflowStatus.VotingSessionStarted);
    }

    // Cloturer la session des votes
    function stopVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote doit etre ouverte");
        _updateWorkflowStatus(WorkflowStatus.VotingSessionEnded);
    }  

    // Retourne la liste des propositions 
    function getProposals() public view returns(Proposal[] memory)  {
        return proposals;
    }

    // Le caller doit être enregistré comme électeur pour réaliser l'action
    modifier isRegistered() {
        require(voters[msg.sender].isRegistered, unicode"Vous n'êtes pas inscrit sur la liste de vote");
        _;
    }   
  
    // Ajouter une proposition
    function addproposal(string memory _newProposalDescription) public isRegistered {
        require(bytes(_newProposalDescription).length > 0, "Aucune proposition renseignee"); 
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions est fermee"); 

        // La proposition est ajoutée si pas déjà présente (éviter les doublons)
        for(uint i = 0; i < proposals.length; i++){
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_newProposalDescription))) {
                revert("Une proposition existe deja");
            }
        }

        proposals.push(Proposal(_newProposalDescription, 0));
        emit ProposalRegistered(proposals.length);
    }

    // Les électeurs inscrits votent pour leur proposition préférée.
    // POUR VOTER saisir la position de la proposition dans le tableau (à partir de 0)
   function vote(uint _indexVotedProposalId) public isRegistered {
        require(_indexVotedProposalId >= 0, "Vote invalide");
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        require(!voters[msg.sender].hasVoted, "Votre vote a deja ete pris en compte");

        voters[msg.sender] = Voter(true, true, _indexVotedProposalId);
        proposals[_indexVotedProposalId].voteCount += 1;
        emit Voted(msg.sender, _indexVotedProposalId);
    }

    // Dépouillemement des votes
    function countVotes() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "La session de vote est toujours ouverte");
        _updateWorkflowStatus(WorkflowStatus.VotesTallied);

        // Le gagnant ou les gagnants (en cas d'égalité) avec le plus de votes sont copiés dans un tableau
        for (uint i = 0; i < proposals.length; i++){
            if (proposals[i].voteCount >= nbMaxVotes){
                // Si une propososition a un nombre de votes plus important, on réinitialise le tableau des gagnants
                if (proposals[i].voteCount > nbMaxVotes){
                    delete winningProposals;
                }
                // On conserve le nombre de votse le plus important
                nbMaxVotes = proposals[i].voteCount;
                // On enregistre la proposition gagante ou les propositions gaghnantes en cas d'égalité
                winningProposals.push(proposals[i]);
            }
        }
    }   

    // Retourne le gagnant (éventuellemetnt les gagnants en cas d'égalité)
    function getWinner() public view returns(Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Le nom du gagnant n'est pas disponible");
        return winningProposals;
    }
}
