// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Tiles, GameProperties, GamePropertiesData } from "../codegen/index.sol";
import { BuildingType } from "../../../codegen/common.sol";
import { IERC721Mintable } from "@latticexyz/world-modules/src/modules/erc721-puppet/IERC721Mintable.sol";

library TileRateLibrary {

  error AlreadyPlaced();
  error FeeInvalid();
  error PositionInvalid();

  struct NeighbourPosition {
    int8 deltaX;
    int8 deltaY;
  }

struct NeighbourRate {
    address owner;
    int256 rate;
  }

  function tileId(uint256 gameId, uint256 x, uint256 y) public pure returns(uint256) {
    if (x >= 100 || y >= 100) revert PositionInvalid();
    return (gameId * 10000) + (x * 100) + y;
  }

  function tilePosition(uint256 tokenId) public pure returns(uint256 gameId, uint256 x, uint256 y) {
    gameId = tokenId / 10000;
    tokenId -= gameId * 10000;
    x = tokenId / 100;
    y = tokenId - x * 100;
    return (gameId, x, y);
  }

  function _ownerOf(IERC721Mintable nft, uint256 tokenId) internal view returns(address) {
    try nft.ownerOf(tokenId) returns(address owner) {
      return owner;
    } catch (bytes memory) {
      return address(0);
    }
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

  function calculateTileRateAndNeighbours(address nftAddress, uint256 gameId, uint256 x, uint256 y, BuildingType buildingType, address sender) public view returns(int256 newTileRate, NeighbourRate[] memory neigbourRates) {
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    NeighbourPosition[] memory positions = createNeighbourPositions();
    neigbourRates = new NeighbourRate[](8);
    newTileRate = int256(gameProperties.baseRate);
    for (uint256 i = 0; i < positions.length; i++) {
      if (((positions[i].deltaX < 0) && (x == 0))
        || ((positions[i].deltaY < 0) && (y == 0))
        || ((positions[i].deltaX == 1) && (x == gameProperties.xSize - 1))
        || ((positions[i].deltaY == 1) && (y == gameProperties.ySize - 1))) continue;
      uint256 neighbourTileId = tileId(
        gameId,
        uint256(int256(x) + positions[i].deltaX),
        uint256(int256(y) + positions[i].deltaY)
      );
      address neighbour = _ownerOf(IERC721Mintable(nftAddress), neighbourTileId);
      if (neighbour == address(0)) continue;
      BuildingType neighbourBuilding = Tiles.get(neighbourTileId);
      int256 bonusNeighbour;
      // Same
      if (neighbourBuilding == buildingType) {
        newTileRate += gameProperties.bonusSame;
        bonusNeighbour = gameProperties.bonusSame;
      } else if ((neighbourBuilding < buildingType)
        || ((neighbourBuilding == type(BuildingType).max) && (uint(buildingType) == 0))
      ) { 
        // Neighbour is victim
        newTileRate += gameProperties.bonusEnemy;
        bonusNeighbour = gameProperties.bonusVictim;
      } else {
        // Neighbour is enemy
        newTileRate += gameProperties.bonusVictim;
        bonusNeighbour = gameProperties.bonusEnemy;
      }
      if (neighbour == sender) {
        newTileRate += bonusNeighbour;
      } else {
        neigbourRates[i] = NeighbourRate(neighbour, bonusNeighbour);
      }
    }
  }

  function calculateTileRate(address nftAddress, uint256 tokenId) public view returns(int256 rate) {
    (uint256 gameId, uint256 x, uint256 y) = tilePosition(tokenId);
    BuildingType buildingType = Tiles.get(tokenId);
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    NeighbourPosition[] memory positions = createNeighbourPositions();
    rate = int256(gameProperties.baseRate);
    for (uint256 i = 0; i < positions.length; i++) {
      if (((positions[i].deltaX < 0) && (x == 0))
        || ((positions[i].deltaY < 0) && (y == 0))
        || ((positions[i].deltaX == 1) && (x == gameProperties.xSize - 1))
        || ((positions[i].deltaY == 1) && (y == gameProperties.ySize - 1))) continue;
      uint256 neighbourTileId = tileId(
        gameId,
        uint256(int256(x) + positions[i].deltaX),
        uint256(int256(y) + positions[i].deltaY)
      );
      address neighbour = _ownerOf(IERC721Mintable(nftAddress), neighbourTileId);
      if (neighbour == address(0)) continue;
      BuildingType neighbourBuilding = Tiles.get(neighbourTileId);
      // Same
      if (neighbourBuilding == buildingType) {
        rate += gameProperties.bonusSame;
      } else if ((neighbourBuilding < buildingType)
        || ((neighbourBuilding == type(BuildingType).max) && (uint(buildingType) == 0))
      ) { 
        // Tile is enemy
        rate += gameProperties.bonusEnemy;
      } else {
        // Tile is victim
        rate += gameProperties.bonusVictim;
      }
      return rate;
    }
  }
}
