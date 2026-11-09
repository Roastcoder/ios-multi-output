# macOS Versus iOS

| Mac Multi-Output feature | On iOS | This app |
|---|---|---|
| Create a persistent system-wide virtual device | Not available | Not possible. Routing exists only inside this app |
| Other apps play through it | Not available | Not possible. Only this app's audio is routed |
| Choose any set of outputs | Limited to eligible port types | Multi-Route and Dual Route, following Apple's rules |
| See every connected output | Only outputs in the current route | Shows the current route and available inputs |
| Primary device (clock source) | Not exposed | Not offered |
| Drift correction per device | Not exposed | Not offered. Reports engine clock against host clock only |
| Set the sample rate per device | One session-wide preferred rate; iOS decides the result | Requested in Settings, with the granted value shown |
| Channel layout per device | Port channels are readable | Shown when reported, and used to build the channel map |
| Master volume | System volume only through `MPVolumeView` | System slider plus an app-level volume |
| Per-device hardware volume | Not exposed | Not claimed |
| Mute a device | No hardware control | The output's channels are silenced in the channel map |
| Bluetooth in a multi-output group | A2DP is excluded from multi-route. Hands-free and LE are allowed in Dual Route | Follows those rules |
| AirPlay in a group | Not eligible | Single route through Apple's picker |
| Process audio taps | Not in the iOS SDK | Not possible |
| Virtual AVB | No equivalent found | Not offered |

## Several Bluetooth headphones

A Mac Multi-Output Device can include several Bluetooth headphones. iOS gives apps no equivalent: A2DP is excluded from multi-route, and Dual Route allows only one secondary device alongside the built-in speaker. Apple's own Share Audio feature can send sound to a second pair of supported AirPods or Beats, but it's a system feature that apps can't control.

## Best supported alternatives

- **Playing to two wired outputs:** use Multi-Route with a USB-C interface or hub that exposes more than one eligible output.
- **Speaker plus a headset:** use Dual Route on iOS 26.2 or later.
- **Bluetooth or AirPlay:** use System Route and choose the destination in Apple's picker.
- **Several AirPlay speakers at once:** iOS can group AirPlay 2 speakers in its own system picker. That's a system feature, and this app doesn't control it.
