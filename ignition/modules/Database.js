const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const udo = require("../../udo");

module.exports = buildModule("Database", (m) => {
    const myLib = m.library("IterableMap");

    const database = m.contract("Database", [udo.AUTH_KEY], {
        libraries: {
          IterableMap: myLib,
        },
    });
    
    return { database };
});