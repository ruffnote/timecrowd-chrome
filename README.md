# TimeCrowd Chrome Extension

## OAuth

https://timecrowd.net/oauth/applications/new 

Redirect URI: `https://jahjoedcfifbemdippjhpcljnkcfbbbk.chromiumapp.org/provider_cb`

```
# src/coffee/keys.coffee 
TimeCrowd.keys = {
  clientId: 'ID'
  clientSecret: 'SECRET'
}
```

## Build

```
# Install
$ npm install --global gulp
$ npm install

# Watch
$ gulp [watch]

# CoffeeLint
$ gulp lint

# Package
./pack.sh
```

## Install

1. chrome://extensions/
2. Load unpacked extention
3. /path/to/app

## Jasmine

```
chrome-extension://jahjoedcfifbemdippjhpcljnkcfbbbk/jasmine/SpecRunner.html
```
