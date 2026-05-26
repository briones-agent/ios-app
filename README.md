# wallabag iOS + React Native

This is an experimental fork of the official [wallabag iOS](https://github.com/wallabag/ios-app) with the sole purpose of testing brownfield support for Expo and React Native in large native-first codebases. Its commits serve as a reference for anyone interested in integrating React Native into an existing iOS app, especially those that don't want to refactor the whole project structure to accommodate React Native.

This project uses Expo's brownfield isolated approach (Expo SDK 56 canary — `expo-brownfield@56.0.16-canary-20260526-6cd5e37`) with **bidirectional shared state**: wallabag publishes a mock reading-list snapshot (unread count, total count, sync status, last-synced timestamp, article list) into the `expo-brownfield` shared-state KV store, and the embedded React Native "Reading List Inspector" screen renders it reactively via `useSharedState`. Two RN buttons ("Mark next as read", "Sync now") send messages back through `expo-brownfield`'s messaging channel; native updates the shared state and RN sees the new values without re-rendering.

This card also validates the `expo-image`/`SDWebImage` SPM-deps fix from the canary release — the embedded RN screen renders real images via `expo-image` inside a brownfield framework.

## Integration steps

Check commits for detailed steps, full instructions can be found in the [expo-brownfield documentation](https://docs.expo.dev/brownfield/overview/).

1. **Create the Expo app**: `npx create-expo-app expo-app --template default@canary-sdk-56`.
2. **Install expo-brownfield**: `cd expo-app && npm install --legacy-peer-deps expo-brownfield@56.0.16-canary-20260526-6cd5e37 expo-build-properties`. Configure the plugin in `app.json`, then `npx expo-brownfield build:ios --release --package WallabagExpoArtifacts --verbose`.
3. **Add React Native view**: Add the local Swift Package to `wallabag.xcodeproj`, bump `IPHONEOS_DEPLOYMENT_TARGET` to 17.0, link the single aggregate product `WallabagExpoArtifacts-release` to the wallabag target. See `integrate_expo.rb` for the idempotent xcodeproj automation.
4. **Wire shared state**: Native side calls `BrownfieldState.set(key, value)` + `BrownfieldMessaging.addListener`. RN side uses `useSharedState` + `sendMessage`. See `App/ExpoIntegration.swift` and `expo-app/src/app/index.tsx`.

## Build prereqs

- Xcode 16+ with the iOS 17 simulator runtime.
- Wallabag expects a `Config.xcconfig` at the repo root (gitignored upstream — populate with your signing config or leave empty for simulator-only builds).

<details>
<summary>wallabag 2 official iOS</summary>

> [!CAUTION]
> This repository is no longer accepting contributions.
> The original maintainer has shifted focus to a closed-source version (version 7.6 onwards), and the wallabag core team will not be overseeing further development of this open-source repository at that time.
> 
> Please refer to the related [App Store](https://apps.apple.com/us/app/wallabag-2-official/id1170800946) page for any comment or inquiry regarding the current iOS application.

# wallabag 2 official iOS [![Build Status](https://travis-ci.org/wallabag/ios-app.svg?branch=master)](https://travis-ci.org/wallabag/ios-app)

<img align="left" src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/78/23/c3/7823c39e-9da9-8f0b-7a13-299a2de43725/AppIcon-0-0-1x_U007epad-0-85-220.jpeg/540x540bb.jpg" alt="Wallabag 2 official" style="width: 20%; object-fit: contain;" />

wallabag is a self-hosted read-it-later app.  
Unlike other services, wallabag is free and open source.  
wallabag 2 official iOS is a companion app for [wallabag](https://www.wallabag.org).  

<a href="https://apps.apple.com/us/app/wallabag-2-official/id1170800946?itscg=30200&itsct=apps_box_badge&mttnsubad=1170800946" style="display: inline-block;">
	<img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1479340800" alt="Download on the App Store" style="width: 246px; height: 82px; vertical-align: middle; object-fit: contain;" />
</a>

[Join TestFlight Beta](https://testflight.apple.com/join/73Pvd1wL)

## About wallabag

wallabag has been made for you to comfortably read and archive your articles.
You can download wallabag from wallabag.org and follow the instructions to install it on your own server.
Alternatively, you can directly sign up for [wallabag.it](https://wallabag.it) or [Framabag](https://framabag.org).

This application allows you to put a link in your wallabag instance, letting you read your wallabag links offline.

wallabag is a creation from Nicolas Lœuillet released under the MIT License (Expat License).

## About wallabag 2 official iOS

This is a self-learning project.

I'm really happy to discover Swift and the apple ecosystem.

You will find mistakes, many mistakes, do not blame me, learn me with a PR.

You contribute to an excellent opensource project, and you will make me evolve in the Swift language


## Screenshots
[<img src="/fastlane/framed/iPhone6Plus-01Home-d41d8cd98f00b204e9800998ecf8427e_framed.png" align="left" width="200" hspace="10" vspace="10">](/fastlane/framed/iPhone6Plus-01Home-d41d8cd98f00b204e9800998ecf8427e_framed.png)
[<img src="/fastlane/framed/iPhone6Plus-02Article-d41d8cd98f00b204e9800998ecf8427e_framed.png" align="center" width="200" hspace="10" vspace="10">](/fastlane/framed/iPhone6Plus-02Article-d41d8cd98f00b204e9800998ecf8427e_framed.png)

## Contributing
wallabag app is a free and open source project developed by volunteers. Any contributions are welcome. Here are a few ways you can help:
 * [Report bugs and make suggestions.](https://github.com/wallabag/ios-app/issues)
 * Write some code. Please follow the code style used in the project to make a review process faster.

## License

This application is released under MIT (see [LICENSE](LICENSE)).
Some of the used libraries are released under different licenses.

</details>
