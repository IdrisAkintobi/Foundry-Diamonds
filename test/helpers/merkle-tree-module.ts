import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { parse } from "csv-parse";
import { createReadStream } from "node:fs";
import { resolve } from "node:path";

const filePath: string = resolve("data", "records.csv");

type RecordType = { address: string; amount: string };

async function generateMerkleTree(): Promise<
  StandardMerkleTree<(string | bigint)[]>
> {
  const parser = parse({ columns: true }) as unknown as NodeJS.ReadWriteStream;
  const records: RecordType[] = [];

  return new Promise((resolve, reject) => {
    parser.on("readable", () => {
      let record: string | Buffer;
      while ((record = parser.read())) {
        records.push(record as unknown as RecordType);
      }
    });

    parser.on("error", (err) => {
      reject(err);
    });

    parser.on("end", () => {
      const parsedRecords = records.map((i) => [i.address, BigInt(i.amount)]);

      const tree = StandardMerkleTree.of(parsedRecords, ["address", "uint256"]);
      resolve(tree);
    });

    const fileStream = createReadStream(filePath);
    fileStream.pipe(parser);
  });
}

export const getMerkleTreeRoot = async (): Promise<string> => {
  const tree = await generateMerkleTree();
  return tree.root;
};

export const generateMerkleProof = async (
  address: string,
  amount: string
): Promise<string[]> => {
  const tree = await generateMerkleTree();
  const proof = tree.getProof([address, amount]);
  return proof;
};

export const verifyMerkleProof = async (
  address: string,
  amount: string,
  proof: string[]
): Promise<boolean> => {
  const tree = await generateMerkleTree();
  const verified = tree.verify([address, BigInt(amount)], proof);
  return verified;
};
