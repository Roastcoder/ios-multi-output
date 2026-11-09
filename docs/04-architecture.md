# Technical Architecture

Swift 6, SwiftUI and MVVM, with main-actor isolation by default and no third-party dependencies or backend.

```text
Views → ViewModels → AudioStack → Services → AVFoundation
```

| Layer | Files | Responsibility |
|---|---|---|
| App | `AudioStack`, `MultiOutputApp` | Creates the services and connects their events |
| Models | `AudioDevice`, `AudioRoute`, `AudioConfiguration`, `PlaybackState` | Plain values, eligibility rules and records |
| Services | `AudioSessionManager` | Category, mode, preferences and system notifications |
| | `AudioDeviceManager` | Reads the current route and available inputs |
| | `AudioRoutingManager` | Selected outputs and channel map construction |
| | `AudioEngineManager` | `AVAudioEngine` graph, transport and level tap |
| | `AudioMonitoringService` | Levels, event log and clock measurement |
| | `TestSignalGenerator`, `LatencyProbe`, `CompatibilityLog` | Test signals, latency and device results |
| ViewModels | Dashboard, DeviceManager, Playback, Settings | Screen state and user actions |
| Views | Dashboard, AudioDevices, Playback, Diagnostics, Settings | SwiftUI screens |
| Utilities | `AudioFormatHelper`, `AudioErrorHandler`, `PermissionsManager` | Formatting, error text and microphone access |

## Audio path

```text
AVAudioPlayerNode → main mixer → output node → channel map → eligible ports
```

The engine produces stereo. For Multi-Route and Dual Route, `AudioRoutingManager` builds Apple's flattened map:

```text
Ports:     USB (2)    Headphones (2)
Positions: 0  1       2  3
Both on:   0  1       0  1
USB muted: -1 -1      0  1
```

The map is applied with `kAudioOutputUnitProperty_ChannelMap` on the output unit. Stereo repeats across a port's channels, and a mono port receives the left channel only.

If iOS doesn't report channels for every port, no map is applied, because a guessed map could silence every output.

## Route and failure handling

| Event | Response |
|---|---|
| Output ports change while playing | Stop, because channel positions may have moved |
| Interruption begins | Stop and log |
| Engine configuration change | Stop and log |
| Media services reset | Stop and reapply the session |
| iOS rejects the channel map | Show the error and restore the previous selection |

Playback restarts from the beginning after any of these. Resuming at the same position isn't implemented.

## Threading

AVFoundation calls taps and completion handlers off the main thread. Those closures are built in `nonisolated` functions and hop back to the main actor with a `Task`. Without that, Swift 6's isolation checks would crash at runtime.

## Tests

`MultiOutputTests` uses Swift Testing to cover channel maps, eligibility rules, signal generation, onset detection, drift calculation, RMS, outcome rules, status text, persistence and log export. Real audio hardware behavior can't be unit tested.
