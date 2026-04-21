
const SELF_NAME = "🏠 LA-Self";

const selfNode = {
  name: SELF_NAME,
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

const prependRule = [
  // ===== 本地地址直连 =====
  "IP-CIDR,127.0.0.0/8,DIRECT",
  "IP-CIDR6,::1/128,DIRECT",
  "DOMAIN,localhost,DIRECT",
  "DOMAIN-SUFFIX,local,DIRECT",

  // ===== 特定应用规则 =====
  "PROCESS-NAME,WeChat,DIRECT",
  "PROCESS-NAME,git-remote-http,BosLife",
  "PROCESS-PATH-REGEX,/Users/kan/.local/share/claude/*,🏠 LA-Self",

  // ===== Claude / Anthropic / OpenAI 走自建（绕开机场脏 IP）=====
  "DOMAIN-KEYWORD,claude,🏠 LA-Self",
  "DOMAIN-SUFFIX,anthropic.com,🏠 LA-Self",
  "DOMAIN-KEYWORD,openai,🏠 LA-Self",
  "DOMAIN-SUFFIX,openai.com,🏠 LA-Self",
  "DOMAIN-SUFFIX,chatgpt.com,🏠 LA-Self",
  "DOMAIN-SUFFIX,chat.com,🏠 LA-Self",
  "DOMAIN-SUFFIX,oaiusercontent.com,🏠 LA-Self",
  "DOMAIN-SUFFIX,oaistatic.com,🏠 LA-Self",
  "DOMAIN-KEYWORD,codex,🏠 LA-Self",
  "DOMAIN-SUFFIX,statsig.com,🏠 LA-Self",     // Anthropic + OpenAI 功能开关 / A/B 测试
  "DOMAIN-SUFFIX,statsigapi.net,🏠 LA-Self",  // Statsig API 备用端点

  // ===== 其他域名 =====
  "DOMAIN-KEYWORD,reddit,BosLife",

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
  // 注入自建节点
  config.proxies = config.proxies || [];
  config.proxies.unshift(selfNode);

  // 将自建节点加入 BosLife 组
  config["proxy-groups"] = config["proxy-groups"] || [];
  const boslife = config["proxy-groups"].find(g => g.name === "BosLife");
  if (boslife) {
    boslife.proxies = [SELF_NAME, ...(boslife.proxies || [])];
  }

  // 前置规则
  config.rules = prependRule.concat(config.rules || []);

  return config;
}
