// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { GameProperties } from "../codegen/index.sol";
import { BuildingType } from "../codegen/common.sol";

contract ConfigSystem is System {
  function configGame(
      uint256 gameId,
      uint256 xSize,
      uint256 ySize,
      uint256 baseRate,
      int256 bonusSame,
      int256 bonusEnemy,
      int256 bonusVictim,
      uint256 pricePerTile
  ) public {
    GameProperties.set(
      gameId,
      xSize,
      ySize,
      baseRate,
      bonusSame,
      bonusEnemy,
      bonusVictim,
      pricePerTile
      );
  }
}
