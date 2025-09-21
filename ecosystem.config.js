module.exports = {
  apps: [{
    name: "pulseo",
    cwd: "/var/www/pulseo/current",
    script: "node_modules/next/dist/bin/next",
    args: "start -p 3000",
    env: { NODE_ENV: "production" },
    max_restarts: 5,
    watch: false
  }]
}
