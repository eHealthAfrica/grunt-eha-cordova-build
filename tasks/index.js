/* global require, process, __dirname, module */
'use strict';

var exec = require('child_process').exec;
var util = require('util');
var fs = require('fs');
var path = require('path');
var walk = function(dir, done) {
  var results = [];
  fs.readdir(dir, function(err, list) {
    if (err) return done(err);
    var pending = list.length;
    if (!pending) return done(null, results);
    list.forEach(function(file) {
      file = path.resolve(dir, file);
      fs.stat(file, function(err, stat) {
        if (stat && stat.isDirectory()) {
          walk(file, function(err, res) {
            results = results.concat(res);
            if (!--pending) done(null, results);
          });
        } else {
          results.push(file);
          if (!--pending) done(null, results);
        }
      });
    });
  });
};

function checkFile(fileName) {
  try {
    fs.statSync(process.cwd() + '/' + fileName);
    return true;
  } catch(e) {
    return false;
  }
}

module.exports = function(grunt) {
  grunt.registerTask('ehaCordovaBuild', function(type, country, rebuild) {
    var done = this.async();
    var data = this.options();
    var version = grunt.file.readJSON('package.json').version;

    var interpolators = util._extend({
      type: type,
      country: country
    }, data);

    grunt.template.addDelimiters('handlebars', '{%', '%}');
    var pkg = grunt.template.process(data.package, { data: interpolators, delimiters: 'handlebars' });
    var buildCmd = grunt.template.process(data.buildCmd, { data: interpolators, delimiters: 'handlebars' });

    var cmd = path.resolve(process.cwd(), __dirname + '/../scripts/build.sh');
    var env = util._extend({
      APPDIR:   data.appdir,
      PACKAGE:  pkg,
      APPNAME:  data.appname,
      COMMAND:  buildCmd,
      VERSION:  version
    }, process.env);

    var child = exec(cmd + " " + type + " " + country + " " + rebuild, {
      cwd: process.cwd(),
      env: env
    }, function(err, stdout, stderr) {
      if(err) {
        console.log('got err', err, stdout, stderr);
        return grunt.fatal(err);
      }

      done();
    });

    child.stdout.on('data', function(message) {
      grunt.log.write(message.toString());
    });
  });


  grunt.registerTask('ehaCordovaTemplate', function() {
    // This task looks for the necessary files
    // and copies them to the project folder
    var done = this.async();
    var templatePath = path.resolve(__dirname, '../templates') + '/';

    walk(__dirname + '/../templates', function(err, fileList) {
      if(err) {
        return grunt.fatal(err);
      }

      fileList.forEach(function(path) {
        path = path.replace(templatePath, '');
        if(checkFile(path)) {
          grunt.verbose.writeln(path + ' already exists, not copying');
          return;
        }

        grunt.log.writeln(path + ' not found, copying');
        grunt.file.copy(__dirname + '/../templates/' + path, process.cwd() + '/' + path);
      });

      done();
    });
  });


  // Copies config.xml to cordova build dir, sets package name after country
  grunt.registerTask('ehaCordovaConfig', function(country, version, buildDir, pkg, appName) {
    var file = grunt.file.read('config.template.xml');
    var processed = grunt.template.process(file, { data: {
      country: country, version: version,
      packageName: pkg, appName: appName
    }});
    grunt.file.write(buildDir + '/config.xml', processed);
  });

  var childProcess = require('child_process');
  grunt.registerTask('ehaCordovaPlugins', function(buildDir) {
    // Loops over cordova plugins from project_root/plugins.json and installs them
    var done = this.async();
    var plugins = grunt.file.readJSON('package.json').cordovaPlugins || {};
    if(Object.keys(plugins).length === 0) {
      grunt.log.writeln('No Plugins Found, add them in cordovaPlugins in package.json');
    }

    var packages = Object.keys(plugins).map(function(key) {
      if(/github\.com/.test(plugins[key])) {
        return plugins[key];
      }

      return key + "@" + plugins[key];
    });

    (function next(err) {
      if(err) {
        grunt.fail.warn(err);
      }

      var pack = packages.shift();
      if(!pack) {
        return done();
      }

      grunt.log.writeln('Adding cordova plugin: ' + pack);
      childProcess.exec(__dirname + '/../node_modules/.bin/cordova plugin add ' + pack, { cwd: buildDir }, next);
    })();
  });

};
