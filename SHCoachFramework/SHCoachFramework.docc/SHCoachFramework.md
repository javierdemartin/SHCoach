# ``SHCoachFramework``

`SHCoach` is a multiplatform Swift framework that helps you with the creation of a [custom catalog](https://developer.apple.com/documentation/shazamkit/shcustomcatalog).

Supported architectures for this framework are:

* Simulator (`ios-arm64`)
* Mac Catalyst (`ios-arm64_x86_64-maccatalyst`)
* iOS Devices (`ios-arm64_x86_64-simulator`)

Certain functionalities are only available for iOS devices. This is due to the nature of the hardware microphones available on those devices. ShazamKit's signal processing algorithm requires specific values of input frequencies in order for the matching algorithm to work. Other microphones or input sources may not be compatible.

Running the demo app provided with the framework on iOS devices allows the user to create a [`SHCustomCatalog`](https://developer.apple.com/documentation/shazamkit/shcustomcatalog) by importing audio files or by recording with the microphone.

Alternatively, running this same app with a target of macOS using Catalyst, Rosetta or Designed for iPad mode (available on Apple Silicon machines) will only let the user create a [custom catalog](https://developer.apple.com/documentation/shazamkit/shcustomcatalog) by importing audio files.

## Overview


`SHCoachFramework` contains the source code to create a multiplatform `XCFramework`.

The project's root folder contains a build script `build.sh` that compiles the framework for three separate architectures and then joins all of the `.framework` files into a single `.xcframework` that can be used outside of this project for distribution.


## Considerations

This framework makes use of the microphone capabilities of your iOS/iPadOS device. For it to work you need to grant access to the microphone on the `Info.plist` file under `Privacy - Microphone Usage Description`.

If your project has been created with Xcode 13 or newer the location of `Info.plist` has been moved. To add this property:

1. Select your project on the Project Navigator (`CMD + 0`).
2. Select your iOS/iPadOS target.
3. Select the *Info* tab.
4. Under *Custom iOS Target Properties* add a new row with the key *Privacy - Microphone Usage Description*.

