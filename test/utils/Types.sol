// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

struct Users {
    // Default admin for all contracts.
    address payable admin;
    // Impartial user.
    address payable alice;
    // Default stream broker.
    address payable broker;
}
