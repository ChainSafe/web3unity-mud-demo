// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Owners, OwnersData, GlobalConfig } from "../codegen/index.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";
import { IERC20 } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20.sol";

contract OwnersSystem is System {

  event Claim(uint256 indexed owner, uint256 amount);

  function claim() public {
    OwnersData memory ownersData = Owners.get(_msgSender());
    IERC20 token = IERC20(GlobalConfig.get());
    uint256 unclaimed = ownersData.unclaimed;
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace("app");
    uint256 balance = Balances.get(namespaceResource);
    if(token.balanceOf(address(this)));
  }
}
