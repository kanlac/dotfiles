
const DIRECT_NAME = "🏠 LA-Direct";
const CDN_NAME = "🏠 LA-CDN";
const GROUP_NAME = "🏠 LA";

const directNode = {
  name: DIRECT_NAME,
  type: "vless",
  server: "__LISA_LA_SERVER__",
  port: 443,
  uuid: "__LISA_LA_UUID__",
  network: "tcp",
  tls: true,
  udp: true,
  flow: "xtls-rprx-vision",
  "client-fingerprint": "chrome",
  servername: "www.microsoft.com",
  "reality-opts": {
    "public-key": "__LISA_LA_PUBLIC_KEY__",
    "short-id": "__LISA_LA_SHORT_ID__",
  },
};

const cdnNode = {
  name: CDN_NAME,
  type: "vless",
  server: "__LISA_CDN_SERVER__",
  port: 443,
  uuid: "__LISA_LA_UUID__",
  network: "ws",
  tls: true,
  udp: false,
  servername: "__LISA_CDN_DOMAIN__",
  "ws-opts": {
    path: "/ws",
    headers: { Host: "__LISA_CDN_DOMAIN__" },
  },
};

const selfGroup = {
  name: GROUP_NAME,
  type: "url-test",
  proxies: [CDN_NAME, DIRECT_NAME],
  url: "https://www.gstatic.com/generate_204",
  interval: 300,
  tolerance: 50,
};

function findAirportGroup(config) {
  const groups = config["proxy-groups"] || [];
  return (groups.find(g => g.type === "select" && g.name !== GROUP_NAME) || {}).name;
}

function main(config) {
  config.proxies = config.proxies || [];
  config.proxies.unshift(directNode, cdnNode);

  config["proxy-groups"] = config["proxy-groups"] || [];
  config["proxy-groups"].unshift(selfGroup);

  const airport = findAirportGroup(config);
  if (!airport) return config;

  const airportGroup = config["proxy-groups"].find(g => g.name === airport);
  if (airportGroup) {
    airportGroup.proxies = [GROUP_NAME, DIRECT_NAME, CDN_NAME, ...(airportGroup.proxies || [])];
  }

  config.rules = (config.rules || []).map(r =>
    r === "MATCH,DIRECT" ? `MATCH,${airport}` : r
  );

  const prependRule = [
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR6,::1/128,DIRECT",
    "DOMAIN,localhost,DIRECT",
    "DOMAIN-SUFFIX,local,DIRECT",

    "PROCESS-NAME,WeChat,DIRECT",
    `PROCESS-NAME,git-remote-http,${airport}`,
    `PROCESS-PATH-REGEX,/Users/kan/.local/share/claude/*,${GROUP_NAME}`,

    `DOMAIN-KEYWORD,claude,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,anthropic.com,${GROUP_NAME}`,
    `DOMAIN-KEYWORD,openai,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,openai.com,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,chatgpt.com,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,chat.com,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,oaiusercontent.com,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,oaistatic.com,${GROUP_NAME}`,
    `DOMAIN-KEYWORD,codex,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,statsig.com,${GROUP_NAME}`,
    `DOMAIN-SUFFIX,statsigapi.net,${GROUP_NAME}`,

    `DOMAIN-KEYWORD,reddit,${airport}`,
    `DOMAIN-KEYWORD,runpod,${airport}`,

    "GEOIP,PRIVATE,DIRECT",
    "GEOIP,CN,DIRECT",
    `GEOIP,US,${airport}`,
    `GEOIP,JP,${airport}`,
    `GEOIP,SG,${airport}`,
    `GEOIP,GB,${airport}`,
    `GEOIP,DE,${airport}`,
    `GEOIP,FR,${airport}`,
    `GEOIP,CA,${airport}`,
    `GEOIP,AU,${airport}`,
    `GEOIP,KR,${airport}`,
    `GEOIP,TW,${airport}`,
    `GEOIP,HK,${airport}`,
  ];

  config.rules = prependRule.concat(config.rules);

  return config;
}
