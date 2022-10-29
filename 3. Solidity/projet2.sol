const Voting = artifacts.require("./contrats/Voting");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { expect } = require('chai');

contract("Voting", accounts => {

    const _owner = accounts[0];
    const address_voter1 = accounts[1];
    const address_voter2 = accounts[2];
    const address_voter3 = accounts[3];
    const address_voter4 = accounts[4];
    const address_voter5 = accounts[5];

    let workflowStatus;
    let votingContractInstance;

    describe("// xxxxxxxx Controles de sécurité xxxxxxxxx //", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("REVERT if the caller is not the owner", async () => {
            // Test Ownable
            await expectRevert(votingContractInstance.addVoter(address_voter1, { from: address_voter1 }), "caller is not the owner");
            await expectRevert(votingContractInstance.endProposalsRegistering({ from: address_voter1 }), "caller is not the owner");
            await expectRevert(votingContractInstance.startVotingSession({ from: address_voter1 }), "caller is not the owner");
            await expectRevert(votingContractInstance.endVotingSession({ from: address_voter1 }), "caller is not the owner");
            await expectRevert(votingContractInstance.tallyVotes({ from: address_voter1 }), "caller is not the owner");
        });

        it("REVERT if the caller is not a voter", async () => {
            // Test du modifier onlyVoters
            await expectRevert(votingContractInstance.addProposal("", { from: _owner }), "You're not a voter");
            await expectRevert(votingContractInstance.getOneProposal(0, { from: _owner }), "You're not a voter");
            await expectRevert(votingContractInstance.setVote(0, { from: _owner }), "You're not a voter");
        });

        it("REVERT if the expected workflow is different", async () => {
            // Initialialement le statut est RegisteringVoters
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(0));

            // On déclare un voter pour le test
            await votingContractInstance.addVoter(address_voter1, { from: _owner });

            // REVERT car statut attendu différent (de RegisteringVoters) 
            await expectRevert(votingContractInstance.addProposal("", { from: address_voter1 }), "Proposals are not allowed yet");
            await expectRevert(votingContractInstance.endProposalsRegistering({ from: _owner }), "Registering proposals havent started yet");
            await expectRevert(votingContractInstance.startVotingSession({ from: _owner }), "Registering proposals phase is not finished");
            await expectRevert(votingContractInstance.setVote(0, { from: address_voter1 }), "Voting session havent started yet");
            await expectRevert(votingContractInstance.endVotingSession({ from: _owner }), "Voting session havent started yet");
            await expectRevert(votingContractInstance.tallyVotes({ from: _owner }), "Current status is not voting session ended");
        });
    });

    describe("// ::::::::::::: REGISTRATION ::::::::::::: //", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("L'administrateur ajoute des electeurs sur la whitelist", async () => {
            // Test de l'ajout de 2 voters
            expectEvent(await votingContractInstance.addVoter(address_voter1, { from: _owner }), "VoterRegistered", { voterAddress: address_voter1 });
            expectEvent(await votingContractInstance.addVoter(address_voter2, { from: _owner }), "VoterRegistered", { voterAddress: address_voter2 });

            // Vérification du storage
            const voter = await votingContractInstance.getVoter(address_voter1, { from: address_voter1 });
            expect(voter.isRegistered).to.be.true;
            expect(voter.hasVoted).to.be.false;
            expect(new BN(voter.votedProposalId)).to.be.bignumber.equal(new BN(0));

            const voter2 = await votingContractInstance.getVoter(address_voter2, { from: address_voter2 });
            expect(voter2.isRegistered).to.be.true;
            expect(voter2.hasVoted).to.be.false;
            expect(new BN(voter2.votedProposalId)).to.be.bignumber.equal(new BN(0));
        });

        it("Un électeur ne peut pas être ajouté 2 fois sur la whitelist", async () => {
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
            await expectRevert(votingContractInstance.addVoter(address_voter1, { from: _owner }), "Already registered");
        });
    });

    describe("// ::::::::::::: PROPOSAL ::::::::::::: //", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
        });

        it("L'adminisrateur ouvre la session d'enregistrement des propositions", async () => {
            // Ouverture de la session
            expectEvent(await votingContractInstance.startProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(0), newStatus: new BN(1) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(1));

            // Test de la proposition initialie GENESIS
            const proposal = await votingContractInstance.getOneProposal(0, { from: address_voter1 });
            expect("GENESIS").to.equal(proposal.description);
        });

        it("Un électeur ne peut pas ajouter une proposition vide", async () => {
            await votingContractInstance.startProposalsRegistering({ from: _owner });
            await expectRevert(votingContractInstance.addProposal("", { from: address_voter1 }), "Vous ne pouvez pas ne rien proposer");
        });

        it("Des électeurs ajoutent des propositions", async () => {

            await votingContractInstance.addVoter(address_voter2, { from: _owner });
            await votingContractInstance.startProposalsRegistering({ from: _owner });

            // On recheck la proposition GENESIS 
            const proposal0 = await votingContractInstance.getOneProposal(0, { from: address_voter1 });
            expect("GENESIS").to.equal(proposal0.description);

            // Ajout des 2 propositions par le Voter 1
            expectEvent(await votingContractInstance.addProposal("Manger une bonne pizza !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(1) });
            const proposal1 = await votingContractInstance.getOneProposal(1, { from: address_voter1 });
            expect("Manger une bonne pizza !").to.equal(proposal1.description);

            expectEvent(await votingContractInstance.addProposal("Bien dormir la nuit !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(2) });
            const proposal2 = await votingContractInstance.getOneProposal(2, { from: address_voter1 });
            expect("Bien dormir la nuit !").to.equal(proposal2.description);

            // Ajout d'une proposition par le Voter 2
            expectEvent(await votingContractInstance.addProposal("Boire une bière ! :)", { from: address_voter2 }), "ProposalRegistered", { proposalId: new BN(3) });
            const proposal3 = await votingContractInstance.getOneProposal(3, { from: address_voter1 });
            expect("Boire une bière ! :)").to.equal(proposal3.description);
        });

        it("L'administrateur cloture la session d'enregistrement", async () => {
            // Ouverture de la session d'enregistrement
            await votingContractInstance.startProposalsRegistering({ from: _owner });
            // Ajout d'une proposition
            expectEvent(await votingContractInstance.addProposal("Manger une bonne pizza !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(1) });

            // Fermerture de la ession d'enregistrement
            expectEvent(await votingContractInstance.endProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(1), newStatus: new BN(2) });
            const workflowStatus = await votingContractInstance.workflowStatus.call();
            // Check du nouveau statut
            expect(workflowStatus).to.be.bignumber.equal(new BN(2));
        });

    });

    describe("// ::::::::::::: VOTE ::::::::::::: //", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });

            expectEvent(await votingContractInstance.addVoter(address_voter1, { from: _owner }), "VoterRegistered", { voterAddress: address_voter1 });
            expectEvent(await votingContractInstance.addVoter(address_voter2, { from: _owner }), "VoterRegistered", { voterAddress: address_voter2 });
            expectEvent(await votingContractInstance.startProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(0), newStatus: new BN(1) });
            expectEvent(await votingContractInstance.addProposal("Manger une bonne pizza !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(1) });
        });

        it("L'administrateur ouvre la session de vote", async () => {
            expectEvent(await votingContractInstance.endProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(1), newStatus: new BN(2) });
            expectEvent(await votingContractInstance.startVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(2), newStatus: new BN(3) });
            const workflowStatus = await votingContractInstance.workflowStatus.call();
            expect(workflowStatus).to.be.bignumber.equal(new BN(3));
        });

        it("L'électeur vote (une seule fois) pour sa proposition préférée", async () => {
            // Dans ce cas de test, les voters 1 et 2 ajoutents d'autres propositions
            expectEvent(await votingContractInstance.addProposal("Prendre du bon temps !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(2) });
            expectEvent(await votingContractInstance.addProposal("Travailler ses TP pour la formation", { from: address_voter2 }), "ProposalRegistered", { proposalId: new BN(3) });
            expectEvent(await votingContractInstance.addProposal("Voir ses amis !", { from: address_voter2 }), "ProposalRegistered", { proposalId: new BN(4) });
            expectEvent(await votingContractInstance.addProposal("Faire du sport !", { from: address_voter2 }), "ProposalRegistered", { proposalId: new BN(5) });

            // Fin de la session d'nregistrement des propositions
            expectEvent(await votingContractInstance.endProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(1), newStatus: new BN(2) });

            // Début de la session des votes
            expectEvent(await votingContractInstance.startVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(2), newStatus: new BN(3) });

            // Tester le vote pour une proposition inxexistante
            await expectRevert(votingContractInstance.setVote(new BN(6), { from: address_voter1 }), "Proposal not found");

            // Vote d'un premier voter - On checke les donnnées du voter avant et apres le vote
            const voter1beforeVote = await votingContractInstance.getVoter(address_voter1, { from: address_voter1 });
            expect(voter1beforeVote.isRegistered).to.be.true;
            expect(voter1beforeVote.hasVoted).to.be.false;
            expect(new BN(voter1beforeVote.votedProposalId)).to.be.bignumber.equal(new BN(0));

            // Vote pour la proposition "Travailler ses TP pour la formation"
            expectEvent(await votingContractInstance.setVote(new BN(3), { from: address_voter1 }), "Voted", { voter: address_voter1, proposalId: new BN(3) });

            const voter1AfterVote = await votingContractInstance.getVoter(address_voter1, { from: address_voter1 });
            expect(voter1AfterVote.isRegistered).to.be.true;
            expect(voter1AfterVote.hasVoted).to.be.true;
            expect(new BN(voter1AfterVote.votedProposalId)).to.be.bignumber.equal(new BN(3));

            // Vote d'un deuxième électeur (juste pour s'assurer qu'il n'y a pas de pb avec plusieurs votes)
            const voter2BeforeVote = await votingContractInstance.getVoter(address_voter2, { from: address_voter2 });
            expect(voter2BeforeVote.isRegistered).to.be.true;
            expect(voter2BeforeVote.hasVoted).to.be.false;
            expect(new BN(voter2BeforeVote.votedProposalId)).to.be.bignumber.equal(new BN(0));

            expectEvent(await votingContractInstance.setVote(new BN(5), { from: address_voter2 }), "Voted", { voter: address_voter2, proposalId: new BN(5) });

            const voter2AfterVote = await votingContractInstance.getVoter(address_voter2, { from: address_voter2 });
            expect(voter2AfterVote.isRegistered).to.be.true;
            expect(voter2AfterVote.hasVoted).to.be.true;
            expect(new BN(voter2AfterVote.votedProposalId)).to.be.bignumber.equal(new BN(5));

            // L'électeur ne peut pas voter 2 fois, on vérifie que son 2eme vote n'a pas écrasé le premier
            await expectRevert(votingContractInstance.setVote(new BN(4), { from: address_voter1 }), "You have already voted");
            const voter1AfterOtherVote = await votingContractInstance.getVoter(address_voter1, { from: address_voter1 });
            expect(voter1AfterOtherVote.isRegistered).to.be.true;
            expect(voter1AfterOtherVote.hasVoted).to.be.true;
            expect(new BN(voter1AfterOtherVote.votedProposalId)).to.be.bignumber.equal(new BN(3));
        });

        it("L'administrateur cloture la session des votes", async () => {
            expectEvent(await votingContractInstance.endProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(1), newStatus: new BN(2) });
            expectEvent(await votingContractInstance.startVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(2), newStatus: new BN(3) });
            expectEvent(await votingContractInstance.setVote(new BN(1), { from: address_voter1 }), "Voted", { voter: address_voter1, proposalId: new BN(1) });

            expectEvent(await votingContractInstance.endVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(3), newStatus: new BN(4) });
            const workflowStatus = await votingContractInstance.workflowStatus.call();
            expect(workflowStatus).to.be.bignumber.equal(new BN(4));
        });
    });

    describe("// ::::::::::::: RESULTS ::::::::::::: //", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("L'administrateur désigne le vainqueur", async () => {

            // Checke du Statut initial
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(0));

            // Déclaration de 5 voters
            expectEvent(await votingContractInstance.addVoter(address_voter1, { from: _owner }), "VoterRegistered", { voterAddress: address_voter1 });
            expectEvent(await votingContractInstance.addVoter(address_voter2, { from: _owner }), "VoterRegistered", { voterAddress: address_voter2 });
            expectEvent(await votingContractInstance.addVoter(address_voter3, { from: _owner }), "VoterRegistered", { voterAddress: address_voter3 });
            expectEvent(await votingContractInstance.addVoter(address_voter4, { from: _owner }), "VoterRegistered", { voterAddress: address_voter4 });
            expectEvent(await votingContractInstance.addVoter(address_voter5, { from: _owner }), "VoterRegistered", { voterAddress: address_voter5 });

            // L'administrateur ouvre la session des propositions
            expectEvent(await votingContractInstance.startProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(0), newStatus: new BN(1) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(1));

            // Ajout d'une propostion par voter
            expectEvent(await votingContractInstance.addProposal("Manger une bonne pizza !", { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(1) });
            expectEvent(await votingContractInstance.addProposal("Prendre du bon temps !", { from: address_voter2 }), "ProposalRegistered", { proposalId: new BN(2) });
            expectEvent(await votingContractInstance.addProposal("Travailler ses TP pour la formation", { from: address_voter3 }), "ProposalRegistered", { proposalId: new BN(3) });
            expectEvent(await votingContractInstance.addProposal("Voir ses amis !", { from: address_voter4 }), "ProposalRegistered", { proposalId: new BN(4) });
            expectEvent(await votingContractInstance.addProposal("Faire du sport !", { from: address_voter5 }), "ProposalRegistered", { proposalId: new BN(5) });

            // L'administrateur met fin à la session des propositions
            expectEvent(await votingContractInstance.endProposalsRegistering({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(1), newStatus: new BN(2) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(2));

            // L'administrateur ouvre la session des votes
            expectEvent(await votingContractInstance.startVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(2), newStatus: new BN(3) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(3));

            // Votes enregistrés (2 votes pour "Travailler ses TP pour la formation", 1 vote pour "Manger une bonne pizza !", 1 vote pour "Voir ses amis !", 1 vote pour "Faire du sport !" )
            expectEvent(await votingContractInstance.setVote(new BN(3), { from: address_voter1 }), "Voted", { voter: address_voter1, proposalId: new BN(3) });
            expectEvent(await votingContractInstance.setVote(new BN(1), { from: address_voter2 }), "Voted", { voter: address_voter2, proposalId: new BN(1) });
            expectEvent(await votingContractInstance.setVote(new BN(3), { from: address_voter3 }), "Voted", { voter: address_voter3, proposalId: new BN(3) });
            expectEvent(await votingContractInstance.setVote(new BN(4), { from: address_voter4 }), "Voted", { voter: address_voter4, proposalId: new BN(4) });
            expectEvent(await votingContractInstance.setVote(new BN(5), { from: address_voter5 }), "Voted", { voter: address_voter5, proposalId: new BN(5) });

            // L'administrateur met fin à la session des votes 
            expectEvent(await votingContractInstance.endVotingSession({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(3), newStatus: new BN(4) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(4));

            // L'administrateur coomptabilise les votes
            expectEvent(await votingContractInstance.tallyVotes({ from: _owner }), "WorkflowStatusChange", { previousStatus: new BN(4), newStatus: new BN(5) });
            expect(await votingContractInstance.workflowStatus.call()).to.be.bignumber.equal(new BN(5));

            // L'administrateur déclare la proposition gagnante  
            const winningProposalID = await votingContractInstance.winningProposalID.call();
            expect(winningProposalID).to.be.bignumber.equal(new BN(3));

            await expectRevert(votingContractInstance.addVoter(address_voter1, { from: _owner }), "Voters registration is not open yet");
        });
    });
});
