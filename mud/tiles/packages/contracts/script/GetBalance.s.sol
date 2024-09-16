// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
 
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { Balances } from "@latticexyz/world/src/codegen/tables/Balances.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
 
contract GetBalance is Script {
  function run() external {
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    StoreSwitch.setStoreAddress(worldAddress);
    console.log("World at:", worldAddress);
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("app"));
    console.log("Namespace ID: %x", uint256(ResourceId.unwrap(namespaceResource)));
    uint256 balance = Balances.get(namespaceResource);
    console.log("Balance: %d wei", balance);
  }
}