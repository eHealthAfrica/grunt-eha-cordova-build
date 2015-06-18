Cordova Build Module:
-----

Set Up:

1. Install this module:
`npm install --save-dev eHealthAfrica/eha-cordova-build`

2. Install cordova-android platform. This is done locally,
so each app can chose different versions shuold they want to.
`npm install --save-dev cordova-android`

3. Generate the cordova-plugins.json config.template.xml, and app/VERSION files:
`grunt ehaCordovaTemplate`
Modify config.template.xml, cordova-plugins.json and app/VERSION after your needs. **those files should be checked in in your version control**.

4. In your gruntfile, add
```
  grunt.loadNpmTasks('eha-cordova-build');

  grunt.config.init({
    ehaCordovaBuild: {
      options: {
        appdir: 'build-test',
        package: 'com.ehealthafrica.{%= country %}.buildtest',
        appname: 'Build Test',
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


### Version

The app version is read from package.json

