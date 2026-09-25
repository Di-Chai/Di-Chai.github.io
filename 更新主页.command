#!/bin/sh
# Finder: double-click to rebuild from YAML and open the generated homepage.
cd "$(dirname "$0")" || exit 1
if ruby scripts/build.rb; then
  open index.html
else
  printf '\n请修正上面的内容格式错误，然后重试。按回车退出。\n'
  read -r answer
  exit 1
fi
