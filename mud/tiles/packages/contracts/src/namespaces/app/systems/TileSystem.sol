// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Tiles, Owners, OwnersData, GameProperties, GamePropertiesData } from "../codegen/index.sol";
import { BuildingType } from "../../../codegen/common.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ERC721Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { IERC721Mintable } from "@latticexyz/world-modules/src/modules/erc721-puppet/IERC721Mintable.sol";

contract TileSystem is System {

  error AlreadyPlaced();
  error FeeInvalid();
  error PositionInvalid();

  struct NeighbourPosition {
    int8 deltaX;
    int8 deltaY;
  }

  function tileId(uint256 gameId, uint256 x, uint256 y) public pure returns(uint256) {
    if (x >= 100 || y >= 100) revert PositionInvalid();
    return (gameId * 10000) + (x * 100) + y;
  }

  function _ownerOf(IERC721Mintable nft, uint256 tokenId) internal view returns(address) {
    try nft.ownerOf(tokenId) returns(address owner) {
      return owner;
    } catch (bytes memory) {
      return address(0);
    }
  }

  function getNft() public view returns(address) {
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("TILES"));
    ResourceId erc721RegistryResource = WorldResourceIdLib.encode(RESOURCE_TABLE, "erc721-puppet", "ERC721Registry");
    return ERC721Registry.getTokenAddress(erc721RegistryResource, namespaceResource);
  }

  function placeTile(uint256 gameId, uint256 x, uint256 y, BuildingType buildingType) public payable {
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    if ((x >= gameProperties.xSize) || (y >= gameProperties.ySize)) revert PositionInvalid();
    if (_msgValue() != gameProperties.pricePerTile) revert FeeInvalid();
    IERC721Mintable nft = IERC721Mintable(getNft());
    uint256 newTileId = tileId(gameId, x, y);
    address owner = _ownerOf(nft, newTileId);
    if (owner != address(0)) revert AlreadyPlaced();

    Tiles.set(newTileId, buildingType);
    OwnersData memory ownersData = Owners.get(_msgSender());
    // calc rate for this tile and update rate for neighbors
    NeighbourPosition[] memory positions = createNeighbourPositions();
    int256 newTileRate = int256(gameProperties.baseRate);
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
      address neighbour = _ownerOf(nft, neighbourTileId);
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
      OwnersData memory neighbourData = Owners.get(neighbour);
      if (neighbour == _msgSender()) {
        newTileRate += bonusNeighbour;
      } else {
        int256 rate = neighbourData.rate;
        if (rate > 0) {
          uint256 unclaimed = neighbourData.unclaimed + uint256(rate) * (block.timestamp - neighbourData.lastUpdateTime);
          Owners.setUnclaimed(neighbour, unclaimed);
        }
        Owners.setLastUpdateTime(neighbour, block.timestamp);
        Owners.setRate(neighbour, rate + bonusNeighbour);
      }
    }
    int256 ownerRate = ownersData.rate;
    if (ownerRate > 0) {
      uint256 unclaimed = ownersData.unclaimed + uint256(ownerRate) * (block.timestamp - ownersData.lastUpdateTime);
      Owners.setUnclaimed(_msgSender(), unclaimed);
    }
    Owners.setLastUpdateTime(_msgSender(), block.timestamp);
    Owners.setRate(_msgSender(), ownerRate + newTileRate);
    nft.safeMint(_msgSender(), newTileId);
  }

  // TODO: Update rate when NFT changes owners.

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
