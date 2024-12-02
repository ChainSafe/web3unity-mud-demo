// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ERC721System } from "@latticexyz/world-modules/src/modules/erc721-puppet/ERC721System.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IWorld } from "../../../codegen/world/IWorld.sol";
import { UpdateSystem } from "./UpdateSystem.sol";

contract NftSystem is ERC721System {

  function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    address from = super._update(to, tokenId, auth);
    address tokenAddress = address(puppet());
    ResourceId updateResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "app", "UpdateSystem");
    IWorld(_world()).call(
      updateResource,
      abi.encodeWithSelector(UpdateSystem.updateOwnersRate.selector,
        tokenAddress, to, from, tokenId)
    );
    return from;
  }
}
