// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/ConvexRewardPool.sol";
import "src/PoolManager.sol";
import "src/Booster.sol";
import "src/RewardFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestContract is Test {
    ConvexRewardPool c;
    ConvexRewardPool publicC;
    PoolManager p;
    Booster b;
    RewardFactory f;

    IERC20 _crv;
    address _curveGauge = "0x5839337bf070Fea56595A5027e83Cd7126b23884";
    address _convexStaker = "0x989AEb4d175e16225E39E87d0D97A3360524AD80";
    address _convexBooster = "0xF403C135812408BFbE8713b5A23a04b3D48AAE31";
    IERC20 _lptoken;

    address _factory = " 0xabC000d88f23Bb45525E447528DBF656A9D55bf5";

    function setUp() public {
        arbitrumFork = vm.createSelectFork("https://arb1.arbitrum.io/rpc");
        vm.startPrank("0x2CA7759dcE155e15dF9cDBd8322C8Eb2934c5558");
        _crv = IERC20("0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978");
        _lptoken = IERC20("0xf7fed8ae0c5b78c19aadd68b700696933b0cefd9");
        b = Booster(_convexBooster);
        p = PoolManager("0x3CeeAd93972703a4668EcD9FcAB5b99C8fa39ae3");
        f = new RewardFactory(
            _convexBooster,
            _convexStaker,
            "0xf53173a3104bFdC4eD2FA579089B5e6Bf4fc7a2b"
        );
        publicC = new ConvexRewardPool();
        b.setRewardFactory(address(f));
        vm.stopPrank();
    }

    function testSetPool() public {
        vm.startPrank("0x947B7742C403f20e5FaCcDAc5E092C943E7D0277");
        p.addPool(_curveGauge, _factory);
        address Ac = b.poolInfo[b.poolLength - 1].rewards;
    }
}
