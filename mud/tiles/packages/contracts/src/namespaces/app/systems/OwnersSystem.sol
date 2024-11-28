// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ERC20Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { Owners, OwnerRates, OwnerRatesData, GameProperties } from "../codegen/index.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";
import { IERC20Mintable } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20Mintable.sol";
import { TileRateLibrary } from "../libraries/TileRateLibrary.sol";

contract OwnersSystem is System {

  event Claim(address indexed owner, uint256 amount);
  error NothingToClaim();

  function getToken() public view returns(address) {
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("TOKENS"));
    ResourceId erc20RegistryResource = WorldResourceIdLib.encode(RESOURCE_TABLE, "erc20-puppet", "ERC20Registry");
    return ERC20Registry.getTokenAddress(erc20RegistryResource, namespaceResource);
  }

  function claim(uint256[] memory games) public {
    uint256 unclaimed = Owners.getUnclaimed(_msgSender());
    for (uint256 i = 0; i < games.length; ++i) {
      uint256 gameId = games[i];
      uint256 processUpTo = TileRateLibrary.min(GameProperties.get(gameId).endDate, block.timestamp);
      OwnerRatesData memory user = OwnerRates.get(_msgSender(), gameId);
      if (user.lastUpdateTime < processUpTo) {
        int256 rate = user.rate;
        if (rate > 0) {
          unclaimed += uint256(rate) * (processUpTo - user.lastUpdateTime);
          OwnerRates.setLastUpdateTime(_msgSender(), gameId, processUpTo);
        }
      }
    }
    if (unclaimed == 0) revert NothingToClaim();
    IERC20Mintable token = IERC20Mintable(getToken());
    Owners.setUnclaimed(_msgSender(), 0);
    token.mint(_msgSender(), unclaimed);
    emit Claim(_msgSender(), unclaimed);
  }
}
