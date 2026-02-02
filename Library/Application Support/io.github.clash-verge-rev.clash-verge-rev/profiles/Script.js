const prependRule = [
  "DOMAIN-SUFFIX,reddit.com,BosLife",
  "DOMAIN-KEYWORD,chaoci,BosLife",
  // claude
  "PROCESS-NAME,claude,BosLife",
  "PROCESS-NAME,2.1.29,BosLife",
  "DOMAIN-KEYWORD,claude,BosLife",
  // wechat
  "PROCESS-NAME,WeChat,DIRECT",
  // 或更稳
  // "PROCESS-PATH,/Applications/WeChat.app/Contents/MacOS/WeChat,DIRECT",
];

function main(config) {
  config.rules = prependRule.concat(config.rules || []);
  return config;
}
