module.exports = process.argv[2] === "main" ? require("./main") : require("./shasta");
