# SHCoach

Demo project app + multi-platform XCFramework to help the creation of custom ShazamKit catalogs from audio files or recordings.

[Demo video of the app & framework in use](https://youtu.be/0_F7Bn3Ta2o)

----------------------------

Xcode project contains three targets:

* `SHCoach (iOS)`, demo iOS app for users trying to generate a custom ShazamKit catalog. Can be used on any iOS device (iOS 15) and from macOS Catalyst.
* `Tests iOS`, target containing tests for the developed framework
* `SHCoachFramework`, contains the framework code which will be wrapped onto a multi platform XCFramework using a build script

## Framework Creation

Repository comes with a `build.sh` scripts that automates the creation of the `.xcframework`.

In order for the target to be distributed as a framework there are a couple of settings that have been changed in the project.

* Enable **Build Library for Distribution** under **Build Settings** for the `SHCoachFramework`. This can also be done in the console when calling `xcodebuild` as `BUILD_LIBRARIES_FOR_DISTRIBUTION=YES`. Generates a binary interface so the framework is compatible with different compiler and/or Xcode versions.
* Disable **Skip Install** under **Build Settings** for the `SHCoachFramework`. This can also be done in the console when calling `xcodebuild` as `SKIP_INSTALL=NO`. Causes the framework to be copied into the archive which will be used to create the `.xcframework`. 

When the `build.sh` script finishes the resulting framework will be stored on `$HOME`. Then you can use it on any project you want by importing it to the Xcode project as you would do with any other framework.

---------------------------------

As of **Xcode 13 there is a new way to build cross platform frameworks from a single target from inside Xcode**. It's described more in depth in [Session 10210 @ WWDC'21 Explore advanced project configuration in Xcode](https://developer.apple.com/videos/play/wwdc2021/10210/). Steps to follow are,

1. Select your multi-platform target from the project pane on the left. Go to *Build Settings* and enable *Allow multi-platform builds* under the *Build Options* section.
2. On that same tab but under *Architectures* section select *Any Platform* for the *Supported Platforms* settings.
3. Change to the *Build Phases* tab and under *Compile Sources* for each file that will go into the framework select the platforms you want to enable/disable from the *Filters* column. If you haven't touched anything previously here it should be marked as *Always Used*.

## Documentation

Project contains documentad code alongside a [DocC](https://developer.apple.com/documentation/docc) documentation project which can be exported when using Xcode 13 or newer.


## Demo App

SwiftUI app that puts to use the created framework. Tab-based application that let's you create a `SHCustomCatalog` with audio files that you provide via the document explorer or that you record using your microphone. You can create a `SHCustomCatalog` with both audio files and microphone recordings.

When you're done adding audio samples you can export your `SHCustomCatalog` file so it's used on another app you're working on or it can be tested on this same app.

There's a second, on this demo app that let's you test any `SHCustomCatalog` by loading it from the document explorer and playing a sound from another device. If a match has been found it will display its name and if it's not it will display an error.


## Testing

A new protocool, `AVAudioEngineMockable` is defined that's adopted by `AVAudioEngine`. Any class that makes use of ` AVAudioEngine` will substitute that reference for the protocol so a fake `AVAudioEngine` can be injected and used and mock certain functionality like microphone usage that requires real hardware.

Enabled code coverage only for `SHCoachFramework` target.

There are certain aspects that can't be tested like emulating real microphone input to check matches.

Alternatively, to test a `SHCustomCatalog` and making use of `AVAudioEngineMockable` a model can be tested passing as inputs the `SHSignature` of an audio file. In the `Resources` folder of the project there are three audio samples used to test this aspect of the framework: A full length song, a small piece of that same song to simulate a match and an incorrect song to simulate an incorrect match.

## Troubleshooting

### Building the XCFramework

If some of the following errors happen

```
/SHCoachFramework/SHCatalogCreator.swift:9:8: error: no such module 'ShazamKit'
import ShazamKit
```

or


```
xcodebuild: error: SDK "macosx12.0" cannot be located.
```

Framework has been created using Xcode's 13 beta 5 toolchain. Compiling this framework or project without selecting the latest Xcode beta from `xcode-select` can result in an error. That can be fixed by selecting latest version with the following command,

```
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
```

After creating a `xcframework` always build against a real target of the destination platforms as some compilation errors don't appear until buildtime or runtime.

If the situation needed it a XCFramework can be distributed through a Swift Package that contains the binary framework inside allowing us to keep the source code private.

## Interesting References

* [Session 10147 WWDC 2020 - Distribute binary frameworks as Swift Packages](https://developer.apple.com/wwdc20/10147)
* [Session 416 WWDC 2019 - Binary Frameworks in Swift](https://developer.apple.com/wwdc19/416) 
* [Distribute Binary Frameworks, Xcode Help](https://help.apple.com/xcode/mac/11.4/#/dev6f6ac218b)
* [Xcode Build setting flags](https://help.apple.com/xcode/mac/11.4/#/itcaec37c2a6?sub=devfeb7a0695)
* [ShazamKit Documentation](https://developer.apple.com/documentation/shazamkit)
* [Session 501 WWDC 2012 - What's New in AVAudioEngine](https://developer.apple.com/wwdc19/510)
* [Building a Signal Generator](https://developer.apple.com/documentation/avfaudio/audio_engine/building_a_signal_generator)
