#!/bin/zsh
# Render a 375-wide HTML page to a 3x PNG with alpha, in headless Chrome.
#   render.sh page.html out.png [height=812]
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
H=${3:-812}
"$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=3 \
  --default-background-color=00000000 --window-size=375,$H \
  --allow-file-access-from-files --screenshot="$2" "file://$(cd $(dirname $1) && pwd)/$(basename $1)" >/dev/null 2>&1
