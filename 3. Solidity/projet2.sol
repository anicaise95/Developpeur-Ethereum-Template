const Voting = artifacts.require("./contrats/Voting");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
const { expect } = require('chai');

contract("Voting", accounts => {

    const _owner = accounts[0];
    const adress_voter1 = accounts[1];
    const adress_voter2 = accounts[2];
    const adress_voter3 = accounts[3];

    let votingContractInstance;

    describe("Ajout d'électeurs sur la whitelist", function () {

        before(async function () {
            votingContractInstance = await Voting.new({ from: _owner });
        });

        it("Should be OK .... Ajout de 3 nouveaux électeurs", async () => {

            // Ajout d'un électeur par l'admin
            expectEvent(await votingContractInstance.addVoter(adress_voter1, { from: _owner }), "VoterRegistered", { voterAddress: adress_voter1 });
            const voter = await votingContractInstance.getVoter(adress_voter1, { from: adress_voter1 });
            expect(voter.isRegistered).to.be.true;
            expect(voter.hasVoted).to.be.false;
            expect(new BN(voter.votedProposalId)).to.be.bignumber.equal(new BN(0));

            // Ajout d'un électeur par l'admin
            expectEvent(await votingContractInstance.addVoter(adress_voter2, { from: _owner }), "VoterRegistered", { voterAddress: adress_voter2 });
            const voter2 = await votingContractInstance.getVoter(adress_voter2, { from: adress_voter2 });
            expect(voter2.isRegistered).to.be.true;
            expect(voter2.hasVoted).to.be.false;
            expect(new BN(voter2.votedProposalId)).to.be.bignumber.equal(new BN(0));

            // Ajout d'un électeur par l'admin
            expectEvent(await votingContractInstance.addVoter(adress_voter3, { from: _owner }), "VoterRegistered", { voterAddress: adress_voter3 });
            const voter3 = await votingContractInstance.getVoter(adress_voter3, { from: adress_voter3 });
            expect(voter3.isRegistered).to.be.true;
            expect(voter3.hasVoted).to.be.false;
            expect(new BN(voter3.votedProposalId)).to.be.bignumber.equal(new BN(0));

        });

        it("Revert si ajout d'un électeur existant", async () => {
            await expectRevert(votingContractInstance.addVoter(adress_voter1, { from: _owner }), "Already registered");
        });
    });

    describe("Ajout de propositions", function () {
        describe("Test des event et require", function () {
            // Uniquement pour les voteurs
            it("Should be KO .. if admin", async () => {
                await expectRevert(votingContractInstance.addProposal("", { from: _owner }), "You're not a voter");
            });
            // La session d'enregistrement n'est pas encore ouverte
            it("Should be KO .. Proposals are not allowed yet ! ", async () => {
                await expectRevert(votingContractInstance.addProposal("MARSEILLE", { from: adress_voter1 }), "Proposals are not allowed yet");
            });


            it("KO .. Proposal can't be empty ! ", async () => {
                await expectRevert(votingContractInstance.addProposal("", { from: adress_voter1 }), "Vous ne pouvez pas ne rien proposer");
            });

        });

        describe("Ouverture de la session d'enregistrement", function () {
            it("Should be KO .. Registering proposals can't be started now", async () => {
                const event = await votingContractInstance.startProposalsRegistering({ from: _owner });
                //expectEvent(event, "WorkflowStatusChange", { newStatus: "ProposalsRegistrationStarted" });
            });
        });

        describe("Ajout de n propositions", function () {

        });
    });
});
