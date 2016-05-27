# TimeCrowd Chrome Extension

## OAuth

https://timecrowd.net/oauth/applications/new

Redirect URI: `https://jahjoedcfifbemdippjhpcljnkcfbbbk.chromiumapp.org/provider_cb`

```
# src/coffee/keys.coffee
TimeCrowd.keys =
  baseUrl: 'https://timecrowd.net/'
  clientId: 'ID'
  clientSecret: 'SECRET'
```

## Build

```
# Install
$ npm install --global gulp
$ npm install
$ gem install scss_lint scss_lint_reporter_checkstyle

# Watch
$ gulp [watch]
```

## Install

1. chrome://extensions/
2. Load unpacked extention
3. /path/to/app

## Package
```
./pack.sh
```

## Jasmine

```
chrome-extension://jahjoedcfifbemdippjhpcljnkcfbbbk/jasmine/SpecRunner.html
```
