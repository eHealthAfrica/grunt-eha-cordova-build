Cordova Build Module:
-----

Set Up:

1. Install this module:
`npm install --save-dev eHealthAfrica/eha-cordova-build`

2. Install cordova-android platform. This is done locally,
so each app can chose different versions shuold they want to.
`npm install --save-dev cordova-android`

3. Generate the config.template.xml file:
`grunt ehaCordovaTemplate`
Modify config.template.xml after your needs. **this file should be checked in in your version control**.

4. In your gruntfile, add
```
  grunt.loadNpmTasks('eha-cordova-build');

  grunt.config.init({
    ehaCordovaBuild: {
      options: {
        appdir: 'build-test',
        package: 'com.ehealthafrica.{%= country %}.buildtest',
        appname: 'Build Test',
        // Adapt this to what your apps build system is
        buildCmd: 'grunt build:{%=type%}:{%=country%}:{%=rebuild%}'
      }
    }
  });
```
Note that you need to use different delimiters, to get past the grunt initial expansion.

5. Add a `cordovaPlugins` key in package.json, example
```
  "cordovaPlugins": {
    "cordova-plugin-crosswalk-webview": "^1.2.0",
    "cordova-plugin-dialogs": "^1.1.0",
    "cordova-plugin-google-analytics": "^0.7.1",
    "cordova-plugin-network-information": "^1.0.0",
    "cordova-plugin-vibration": "^1.1.0",
    "cordova-plugin-whitelist": "^1.0.0",
    "device-information": "https://github.com/vliesaputra/DeviceInformationPlugin",
    "phonegap-sms": "https://github.com/aharris88/phonegap-sms-plugin.git",
    "local-notifications": "https://github.com/sapk/cordova-plugin-local-notifications.git"
  },
```

6. build with `grunt ehaCordovaBuild:snapshot:country`

### Cordova Plugins

Cordova plugins are installed via a 'cordovaPlugins' key in package.json. See example above.

### App Version

The app version is read from package.json

### Travis Build

This module does not provide you with a travis build script. However, here's an example:


```bash
set -e

info() { echo "$0: $1"; }
error() { info "$1"; exit 1; }
build() { info "Performing $1 build"; }
skip() { info "${1}. Skipping build."; exit 0; }

[[ "$TRAVIS_PULL_REQUEST" == "false" ]] || {
  skip "This build was triggered by a pull request"
}

if [[ "$TRAVIS_TAG" ]]; then
  BUILD_STAGE="release"
elif [[ "$TRAVIS_BRANCH" == "develop" ]]; then
  BUILD_STAGE="snapshot"
else
  skip "Unsupported branch $TRAVIS_BRANCH and/or untagged commit"
fi

# Only build sl right now
grunt ehaCordovaBuild:$BUILD_STAGE:sl

# throw away app directory, we just want the APKs
rm -Rf build/biometrics
```

Note that the deletion of the bottom needs to be the same as the 'appdir' grunt option for ehaCordovaBuild

