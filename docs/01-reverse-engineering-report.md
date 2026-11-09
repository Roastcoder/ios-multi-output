# Reverse-Engineering Research Report

**Target:** Audio MIDI Setup 3.8 on macOS 26.6.2. **SDK references:** Xcode 26.5, iOS 26.5 and macOS SDK headers.

## Method and limits

The app was inspected statically with `otool`, `nm`, `strings`, `codesign` and `plutil`, then compared with Apple's public headers and documentation.

- **REA:** it was registered for Claude Code, but its tools weren't available in the session that did this work, and no disassembly engine was configured. No REA Evidence or decompilation backs this report.
- **What that means:** symbols and strings show what the app contains. They don't prove control flow, call order or runtime behavior.
- **Scope:** no Apple code was copied into this project. CoreMIDI's library code and the MIDI driver plugins weren't analyzed.

Each finding is labeled **Observed** (directly seen), **Documented** (stated by Apple) or **Inferred** (a conclusion from the others).

## How the Mac feature appears to work

| Finding | Label |
|---|---|
| The app links Core Audio and calls `AudioObjectGetPropertyData`, `AudioObjectSetPropertyData` and the property listener functions | Observed |
| It contains `createStackedDevice:`, `createAggregateDevice`, `isStacked` and `getSubdeviceList` | Observed |
| The saved selection for a Multi-Output Device on the test Mac was named `AMS2_StackedOutput` | Observed |
| The aggregate key `kAudioAggregateDeviceIsStackedKey` describes sub-devices whose output streams are all fed the same data | Documented |
| A Multi-Output Device is a Core Audio aggregate device in its stacked form | Inferred |

## Clock source and drift correction

| Finding | Label |
|---|---|
| The app contains `clockSourceChanged:`, `getClockSources`, `getClockDomain` and `automaticDriftCorrection` | Observed |
| `kAudioAggregateDeviceMainSubDeviceKey` names the sub-device that acts as time source | Documented |
| `kAudioSubDevicePropertyDriftCompensation` and its quality levels control drift compensation per sub-device | Documented |
| The Primary Device menu sets the main sub-device, and the Drift Correction checkbox sets drift compensation | Inferred |

## Other Audio MIDI Setup internals

- **Latency UI:** a `LatencyGraph` class exists. Its behavior wasn't examined. (Observed)
- **Audio taps:** the app imports `AudioHardwareCreateProcessTap` and `CATapDescription`. (Observed)
- **Virtual AVB:** the app imports `AVBVirtualAudioConfiguration` and related classes. (Observed)
- **Entitlements:** microphone pre-approval, setting the output device, and access to protected `AudioSettings` storage. (Observed)

## iOS findings

| Topic | Finding | Source |
|---|---|---|
| HAL API | The iOS SDK's CoreAudio headers contain only `CoreAudioTypes.h`. `AudioObject` calls are exported in the SDK's linker stubs but have no public header, so this app doesn't use them | iOS 26.5 SDK |
| Enumeration | `AVAudioSession` exposes `currentRoute` and `availableInputs`. There is no list of idle outputs | SDK |
| Multi-route eligibility | USB, line out, headphones, HDMI and built-in speaker; the speaker only when no other eligible output is connected | `AVAudioSessionTypes.h` |
| Bluetooth A2DP | The A2DP option is false and can't be set in `multiRoute` | `AVAudioSessionTypes.h` |
| Dual Route | New in iOS 26.2. Built-in speaker primary, with a secondary headset, headphones, Bluetooth LE or HFP. Needs `allowBluetoothHFP` | `AVAudioSessionTypes.h` |
| Channel routing | iOS flattens all ports into one global channel array. An output channel map binds source channels to positions | [Apple documentation](https://developer.apple.com/documentation/avfaudio/routing-audio-to-specific-devices-in-multidevice-sessions) |
| AirPlay | Selected by the user through `AVRoutePickerView`. Not on the multi-route eligible list | SDK |
| Volume | `outputVolume` is read-only. `MPVolumeView` is the system control | SDK |
| Audio Workgroups | Exposed for real-time threads, but the property is marked unavailable from Swift. This app creates no real-time threads of its own, so it doesn't need it | `AudioUnitProperties.h` |
| Audio MIDI Services | Not used, because Multi-Output is an audio routing feature | Design decision |

## Synchronization

| Topic | What this app does |
|---|---|
| Buffer scheduling | One `AVAudioPlayerNode` feeds one mixer, so every destination gets the same samples from one render callback |
| Sample-rate conversion | The engine's mixer converts sources to the hardware rate |
| Playback latency | Shows `outputLatency`, `ioBufferDuration` and `presentationLatency`, which iOS reports for the session, not per port |
| Clock differences and drift | iOS exposes no per-port clocks, so drift between outputs can't be measured or corrected. The app reports only the engine clock against the system host clock |
| Buffer underruns | iOS gives no underrun callback for this engine graph, so the app doesn't claim to detect them |
| Hardware clock sync | **Not claimed.** There's no public iOS equivalent of the Mac's primary device or drift correction |

## Developer reports that need real-device checks

These come from Apple Developer Forums threads, mostly from around iOS 8, and may not hold today:

- One developer couldn't get simultaneous output from `AVAudioEngine` channel maps.
- Some HDMI adapters only worked at 44.1 kHz.
- `multiRoute` with `mixWithOthers` reportedly stops the hardware volume buttons working.

## Sources

- [Routing audio to specific devices in multidevice sessions](https://developer.apple.com/documentation/avfaudio/routing-audio-to-specific-devices-in-multidevice-sessions)
- [Audio MIDI Setup User Guide](https://support.apple.com/guide/audio-midi-setup/toc)
- [AVAudioEngine and Multiroute forum thread](https://developer.apple.com/forums/thread/15416)
- [AVAudioSession multiRoute and volume buttons forum thread](https://developer.apple.com/forums/thread/750211)
- [Bluetooth MIDI on iOS (QA1831)](https://developer.apple.com/library/ios/qa/qa1831/_index.html)
