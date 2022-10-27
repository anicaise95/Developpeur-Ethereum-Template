const Voting = artifacts.require("./contrats/Voting");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { expect } = require('chai');


contract("Voting", accounts => {

    const _owner = accounts[0];
    const address_voter1 = accounts[1];
    const address_voter2 = accounts[2];
    const address_voter3 = accounts[3];
    const address_autre = accounts[4];

    let workflowStatus;
    let votingContractInstance;

    describe("Ajout d'électeurs sur la whitelist", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("Check le worflow initial => RegisteringVoters", async () => {
            workflowStatus = await votingContractInstance.workflowStatus.call();
            expect(workflowStatus).to.be.bignumber.equal(new BN(0));
        });

        it("Seul l'administrateur est habilité à ajouter un électeur", async () => {
            await expectRevert(votingContractInstance.addVoter(address_voter1, { from: address_voter1 }), "caller is not the owner");
        });

        it("L'administrateur ajoute 2 voters, check de leur présence sur la whitelist", async () => {
            expectEvent(await votingContractInstance.addVoter(address_voter1, { from: _owner }), "VoterRegistered", { voterAddress: address_voter1 });
            expectEvent(await votingContractInstance.addVoter(address_voter2, { from: _owner }), "VoterRegistered", { voterAddress: address_voter2 });

            const voter = await votingContractInstance.getVoter(address_voter1, { from: address_voter1 });
            expect(voter.isRegistered).to.be.true;
            expect(voter.hasVoted).to.be.false;
            expect(new BN(voter.votedProposalId)).to.be.bignumber.equal(new BN(0));

            const voter2 = await votingContractInstance.getVoter(address_voter2, { from: address_voter2 });
            expect(voter2.isRegistered).to.be.true;
            expect(voter2.hasVoted).to.be.false;
            expect(new BN(voter2.votedProposalId)).to.be.bignumber.equal(new BN(0));
        });

        it("Un électeur ne peut pas être ajouté 2 fois", async () => {
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
            await expectRevert(votingContractInstance.addVoter(address_voter1, { from: _owner }), "Already registered");
        });
    });


    describe("Ajout de propositions", function () {

        beforeEach(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("Un électeur absent de la whitelist ne peut pas ajouter de proposition", async () => {
            await expectRevert(votingContractInstance.addProposal("MARSEILLE", { from: address_voter1 }), "You're not a voter");
        });

        it("Un électeur ne peut pas ajouter une proposition avant l'ouverture de la session", async () => {
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
            await expectRevert(votingContractInstance.addProposal("MARSEILLE", { from: address_voter1 }), "Proposals are not allowed yet");
        });

        it("Un électeur ne peut pas ajouter une proposition vide", async () => {
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
            await votingContractInstance.startProposalsRegistering({ from: _owner });
            await expectRevert(votingContractInstance.addProposal("", { from: address_voter1 }), "Vous ne pouvez pas ne rien proposer");
        });

        it("Un électeur ajoute la proposition MARSEILLE", async () => {
            await votingContractInstance.addVoter(address_voter1, { from: _owner });
            await votingContractInstance.startProposalsRegistering({ from: _owner });
            expectEvent(await votingContractInstance.addProposal(address_voter1, { from: address_voter1 }), "ProposalRegistered", { proposalId: new BN(1) });
            console.log(await (votingContractInstance.getOneProposal(1, { from: address_voter1 }).description));
            //expect(proposition).equal("MARSEILLE");
        });


    });

});
