import { generateMerkleProof, getMerkleTreeRoot } from "./merkle-tree-module";

const funcName = process.argv[2];
const address = process.argv[3];
const amount = process.argv[4];

(async () => {
  try {
    let result: string | string[];
    if (funcName === "getMerkleTreeRoot") {
      result = await getMerkleTreeRoot();
    } else if (funcName === "generateMerkleProof") {
      const proof = await generateMerkleProof(address, amount);
      result = proof
        .map((hexStr) => (hexStr.startsWith("0x") ? hexStr.slice(2) : hexStr))
        .join("");
    } else {
      throw new Error("Invalid function name");
    }
    console.log(result);
  } catch (error) {
    console.log("");
  }
})();
