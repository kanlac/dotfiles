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

const AI_EGRESS = {
  groupName: "🤖 AI-EGRESS",
};

// Rendered from an ignored, mode-0600 local inventory. Never put real proxy
// credentials in this public template.
const AI_EGRESS_PRIVATE = __AI_EGRESS_PRIVATE__;
const AI_EGRESS_PROXIES = [
  ...AI_EGRESS_PRIVATE.proxies.filter(
    proxy => proxy.name === AI_EGRESS_PRIVATE.primary
  ),
  ...AI_EGRESS_PRIVATE.proxies.filter(
    proxy => proxy.name !== AI_EGRESS_PRIVATE.primary
  ),
];

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
  // Process rules are the fail-safe for new or shared vendor domains.
  "PROCESS-NAME,claude",
  "PROCESS-NAME,Claude",
  "PROCESS-NAME,codex",
  "PROCESS-NAME,codex-code-mode-host",
  "PROCESS-NAME,ChatGPT",
  "PROCESS-PATH-REGEX,.*/(@anthropic-ai/claude-code|@openai/codex|\\.local/share/claude|\\.codex)/.*",

  // Anthropic / Claude.
  "DOMAIN-KEYWORD,claude",
  "DOMAIN-KEYWORD,anthropic",
  "DOMAIN-SUFFIX,anthropic.com",
  "DOMAIN-SUFFIX,claude.ai",
  "DOMAIN-SUFFIX,claude.com",

  // OpenAI / ChatGPT / Codex core and product domains.
  "DOMAIN-KEYWORD,openai",
  "DOMAIN-KEYWORD,chatgpt",
  "DOMAIN-KEYWORD,codex",
  "DOMAIN-SUFFIX,openai.com",
  "DOMAIN-SUFFIX,chatgpt.com",
  "DOMAIN-SUFFIX,chat.com",
  "DOMAIN-SUFFIX,ai.com",
  "DOMAIN-SUFFIX,sora.com",
  "DOMAIN-SUFFIX,oaiusercontent.com",
  "DOMAIN-SUFFIX,oaistatic.com",
  "DOMAIN-SUFFIX,auth.openai.com",
  "DOMAIN-SUFFIX,openaimerge.com",
  "DOMAIN-SUFFIX,prodregistryv2.org",
  "DOMAIN,chat.openai.com.cdn.cloudflare.net",
  "DOMAIN,openai-api.arkoselabs.com",
  "DOMAIN,openaicom-api-bdcpf8c6d2e9atf6.z01.azurefd.net",
  "DOMAIN,openaicomproductionae4b.blob.core.windows.net",
  "DOMAIN,production-openaicom-storage.azureedge.net",
  "DOMAIN-SUFFIX,openaiapi-site.azureedge.net",
  "DOMAIN-SUFFIX,openaicom.imgix.net",

  // OpenAI auth, risk control, feature flags, telemetry, files and realtime.
  "DOMAIN-SUFFIX,statsig.com",
  "DOMAIN-SUFFIX,statsigapi.net",
  "DOMAIN-SUFFIX,featuregates.org",
  "DOMAIN-SUFFIX,featureassets.org",
  "DOMAIN-SUFFIX,arkoselabs.com",
  "DOMAIN-SUFFIX,auth0.com",
  "DOMAIN-SUFFIX,livekit.cloud",
  "DOMAIN-SUFFIX,workos.com",
  "DOMAIN-SUFFIX,workoscdn.com",
  "DOMAIN-SUFFIX,intercom.io",
  "DOMAIN-SUFFIX,intercomcdn.com",
  "DOMAIN-SUFFIX,launchdarkly.com",
  "DOMAIN-SUFFIX,algolia.net",
  "DOMAIN-SUFFIX,segment.io",
  "DOMAIN-SUFFIX,sentry.io",
  "DOMAIN-SUFFIX,observeit.net",
  "DOMAIN-SUFFIX,identrust.com",
  "DOMAIN-SUFFIX,sendgrid.net",
  "DOMAIN,rum.browser-intake-datadoghq.com",
  "DOMAIN,browser-intake-datadoghq.com",
  "DOMAIN,static.cloudflareinsights.com",
  "DOMAIN-SUFFIX,challenges.cloudflare.com",
  "DOMAIN,cdn.usefathom.com",
  "DOMAIN,js.stripe.com",
  "DOMAIN,humb.apple.com",
  "IP-CIDR,24.199.123.28/32,no-resolve",
  "IP-CIDR,64.23.132.171/32,no-resolve",

  // Other major AI services from the BosLife / Nexitally AI groups.
  "DOMAIN-KEYWORD,gemini",
  "DOMAIN-KEYWORD,generativeai",
  "DOMAIN-KEYWORD,perplexity",
  "DOMAIN-KEYWORD,colab",
  "DOMAIN-KEYWORD,developerprofiles",
  "DOMAIN-SUFFIX,perplexity.ai",
  "DOMAIN-SUFFIX,pplx.ai",
  "DOMAIN-SUFFIX,bard.google.com",
  "DOMAIN-SUFFIX,deepmind.com",
  "DOMAIN-SUFFIX,deepmind.google",
  "DOMAIN-SUFFIX,generativeai.google",
  "DOMAIN-SUFFIX,proactivebackend-pa.googleapis.com",
  "DOMAIN-SUFFIX,aisandbox-pa.googleapis.com",
  "DOMAIN-SUFFIX,robinfrontend-pa.googleapis.com",
  "DOMAIN-SUFFIX,aistudio.google.com",
  "DOMAIN-SUFFIX,generativelanguage.googleapis.com",
  "DOMAIN-SUFFIX,apis.google.com",
  "DOMAIN-SUFFIX,x.ai",
  "DOMAIN-SUFFIX,grok.com",
  "DOMAIN-SUFFIX,chorus.sh",
  "DOMAIN,ai.google.dev",
  "DOMAIN,alkalimakersuite-pa.clients6.google.com",
  "DOMAIN,alkalicore-pa.clients6.google.com",
  "DOMAIN,waa-pa.clients6.google.com",
  "DOMAIN,makersuite.google.com",
  "DOMAIN,copilot.microsoft.com",
];

const AI_DNS_NAMESERVERS = [
  `https://1.1.1.1/dns-query#${AI_EGRESS.groupName}`,
  `https://8.8.8.8/dns-query#${AI_EGRESS.groupName}`,
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

  const selectGroup = groups.find(group =>
    group.type === "select" && group.name !== AI_EGRESS.groupName
  );
  return selectGroup && selectGroup.name;
}

function removeByName(items, name) {
  return (items || []).filter(item => item.name !== name);
}

function applyAiEgress(config) {
  const nodeNames = AI_EGRESS_PROXIES.map(proxy => proxy.name);
  const nodeNameSet = new Set(nodeNames);
  config.proxies = [
    ...AI_EGRESS_PROXIES,
    ...(config.proxies || []).filter(proxy => !nodeNameSet.has(proxy.name)),
  ];

  config["proxy-groups"] = removeByName(
    config["proxy-groups"],
    AI_EGRESS.groupName
  );
  config["proxy-groups"].unshift({
    name: AI_EGRESS.groupName,
    type: "select",
    proxies: nodeNames.length ? nodeNames : ["REJECT-DROP"],
  });
}

function appendPolicy(rule, policy) {
  const noResolve = ",no-resolve";
  if (rule.endsWith(noResolve)) {
    return `${rule.slice(0, -noResolve.length)},${policy}${noResolve}`;
  }
  return `${rule},${policy}`;
}

function aiDnsPolicy() {
  const policy = {};

  for (const rule of AI_RULES) {
    const [type, value] = rule.split(",", 2);
    if (type === "DOMAIN") {
      policy[value] = AI_DNS_NAMESERVERS;
    } else if (type === "DOMAIN-SUFFIX") {
      policy[`+.${value}`] = AI_DNS_NAMESERVERS;
    }
  }

  return policy;
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
    // Default all non-CN DNS to the fixed AI egress. This is intentionally
    // broad: a second DNS egress is a larger risk than over-routing DNS.
    nameserver: AI_DNS_NAMESERVERS,
    fallback: [],
    "nameserver-policy": {
      ...aiDnsPolicy(),
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

    ...AI_RULES.map(rule => appendPolicy(rule, AI_EGRESS.groupName)),

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
  // global Script. Treat the injected group + nodes as an idempotency marker.
  const existingGroup = (config["proxy-groups"] || []).some(
    group => group.name === AI_EGRESS.groupName
  );
  const existingNodes = new Set(
    (config.proxies || []).map(proxy => proxy.name)
  );
  if (
    existingGroup &&
    AI_EGRESS_PROXIES.every(proxy => existingNodes.has(proxy.name))
  ) {
    return config;
  }

  applyDns(config);
  applyTun(config);
  applySniffer(config);
  applyAiEgress(config);
  const airport = findAirportGroup(config);
  applyRules(config, airport);
  return config;
}
