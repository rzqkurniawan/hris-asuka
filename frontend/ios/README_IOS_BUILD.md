# iOS Build & Run Guide

## Problem
Flutter `flutter run` command may fail with codesigning error:
```
resource fork, Finder information, or similar detritus not allowed
```

## Solution: Build via Xcode CLI

### 1. List Available Simulators
```bash
xcrun simctl list devices available | grep -i "iphone\|ipad"
```

### 2. Build for Simulator

**iPhone Simulator:**
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios

xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=<SIMULATOR_ID>" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=YES \
  build
```

**Example Simulator IDs:**
- iPhone 15 Pro Max: `9D842514-DD0A-41C2-A106-5C78C769904A`
- iPad Pro 13-inch (M4): `91B2B516-ABC1-4DFB-954F-F7C216A87565`

### 3. Install & Launch App
```bash
# Install
xcrun simctl install "<SIMULATOR_ID>" ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app

# Launch
xcrun simctl launch "<SIMULATOR_ID>" com.asuka.hris

# Open Simulator app
open -a Simulator
```

---

## Build for Real Device

### 1. Build
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios

xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -destination "id=<DEVICE_ID>" \
  -configuration Debug \
  build
```

**Device ID Rizqik's iPhone:** `00008120-00160D8A02F3C01E`

### 2. Install & Launch
```bash
# Install
xcrun devicectl device install app --device "<DEVICE_ID>" ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos/Runner.app

# Launch
xcrun devicectl device process launch --device "<DEVICE_ID>" com.asuka.hris
```

---

## Quick Commands (Copy-Paste Ready)

### iPhone 15 Pro Max Simulator
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios && \
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphonesimulator -destination "platform=iOS Simulator,id=9D842514-DD0A-41C2-A106-5C78C769904A" -configuration Debug CODE_SIGNING_ALLOWED=YES build && \
xcrun simctl install "9D842514-DD0A-41C2-A106-5C78C769904A" ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app && \
xcrun simctl launch "9D842514-DD0A-41C2-A106-5C78C769904A" com.asuka.hris && \
open -a Simulator
```

### iPad Pro 13-inch Simulator
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios && \
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphonesimulator -destination "platform=iOS Simulator,id=91B2B516-ABC1-4DFB-954F-F7C216A87565" -configuration Debug CODE_SIGNING_ALLOWED=YES build && \
xcrun simctl install "91B2B516-ABC1-4DFB-954F-F7C216A87565" ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app && \
xcrun simctl launch "91B2B516-ABC1-4DFB-954F-F7C216A87565" com.asuka.hris && \
open -a Simulator
```

### Real Device (Rizqik's iPhone)
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios && \
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphoneos -destination "id=00008120-00160D8A02F3C01E" -configuration Debug build && \
xcrun devicectl device install app --device "00008120-00160D8A02F3C01E" ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos/Runner.app && \
xcrun devicectl device process launch --device "00008120-00160D8A02F3C01E" com.asuka.hris
```

---

## App Store / TestFlight Build

1. Open Xcode:
   ```bash
   open /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios/Runner.xcworkspace
   ```

2. Select **Any iOS Device (arm64)** as target

3. Update version in **Runner > General**:
   - Version: `1.0.x`
   - Build: `x`

4. **Product > Archive**

5. **Window > Organizer** > Select archive > **Distribute App**

---

## Troubleshooting

### Clean Build
```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
flutter pub get
cd ios && pod install
```

### "Pods_Runner framework not found" Error (Simulator)
Jika build simulator gagal dengan error `ld: framework 'Pods_Runner' not found`, build Pods-Runner scheme terlebih dahulu:

```bash
cd /Users/rzqkurniawan/Documents/hris-asuka/frontend/ios

# Step 1: Build Pods-Runner first
xcodebuild -workspace Runner.xcworkspace \
  -scheme "Pods-Runner" \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=9D842514-DD0A-41C2-A106-5C78C769904A" \
  -configuration Debug \
  build

# Step 2: Then build Runner
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=9D842514-DD0A-41C2-A106-5C78C769904A" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=YES \
  build
```

### Check Device/Simulator Status
```bash
# List devices
flutter devices

# List simulators
xcrun simctl list devices available
```
