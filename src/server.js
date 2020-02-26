const fs = require("fs");
const path = require("path");
const express = require("express");
const process = require("process");
const { exec } = require("child_process");

// Constants
const HOST = "0.0.0.0";
const PORT = 3000;
const MAKE_DIR = process.env.MAKE_DIR || "/webhooks";
const MAKEFILE = `${MAKE_DIR}/Makefile`;
const SECRET_FILE = `${MAKE_DIR}/SECRET`;

const app = express();

// Get hot reloaded secret
const getSecret = () => {
  if (fs.existsSync(SECRET_FILE)) {
    return fs.readFileSync(SECRET_FILE);
  }
  return process.env.SECRET;
};

// Security
app.use((req, res, next) => {
  const secret = getSecret();
  if (secret && req.headers.authorization !== `Bearer ${secret}`) {
    return res.status(401).send("Unauthorized");
  }
  return next();
});

// Sanity check
if (!fs.existsSync(MAKEFILE)) {
  console.error(`${MAKEFILE} does not exists`);
  process.exit(1);
}

// Print an optional container introduction on startup
process.nextTick(() => {
  const opts = { cwd: MAKE_DIR };
  exec(`make intro`, opts, (error, stdout) => console.log(stdout));
});

// All GET requests
app.get("*", (req, res) => {
  // Parse URL
  const { name: target } = path.parse(req.path);
  const ENV = Object.entries(req.query).reduce((acc, [key, value]) => {
    acc[key.toUpperCase()] = value;
    return acc;
  }, {});

  // Marshal command results into json
  const handleExec = (error, stdout, stderr) => {
    if (error) {
      const response = { target, env: ENV, status: error.code };
      console.log(stderr);
      return res.status(500).json(response);
    }
    console.log(stdout);
    return res.json({ status: 0 });
  };

  // Execute make target
  const opts = { env: ENV, cwd: MAKE_DIR };
  const command = `make ${target}`;
  const env = Object.entries(ENV)
    .map(([key, value]) => `${key}=${value}`)
    .join(" ");
  console.log("## ==", new Date(), env, command);
  exec(command, opts, handleExec);
});

// Start HTTP server
app.listen(PORT, HOST);
console.log(`# Running at http://${HOST}:${PORT}`);

// Terminate with Ctrl-C
process.on("SIGINT", () => {
  console.log("# Interrupted");
  process.exit(0);
});
