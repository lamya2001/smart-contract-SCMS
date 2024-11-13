const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SupplyChainContract", function () {
    let supplyChainContract;
    let companyAddress;

    beforeEach(async () => {
        await network.provider.request({
            method: "hardhat_reset",
            params: [],
        });

        [companyAddress] = await ethers.getSigners();

        const SupplyChain = await ethers.getContractFactory("SupplyChainContract");
        supplyChainContract = await SupplyChain.deploy();
        await supplyChainContract.waitForDeployment();

        if (!supplyChainContract.target) {
            throw new Error("Contract deployment failed, address is null");
        }
    });

    describe("createContract", function () {
        it("should create a contract successfully", async function () {
            const purchaseOrderId = 4;
            const transportOrderId = 8;
            const sellerShortId = ethers.encodeBytes32String("seller2");
            const buyerShortId = ethers.encodeBytes32String("buyer2");
            const transporterId = ethers.encodeBytes32String("transporter1");

            const totalBuyerPayment = 700;
            const totalTransportPayment = 100;
            const estimatedDeliveryTimes = [1635553600, 1635630000];
            const sellerAddressBytes = "Ksa,jeddah,Al Faisaliyyah,Sari,2345";
            const buyerAddressBytes = "ksa,Riyadh, Alyasmin,Olaya,2387";

            //test 1
            // const itemNames = [ethers.encodeBytes32String("RawMaterial1"), ethers.encodeBytes32String("RawMaterial2")];
            // const quantities = [100, 5];
            // const options = ["color red , size small", "no options"];

            //test2
            const itemNames = [ethers.encodeBytes32String("RawMaterial1")];
            const quantities = [100];
            const options = ["color red , size small"];

            const tx = await supplyChainContract.createContract(
                purchaseOrderId,
                transportOrderId,
                sellerShortId,
                buyerShortId,
                transporterId,
                totalBuyerPayment,
                totalTransportPayment,
                estimatedDeliveryTimes,
                sellerAddressBytes,
                buyerAddressBytes,
                itemNames,
                quantities,
                options
            );

            const receipt = await tx.wait();
            const blockNumber = receipt.blockNumber;

            const contract = await supplyChainContract.getContract(supplyChainContract.target);

            console.log("Contract Address:", supplyChainContract.target);
            console.log("Block Number:", blockNumber);
            console.log("Contract details:");
            console.log("Purchase Order ID:", contract.purchaseOrderId.toString());
            console.log("Transport Order ID:", contract.transportOrderId.toString());
            console.log("Seller Short ID:", ethers.decodeBytes32String(contract.sellerShortId));
            console.log("Buyer Short ID:", ethers.decodeBytes32String(contract.buyerShortId));
            console.log("Transporter ID:", ethers.decodeBytes32String(contract.transporterId));
            console.log("Total Buyer Payment:", contract.totalBuyerPayment.toString());
            console.log("Total Transport Payment:", contract.totalTransportPayment.toString());

            console.log("Seller Address:", sellerAddressBytes);
            console.log("Buyer Address:", buyerAddressBytes);

            console.log("Estimated Delivery Times:");
            contract.estimatedDeliveryTimes.forEach((time, index) => {
                console.log(`Estimated Delivery Time ${index + 1}:`, new Date(Number(time) * 1000).toLocaleString());
            });

            console.log("Items:");
            for (let i = 0; i < contract.items.length; i++) {
                console.log("Item Name:", ethers.decodeBytes32String(contract.items[i].itemName));
                console.log("Quantity:", contract.items[i].quantity.toString());
                console.log("Options:", contract.items[i].options);
            }

            expect(contract.purchaseOrderId).to.equal(purchaseOrderId);
            expect(contract.transportOrderId).to.equal(transportOrderId);
            expect(contract.sellerShortId).to.equal(sellerShortId);
            expect(contract.buyerShortId).to.equal(buyerShortId);
            expect(contract.transporterId).to.equal(transporterId);
            expect(contract.totalBuyerPayment.toString()).to.equal(totalBuyerPayment.toString());
            expect(contract.totalTransportPayment.toString()).to.equal(totalTransportPayment.toString());
            // expect(contract.items.length).to.equal(2);//for test 1
            expect(contract.items.length).to.equal(1);//for test 2
        });
    });

    describe("markContractAsDelivered", function () {
        it("should mark the contract as delivered", async function () {
            const actualDeliveryTime = 1635633600;

            await supplyChainContract.markContractAsDelivered(supplyChainContract.target, actualDeliveryTime);

            const contract = await supplyChainContract.getContract(supplyChainContract.target);

            console.log("Contract delivered details:");
            console.log("Purchase Order Status:", contract.purchaseOrderStatus);
            console.log("Actual Delivery Time:", new Date(Number(contract.actualDeliveryTime) * 1000).toLocaleString());

            expect(contract.purchaseOrderStatus).to.equal(1);
            expect(contract.actualDeliveryTime).to.equal(actualDeliveryTime);
        });
    });
});
