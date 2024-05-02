// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src/Test.sol";

import "src/ConvexRewardPool.sol";
import "src/PoolManager.sol";
import "src/Booster.sol";
import "src/RewardFactory.sol";
import "src/PoolRewardHook.sol";
import "src/RewardManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/forge-std/src/StdUtils.sol";
import "lib/forge-std/src/console.sol";

contract TestContract is Test {
    uint256 public arbitrumFork;

    ConvexRewardPool public convexRewardPool;
    ConvexRewardPool public template;
    PoolManager public poolManager;
    Booster public booster;
    RewardFactory public rewardFactory;
    PoolRewardHook public rewardHook;
    RewardManager public rewardManager;

    IERC20 public _crv;
    address public _curveGauge = 0x5839337bf070Fea56595A5027e83Cd7126b23884;
    address public _convexStaker = 0x989AEb4d175e16225E39E87d0D97A3360524AD80;
    address public _convexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    IERC20 public _lptoken;

    address public _factory = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5;

    function setUp() public {
        arbitrumFork = vm.createSelectFork("https://arb1.arbitrum.io/rpc");
        _crv = IERC20(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
        _lptoken = IERC20(0xF7Fed8Ae0c5B78c19Aadd68b700696933B0Cefd9);
        booster = Booster(_convexBooster);

        vm.startPrank(0x2CA7759dcE155e15dF9cDBd8322C8Eb2934c5558);
        poolManager = PoolManager(0x3CeeAd93972703a4668EcD9FcAB5b99C8fa39ae3);
        rewardFactory = new RewardFactory(
            _convexBooster,
            _convexStaker,
            0xf53173a3104bFdC4eD2FA579089B5e6Bf4fc7a2b
        );
        template = new ConvexRewardPool();
        booster.setRewardFactory(address(rewardFactory));
        rewardManager = RewardManager(booster.rewardManager());
        vm.stopPrank();

        vm.startPrank(rewardManager.owner());
        rewardHook = new PoolRewardHook(_convexBooster);
        rewardManager.setPoolHook(address(rewardHook));
        vm.stopPrank();

        vm.prank(address(booster.owner()));
        rewardFactory.setImplementation(address(template));

        vm.startPrank(0x947B7742C403f20e5FaCcDAc5E092C943E7D0277);
        poolManager.shutdownPool(15);
        poolManager.addPool(_curveGauge, _factory);
        (, , address rewards, , ) = booster.poolInfo(booster.poolLength() - 1);
        convexRewardPool = ConvexRewardPool(rewards);
    }

    function testSetPool() public view {
        assertEq(booster.poolLength(), 29);
    }

    function testDeposit() public {
        vm.startPrank(address(1));
        deal(address(_lptoken), address(address(1)), 10 ether);
        IERC20(_lptoken).approve(
            address(booster),
            IERC20(_lptoken).balanceOf(address(1))
        );
        booster.depositAll(28);
    }

    function testClaimRewards() public {
        vm.warp(block.number + 1 days);
        convexRewardPool.getReward(address(1));
    }

    function testWithdrawWithClaim() public {
        convexRewardPool.withdrawAll(true);
    }

    function testWithdrawWithoutClaim() public {
        vm.startPrank(address(1));
        deal(address(_lptoken), address(address(1)), 10 ether);
        IERC20(_lptoken).approve(
            address(booster),
            IERC20(_lptoken).balanceOf(address(1))
        );
        booster.depositAll(28);
        convexRewardPool.withdrawAll(false);
    }
}
