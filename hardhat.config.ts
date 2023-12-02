import { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

export const config: HardhatUserConfig = {};

task("hello", "says hi", (taskArgs, hre) => {
  console.log(`Hello, ${taskArgs.name}`);
}).addOptionalParam("name");
