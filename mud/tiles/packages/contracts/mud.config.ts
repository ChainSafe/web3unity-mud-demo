import { defineWorld } from "@latticexyz/world";
import { encodeAbiParameters, stringToHex } from "viem";

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
              stringToHex("TILES", { size: 14 }), // namespace
              ["No Valuable Token", "TILES", "http://www.example.com/base/uri/goes/here"], // end of the ERC-721 metadata tuple
            ], // end of parameter list
          ), // end of encodeAbiParameters call
        }, // end of the argument
      ], // end of list of args for the module
    },
    {
      artifactPath: "@latticexyz/world-modules/out/ERC20Module.sol/ERC20Module.json",
      root: false,
      args: [
        {
          type: "bytes",
          value: encodeAbiParameters(
            [
              { type: "bytes14" },
              {
                type: "tuple",
                components: [{ type: "uint8" }, { type: "string" }, { type: "string" }],
              },
            ],
            [
              stringToHex("TOKENS", { size: 14 }),
              [18, "Worthless Token", "WT"],
            ],
          ),
        },
      ],
    },
  ],
  namespaces: {
    app: {
      tables: {
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
              rate: "int256",
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
