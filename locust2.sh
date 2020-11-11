curl https://raw.githubusercontent.com/marthacryan/BugzBGone/master/finder.js -o finder.js
curl https://raw.githubusercontent.com/marthacryan/BugzBGone/master/package.json -o package.json

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 15
npm i
node finder.js
