const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Betting Contract", function () {
  let Betting;
  let bettingContract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    Betting = await ethers.getContractFactory("Betting");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    bettingContract = await Betting.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await bettingContract.owner()).to.equal(owner.address);
    });
  });

  describe("Betting functionality", function () {
    it("Allows to place a bet and checks entrance fee", async function () {
      await bettingContract.OpenBetting();
      await expect(bettingContract.connect(addr1).bet(1, 2, { value: ethers.parseEther("0.01") })).to.be.revertedWith("You must pay the entrance fees");
      await bettingContract.connect(addr1).bet(1, 2, { value: 10 }); // Assuming entrance fee is 10 wei
      const betInfo = await bettingContract.bets(0);
      expect(betInfo.better).to.equal(addr1.address);
    });

    it("Prevents betting when betting is closed", async function () {
      await bettingContract.connect(owner).closeBetting();
      await expect(bettingContract.connect(addr1).bet(1, 2, { value: 10 })).to.be.revertedWith("Bets are closed");
    });
  });

  describe("Gains distribution", function () {
    beforeEach(async function () {
      // Ouvrir les paris, placer quelques paris et fermer les paris
      await bettingContract.OpenBetting();
      // Placer les paris avec des scores différents, dont certains correspondent au score final
      await bettingContract.connect(addr1).bet(2, 1, { value: 10 }); // Gagnant
      await bettingContract.connect(addr2).bet(1, 3, { value: 10 }); // Perdant
      // Assumer que le reste des adresses font aussi des paris...
      await bettingContract.connect(owner).closeBetting();
      // Définir un score final où addr1 est un gagnant
      await bettingContract.connect(owner).setFinalScore(2, 1);
    });
  
    it("Distributes gains to winners", async function () {
      // Sauvegarder le solde avant distribution
      const initialBalance = await ethers.provider.getBalance(addr1);
  
      // Terminer les paris pour déclencher la distribution des gains
      await bettingContract.connect(owner).endBets();
  
      // Vérifier que le solde de addr1 a augmenté
      const finalBalance = await ethers.provider.getBalance(addr1);
      expect(finalBalance).to.be.above(initialBalance);
  
      // Vous pouvez également vouloir vérifier que les gagnants exacts ont reçu les gains attendus
      // Cela pourrait nécessiter de calculer le gain attendu en fonction de la logique de votre contrat
      // et de comparer cela avec la différence entre le solde final et initial de addr1.
    });
  
    it("Ensures no gains for losers", async function () {
      // Sauvegarder le solde avant distribution pour un perdant
      const initialBalance = await ethers.provider.getBalance(addr2);
  
      // Terminer les paris pour déclencher la distribution des gains
      await bettingContract.connect(owner).endBets();
  
      // Vérifier que le solde de addr2 n'a pas significativement changé (en tenant compte du coût du gaz)
      const finalBalance = await ethers.provider.getBalance(addr2);
      expect(finalBalance).to.be.closeTo(initialBalance, ethers.parseEther("0.001")); // tolérance pour le coût du gaz
    });
  });
  
});
