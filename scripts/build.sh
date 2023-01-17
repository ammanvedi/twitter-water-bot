rm -r dist

spago bundle-module --main Main --to dist/index.js --platform node --source-maps

cp lambda.package.json dist/package.json
cp bot.config.json dist/bot.config.json