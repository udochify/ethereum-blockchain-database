const udo = require("../udo");
const hre = require("hardhat");
const DatabaseModule = require("../ignition/modules/Database");

async function main() {
    const database = await hre.ignition.deploy(DatabaseModule, {
      parameters: { Database: {authKey: udo.AUTH_KEY} },
    });

    console.log(`Database deployed to: ${database.database.target}`);
}

main().catch(console.error);