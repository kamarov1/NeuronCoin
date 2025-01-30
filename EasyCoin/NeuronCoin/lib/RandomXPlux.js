const crypto = require('crypto');
const xxhash = require('xxhash-wasm');

class RandomXPlus {
    constructor() {
        this.initPromise = xxhash().then(xxhash => {
            this.xxhash64 = xxhash.h64;
        });
    }

    async initialize() {
        await this.initPromise;
    }

    async hash(input) {
        const buffer = Buffer.from(input);
        const seed = crypto.randomBytes(32);

        // Primeira fase: xxHash
        const xxHashResult = this.xxhash64(buffer, seed);

        // Segunda fase: AES rounds
        let result = Buffer.from(xxHashResult, 'hex');
        for (let i = 0; i < 4; i++) {
            result = this.aesRound(result, seed);
        }

        // Terceira fase: SHA3
        return crypto.createHash('sha3-256').update(result).digest('hex');
    }

    aesRound(data, key) {
        const cipher = crypto.createCipheriv('aes-256-ecb', key, null);
        cipher.setAutoPadding(false);
        return Buffer.concat([cipher.update(data), cipher.final()]);
    }

    async verify(hash, difficulty) {
        const target = BigInt(2 ** 256 - 1) / BigInt(difficulty);
        const hashValue = BigInt(`0x${hash}`);
        return hashValue < target;
    }
}

module.exports = RandomXPlus;
