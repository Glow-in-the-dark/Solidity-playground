const { deployments, ethers } = require("hardhat");
const { assert, expect } = require("chai");
const { developmentChains } = require("../../helper-hardhat-config");

!developmentChains.includes(network.name) // wrap this whole test, so that if will run only on local network & not on main/live testnet.
  ? describe.skip
  : describe("FundMe", async function () {
      let fundMe;
      let deployer;
      let mockV3Aggregator;

      const sendValue = ethers.utils.parseEther("1");
      //deploy FundMe conctract first before we test.
      // using Hardhat-deploy
      beforeEach(async function () {
        // const accounts = await ethers.getSigners(); // this line will return the "accounts: [Private_key]" of your network.
        // const accountZero = accounts[0];
        deployer = (await getNamedAccounts()).deployer;
        await deployments.fixture(["all"]); // fixture(["all"]) call deploys all contracts defined in the deployment scripts (deploy/*) of your Hardhat project, which is useful for testing the entire system end-to-end, as it provides a fresh contract environment for each test run.
        (fundMe = await ethers.getContract("FundMe")), deployer; //get the most recent deployed contract of "FundMe"
        mockV3Aggregator = await ethers.getContract(
          "MockV3Aggregator",
          deployer
        );
      });

      describe("constructor", async function () {
        //describe
        it("sets the aggregator address correctly", async function () {
          const response = await fundMe.getPriceFeed();
          assert.equal(response, mockV3Aggregator.address);
        });
      });

      describe("fund", async function () {
        it("Fails if you don't send enough ETH", async function () {
          // by using expect().to.be.revertedWith , we can expect things to be failed, else if we use asset, athought it failed correctly, it will break the test.
          await expect(fundMe.fund()).to.be.revertedWith(
            "you neeed to spend more ETH!" // This checked and make sure that the error msg is the same as the line77. in "FundMe.sol"
          );
        });
        it("update the amount funded data structure", async function () {
          await fundMe.fund({ value: sendValue });
          const response = await fundMe.getAddressToAmountFunded(deployer);
          assert.equal(response.toString(), sendValue.toString());
        });
        it("adds funder to array of getFunders", async function () {
          await fundMe.fund({ value: sendValue });
          const funder = await fundMe.getFunders(0);
          assert.equal(funder, deployer);
        });
      });

      describe("withdraw", async function () {
        beforeEach(async function () {
          await fundMe.fund({ value: sendValue });
        });

        it("withdraw ETH from a single founder", async function () {
          // arrange
          const startingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const startingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // act
          const transactionResponse = await fundMe.withdraw();
          const transactionReceipt = await transactionResponse.wait(1);
          const { gasUsed, effectiveGasPrice } = transactionReceipt;
          const gasCost = gasUsed.mul(effectiveGasPrice);

          const endingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const endingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // assert
          assert.equal(endingFundMeBalance, 0);
          // assert.equal(startingFundMeBalance + startingDeployerBalance, endingDeployerBalance) // use .add() is better since we are working with bigNumber type.
          assert.equal(
            startingFundMeBalance.add(startingDeployerBalance).toString(),
            endingDeployerBalance.add(gasCost).toString()
          );
        });

        it("cheapWithdraw ETH from a single founder", async function () {
          // arrange
          const startingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const startingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // act
          const transactionResponse = await fundMe.cheaperWithdraw();
          const transactionReceipt = await transactionResponse.wait(1);
          const { gasUsed, effectiveGasPrice } = transactionReceipt;
          const gasCost = gasUsed.mul(effectiveGasPrice);

          const endingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const endingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // assert
          assert.equal(endingFundMeBalance, 0);
          // assert.equal(startingFundMeBalance + startingDeployerBalance, endingDeployerBalance) // use .add() is better since we are working with bigNumber type.
          assert.equal(
            startingFundMeBalance.add(startingDeployerBalance).toString(),
            endingDeployerBalance.add(gasCost).toString()
          );
        });

        it("allows us to withdraw from multiple getFunders", async function () {
          //Arrange
          const accounts = await ethers.getSigners();
          for (let i = 1; i < 6; i++) {
            // because "fundme" - Line 17, is actually currently connected to "deployer" address, now we need to connect it to other accounts, to send the Eth.
            const fundMeConnectedContract = await await fundMe.connect(
              accounts[i]
            );
            await fundMeConnectedContract.fund({ value: sendValue });
          }
          const startingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const startingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );

          // Act
          const transactionResponse = await fundMe.withdraw();
          const transactionReceipt = await transactionResponse.wait(1);
          const { gasUsed, effectiveGasPrice } = transactionReceipt;
          const gasCost = gasUsed.mul(effectiveGasPrice);

          const endingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const endingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // assert
          assert.equal(endingFundMeBalance, 0);
          // assert.equal(startingFundMeBalance + startingDeployerBalance, endingDeployerBalance) // use .add() is better since we are working with bigNumber type.
          assert.equal(
            startingFundMeBalance.add(startingDeployerBalance).toString(),
            endingDeployerBalance.add(gasCost).toString()
          );

          // Make Sure the getFunders are reset properly
          await expect(fundMe.getFunders(0)).to.be.reverted;
          for (i = 1; i < 6; i++) {
            assert.equal(
              await fundMe.getAddressToAmountFunded(accounts[i].address),
              0
            );
          }
        });

        // ONLY allows owners to withdraw. Wen other accounts try to call, it gets reverted.
        it("Only allows the owner to withdraw", async function () {
          const accounts = await ethers.getSigners();
          const fundMeConnectedContract = await fundMe.connect(accounts[1]);
          // await expect(fundMeConnectedContract.withdraw()).to.be.reverted; // checked it it didn't went tru, and indeed reverted.

          await fundMeConnectedContract.withdraw();
          // but since we have error code already, for FundMe's owner modifider,
          await expect(fundMeConnectedContract.withdraw()).to.be.revertedWith(
            "FundMe__NotOwner()"
          );
        });

        it("CheaperWithdrawal testing...", async function () {
          //Arrange
          const accounts = await ethers.getSigners();
          for (let i = 1; i < 6; i++) {
            // because "fundme" - Line 17, is actually currently connected to "deployer" address, now we need to connect it to other accounts, to send the Eth.
            const fundMeConnectedContract = await await fundMe.connect(
              accounts[i]
            );
            await fundMeConnectedContract.fund({ value: sendValue });
          }
          const startingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const startingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );

          // Act
          const transactionResponse = await fundMe.cheaperWithdraw();
          const transactionReceipt = await transactionResponse.wait(1);
          const { gasUsed, effectiveGasPrice } = transactionReceipt;
          const gasCost = gasUsed.mul(effectiveGasPrice);

          const endingFundMeBalance = await fundMe.provider.getBalance(
            fundMe.address
          );
          const endingDeployerBalance = await fundMe.provider.getBalance(
            deployer
          );
          // assert
          assert.equal(endingFundMeBalance, 0);
          // assert.equal(startingFundMeBalance + startingDeployerBalance, endingDeployerBalance) // use .add() is better since we are working with bigNumber type.
          assert.equal(
            startingFundMeBalance.add(startingDeployerBalance).toString(),
            endingDeployerBalance.add(gasCost).toString()
          );

          // Make Sure the getFunders are reset properly
          await expect(fundMe.getFunders(0)).to.be.reverted;
          for (i = 1; i < 6; i++) {
            assert.equal(
              await fundMe.getAddressToAmountFunded(accounts[i].address),
              0
            );
          }
        });
      });
    });
