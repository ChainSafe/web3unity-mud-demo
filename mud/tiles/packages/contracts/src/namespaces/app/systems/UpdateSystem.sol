// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";
import { Owners, OwnersData } from "../codegen/index.sol";
import { TileRateLibrary } from "../libraries/TileRateLibrary.sol";

contract UpdateSystem is System {
  error NegativeRate();
  function updateOwnersRate(address nftAddress, address to, address from, uint256 tokenId) external {
    // Update only if it's not mint (because it's already updated during placeTile)
    if (from != address(0)) {
      int256 tileRate = TileRateLibrary.calculateTileRate(nftAddress, tokenId);
      if (tileRate < 0) revert NegativeRate();
      // Update previous owner
      OwnersData memory fromData = Owners.get(from);
      int256 fromRate = fromData.rate;
      if (fromRate > 0) {
        uint256 unclaimed = fromData.unclaimed + uint256(fromRate) * (block.timestamp - fromData.lastUpdateTime);
        Owners.setUnclaimed(from, unclaimed);
      }
      Owners.setLastUpdateTime(from, block.timestamp);
      int256 updatedFromRate = fromRate - tileRate;
      if (updatedFromRate < 0) revert NegativeRate();
      Owners.setRate(from, updatedFromRate);
      // Update new owner
      if (to != address(0)) {
        OwnersData memory toData = Owners.get(to);
        int256 toRate = toData.rate;
        if (toRate > 0) {
          uint256 unclaimed = toData.unclaimed + uint256(toRate) * (block.timestamp - toData.lastUpdateTime);
          Owners.setUnclaimed(to, unclaimed);
        }
        Owners.setLastUpdateTime(to, block.timestamp);
        Owners.setRate(to, toRate + tileRate);
      }
    }
  }
}
