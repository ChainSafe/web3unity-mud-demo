// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Balances } from "@latticexyz/world/src/codegen/tables/Balances.sol";
import { GameProperties } from "../codegen/index.sol";
import { BuildingType } from "../../../codegen/common.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";

contract ConfigSystem is System {

  error SizeInvalid();

  function configGame(
      uint256 gameId,
      uint256 xSize,
      uint256 ySize,
      uint256 baseRate,
      int256 bonusSame,
      int256 bonusEnemy,
      int256 bonusVictim,
      uint256 pricePerTile,
      uint256 endDate
  ) public {
    if (xSize >= 100 || ySize >= 100) revert SizeInvalid();

    GameProperties.set(
      gameId,
      xSize,
      ySize,
      baseRate,
      bonusSame,
      bonusEnemy,
      bonusVictim,
      pricePerTile,
      endDate
    );
  }

  function withdraw() public {
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace("app");
    uint256 balance = Balances.get(namespaceResource);
    IWorld(_world()).transferBalanceToAddress(namespaceResource, _msgSender(), balance);
  }
}
