# OrderBot

OrderBot is an iPad-based voice ordering kiosk prototype. The product concept
is an expressive ordering assistant plus an iPad menu screen: customers look at
the menu, speak what they want, confirm the order on screen, and submit by
voice.

Core design principle:

> The screen is for confirmation. Voice is for operation.

## Product Flow

The intended ordering loop is:

```text
Idle welcome
-> Customer approaches
-> Mascot assistant guides the customer
-> Customer orders by voice
-> iPad updates the order
-> Assistant asks for confirmation
-> Customer confirms by voice
-> Order is submitted
```

The first version focuses on a stable, confirmable ordering loop rather than
full natural-language coverage. It should support these five voice actions:

- Add menu items
- Modify menu items
- Delete menu items
- Finish ordering
- Confirm submission

## Main Roles

- Mascot assistant: welcomes, guides, replies, confirms, and thanks the
  customer. The app keeps both cat and corgi mascot variants.
- iPad screen: shows the menu, current order, candidate matches, final
  confirmation, and completion state.
- Customer: looks at the screen and orders by voice.
- POS / kitchen integration: receives confirmed orders in a later stage.

## Technical Direction

- App platform: SwiftUI on iPad.
- Core logic: shared Swift package code for menu, order, and intent parsing.
- Speech direction: iOS Speech framework for first-party speech recognition.
- First input target: iPad microphone recording.
- CLI support: test speech and parsing flows with `.wav` audio files.

The project should avoid complex external speech services in the first version.
The goal is to prove the end-to-end loop: record audio, transcribe speech, parse
ordering intent, update the iPad UI, and confirm submission.

## State Model

Expected kiosk states:

```text
Idle
-> Greeting
-> Listening
-> Parsing
-> OrderUpdated
-> AskMore
-> FinalConfirm
-> Completed
```

Important error and recovery states include unclear speech, no speech, cancel,
reset, and human-help fallback.

## Run on iPad Simulator

This project targets iPad only. Pick an iPad simulator by name, resolve its
local UDID, and use that UDID for install and launch so commands do not
accidentally target another booted device.

```sh
IPAD_NAME="iPad Pro 13-inch (M5)"
IPAD_UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; name=sys.argv[1]; data=json.load(sys.stdin); matches=[d["udid"] for devices in data["devices"].values() for d in devices if d.get("name")==name and d.get("isAvailable")]; print(matches[0] if matches else "")' "$IPAD_NAME")
test -n "$IPAD_UDID" || { echo "No available simulator named: $IPAD_NAME"; exit 1; }
xcrun simctl boot "$IPAD_UDID" || true
xcrun simctl bootstatus "$IPAD_UDID" -b
open -a Simulator
```

Build the iPad app:

```sh
xcodebuild -project OrderBot.xcodeproj \
  -scheme OrderBotIOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -derivedDataPath .build/xcode \
  build
```

Open Simulator, install the built app, and launch it:

```sh
open -a Simulator
xcrun simctl install "$IPAD_UDID" .build/xcode/Build/Products/Debug-iphonesimulator/OrderBot.app
xcrun simctl launch "$IPAD_UDID" com.orderbot.ipad
```

One-line build and launch:

```sh
IPAD_NAME="iPad Pro 13-inch (M5)"; IPAD_UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; name=sys.argv[1]; data=json.load(sys.stdin); matches=[d["udid"] for devices in data["devices"].values() for d in devices if d.get("name")==name and d.get("isAvailable")]; print(matches[0] if matches else "")' "$IPAD_NAME"); test -n "$IPAD_UDID" || { echo "No available simulator named: $IPAD_NAME"; exit 1; }; xcrun simctl boot "$IPAD_UDID" || true; xcrun simctl bootstatus "$IPAD_UDID" -b && xcodebuild -project OrderBot.xcodeproj -scheme OrderBotIOS -destination "platform=iOS Simulator,name=$IPAD_NAME" -derivedDataPath .build/xcode build && open -a Simulator && xcrun simctl install "$IPAD_UDID" .build/xcode/Build/Products/Debug-iphonesimulator/OrderBot.app && xcrun simctl launch "$IPAD_UDID" com.orderbot.ipad
```
