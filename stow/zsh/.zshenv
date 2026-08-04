#
# ~/.zshenv
# (ZSH environment: すべてのzsh起動で読まれる)

# .npmrcは$HOMEも~も展開しないため、prefixはここから渡してmachine非依存に保つ。
export NPM_CONFIG_PREFIX="$HOME/.local/npm-global"
