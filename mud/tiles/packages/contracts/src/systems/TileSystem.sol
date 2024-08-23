// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Tiles, Owners, GameProperties, GamePropertiesData } from "../codegen/index.sol";
import { BuildingType } from "../codegen/common.sol";

error AlreadyPlaced();
error InvalidFee();

contract TileSystem is System {
  function placeTile(uint256 gameId, uint256 x, uint256 y, BuildingType buildingType) public payable {
    address owner = Tiles.getOwner(gameId, x, y);
    if (owner != address(0)) revert AlreadyPlaced();
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    if (msg.value != gameProperties.pricePerTile) revert InvalidFee();
    Tiles.set(gameId, x, y, buildingType, msg.sender);
    // Owners.set();
    // Recalc rates for neighbors
  }
}
