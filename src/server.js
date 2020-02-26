const fs = require("fs");
const path = require("path");
const express = require("express");
const { exec } = require("child_process");

const HOST = "0.0.0.0";
const PORT = parseInt(process.env.PORT || "3000", 10);
const { TOKEN } = process.env;
const BASE_DIR = process.env.BASE_DIR || "/webhook";
const MAKEFILE = `${BASE_DIR}/Makefile`;

const app = express();

if (TOKEN)
  app.use((req, res, next) => {
    if (req.headers.authorization !== `Bearer ${TOKEN}`)
      return res.status(401).send("Unauthorized");
    return next();
  });

if (!fs.existsSync(MAKEFILE)) {
  console.error(`${MAKEFILE} does not exists`);
  process.exit(1);
}

app.get("*", (req, res) => {
  const { name: target } = path.parse(req.path);
  const config = { env: req.query, cwd: BASE_DIR };

  exec(`make ${target}`, config, (error, stdout, stderr) => {
    if (error) {
      console.error(new Date(), { target, env: req.query, status: error.code });
      return res.status(500).send(stderr);
    }

    console.log(new Date(), { status: 0 });
    return res.send("OK");
  });
});

app.listen(PORT, HOST);

console.log(`==> Running at http://localhost:${PORT}`);
