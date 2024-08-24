import { setup } from "./mud/setup";
import mudConfig from "contracts/mud.config";
import { encodeEntity } from "@latticexyz/store-sync/recs";
import { getComponentValue } from "@latticexyz/recs";

const {
  components,
  systemCalls: { increment, placeTile, configGame },
  network,
} = await setup();

await configGame();

// Components expose a stream that triggers when the component is updated.
components.Counter.update$.subscribe((update) => {
  const [nextValue, prevValue] = update.value;
  console.log("Counter updated", update, { nextValue, prevValue });
  document.getElementById("counter")!.innerHTML = String(nextValue?.value ?? "unset");
});

// Attach the increment function to the html element with ID `incrementButton` (if it exists)
document.querySelector("#incrementButton")?.addEventListener("click", increment);

// Components expose a stream that triggers when the component is updated.
components.Tiles.update$.subscribe((update) => {
  const [nextValue, prevValue] = update.value;
  console.log("Tiles updated", nextValue);
  // document.getElementById("tile")!.innerHTML = String(nextValue?.building ?? "unset");
});

components.Owners.update$.subscribe((update) => {
  const [nextValue, prevValue] = update.value;
  console.log("Owners updated", nextValue);
  // document.getElementById("tile")!.innerHTML = String(nextValue?.building ?? "unset");
});

const listener = () => {
  const gameId = document.getElementById("gameId")?.value;
  const x = document.getElementById("x")?.value;
  const y = document.getElementById("y")?.value;
  const buildingType = document.getElementById("buildingType")?.value;
  console.log("gameId, x, y, type: ", gameId, x, y, buildingType);
  placeTile([gameId, x, y, buildingType]);
};

// Attach the placeTile function to the html element with ID `incrementButton` (if it exists)
document.querySelector("#placeTileButton")?.addEventListener("click", listener);

// https://vitejs.dev/guide/env-and-mode.html
if (import.meta.env.DEV) {
  const { mount: mountDevTools } = await import("@latticexyz/dev-tools");
  mountDevTools({
    config: mudConfig,
    publicClient: network.publicClient,
    walletClient: network.walletClient,
    latestBlock$: network.latestBlock$,
    storedBlockLogs$: network.storedBlockLogs$,
    worldAddress: network.worldContract.address,
    worldAbi: network.worldContract.abi,
    write$: network.write$,
    recsWorld: network.world,
  });
}
