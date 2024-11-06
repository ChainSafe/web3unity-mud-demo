// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { BuildingType } from "../common.sol";

/**
 * @title ITileSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITileSystem {
  error AlreadyPlaced();
  error FeeInvalid();
  error PositionInvalid();

  function app__placeTile(uint256 gameId, uint256 x, uint256 y, BuildingType buildingType) external payable;
}
