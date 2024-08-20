// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Tiles } from "../codegen/index.sol";
import { BuildingType } from "../codegen/common.sol";

contract TileSystem is System {
  function placeTile() public returns (uint32) {
    Tiles.set(1, 2, 3, BuildingType.Triangle, msg.sender);
    return 1;
  }
}
