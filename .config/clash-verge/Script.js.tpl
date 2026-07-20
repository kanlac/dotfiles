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

// Rendered from an ignored, mode-0600 local inventory. Never put real proxy
// credentials in this public template.
const SERVICE_ROUTING_PRIVATE = __SERVICE_ROUTING_PRIVATE__;
const SERVICE_ROUTING_PROVIDERS = SERVICE_ROUTING_PRIVATE.providers;
const SERVICE_EGRESS_POLICIES = SERVICE_ROUTING_PRIVATE.policies;
const SERVICE_ROUTING_ROUTE_EXCLUDES = SERVICE_ROUTING_PRIVATE.routeExcludeAddresses;
const SERVICE_GROUP_NAMES = new Set(
  Object.values(SERVICE_EGRESS_POLICIES).map(policy => policy.group)
);

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

const CLAUDE_PROCESS_RULES = [
  "PROCESS-NAME,claude",
  "PROCESS-NAME,Claude",
  "PROCESS-PATH-REGEX,.*/(@anthropic-ai/claude-code|\\.local/share/claude)/.*",
];

const OPENAI_PROCESS_RULES = [
  "PROCESS-NAME,codex",
  "PROCESS-NAME,codex-code-mode-host",
  "PROCESS-NAME,ChatGPT",
  "PROCESS-PATH-REGEX,.*/(@openai/codex|\\.codex)/.*",
];

function dnsNameserversFor(policy) {
  return [
    `https://1.1.1.1/dns-query#${policy}`,
    `https://8.8.8.8/dns-query#${policy}`,
  ];
}

const AIRPORT_RULES = [
  "DOMAIN-KEYWORD,reddit",
  "DOMAIN-KEYWORD,runpod",
];

const REMOTE_RULE_PROVIDERS = {
  "kanlac-anthropic": {
    type: "http",
    behavior: "classical",
    format: "text",
    url: "https://raw.githubusercontent.com/kanlac/proxy-rules/main/rules/ai/anthropic.list",
    path: "./ruleset/kanlac-anthropic.list",
    interval: 86400,
  },
  "kanlac-openai": {
    type: "http",
    behavior: "classical",
    format: "text",
    url: "https://raw.githubusercontent.com/kanlac/proxy-rules/main/rules/ai/openai.list",
    path: "./ruleset/kanlac-openai.list",
    interval: 86400,
  },
  "kanlac-spotify": {
    type: "http",
    behavior: "classical",
    format: "yaml",
    url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Spotify/Spotify_No_Resolve.yaml",
    path: "./ruleset/spotify.yaml",
    interval: 86400,
  },
};

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

  const selectGroup = groups.find(group =>
    group.type === "select" && !SERVICE_GROUP_NAMES.has(group.name)
  );
  return selectGroup && selectGroup.name;
}

function removeByName(items, name) {
  return (items || []).filter(item => item.name !== name);
}

function applyServiceEgress(config) {
  config["proxy-providers"] = {
    ...(config["proxy-providers"] || {}),
    ...SERVICE_ROUTING_PROVIDERS,
  };

  for (const policy of Object.values(SERVICE_EGRESS_POLICIES).reverse()) {
    config["proxy-groups"] = removeByName(config["proxy-groups"], policy.group);
    config["proxy-groups"].unshift({
      name: policy.group,
      type: "select",
      proxies: ["REJECT-DROP"],
      use: policy.use,
    });
  }
}

function appendPolicy(rule, policy) {
  const noResolve = ",no-resolve";
  if (rule.endsWith(noResolve)) {
    return `${rule.slice(0, -noResolve.length)},${policy}${noResolve}`;
  }
  return `${rule},${policy}`;
}

function isIpLiteral(server) {
  return /^(?:\d{1,3}\.){3}\d{1,3}$/.test(server);
}

function routeExcludeAddresses(config) {
  const addresses = new Set([
    ...(config.tun?.["route-exclude-address"] || []),
    ...SERVICE_ROUTING_ROUTE_EXCLUDES,
  ]);

  for (const proxy of config.proxies || []) {
    if (isIpLiteral(proxy.server)) {
      addresses.add(`${proxy.server}/32`);
    }
  }

  return [...addresses].sort();
}

function applyDns(config, airport) {
  const defaultNameservers = airport
    ? dnsNameserversFor(airport)
    : ["https://1.1.1.1/dns-query", "https://8.8.8.8/dns-query"];
  const anthropicGroup = SERVICE_EGRESS_POLICIES.anthropic.group;
  const openaiGroup = SERVICE_EGRESS_POLICIES.openai.group;
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
    nameserver: defaultNameservers,
    fallback: [],
    "nameserver-policy": {
      "rule-set:kanlac-anthropic": dnsNameserversFor(anthropicGroup),
      "rule-set:kanlac-openai": dnsNameserversFor(openaiGroup),
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

function applyRuleProviders(config, airport) {
  const downloadProxy = airport || "DIRECT";
  config["rule-providers"] = {
    ...(config["rule-providers"] || {}),
    ...Object.fromEntries(
      Object.entries(REMOTE_RULE_PROVIDERS).map(([name, provider]) => [
        name,
        {...provider, proxy: downloadProxy},
      ])
    ),
  };
}

function applyRules(config, airport) {
  if (airport) {
    config.rules = (config.rules || []).map(rule =>
      rule === "MATCH,DIRECT" ? `MATCH,${airport}` : rule
    );
  }

  const prependRule = [
    "IP-CIDR,127.0.0.0/8,DIRECT",
    "IP-CIDR6,::1/128,DIRECT",
    "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve",
    "IP-CIDR,100.100.100.100/32,DIRECT,no-resolve",
    "DOMAIN,localhost,DIRECT",
    "DOMAIN-SUFFIX,local,DIRECT",
    "DOMAIN-SUFFIX,ts.net,DIRECT",

    // Keep Spotify direct on both the desktop app and web/mobile clients.
    "PROCESS-NAME,Spotify,DIRECT",
    "RULE-SET,kanlac-spotify,DIRECT",

    ...CLAUDE_PROCESS_RULES.map(rule =>
      appendPolicy(rule, SERVICE_EGRESS_POLICIES.anthropic.group)
    ),
    `RULE-SET,kanlac-anthropic,${SERVICE_EGRESS_POLICIES.anthropic.group}`,
    ...OPENAI_PROCESS_RULES.map(rule =>
      appendPolicy(rule, SERVICE_EGRESS_POLICIES.openai.group)
    ),
    `RULE-SET,kanlac-openai,${SERVICE_EGRESS_POLICIES.openai.group}`,

    "DOMAIN-KEYWORD,immersivetranslate,DIRECT",
    "DOMAIN-KEYWORD,feishu,DIRECT",

    ...CAPTIVE_PORTAL_RULES,
    ...AIRPORT_CONTROL_RULES,

    "PROCESS-NAME,WeChat,DIRECT",
    ...(airport ? [
      `DOMAIN,mp.weixin.qq.com,${airport}`,
      `PROCESS-NAME,git-remote-http,${airport}`,
      ...AIRPORT_RULES.map(rule => appendPolicy(rule, airport)),
    ] : []),

    "GEOIP,PRIVATE,DIRECT",
    "GEOIP,CN,DIRECT",
    ...(airport
      ? AIRPORT_GEOIP_RULES.map(rule => appendPolicy(rule, airport))
      : []),
  ];

  config.rules = prependRule.concat(config.rules || []);
}

function main(config) {
  // A historical profile may still bind this transformer in addition to the
  // global Script. Treat the injected group + providers as an idempotency marker.
  const existingGroups = new Map(
    (config["proxy-groups"] || []).map(group => [group.name, group])
  );
  const existingProviders = config["proxy-providers"] || {};
  if (
    Object.values(SERVICE_EGRESS_POLICIES).every(policy => {
      const group = existingGroups.get(policy.group);
      return group && policy.use.every(provider =>
        group.use?.includes(provider) && existingProviders[provider]
      );
    })
  ) {
    return config;
  }

  const airport = findAirportGroup(config);
  applyDns(config, airport);
  applyTun(config);
  applySniffer(config);
  applyServiceEgress(config);
  applyRuleProviders(config, airport);
  applyRules(config, airport);
  return config;
}
