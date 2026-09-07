#!/usr/bin/env bash
# Push the Stillwater site from a fresh session VM (gh login does not persist between sessions).
# Step 1:  bash push_site.sh code    -> prints a one-time code; Kenneth enters it at https://github.com/login/device
# Step 2:  bash push_site.sh push    -> exchanges the code for a token, clones, copies index.html, commits, pushes
# Uses the public gh CLI OAuth client id (device flow). Token lives only in $HOME/tok.json for the session.
set -e
CID=178c6fc778ccc68e1d6a
SRC="$HOME/mnt/Life-OS/stillwater/website"
case "$1" in
  code)
    curl -s -X POST -H "Accept: application/json" -d "client_id=$CID&scope=repo" https://github.com/login/device/code > $HOME/devcode.json
    python3 -c "import json;d=json.load(open('$HOME/devcode.json'));print('CODE:',d['user_code'],'  at',d['verification_uri'],'  (expires in',d['expires_in'],'s)')" ;;
  push)
    DC=$(python3 -c "import json;print(json.load(open('$HOME/devcode.json'))['device_code'])")
    curl -s -X POST -H "Accept: application/json" -d "client_id=$CID&device_code=$DC&grant_type=urn:ietf:params:oauth:grant-type:device_code" https://github.com/login/oauth/access_token > $HOME/tok.json
    TOK=$(python3 -c "import json;print(json.load(open('$HOME/tok.json')).get('access_token',''))")
    [ -n "$TOK" ] || { echo "not authorized yet:"; cat $HOME/tok.json; exit 1; }
    rm -rf $HOME/site-push && git clone -q https://github.com/KenBone23/stillwater-site.git $HOME/site-push
    cp "$SRC/index.html" $HOME/site-push/index.html
    for f in 404.html favicon.svg apple-touch-icon.png og.png robots.txt sitemap.xml CNAME kenneth.jpg; do [ -f "$SRC/$f" ] && cp "$SRC/$f" $HOME/site-push/$f; done
    cd $HOME/site-push && git add -A && git -c user.name=KenBone23 -c user.email=kenneth@stillwater-partners.com commit -qm "${2:-Site update from Life-OS}" || { echo "nothing to commit"; exit 0; }
    git push -q https://x-access-token:$TOK@github.com/KenBone23/stillwater-site.git HEAD:main && echo "PUSHED $(git rev-parse --short HEAD)" ;;
  *) echo "usage: push_site.sh code | push [commit message]";;
esac
