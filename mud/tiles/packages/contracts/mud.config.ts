import { defineWorld } from "@latticexyz/world";
import { encodeAbiParameters } from "viem";

export default defineWorld({
  enums: {
    BuildingType: ["Circle", "Triangle", "Square"],
  },
  modules: [

    {
      artifactPath: "@latticexyz/world-modules/out/PuppetModule.sol/PuppetModule.json",
      root: false,
      args: [],
    },
    {
      artifactPath: "@latticexyz/world-modules/out/ERC721Module.sol/ERC721Module.json",
      root: false,
      args: [
        {
          type: "bytes",
          value: encodeAbiParameters(
            [
              { type: "bytes14" },
              {
                type: "tuple",
                components: [{ type: "string" }, { type: "string" }, { type: "string" }],
              },
            ], // end of list of types
            [
              "0x44444444".padEnd(30, "0"), // namespace
              // "0x617070".padEnd(32, "0"), // namespace
              ["No Valuable Token", "NVT", "http://www.example.com/base/uri/goes/here"], // end of the ERC-721 metadata tuple
            ], // end of parameter list
          ), // end of encodeAbiParameters call
        }, // end of the argument
      ], // end of list of args for the module
    },
  ],
  namespaces: {
    app: {
      tables: {
        GlobalConfig: {
          schema: {
            erc20token: "address",
          },
          key: [],
        },
        GameProperties: {
          schema: {
            gameId: "uint256",
            xSize: "uint256",
            ySize: "uint256",
            baseRate: "uint256",
            bonusSame: "int256",
            bonusEnemy: "int256",
            bonusVictim: "int256",
            pricePerTile: "uint256"
          },
          key: ["gameId"],
        },
        Tiles: {
          schema: {
            gameId: "uint256",
            x: "uint256",
            y: "uint256",
            building: "BuildingType",
            owner: "address"
          },
          key: ["gameId", "x", "y"],
        },
        Owners: {
          schema: {
              ownerAddress: "address",
              rate: "uint256",
              lastUpdateTime: "uint256",
              unclaimed: "uint256"
            },
            key: ["ownerAddress"],
        },
      },
      systems: {
        ConfigSystem: {
          openAccess: false,
          accessList: ["0x953C2658358Ace1D0335a11140Bb7D2469FCbC05"],
        }
      },
      
    },
  },
});
