// Sideloads the built zip to a Roku in developer mode on your network:
//   ROKU_HOST=192.168.x.x ROKU_PASSWORD=... npm run deploy
const rokuDeploy = require("roku-deploy");
const host = process.env.ROKU_HOST, password = process.env.ROKU_PASSWORD;
if (!host || !password) { console.error("Set ROKU_HOST and ROKU_PASSWORD (the developer-mode password)."); process.exit(1); }
rokuDeploy.publish({ host, password, outDir: "out", outFile: "cove-roku.zip" })
    .then(() => console.log(`Installed on ${host}`))
    .catch(e => { console.error(e.message || e); process.exit(1); });
