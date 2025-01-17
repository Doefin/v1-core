const axios= require('axios');
// const delay = require('delay');

const startingBlockNumber = 879647;
const numberOfBlocks = 1;

async function fetchBlock(blockNumber) {
  try {
    const response = await axios.get(`https://api.blockcypher.com/v1/btc/main/blocks/${blockNumber}`);
    return response.data;
  } catch (error) {
    console.error(`Error fetching block ${blockNumber}:`, error.message);
    return null;
  }
}

function formatBlockHeader(block) {
  return {
    version: `0x${block.ver.toString(16).padStart(8, '0')}`,
    prevBlockHash: `0x${block.prev_block}`,
    merkleRootHash: `0x${block.mrkl_root}`,
    timestamp: Math.floor(new Date(block.time).getTime() / 1000),
    nBits: block.bits,
    nonce: block.nonce,
    blockHash: `0x${block.hash}`,
    blockNumber: block.height
  };
}

async function fetchBlockHeaders() {
  const blockHeaders = [];

  for (let i = 0; i < numberOfBlocks; i++) {
    const blockNumber = startingBlockNumber - i;
    const block = await fetchBlock(blockNumber);

    if (block) {
      const header = formatBlockHeader(block);
      blockHeaders.unshift(header);
      console.log(`Fetched block ${blockNumber}`);
    } else {
      console.log(`Skipping block ${blockNumber} due to error`);
    }

    await delay(2000);
  }

  return blockHeaders;
}
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}


fetchBlockHeaders().then(headers => {
  console.log(headers.length)
  console.log(JSON.stringify(headers, null, 2));
}).catch(error => {
  console.error('Error:', error.message);
});
