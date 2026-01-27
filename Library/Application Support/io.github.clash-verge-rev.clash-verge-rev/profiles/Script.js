const prependRule = [
  "DOMAIN-SUFFIX,reddit.com,BosLife",
  "DOMAIN-KEYWORD,chaoci,BosLife",
  "PROCESS-NAME,WeChat,DIRECT",
  // 或更稳
  // "PROCESS-PATH,/Applications/WeChat.app/Contents/MacOS/WeChat,DIRECT",
];

function main(config) {
  config.rules = prependRule.concat(config.rules || []);
  return config;
}
