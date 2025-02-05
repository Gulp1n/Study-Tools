# Build instructions

## vite build

go to the popup directory
```
cd popup
```
download dependencies (if you are yet to do so)
```
npm i
```
build extention
```
npm run build
```
congrats, you build the thing.

## load debug mode
on chromium just select the projects root folder.  
on firefox, ensure to rename manifest-firefox.json to manifest.json enorder to be able to load it.
```
mv manifest.json manifest-chromium.json
mv manifest-firefox.json manifest.json
```

## release build
eaziest method is to use the github action.  
the github action in set to build the extention for both browsers on a push to main, the output can be found in the actions tab on github.