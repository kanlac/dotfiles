const prependRule = [
  // ===== 本地地址直连（避免代理拦截本地服务）=====
  "IP-CIDR,127.0.0.0/8,DIRECT",        // 所有 127.x.x.x 地址
  "IP-CIDR6,::1/128,DIRECT",           // IPv6 localhost
  "DOMAIN,localhost,DIRECT",           // localhost 域名
  "DOMAIN-SUFFIX,local,DIRECT",        // *.local 域名
  // ===== 其他规则 =====
  "DOMAIN-KEYWORD,reddit,BosLife",
  "DOMAIN-KEYWORD,chaoci,BosLife",
  "PROCESS-NAME,git-remote-http,BosLife",
  // claude
  "PROCESS-PATH-REGEX,/Users/kan/.local/share/claude/*,BosLife",
  "DOMAIN-KEYWORD,claude,BosLife",
  // 应该不需要
  // "PROCESS-NAME,claude,BosLife",
  // wechat
  "PROCESS-NAME,WeChat,DIRECT",
  // 或更稳
  // "PROCESS-PATH,/Applications/WeChat.app/Contents/MacOS/WeChat,DIRECT",
];

function main(config) {
  config.rules = prependRule.concat(config.rules || []);
  return config;
}
