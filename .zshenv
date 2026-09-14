# Load environment variables from ~/.env if it exists
# NOTE: ~/.env is gitignored and should contain sensitive tokens/keys
if [ -f "$HOME/.env" ]; then
    source "$HOME/.env"
fi

# opencode 默认把单步输出限在 32000（推理也算），这里放开全局上限，
# 每个模型的实际上限由 ~/.config/opencode/opencode.json 里的 limit.output 决定
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=1000000

# ---- Proxy toggle via env: PROXY=on ----
if [[ "${PROXY:l}" == "on" ]]; then
  local http="http://127.0.0.1:7890"
  local socks="socks5://127.0.0.1:7890"

  export http_proxy="$http"
  export https_proxy="$http"
  export HTTP_PROXY="$http"
  export HTTPS_PROXY="$http"
  export all_proxy="$socks"
  export ALL_PROXY="$socks"
  export no_proxy="localhost,127.0.0.1,::1,.local,.ts.net,example.com,.example.com,10.0.0.0/8,100.64.0.0/10,192.168.0.0/16,172.16.0.0/12"
  export NO_PROXY="$no_proxy"
else
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
fi
