# Physical-Device Testing

The Simulator has one output and no real accessories, so only an iPhone can confirm simultaneous playback.

## Setup

1. Install the app using [build and deployment](06-build-and-deploy.md).
2. Keep the volume low when you start, and raise it gradually.
3. Connect the outputs you want to test. On iPhone, a USB-C hub or interface is usually needed to connect more than one wired output.

## Record a route result

1. Open **Studio** and choose the routing mode.
2. Check that **Destinations** lists the outputs you connected. If one is missing, iOS hasn't included it in the route. Record that as restricted.
3. Open **Diagnostics > Audio Test Lab**.
4. Tap **Play Verification Tone**, then turn on **Heard on…** only for outputs you actually heard.
5. Tap **Save Result**.
6. After your tests, tap **Export as Markdown**.

## Combinations to test

- Built-in speaker, wired USB-C audio, Bluetooth headphones and AirPlay, each alone in System Route
- USB + wired headphones, and USB + HDMI, in Multi-Route
- Built-in speaker + wired output in Multi-Route (expected to be restricted)
- Bluetooth + wired output in Multi-Route (expected to be restricted)
- AirPlay + local output in Multi-Route (expected to be restricted)
- Built-in speaker + headset in Dual Route, on iOS 26.2 or later

## Behavior tests

For each one, write down what happened and check **Diagnostics** for the logged events.

| Test | How | Expect |
|---|---|---|
| Disconnection | Unplug an output during playback | Playback stops and the route history updates |
| Interruption | Receive a call during playback | Playback stops and the interruption count rises |
| Background | Lock the phone during playback | Audio continues |
| Foreground | Return to the app | Status is still correct |
| Sample rate | Change the rate in Settings and play | The rate iOS granted is shown |
| Long playback | Play a long file for 30 minutes or more | No dropouts; note the clock reading |
| Channels | Run the left and right tests on each output | Sound comes from the correct side |
| Sync | Play a sweep to two outputs close together | Note any audible echo |
| Latency | Run **Measure Latency** several times | Readings are reasonably consistent |

## Share results

Open an issue with the exported Markdown, your iPhone model, iOS version, and the exact accessories and adapters.
