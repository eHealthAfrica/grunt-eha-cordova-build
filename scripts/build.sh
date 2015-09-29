#!/usr/bin/env bash
set -e

pwd="${PWD##}"
app="$APPDIR"
package="$PACKAGE"
appname="$APPNAME"
gruntcmd="$COMMAND"
version="$VERSION"

scriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

keys="$pwd/.android"
build="$pwd/build"
apks="$build/$app/platforms/android/build/outputs/apk"

have() { command -v "$1" >/dev/null; }
info() { echo "$0: $1"; }
error() { info "$1"; exit 1; }
usage() { echo "usage: $0 snapshot|staging|release country (optional rebuild)"; }

if [[ -f "$scriptdir/../node_modules/.bin/cordova" ]]; then
  cordova="$scriptdir/../node_modules/.bin/cordova"
elif [[ -f "$pwd/node_modules/.bin/cordova" ]]; then
  cordova="$pwd/node_modules/.bin/cordova"
else
  error "Cannot find cordova binary in node_modules. Did you run npm install?"
fi

[[ "$1" ]] || { usage; exit 1; }
[[ "$1" == "--help" || "$1" == "-h" ]] && { usage; exit; }
[[ "$1" != "snapshot" && "$1" != "staging" && "$1" != "release" ]] && { usage; exit 1; }
type="$1"

[[ "$2" ]] || { usage; exit 1; }
country="$2"

# Passing a third argument "rebuild" example
# ./scripts/build.sh snapshot lr rebuild
# skips creating a new cordova project and re-downloading plugins
# Just recompiles the assets and builds the project
skipcreate=false
if [[ "$3" == "rebuild" ]]; then
  [[ -d "$build/$app" ]] || error "Can't rebuild because build directory does not exist. Please run a full build ($0 $type $country)"
  skipcreate=true
  echo "Skipping creating project, etc"
fi

info "Building $app $version $type build for Android (Country: $country)"
info "Package ID: $package"
have "android" || error "Android SDK required"

if [[ "$type" != "snapshot" ]]; then
  if ! [[ -f "$keys/android-release-keys.properties" && -f "$keys/ehealth.keystore" ]]; then
    error "Add android-release keys to $keys and try again"
  fi
fi

if [[ $skipcreate == false ]]; then
  [[ -d "$build/$app" ]] && rm -rf "$build/$app"
  mkdir -p "$build"
fi

# grunt build:"$type":"$country"
# Do grunt build, or whatever you need
$gruntcmd

if [[ $skipcreate == false ]]; then
  cd "$build"
  "$cordova" create "$app" "$package" "$appname" --link-to="$pwd/dist"

  grunt ehaCordovaConfig:"$country:$version:$build/$app:$package:$appname:$type"

  cd "$app"
  # Save country ref for checking rebuilds:
  echo "$country" > .country

  # Add the platform we figured matches the crosswalk version
  # Platform commit is specified in package.json
  "$cordova" platform add "$pwd/node_modules/cordova-android/"

  # plugins (including crosswalk)
  grunt ehaCordovaPlugins:"$build/$app"
else
  cd "$build/$app"
  countrytest=$(<.country)
  if [[ $countrytest != $country ]]; then
    error "You can't rebuild for a different country, please run a full build ($0 $type $country)"
  fi
fi


if [[ "$type" != "snapshot" ]]; then
  cp "$keys/android-release-keys.properties" "$build/$app/platforms/android/release-signing.properties"
  cp "$keys/ehealth.keystore" "$build/$app/platforms/android/ehealth.keystore"
fi
cd "$build/$app"

# build 2 files (x86, arm)
export BUILD_MULTIPLE_APKS=true

buildcmd="$cordova build android"
[[ $type == "snapshot" ]] && buildcmd+=" --debug" || buildcmd+=" --release"
$buildcmd

[[ "$type" == "snapshot" ]] && releasetype="debug" || releasetype="release"

if [[ "$country" == "undefined" ]]; then
    country=""
else
    country="$country-"
fi

# cause i suck at bash / karl
latest="latest"

for i in armv7 x86; do
  if [[ -e "$apks/android-$i-$releasetype.apk" ]]; then
    mv "$apks/android-$i-$releasetype.apk" "$build/$app-$i-$type-$country$version.apk"
    cp "$build/$app-$i-$type-$country$version.apk" "$build/$app-$i-$type-$country$latest.apk"
  fi
done

if [[ -e "$apks/android-$releasetype.apk" ]]; then
  mv "$apks/android-$releasetype.apk" "$build/$app-$type-$country$version.apk"
  cp "$build/$app-$type-$country$version.apk" "$build/$app-$type-$country$latest.apk"
fi

info "apks are in $build"
