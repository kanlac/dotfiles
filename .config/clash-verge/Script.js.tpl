/**
 * Self-hosted VLESS Reality + CDN fallback profile transformer.
 *
 * This file is the single source of truth for a Clash/Mihomo client profile.
 * It can be used directly as a Clash Verge profile script, or handed to an AI
 * or conversion tool to derive equivalent configs for other clients.
 * Keep this template public-safe: do not replace placeholders in this file.
 * Generated client files contain real node secrets and must not be committed.
 *
 * Architecture:
 * - Direct: VLESS + Reality + Vision over TCP/443.
 * - CDN: VLESS + WebSocket + TLS over a CDN hostname on TCP/443.
 * - Selection: a url-test group chooses CDN first, direct fallback second.
 * - DNS: fake-ip, DNS hijack, and rule-respecting DoH to reduce DNS leaks.
 * - TUN: enabled with any:53 hijack so system DNS packets enter Mihomo.
 *
 * Required placeholders:
 * - __NODE_SERVER__: public IP or hostname of the VPS for Reality direct.
 * - __NODE_UUID__: VLESS client UUID.
 * - __NODE_REALITY_PUBLIC_KEY__: Reality public key generated on the VPS.
 * - __NODE_REALITY_SHORT_ID__: Reality short id generated on the VPS.
 * - __NODE_CDN_SERVER__: CDN edge hostname or preferred CDN IP/domain.
 * - __NODE_CDN_DOMAIN__: TLS SNI and WebSocket Host for the CDN route.
 */

const NODE = {
  directName: "🏠 LA-Direct",
  cdnName: "🏠 LA-CDN",
  groupName: "🏠 LA",
  directServer: "__NODE_SERVER__",
  cdnServer: "__NODE_CDN_SERVER__",
  cdnDomain: "__NODE_CDN_DOMAIN__",
  uuid: "__NODE_UUID__",
  realityPublicKey: "__NODE_REALITY_PUBLIC_KEY__",
  realityShortId: "__NODE_REALITY_SHORT_ID__",
  realityServerName: "www.microsoft.com",
  wsPath: "/ws",
};

const DIRECT_NODE = {
  name: NODE.directName,
  type: "vless",
  server: NODE.directServer,
  port: 443,
  uuid: NODE.uuid,
  network: "tcp",
  tls: true,
  udp: true,
  flow: "xtls-rprx-vision",
  "client-fingerprint": "chrome",
  servername: NODE.realityServerName,
  "reality-opts": {
    "public-key": NODE.realityPublicKey,
    "short-id": NODE.realityShortId,
  },
};

const CDN_NODE = {
  name: NODE.cdnName,
  type: "vless",
  server: NODE.cdnServer,
  port: 443,
  uuid: NODE.uuid,
  network: "ws",
  tls: true,
  udp: false,
  servername: NODE.cdnDomain,
  "ws-opts": {
    path: NODE.wsPath,
    headers: { Host: NODE.cdnDomain },
  },
};

const NODE_GROUP = {
  name: NODE.groupName,
  type: "url-test",
  proxies: [NODE.cdnName, NODE.directName],
  url: "https://www.gstatic.com/generate_204",
  interval: 300,
  tolerance: 50,
};

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

function removeByName(items, names) {
  const blocked = new Set(names);
  return (items || []).filter(item => !blocked.has(item.name));
}

function findAirportGroup(config) {
  const groups = config["proxy-groups"] || [];
  const selfNames = new Set([NODE.groupName, NODE.directName, NODE.cdnName]);
  const selectGroup = groups.find(group =>
    group.type === "select" && !selfNames.has(group.name)
  );
  return selectGroup && selectGroup.name;
}

function appendPolicy(rule, policy) {
  return `${rule},${policy}`;
}

function applyDns(config) {
  config.dns = {
    enable: true,
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
    mtu: 1500,
    "strict-route": false,
  };
}

function applySniffer(config) {
  config.sniffer = {
    enable: true,
    sniff: {
      TLS: {
        ports: [443, 8443],
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

function applyNodes(config) {
  config.proxies = removeByName(config.proxies, [NODE.directName, NODE.cdnName]);
  config.proxies.unshift(DIRECT_NODE, CDN_NODE);
}

function applyGroups(config) {
  config["proxy-groups"] = removeByName(config["proxy-groups"], [NODE.groupName]);
  config["proxy-groups"].unshift(NODE_GROUP);

  const airport = findAirportGroup(config);
  if (!airport) return null;

  const airportGroup = config["proxy-groups"].find(group => group.name === airport);
  if (airportGroup) {
    const existing = (airportGroup.proxies || []).filter(name =>
      ![NODE.groupName, NODE.directName, NODE.cdnName].includes(name)
    );
    airportGroup.proxies = [NODE.groupName, NODE.directName, NODE.cdnName, ...existing];
  }

  return airport;
}

function applyRules(config, airport) {
  if (!airport) return;

  config.rules = (config.rules || []).map(rule =>
    rule === "MATCH,DIRECT" ? `MATCH,${airport}` : rule
  );

  const prependRule = [
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR6,::1/128,DIRECT",
    "DOMAIN,localhost,DIRECT",
    "DOMAIN-SUFFIX,local,DIRECT",
    "DOMAIN-KEYWORD,immersivetranslate,DIRECT",

    "PROCESS-NAME,WeChat,DIRECT",
    `DOMAIN,mp.weixin.qq.com,${airport}`,
    `PROCESS-NAME,git-remote-http,${airport}`,
    `PROCESS-PATH-REGEX,.*/\\.local/share/claude/.*,${NODE.groupName}`,

    ...AI_RULES.map(rule => appendPolicy(rule, NODE.groupName)),
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
  applyNodes(config);
  const airport = applyGroups(config);
  applyRules(config, airport);
  return config;
}
