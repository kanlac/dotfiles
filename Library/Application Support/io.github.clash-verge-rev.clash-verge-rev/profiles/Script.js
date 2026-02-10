const prependRule = [
  // ===== 本地地址直连（避免代理拦截本地服务）=====
  "IP-CIDR,127.0.0.0/8,DIRECT",        // 所有 127.x.x.x 地址
  "IP-CIDR6,::1/128,DIRECT",           // IPv6 localhost
  "DOMAIN,localhost,DIRECT",           // localhost 域名
  "DOMAIN-SUFFIX,local,DIRECT",        // *.local 域名

  // ===== 特定应用规则 =====
  "PROCESS-NAME,WeChat,DIRECT",        // 微信直连
  "PROCESS-NAME,git-remote-http,BosLife",
  "PROCESS-PATH-REGEX,/Users/kan/.local/share/claude/*,BosLife",

  // ===== 特定域名规则 =====
  "DOMAIN-KEYWORD,reddit,BosLife",
  "DOMAIN-KEYWORD,claude,BosLife",

  // ===== IP 地理位置规则 =====
  "GEOIP,PRIVATE,DIRECT",              // 私有 IP（局域网）直连
  "GEOIP,CN,DIRECT",                   // 中国 IP 直连

  // ===== 主要国外国家/地区走代理 =====
  "GEOIP,US,BosLife",                  // 美国
  "GEOIP,JP,BosLife",                  // 日本
  "GEOIP,SG,BosLife",                  // 新加坡
  "GEOIP,GB,BosLife",                  // 英国
  "GEOIP,DE,BosLife",                  // 德国
  "GEOIP,FR,BosLife",                  // 法国
  "GEOIP,CA,BosLife",                  // 加拿大
  "GEOIP,AU,BosLife",                  // 澳大利亚
  "GEOIP,KR,BosLife",                  // 韩国
  "GEOIP,TW,BosLife",                  // 台湾
  "GEOIP,HK,BosLife",                  // 香港

  // 厂商自带规则中 MATCH,DIRECT 兜底
];

function main(config) {
  config.rules = prependRule.concat(config.rules || []);
  return config;
}
