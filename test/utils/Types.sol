// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

struct Users {
    // Default admin for all contracts.
    address payable admin;
    // User Alice.
    address payable alice;
    // User broker.
    address payable broker;
    // User Fee Address
    address payable feeAddress;
}
