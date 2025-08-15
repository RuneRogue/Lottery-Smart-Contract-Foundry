// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script,console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {codeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns (uint256 ,address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256 ,address) {
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID:", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, codeConstants {

    uint256 public constant SUBSCRIPTION_AMOUNT = 3 ether; //3 LINK

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        uint256 subId = helperConfig.getConfigByChainId(block.chainid).subscriptionId;
        address linkToken = helperConfig.getConfigByChainId(block.chainid).link;
        fundSubscription(vrfCoordinator, subId, linkToken);

    }

    function fundSubscription(address vrfCoordinator , uint256 subId , address linkToken) public {
        console.log("Funding subscription: ",subId);
        console.log("VRF Coordinator: ",vrfCoordinator);
        console.log("On chain: ",block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, SUBSCRIPTION_AMOUNT);
            vm.stopBroadcast();
        }else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, SUBSCRIPTION_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }

    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script, codeConstants {

    function addConsumerUsingConfig(address contractToAddVRF) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        uint256 subId = helperConfig.getConfigByChainId(block.chainid).subscriptionId;
        addConsumer(contractToAddVRF, vrfCoordinator, subId);
    }

    function addConsumer(address contractToAddVRF , address vrfCoordinator , uint256 subId) public {
        console.log("Adding consumer contract: ",contractToAddVRF);
        console.log("VRF Coordinator: ",vrfCoordinator);
        console.log("Chain id: ",block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddVRF);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
