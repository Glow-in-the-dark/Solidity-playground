const { ethers } = require("hardhat");
const { expect, assert } = require("chai");

// describe() takes in a string & a function
// describe("SimpleStorage", () => {})
describe("SimpleStorage", function () {
  let simpleStorageFactory, simpleStorage;

  // beforeEach() : tells us what to do before it runs EACH one of the it()
  beforeEach(async function () {
    simpleStorageFactory = await ethers.getContractFactory("SimpleStorage");
    simpleStorage = await simpleStorageFactory.deploy();
  });

  // where we actually write the code for the test.
  it("Should start with a favourite number of 0", async function () {
    const currentValue = await simpleStorage.retrieve();
    const expectedValue = "0";

    // import "chai" to use assert / expect
    // assert
    // expect
    assert.equal(currentValue.toString(), expectedValue);
    // expect(currentValue.toString()).to.equal(expectedValue)
  });

  // if we want to specify only test this, we can change it() to it.only()
  it("Should update when we call store", async function () {
    const expectedValue = "8";
    const transactionResponse = await simpleStorage.store(expectedValue);
    await transactionResponse.wait(1);

    const currentValue = await simpleStorage.retrieve();
    assert.equal(currentValue.toString(), expectedValue);
  });
});
