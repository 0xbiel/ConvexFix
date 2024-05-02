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

contract TestContract is Test {
    uint256 public arbitrumFork;

    ConvexRewardPool public c;
    ConvexRewardPool public template;
    PoolManager public p;
    Booster public b;
    RewardFactory public f;
    PoolRewardHook public rh;
    RewardManager public rm;

    IERC20 public _crv;
    address public _curveGauge = 0x5839337bf070Fea56595A5027e83Cd7126b23884;
    address public _convexStaker = 0x989AEb4d175e16225E39E87d0D97A3360524AD80;
    address public _convexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    IERC20 public _lptoken;

    address public _factory = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5;

    function setUp() public {
        arbitrumFork = vm.createSelectFork("https://arb1.arbitrum.io/rpc");
        vm.startPrank(0x2CA7759dcE155e15dF9cDBd8322C8Eb2934c5558);
        _crv = IERC20(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
        _lptoken = IERC20(0xF7Fed8Ae0c5B78c19Aadd68b700696933B0Cefd9);
        b = Booster(_convexBooster);
        p = PoolManager(0x3CeeAd93972703a4668EcD9FcAB5b99C8fa39ae3);
        f = new RewardFactory(
            _convexBooster,
            _convexStaker,
            0xf53173a3104bFdC4eD2FA579089B5e6Bf4fc7a2b
        );
        template = new ConvexRewardPool();
        b.setRewardFactory(address(f));
        rm = RewardManager(b.rewardManager());
        vm.stopPrank();
        vm.startPrank(rm.owner());
        rh = new PoolRewardHook(_convexBooster);
        rm.setPoolHook(address(rh));
        vm.stopPrank();
        vm.startPrank(address(b.owner()));
        f.setImplementation(address(template));
        vm.stopPrank();
        vm.startPrank(0x947B7742C403f20e5FaCcDAc5E092C943E7D0277);
        p.shutdownPool(15);
        p.addPool(_curveGauge, _factory);
        (, , address rewards, , ) = b.poolInfo(b.poolLength() - 1);
        c = ConvexRewardPool(rewards);
    }

    function testSetPool() public view {
        assertEq(b.poolLength(), 29);
    }

    function testDeposit() public {
        vm.startPrank(address(1));
        deal(address(_lptoken), address(address(1)), 10 ether);
        IERC20(_lptoken).approve(
            address(b),
            IERC20(_lptoken).balanceOf(address(1))
        );
        b.depositAll(28);
    }

    function testClaimRewards() public {
        vm.warp(block.number + 1 days);
        c.getReward(address(1));
    }

    function testWithdrawWithClaim() public {
        c.withdrawAll(true);
    }

    function testWithdrawWithoutClaim() public {
        vm.startPrank(address(1));
        deal(address(_lptoken), address(address(1)), 10 ether);
        IERC20(_lptoken).approve(
            address(b),
            IERC20(_lptoken).balanceOf(address(1))
        );
        b.depositAll(28);
        c.withdrawAll(false);
    }
}
