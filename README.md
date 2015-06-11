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

4. build with `grunt ehaCordovaBuild:snapshot:country`

