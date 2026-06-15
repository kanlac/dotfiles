/**
 * Personal Clash/Mihomo profile transformer.
 *
 * This file is the single source of truth for a Clash/Mihomo client profile.
 * It can be used directly as a Clash Verge profile script. Keep it
 * public-safe: self-hosted nodes should live in remote subscriptions, not here.
 *
 * Note: external-controller / secret / ports are reserved by Clash Verge itself
 * (merge_default_config) and CANNOT be set here — configure them in Clash Verge's
 * own config.yaml. This script only controls proxies / groups / rules / dns / tun.
 */

const FAKE_IP_FILTER = [
  "*.lan",
  "*.local",
  "*.arpa",
  "time.*.com",
  "ntp.*.com",
  "+.market.xiaomi.com",
  "localhost.ptlogin2.qq.com",
  "*.msftncsi.com",
  "www.msftconnecttest.com",
  // Captive portal / 公共 WiFi 登录探测：必须拿真实 IP，
  // 否则 fake-ip 会让门户跳转拦截失效，星巴克等登录页弹不出来。
  "captive.apple.com",
  "*.apple.com.akadns.net",
  "connectivitycheck.gstatic.com",
  "connectivitycheck.android.com",
  "*.network-auth.com",
  "detectportal.firefox.com",
  "*.kanlac.store",
  "kanlac.store",
];

const AI_RULES = [
  "DOMAIN-KEYWORD,claude",
  "DOMAIN-SUFFIX,anthropic.com",
  "DOMAIN-KEYWORD,openai",
  "DOMAIN-SUFFIX,openai.com",
  "DOMAIN-SUFFIX,chatgpt.com",
  "DOMAIN-SUFFIX,chat.com",
  "DOMAIN-SUFFIX,oaiusercontent.com",
  "DOMAIN-SUFFIX,oaistatic.com",
  "DOMAIN-KEYWORD,codex",
  "DOMAIN-SUFFIX,statsig.com",
  "DOMAIN-SUFFIX,statsigapi.net",
];

const AIRPORT_RULES = [
  "DOMAIN-KEYWORD,reddit",
  "DOMAIN-KEYWORD,runpod",
];

// 公共 WiFi 强制门户（captive portal）探测流量一律直连，
// 不要走代理（登录前代理不可达），让系统能弹出登录页。
const CAPTIVE_PORTAL_RULES = [
  "DOMAIN,captive.apple.com,DIRECT",
  "DOMAIN-SUFFIX,captive.apple.com,DIRECT",
  "DOMAIN,connectivitycheck.gstatic.com,DIRECT",
  "DOMAIN-SUFFIX,connectivitycheck.gstatic.com,DIRECT",
  "DOMAIN-SUFFIX,connectivitycheck.android.com,DIRECT",
  "DOMAIN-SUFFIX,network-auth.com,DIRECT",
  "DOMAIN-SUFFIX,detectportal.firefox.com,DIRECT",
  "PROCESS-NAME,Captive Network Assistant,DIRECT",
  "PROCESS-NAME,CaptiveNetworkAssistant,DIRECT",
];

const AIRPORT_CONTROL_RULES = [
  "DOMAIN-SUFFIX,kanlac.store,DIRECT",
];

const AIRPORT_GEOIP_RULES = [
  "GEOIP,US",
  "GEOIP,JP",
  "GEOIP,SG",
  "GEOIP,GB",
  "GEOIP,DE",
  "GEOIP,FR",
  "GEOIP,CA",
  "GEOIP,AU",
  "GEOIP,KR",
  "GEOIP,TW",
  "GEOIP,HK",
];

function findAirportGroup(config) {
  const groups = config["proxy-groups"] || [];
  const proxyGroup = groups.find(group => group.name === "PROXY" && group.type === "select");
  if (proxyGroup) return proxyGroup.name;

  const selectGroup = groups.find(group => group.type === "select");
  return selectGroup && selectGroup.name;
}

function appendPolicy(rule, policy) {
  return `${rule},${policy}`;
}

function isIpLiteral(server) {
  return /^(?:\d{1,3}\.){3}\d{1,3}$/.test(server);
}

function routeExcludeAddresses(config) {
  const addresses = new Set(config.tun?.["route-exclude-address"] || []);

  for (const proxy of config.proxies || []) {
    if (isIpLiteral(proxy.server)) {
      addresses.add(`${proxy.server}/32`);
    }
  }

  return [...addresses].sort();
}

function applyDns(config) {
  config.dns = {
    enable: true,
    ipv6: false,
    listen: ":53",
    "enhanced-mode": "fake-ip",
    "fake-ip-range": "198.18.0.1/16",
    "fake-ip-filter-mode": "blacklist",
    "prefer-h3": false,
    "respect-rules": true,
    "use-hosts": false,
    "use-system-hosts": false,
    "fake-ip-filter": FAKE_IP_FILTER,
    "default-nameserver": [
      "1.1.1.1",
      "8.8.8.8",
    ],
    nameserver: [
      "https://1.1.1.1/dns-query",
      "https://8.8.8.8/dns-query",
    ],
    fallback: [],
    "nameserver-policy": {
      "geosite:cn": [
        "https://223.5.5.5/dns-query",
        "https://1.12.12.12/dns-query",
      ],
      "*.lan": "system",
      "*.local": "system",
      "*.ts.net": "100.100.100.100",
    },
    // Keep bootstrap DNS literal to avoid a proxy-domain resolution loop.
    "proxy-server-nameserver": [
      "1.1.1.1",
      "8.8.8.8",
    ],
    "direct-nameserver": [
      "https://223.5.5.5/dns-query",
      "https://1.12.12.12/dns-query",
    ],
    "direct-nameserver-follow-policy": true,
    "fallback-filter": {
      geoip: true,
      "geoip-code": "CN",
      ipcidr: [
        "240.0.0.0/4",
        "0.0.0.0/32",
      ],
      domain: [
        "+.google.com",
        "+.facebook.com",
        "+.youtube.com",
      ],
    },
  };
}

function applyTun(config) {
  config.tun = {
    ...(config.tun || {}),
    enable: true,
    stack: "gvisor",
    device: "utun1024",
    "auto-route": true,
    "auto-detect-interface": true,
    "dns-hijack": ["any:53"],
    "route-exclude-address": routeExcludeAddresses(config),
    mtu: 1500,
    "strict-route": false,
  };
}

function applySniffer(config) {
  config.sniffer = {
    enable: true,
    sniff: {
      TLS: {
        ports: [443, 8443, 2096],
        "override-destination": true,
      },
      HTTP: {
        ports: [80, "8080-8880"],
        "override-destination": true,
      },
    },
    "skip-domain": [
      "Mijia Cloud",
      "dlg.io.mi.com",
    ],
  };
}

function applyRules(config, airport) {
  if (!airport) return;

  config.rules = (config.rules || []).map(rule =>
    rule === "MATCH,DIRECT" ? `MATCH,${airport}` : rule
  );

  const prependRule = [
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR6,::1/128,DIRECT",
    "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve",
    "IP-CIDR,100.100.100.100/32,DIRECT,no-resolve",
    "DOMAIN,localhost,DIRECT",
    "DOMAIN-SUFFIX,local,DIRECT",
    "DOMAIN-SUFFIX,ts.net,DIRECT",
    "DOMAIN-KEYWORD,immersivetranslate,DIRECT",
    "DOMAIN-KEYWORD,feishu,DIRECT",

    ...CAPTIVE_PORTAL_RULES,
    ...AIRPORT_CONTROL_RULES,

    "PROCESS-NAME,WeChat,DIRECT",
    `DOMAIN,mp.weixin.qq.com,${airport}`,
    `PROCESS-NAME,git-remote-http,${airport}`,
    `PROCESS-PATH-REGEX,.*/\\.local/share/claude/.*,${airport}`,

    ...AI_RULES.map(rule => appendPolicy(rule, airport)),
    ...AIRPORT_RULES.map(rule => appendPolicy(rule, airport)),

    "GEOIP,PRIVATE,DIRECT",
    "GEOIP,CN,DIRECT",
    ...AIRPORT_GEOIP_RULES.map(rule => appendPolicy(rule, airport)),
  ];

  config.rules = prependRule.concat(config.rules || []);
}

function main(config) {
  applyDns(config);
  applyTun(config);
  applySniffer(config);
  const airport = findAirportGroup(config);
  applyRules(config, airport);
  return config;
}
