
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

const prependRule = [
  // ===== 本地地址直连 =====
  "IP-CIDR,127.0.0.0/8,DIRECT",
  "IP-CIDR6,::1/128,DIRECT",
  "DOMAIN,localhost,DIRECT",
  "DOMAIN-SUFFIX,local,DIRECT",

  // ===== 特定应用规则 =====
  "PROCESS-NAME,WeChat,DIRECT",
  "PROCESS-NAME,git-remote-http,BosLife",
  "PROCESS-PATH-REGEX,/Users/kan/.local/share/claude/*,🏠 LA",

  // ===== Claude / Anthropic / OpenAI 走自建（绕开机场脏 IP）=====
  "DOMAIN-KEYWORD,claude,🏠 LA",
  "DOMAIN-SUFFIX,anthropic.com,🏠 LA",
  "DOMAIN-KEYWORD,openai,🏠 LA",
  "DOMAIN-SUFFIX,openai.com,🏠 LA",
  "DOMAIN-SUFFIX,chatgpt.com,🏠 LA",
  "DOMAIN-SUFFIX,chat.com,🏠 LA",
  "DOMAIN-SUFFIX,oaiusercontent.com,🏠 LA",
  "DOMAIN-SUFFIX,oaistatic.com,🏠 LA",
  "DOMAIN-KEYWORD,codex,🏠 LA",
  "DOMAIN-SUFFIX,statsig.com,🏠 LA",
  "DOMAIN-SUFFIX,statsigapi.net,🏠 LA",

  // ===== 其他域名 =====
  "DOMAIN-KEYWORD,reddit,BosLife",
  "DOMAIN-KEYWORD,runpod,BosLife",

  // ===== IP 地理位置规则 =====
  "GEOIP,PRIVATE,DIRECT",
  "GEOIP,CN,DIRECT",
  "GEOIP,US,BosLife",
  "GEOIP,JP,BosLife",
  "GEOIP,SG,BosLife",
  "GEOIP,GB,BosLife",
  "GEOIP,DE,BosLife",
  "GEOIP,FR,BosLife",
  "GEOIP,CA,BosLife",
  "GEOIP,AU,BosLife",
  "GEOIP,KR,BosLife",
  "GEOIP,TW,BosLife",
  "GEOIP,HK,BosLife",
];

function main(config) {
  config.proxies = config.proxies || [];
  config.proxies.unshift(directNode, cdnNode);

  config["proxy-groups"] = config["proxy-groups"] || [];
  config["proxy-groups"].unshift(selfGroup);

  const boslife = config["proxy-groups"].find(g => g.name === "BosLife");
  if (boslife) {
    boslife.proxies = [GROUP_NAME, DIRECT_NAME, CDN_NAME, ...(boslife.proxies || [])];
  }

  config.rules = (config.rules || []).map(r =>
    r === "MATCH,DIRECT" ? "MATCH,BosLife" : r
  );

  config.rules = prependRule.concat(config.rules);

  return config;
}
