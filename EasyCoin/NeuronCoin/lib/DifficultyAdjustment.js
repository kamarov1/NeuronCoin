class DifficultyAdjustment {
    constructor(targetBlockTime, adjustmentInterval) {
        this.targetBlockTime = targetBlockTime;
        this.adjustmentInterval = adjustmentInterval;
        this.difficulties = [];
        this.timestamps = [];
    }

    addBlock(difficulty, timestamp) {
        this.difficulties.push(difficulty);
        this.timestamps.push(timestamp);

        if (this.difficulties.length > this.adjustmentInterval) {
            this.difficulties.shift();
            this.timestamps.shift();
        }
    }

    calculateNextDifficulty() {
        if (this.difficulties.length < this.adjustmentInterval) {
            return this.difficulties[this.difficulties.length - 1];
        }

        const timeSpan = this.timestamps[this.timestamps.length - 1] - this.timestamps[0];
        const expectedTimeSpan = this.targetBlockTime * (this.adjustmentInterval - 1);

        let adjustment = timeSpan / expectedTimeSpan;

        // Limit adjustment to prevent extreme changes
        adjustment = Math.max(0.75, Math.min(1.25, adjustment));

        const averageDifficulty = this.difficulties.reduce((a, b) => a + b, 0) / this.difficulties.length;
        return Math.round(averageDifficulty * adjustment);
    }

    getAverageDifficulty() {
        return this.difficulties.reduce((a, b) => a + b, 0) / this.difficulties.length;
    }

    getAverageBlockTime() {
        if (this.timestamps.length < 2) return this.targetBlockTime;
        const totalTime = this.timestamps[this.timestamps.length - 1] - this.timestamps[0];
        return totalTime / (this.timestamps.length - 1);
    }
}

module.exports = DifficultyAdjustment;