import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  namespace: "app",
  tables: {
    Counter: {
      schema: {
        value: "uint32",
      },
      key: [],
    },
    Tiles: {
      schema: {
        id: "uint256",
        x: "uint256",
        y: "uint256",
        building: "uint8"
      },
      key: ["id"],
    },
    Owners: {
      schema: {
          ownerAddress: "address",
          rate: "uint256",
          lastUpdateTime: "uint256",
          unclaimed: "uint256",
          tileIds: "uint256[]"
        },
        key: ["ownerAddress"],
    }
  },
});
