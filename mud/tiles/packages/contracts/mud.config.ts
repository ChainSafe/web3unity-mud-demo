import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  enums: {
    BuildingType: ["Circle", "Triangle", "Square"],
  },
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
