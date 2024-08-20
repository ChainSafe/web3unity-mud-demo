import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  namespace: "app",
  enums: {
    BuildingType: ["Circle", "Triangle", "Square"],
  },
  tables: {
    GameProperties: {
      schema: {
        gameId: "uint256",
        xSize: "uint256",
        ySize: "uint256",
        baseRate: "uint256",
        bonusSame: "uint256",
        bonusEnemy: "uint256",
        bonusVictim: "uint256",
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
    Counter: {
      schema: {
        value: "uint32",
      },
      key: [],
    },
  },
});
