# Build instructions

go to popup directory
```
cd popup
```
download dependency's (first time only)
```
npm i
```
build extention
```
npm run build
```
congrats, you have build the thing.

## load debug mode
on chromium just select the projects root folder.  
on firefox, ensure to rename manifest-firefox.json to manifest.json enorder to be able to load it.
```
mv manifest.json manifest-chromium.json
mv manifest-firefox.json manifest.json
```