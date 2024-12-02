// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";
import { Owners, OwnerRates, OwnerRatesData, GameProperties } from "../codegen/index.sol";
import { TileRateLibrary } from "../libraries/TileRateLibrary.sol";

contract UpdateSystem is System {
  error NegativeRate();
  error RateCanChange();
  function updateOwnersRate(address nftAddress, address to, address from, uint256 tokenId) external {
    // Update only if it's not mint (because it's already updated during placeTile)
    if (from != address(0)) {
      (int256 tileRate, bool canChange) = TileRateLibrary.calculateTileRate(nftAddress, tokenId);
      (uint256 gameId,,) = TileRateLibrary.tilePosition(tokenId);
      if (tileRate < 0) revert NegativeRate();
      if (canChange) revert RateCanChange();
      // Update previous owner
      uint256 processUpTo = TileRateLibrary.min(GameProperties.get(gameId).endDate, block.timestamp);
      OwnerRatesData memory fromData = OwnerRates.get(from, gameId);
      int256 fromRate = fromData.rate;
      if (fromData.lastUpdateTime < processUpTo) {
        if (fromRate > 0) {
          uint256 unclaimed = Owners.getUnclaimed(from);
          unclaimed += uint256(fromRate) * (processUpTo - fromData.lastUpdateTime);
          Owners.setUnclaimed(from, unclaimed);
        }
        OwnerRates.setLastUpdateTime(from, gameId, processUpTo);
      }
      int256 updatedFromRate = fromRate - tileRate;
      if (updatedFromRate < 0) revert NegativeRate();
      OwnerRates.setRate(from, gameId, updatedFromRate);
      // Update new owner
      if (to != address(0)) {
        OwnerRatesData memory toData = OwnerRates.get(to, gameId);
        int256 toRate = toData.rate;
        if (fromData.lastUpdateTime < processUpTo) {
          if (toRate > 0) {
            uint256 unclaimed = Owners.getUnclaimed(to);
            unclaimed += uint256(toRate) * (processUpTo - toData.lastUpdateTime);
            Owners.setUnclaimed(to, unclaimed);
          }
          OwnerRates.setLastUpdateTime(to, gameId, processUpTo);
        }
        OwnerRates.setRate(to, gameId, toRate + tileRate);
      }
    }
  }
}
