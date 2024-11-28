// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { ERC721Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { _erc721SystemId } from "@latticexyz/world-modules/src/modules/erc721-puppet/utils.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ResourceId ownersResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "app", "OwnersSystem");
    // Allow Owners system to mint tokens.
    IWorld(worldAddress).transferOwnership(
      WorldResourceIdLib.encodeNamespace(bytes14("TOKENS")),
      Systems.getSystem(ownersResource)
    );

    ResourceId tileResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "app", "TileSystem");
    // Allow Tile system to mint NFTs.
    IWorld(worldAddress).transferOwnership(
      WorldResourceIdLib.encodeNamespace(bytes14("TILES")),
      Systems.getSystem(tileResource)
    );


    // Grant access to tables
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("TILES"));
    ResourceId erc721RegistryResource = WorldResourceIdLib.encode(RESOURCE_TABLE, "erc721-puppet", "ERC721Registry");
    address tokenAddress = ERC721Registry.getTokenAddress(erc721RegistryResource, namespaceResource);
    ResourceId updateResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "app", "UpdateSystem");


    // IWorld(worldAddress).grantAccess(updateResource, address(0x00f2b7298031ea80bB1eE62e92D35904A539ce10));

    IWorld(worldAddress).grantAccess(updateResource, tokenAddress);

    // ResourceId nftResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "app", "NftSystem");
    // address systemAddress = Systems.getSystem(nftResource);
    address systemAddress = Systems.getSystem(_erc721SystemId("TILES"));
    IWorld(worldAddress).grantAccess(updateResource, systemAddress);

    vm.stopBroadcast();
  }
}
