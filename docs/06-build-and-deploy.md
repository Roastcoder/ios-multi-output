# Build and Deployment

## Requirements

- Xcode 26 or later
- iOS 17 or later on the device
- Dual Route needs iOS 26.2 or later

## Run in the Simulator

Open `MultiOutput.xcodeproj`, choose an iPhone Simulator and press **Run**.

From the command line:

```bash
xcodebuild build -project MultiOutput.xcodeproj -scheme MultiOutput -destination 'generic/platform=iOS Simulator'
```

## Run the tests

```bash
xcodebuild test -project MultiOutput.xcodeproj -scheme MultiOutput -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Run on an iPhone

1. Connect and unlock the iPhone, and turn on Developer Mode in **Settings > Privacy & Security**.
2. In Xcode, select the **MultiOutput** target and open **Signing & Capabilities**.
3. Choose your team and change the bundle identifier from `com.example.MultiOutput` to one of your own.
4. Select your iPhone and press **Run**.

## Project settings

| Setting | Value |
|---|---|
| Background mode | `audio`, in `Config/Info.plist` |
| Microphone usage text | Used only for latency measurement |
| Swift | Language mode 6, main actor by default |
| Dependencies | None |

## Installing from an IPA

iPhones only install signed apps, so an unsigned IPA can't be installed by tapping a link on a website.

| Route | Who can install | Needs |
|---|---|---|
| Sideloadly or AltStore with the unsigned IPA | Each person signs it themselves | A free Apple ID works, but the app expires after 7 days |
| Ad Hoc link from your site | Up to 100 registered iPhones per device type | Paid Apple Developer account, each device's UDID, an HTTPS site and an `itms-services` manifest |
| TestFlight public link | Up to 10,000 testers | Paid account and Apple's beta review |
| App Store | Everyone | Paid account and App Review |
| Web Distribution from your site | iPhone users in the EU only | Paid account, Apple's eligibility requirements and notarization |

Enterprise certificates aren't an option, because Apple only allows them for a company's internal apps.

Build an unsigned IPA:

```bash
xcodebuild build -project MultiOutput.xcodeproj -scheme MultiOutput -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
mkdir -p Payload && cp -R build/Build/Products/Release-iphoneos/MultiOutput.app Payload/ && zip -qry MultiOutput-unsigned.ipa Payload
```

## App Store notes

The app uses public APIs only. Before submitting, add an app icon, a privacy policy and your own bundle identifier, and complete physical-device testing. App Review may ask why background audio is needed.
