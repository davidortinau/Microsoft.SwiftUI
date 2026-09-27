#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
agent="${1:-${AILOHA_AGENT_XCFRAMEWORK:-}}"
if [[ -z "$agent" ]]; then
    echo "Pass the external AilohaAgent.xcframework path (v0.1.13)." >&2
    exit 1
fi
if [[ "$agent" != /* ]]; then
    echo "The external AilohaAgent.xcframework path must be absolute." >&2
    exit 1
fi
python3 "$root/scripts/verify-ailoha-input.py" "$agent"

build="$root/.build/ailoha-debug"
mkdir -p "$build"
build="$(cd "$build" && pwd -P)"
if [[ "$build" != "$root/.build/ailoha-debug" ]]; then
    echo "Ailoha build directory must be inside this repository: $build" >&2
    exit 1
fi
output="$build/AilohaDebugShim.xcframework"
run="$(mktemp -d "$build/build.XXXXXX")"
echo "Scratch: $run"
cleanup() {
    if [[ $? -eq 0 ]]; then
        rm -rf -- "$run"
    fi
}
trap cleanup EXIT
source="$root/samples/Ailoha.DebugShim/AilohaDebugShim.swift"

compile() {
    local name="$1" target="$2" sdk="$3" slice="$4" install_name="$5" rpath="$6"
    local external_rpath="${7:-}"
    local -a rpaths=(-Xlinker -rpath -Xlinker "$rpath")
    if [[ -n "$external_rpath" ]]; then
        rpaths+=(-Xlinker -rpath -Xlinker "$external_rpath")
    fi
    local framework="$run/thin-$name/AilohaDebugShim.framework"
    mkdir -p "$framework"
    echo "Compiling Ailoha Debug shim for $name"
    SDKROOT="$sdk" xcrun swiftc -emit-library -swift-version 5 -module-name AilohaDebugShim \
        -target "$target" -sdk "$sdk" \
        -module-cache-path "$run/ModuleCache" \
        -F "$agent/$slice" -framework AilohaAgent \
        -Xlinker -install_name -Xlinker "$install_name" \
        "${rpaths[@]}" \
        -o "$framework/AilohaDebugShim" "$source"
}

ios_sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
sim_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mac_sdk="$(xcrun --sdk macosx --show-sdk-path)"
ios_install="@rpath/AilohaDebugShim.framework/AilohaDebugShim"
mac_install="@rpath/AilohaDebugShim.framework/Versions/A/AilohaDebugShim"

compile ios-device-arm64 arm64-apple-ios17.0 "$ios_sdk" ios-arm64 "$ios_install" '@loader_path/..'
compile ios-simulator-arm64 arm64-apple-ios17.0-simulator "$sim_sdk" ios-arm64_x86_64-simulator "$ios_install" '@loader_path/..'
compile ios-simulator-x86_64 x86_64-apple-ios17.0-simulator "$sim_sdk" ios-arm64_x86_64-simulator "$ios_install" '@loader_path/..'
compile macos-arm64 arm64-apple-macos14.0 "$mac_sdk" macos-arm64_x86_64 "$mac_install" '@loader_path/../../..' "$agent/macos-arm64_x86_64"
compile macos-x86_64 x86_64-apple-macos14.0 "$mac_sdk" macos-arm64_x86_64 "$mac_install" '@loader_path/../../..' "$agent/macos-arm64_x86_64"

ios_framework="$run/ios-device/AilohaDebugShim.framework"
sim_framework="$run/ios-simulator/AilohaDebugShim.framework"
mac_framework="$run/macos/AilohaDebugShim.framework"
mkdir -p "$ios_framework" "$sim_framework" "$mac_framework/Versions/A/Resources"
cp "$run/thin-ios-device-arm64/AilohaDebugShim.framework/AilohaDebugShim" "$ios_framework/AilohaDebugShim"
xcrun lipo -create \
    "$run/thin-ios-simulator-arm64/AilohaDebugShim.framework/AilohaDebugShim" \
    "$run/thin-ios-simulator-x86_64/AilohaDebugShim.framework/AilohaDebugShim" \
    -output "$sim_framework/AilohaDebugShim"
xcrun lipo -create \
    "$run/thin-macos-arm64/AilohaDebugShim.framework/AilohaDebugShim" \
    "$run/thin-macos-x86_64/AilohaDebugShim.framework/AilohaDebugShim" \
    -output "$mac_framework/Versions/A/AilohaDebugShim"

cp "$root/samples/Ailoha.DebugShim/Info.plist" "$ios_framework/Info.plist"
cp "$root/samples/Ailoha.DebugShim/Info.plist" "$sim_framework/Info.plist"
cp "$root/samples/Ailoha.DebugShim/Info.plist" "$mac_framework/Versions/A/Resources/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :MinimumOSVersion string 17.0' "$ios_framework/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :MinimumOSVersion string 17.0' "$sim_framework/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 14.0' "$mac_framework/Versions/A/Resources/Info.plist"
ln -s A "$mac_framework/Versions/Current"
ln -s Versions/Current/AilohaDebugShim "$mac_framework/AilohaDebugShim"
ln -s Versions/Current/Resources "$mac_framework/Resources"

xcodebuild -create-xcframework \
    -framework "$ios_framework" \
    -framework "$sim_framework" \
    -framework "$mac_framework" \
    -output "$run/AilohaDebugShim.xcframework"
python3 "$root/scripts/verify-xcframework.py" "$run/AilohaDebugShim.xcframework" AilohaDebugShim

if [[ -e "$output" ]]; then
    previous_id="$(date -u +%Y%m%dT%H%M%SZ).$$"
    mv "$output" "$build/AilohaDebugShim.previous.$previous_id.xcframework"
    if [[ -f "$build/AilohaDebugShim.provenance.txt" ]]; then
        mv "$build/AilohaDebugShim.provenance.txt" "$build/AilohaDebugShim.previous.$previous_id.provenance.txt"
    fi
fi
mv "$run/AilohaDebugShim.xcframework" "$output"

{
    printf 'Generated (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'External official package: Redth/ailoha-releases v0.1.13\n'
    printf 'External XCFramework: %s\n' "$agent"
    printf 'Official ZIP SHA-256: 7c61cc0705afd160910c962d56afa576550b60de464a4d79722514d622ec710f\n'
    xcodebuild -version
    swift --version
    shasum -a 256 "$source" "$output/Info.plist"
    find "$output" -type f -name AilohaDebugShim -print0 | sort -z | xargs -0 shasum -a 256
} > "$build/AilohaDebugShim.provenance.txt"

echo "Debug-only bridge: $output"
echo "Provenance: $build/AilohaDebugShim.provenance.txt"
