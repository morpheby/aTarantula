
## Building from source ##

### Requirements ###

* [Xcode 9.0 or higher](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) (requires Swift 4.0 and Swift 3.2 modes available)
* [Cocoa Pods](https://cocoapods.org/#install)

### Preparing build environment ###

#### Cocoa Pods ####

To build you will require to install CocoaPods dependencies first:

	pods install

#### libxml2 fix ####

One of the requirements — Kanna — uses libxml2 module, which, unfortunately, is broken in macOS SDK bundled
with Xcode (as of versions 6.0–9.0).

To run the fix, you need to run the script:

	cd Pods/Kanna/Utils
	./correct_libxml2.sh

*Note: You may need to run `xcode-select --switch /Applications/Xcode.app` before running this
script, if you have never done so before.* 

*Note: You can verify if it is properly managed by creating a simple Swift project or playground, importing `xml2`
and then trying to use any of the module functions. If it works, then this step is no longer required.*

### Building ###

Open `aTarantula.xcworkspace` in Xcode and build target `aTarantula`.

-----

### Contents ###

0. [Intro](/README.md)
1. **This document**
2. [Using the application](/docs/using.md)
3. [Extending (creating plugins)](/docs/extending.md)
