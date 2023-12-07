import { configDotenv } from "dotenv";
import { HardhatUserConfig } from "hardhat/types";
import "./tasks";

configDotenv();
export const config: HardhatUserConfig = {};
