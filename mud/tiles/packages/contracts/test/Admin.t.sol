// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { ERC20Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameProperties, GamePropertiesData, Owners, OwnerRates, OwnerRatesData } from "../src/namespaces/app/codegen/index.sol";
import { BuildingType } from "../src/codegen/common.sol";
import { IERC20Mintable } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20Mintable.sol";
import { IERC721Mintable } from "@latticexyz/world-modules/src/modules/erc721-puppet/IERC721Mintable.sol";

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
        5, // pricePerTile,
        block.timestamp + 1000
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
        5, // pricePerTile
        block.timestamp + 1000
      );
      gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);
  }

  function testWithdraw() public {
      vm.prank(admin);
      IWorld(worldAddress).app__configGame(
        1, // gameId,
        10, // xSize,
        5, // ySize,
        10, // baseRate,
        1, // bonusSame,
        3, // bonusEnemy,
        -2, // bonusVictim,
        5, // pricePerTile
        block.timestamp + 1000
      );
      GamePropertiesData memory gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);

      vm.prank(notAdmin);
      IWorld(worldAddress).app__placeTile{value: 5}(
        1,
        1,
        1,
        BuildingType.Circle
      );
      assertEq(worldAddress.balance, 5);
      vm.expectRevert();
      vm.prank(notAdmin);
      IWorld(worldAddress).app__withdraw();
      assertEq(worldAddress.balance, 5);
      uint256 balanceBefore = admin.balance;
      vm.prank(admin);
      IWorld(worldAddress).app__withdraw();
      assertEq(admin.balance, balanceBefore + 5);
      assertEq(worldAddress.balance, 0);
  }

  function testClaim() public {
      IERC20Mintable token = IERC20Mintable(IWorld(worldAddress).app__getToken());
      IERC721Mintable nft = IERC721Mintable(IWorld(worldAddress).app__getNft());
      vm.prank(admin);
      IWorld(worldAddress).app__configGame(
        1, // gameId,
        10, // xSize,
        5, // ySize,
        10, // baseRate,
        1, // bonusSame,
        3, // bonusEnemy,
        -2, // bonusVictim,
        5, // pricePerTile
        block.timestamp + 1000
      );
      GamePropertiesData memory gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);

      vm.prank(notAdmin);
      IWorld(worldAddress).app__placeTile{value: 5}(
        1,
        1,
        1,
        BuildingType.Circle
      );
      skip(3);
      assertEq(worldAddress.balance, 5);
      OwnerRatesData memory notAdminData = OwnerRates.get(notAdmin, 1);
      assertEq(notAdminData.rate, 10);
      vm.prank(notAdmin);
      uint256[] memory games = new uint256[](1);
      games[0] = 1;
      IWorld(worldAddress).app__claim(games);
      assertEq(token.balanceOf(notAdmin), 30);
      assertEq(nft.balanceOf(notAdmin), 1);
      assertEq(nft.ownerOf(10101), notAdmin);
      assertEq(worldAddress.balance, 5);
      vm.expectRevert();
      vm.prank(admin);
      token.mint(notAdmin, 100);
      vm.expectRevert();
      vm.prank(admin);
      nft.mint(notAdmin, 1);
  }

  function testTransfer() public {
      IERC20Mintable token = IERC20Mintable(IWorld(worldAddress).app__getToken());
      IERC721Mintable nft = IERC721Mintable(IWorld(worldAddress).app__getNft());
      vm.prank(admin);
      IWorld(worldAddress).app__configGame(
        1, // gameId,
        10, // xSize,
        5, // ySize,
        10, // baseRate,
        1, // bonusSame,
        3, // bonusEnemy,
        -2, // bonusVictim,
        5, // pricePerTile
        block.timestamp + 1000
      );
      GamePropertiesData memory gameProperties = GameProperties.get(1);
      assertEq(gameProperties.pricePerTile, 5);

      vm.prank(notAdmin);
      IWorld(worldAddress).app__placeTile{value: 5}(
        1,
        0,
        0,
        BuildingType.Circle
      );
      assertEq(worldAddress.balance, 5);
      OwnerRatesData memory notAdminData = OwnerRates.get(notAdmin, 1);
      assertEq(notAdminData.rate, 10);
      vm.prank(notAdmin);
      nft.approve(admin, 10000);
      vm.prank(admin);
      vm.expectRevert();
      nft.safeTransferFrom(notAdmin, admin, 10000);
      vm.startPrank(notAdmin);
      IWorld(worldAddress).app__placeTile{value: 5}(1, 0, 1, BuildingType.Circle);
      IWorld(worldAddress).app__placeTile{value: 5}(1, 1, 0, BuildingType.Circle);
      IWorld(worldAddress).app__placeTile{value: 5}(1, 1, 1, BuildingType.Circle);
      notAdminData = OwnerRates.get(notAdmin, 1);
      assertEq(notAdminData.rate, 52);
      vm.prank(admin);
      nft.safeTransferFrom(notAdmin, admin, 10000);
      assertEq(nft.ownerOf(10000), admin);
      notAdminData = OwnerRates.get(notAdmin, 1);
      assertEq(notAdminData.rate, 39);
      OwnerRatesData memory adminData = OwnerRates.get(admin, 1);
      assertEq(adminData.rate, 13);
  }
}
