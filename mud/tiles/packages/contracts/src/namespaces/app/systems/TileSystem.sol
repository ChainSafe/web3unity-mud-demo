// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Tiles, Owners, OwnerRates, OwnerRatesData, GameProperties, GamePropertiesData } from "../codegen/index.sol";
import { BuildingType } from "../../../codegen/common.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ERC721Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { IERC721Mintable } from "@latticexyz/world-modules/src/modules/erc721-puppet/IERC721Mintable.sol";
import { TileRateLibrary } from "../libraries/TileRateLibrary.sol";

contract TileSystem is System {

  error AlreadyPlaced();
  error FeeInvalid();
  error PositionInvalid();

  function getNft() public view returns(address) {
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("TILES"));
    ResourceId erc721RegistryResource = WorldResourceIdLib.encode(RESOURCE_TABLE, "erc721-puppet", "ERC721Registry");
    return ERC721Registry.getTokenAddress(erc721RegistryResource, namespaceResource);
  }

  function placeTile(uint256 gameId, uint256 x, uint256 y, BuildingType buildingType) public payable {
    uint256 processUpTo;
    {
    GamePropertiesData memory gameProperties = GameProperties.get(gameId);
    if ((x >= gameProperties.xSize) || (y >= gameProperties.ySize)) revert PositionInvalid();
    if (_msgValue() != gameProperties.pricePerTile) revert FeeInvalid();
    processUpTo = TileRateLibrary.min(gameProperties.endDate, block.timestamp);
    }
    IERC721Mintable nft = IERC721Mintable(getNft());
    uint256 newTileId = TileRateLibrary.tileId(gameId, x, y);
    address owner = TileRateLibrary._ownerOf(nft, newTileId);
    if (owner != address(0)) revert AlreadyPlaced();

    Tiles.set(newTileId, buildingType);

    (int256 newTileRate, TileRateLibrary.NeighbourRate[] memory neigbourRates) = 
      TileRateLibrary.calculateTileRateAndNeighbours(address(nft), gameId, x, y, buildingType, _msgSender());
    for (uint256 i = 0; i < neigbourRates.length; i++) {
      if (neigbourRates[i].owner == address(0)) continue;
      address neighbour = neigbourRates[i].owner;
      OwnerRatesData memory neighbourData = OwnerRates.get(neighbour, gameId);
      int256 rate = neighbourData.rate;
      if (neighbourData.lastUpdateTime < processUpTo) {
        if (rate > 0) {
          uint256 unclaimed = Owners.getUnclaimed(neighbour);
          unclaimed += uint256(rate) * (processUpTo - neighbourData.lastUpdateTime);
          Owners.setUnclaimed(neighbour, unclaimed);
        }
        OwnerRates.setLastUpdateTime(neighbour, gameId, processUpTo);
      }
      OwnerRates.setRate(neighbour, gameId, rate + neigbourRates[i].rate);
    }
    OwnerRatesData memory ownersData = OwnerRates.get(_msgSender(), gameId);
    int256 ownerRate = ownersData.rate;
    if (ownersData.lastUpdateTime < processUpTo) {
      if (ownerRate > 0) {
        uint256 unclaimed = Owners.getUnclaimed(_msgSender());
        unclaimed += uint256(ownerRate) * (processUpTo - ownersData.lastUpdateTime);
        Owners.setUnclaimed(_msgSender(), unclaimed);
      }
      OwnerRates.setLastUpdateTime(_msgSender(), gameId, processUpTo);
    }
    OwnerRates.setRate(_msgSender(), gameId, ownerRate + newTileRate);
    nft.safeMint(_msgSender(), newTileId);
  }
}
