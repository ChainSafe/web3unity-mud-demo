// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Tiles, TilesData, Owners, OwnersData, GameProperties, GamePropertiesData } from "../codegen/index.sol";
import { BuildingType } from "../codegen/common.sol";

contract TileSystem is System {

  error AlreadyPlaced();
  error FeeInvalid();
  error PositionInvalid();

  event Debug(uint256 arg);
  event DebugBool(bool arg);

  struct NeighbourPosition {
    int8 deltaX;
    int8 deltaY;
  }

  function placeTile(uint256 gameId, uint256 x, uint256 y, BuildingType buildingType) public payable {
    address owner = Tiles.getOwner(gameId, x, y);
    if (owner != address(0)) revert AlreadyPlaced();
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    if ((x > gameProperties.xSize) || (y > gameProperties.ySize)) revert PositionInvalid();
    if (msg.value != gameProperties.pricePerTile) revert FeeInvalid();
    Tiles.set(gameId, x, y, buildingType, msg.sender);
    OwnersData memory ownersData = Owners.get(msg.sender);
    // calc rate for this tile and update rate for neighbors
    NeighbourPosition[] memory positions = createNeighbourPositions();
    int256 newTileRate = int256(gameProperties.baseRate);
    for (uint256 i = 0; i < positions.length; i++) {
      if (((positions[i].deltaX < 0) && (x == 0))
        || ((positions[i].deltaY < 0) && (y == 0))
        || ((positions[i].deltaX == 1) && (x == gameProperties.xSize))
        || ((positions[i].deltaY == 1) && (y == gameProperties.ySize))) continue;
      int256 newX = int256(x) + positions[i].deltaX;
      int256 newY = int256(y) + positions[i].deltaY;
      TilesData memory neighbour = Tiles.get(gameId, uint256(newX), uint256(newY));
      if (neighbour.owner == address(0)) continue;
      int256 bonusNeighbour;
      // Same
      if (neighbour.building == buildingType) {
        newTileRate += gameProperties.bonusSame;
        bonusNeighbour = gameProperties.bonusSame;
      } 
        // Neighbour is victim
        else if ((neighbour.building < buildingType)
        || ((neighbour.building == type(BuildingType).max)
        && (uint(buildingType) == 0))) { 
          newTileRate += gameProperties.bonusEnemy;
          bonusNeighbour = gameProperties.bonusVictim;
      }       
        // Neighbour is enemy
        else {
          newTileRate += gameProperties.bonusVictim;
          bonusNeighbour = gameProperties.bonusEnemy;
      }
      OwnersData memory neighbourOwner = Owners.get(neighbour.owner);
      uint256 rate = neighbourOwner.rate;
      if (rate > 0) {
        uint256 unclaimed = rate * (block.timestamp - neighbourOwner.lastUpdateTime);
        Owners.setUnclaimed(neighbour.owner, unclaimed);
      }
      Owners.setLastUpdateTime(neighbour.owner, block.timestamp);
      rate = (int256(rate) + bonusNeighbour > 0) ? uint256(int256(rate) + bonusNeighbour) : uint256(0);
      Owners.setRate(neighbour.owner, rate);
    }
    uint256 ownerRate = ownersData.rate;
    if (ownerRate > 0) {
      uint256 unclaimed = ownerRate * (block.timestamp - ownersData.lastUpdateTime);
      Owners.setUnclaimed(msg.sender, unclaimed);
    }
    Owners.setLastUpdateTime(msg.sender, block.timestamp);
    ownerRate = (int256(ownerRate) + newTileRate > 0) ? uint256(int256(ownerRate) + newTileRate) : uint256(0);
    Owners.setRate(msg.sender, ownerRate);
  }

  function createNeighbourPositions() internal pure returns(NeighbourPosition[] memory positions) {
    positions = new NeighbourPosition[](8);
    positions[0] = NeighbourPosition(-1, -1); // left top
    positions[1] = NeighbourPosition(-1,  0); // left middle
    positions[2] = NeighbourPosition(-1,  1); // left bottom
    positions[3] = NeighbourPosition( 0, -1); // top
    positions[4] = NeighbourPosition( 0,  1); // bottom
    positions[5] = NeighbourPosition( 1, -1); // right top
    positions[6] = NeighbourPosition( 1,  0); // right middle
    positions[7] = NeighbourPosition( 1,  1); // right bottom
  }
}
