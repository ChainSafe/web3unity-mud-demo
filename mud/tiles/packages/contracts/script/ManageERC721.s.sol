// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
 
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ERC721Registry } from "@latticexyz/world-modules/src/codegen/index.sol";
import { IERC721Mintable } from "@latticexyz/world-modules/src/modules/erc721-puppet/IERC721Mintable.sol";
 
import { IWorld } from "../src/codegen/world/IWorld.sol";
 
contract ManageERC721 is Script {
  function run() external {
    address worldAddress = address(0x8D8b6b8414E1e3DcfD4168561b9be6bD3bF6eC4B);
 
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);
 
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address myAddress = vm.addr(deployerPrivateKey);
 
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
 
    // Get the ERC-721 token address
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("TILES"));
    ResourceId erc721RegistryResource = WorldResourceIdLib.encode(RESOURCE_TABLE, "erc721-puppet", "ERC721Registry");
    address tokenAddress = ERC721Registry.getTokenAddress(erc721RegistryResource, namespaceResource);
    console.log("Token address", tokenAddress);
 
    // Settings to test with
    uint256 badGoatToken = uint256(0xBAD060A7);
    uint256 beefToken = uint256(0xBEEF);
    address goodGuy = address(0x600D);
    address badGuy = address(0x0BAD);
 
    // Use the token
    IERC721Mintable erc721 = IERC721Mintable(tokenAddress);
 
    // Mint two tokens
    erc721.mint(goodGuy, badGoatToken);
    erc721.mint(myAddress, beefToken);
    console.log("Owner of bad goat:", erc721.ownerOf(badGoatToken));
    console.log("Owner of beef:", erc721.ownerOf(beefToken));
 
    // Transfer a token
    erc721.transferFrom(myAddress, badGuy, beefToken);
    console.log("Owner of bad goat:", erc721.ownerOf(badGoatToken));
    console.log("Owner of beef:", erc721.ownerOf(beefToken));
 
    // Burn the tokens
    erc721.burn(badGoatToken);
    erc721.burn(beefToken);
 
    console.log("Done");
 
    vm.stopBroadcast();
  }
}