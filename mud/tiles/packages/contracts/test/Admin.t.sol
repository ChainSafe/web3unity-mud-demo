// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameProperties, GamePropertiesData } from "../src/codegen/index.sol";

contract AdminTest is MudTest {
  address constant admin = 0x953C2658358Ace1D0335a11140Bb7D2469FCbC05;
  address constant notAdmin = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testConfig() public {
      vm.prank(admin);
      IWorld(worldAddress).app__configGame(
        1, // gameId,
        10, // xSize,
        5, // ySize,
        10, // baseRate,
        1, // bonusSame,
        3, // bonusEnemy,
        -2, // bonusVictim,
        5 // pricePerTile
      );
      GamePropertiesData memory gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);

      vm.prank(notAdmin);
      vm.expectRevert();
      IWorld(worldAddress).app__configGame(
        1, // gameId,
        10, // xSize,
        5, // ySize,
        10, // baseRate,
        1, // bonusSame,
        3, // bonusEnemy,
        -2, // bonusVictim,
        5 // pricePerTile
      );
      gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);
  }
}