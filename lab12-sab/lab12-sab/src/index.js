const http = require("http");
const client = require("prom-client");

const hostname = "0.0.0.0";
const port = 3000;

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const counter = new client.Counter({
  name: "http_requests_total",
  help: "Número total de peticiones recibidas",
});
register.registerMetric(counter);

const server = http.createServer(async (req, res) => {
  if (req.url === "/metrics") {
    res.setHeader("Content-Type", register.contentType);
    res.end(await register.metrics());
    return;
  }

  counter.inc();

  res.statusCode = 200;
  res.setHeader("Content-Type", "text/plain");
  console.log("Query");
  res.end("Hello World from Node.js!\n");
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
