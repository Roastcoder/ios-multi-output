# iOS Compatibility Matrix

**No physical iPhone has been tested yet.** "Expected" comes from Apple's headers and documentation. It isn't a test result. Only a confirmed device run may fill in the "Tested" column.

## Tested environments

| Environment | iOS | Test | Result |
|---|---|---|---|
| iPhone 17 Simulator | 26.5 | System Route tone | Played; level meter moved; finished in 3 seconds |
| iPhone 17 Simulator | 26.5 | Multi-Route tone | Played; level meter moved. The Simulator reports no port channels, so the channel map wasn't applied |

The Simulator has one output, so it can't test simultaneous playback.

## Route combinations

| Combination | Mode | Expected | Tested on iPhone |
|---|---|---|---|
| Built-in speaker alone | System Route | Works | Not tested |
| Wired USB-C audio alone | System Route | Works | Not tested |
| Bluetooth headphones alone | System Route | Works | Not tested |
| AirPlay alone | System Route | Works | Not tested |
| USB + wired headphones | Multi-Route | Documented as supported | Not tested |
| USB + HDMI | Multi-Route | Eligible | Not tested |
| Two USB audio devices | Multi-Route | Not documented; depends on hub and hardware | Not tested |
| Built-in speaker + wired output | Multi-Route | Restricted by iOS | Not tested |
| Bluetooth A2DP + wired output | Multi-Route | Restricted by iOS | Not tested |
| AirPlay + local output | Multi-Route | Not on eligible list | Not tested |
| Built-in speaker + wired headset | Dual Route (26.2+) | Documented as supported | Not tested |
| Built-in speaker + Bluetooth HFP or LE | Dual Route (26.2+) | Documented as supported | Not tested |
| Built-in speaker + output-only headphones | Dual Route (26.2+) | Restricted: the secondary route needs input and output | Not tested |

## Behavior tests

| Scenario | Designed behavior | Tested on iPhone |
|---|---|---|
| Device disconnected during playback | Playback stops and the change is logged | Not tested |
| Incoming call or interruption | Playback stops and the interruption is logged | Not tested |
| Background and foreground | Keeps playing, using the `audio` background mode | Not tested |
| Sample-rate change | Engine configuration change is handled, playback stops | Not tested |
| Long-duration playback | Clock drift against host clock is shown | Not tested |

## Device results

| iPhone model | iOS | Combination | Result |
|---|---|---|---|
| None yet | | | |

To add a row, follow [physical-device testing](05-physical-device-testing.md).
