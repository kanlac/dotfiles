const prependRule = [
  "DOMAIN-SUFFIX,reddit.com,BosLife",
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
