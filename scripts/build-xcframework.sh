#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
package="$root/native/MicrosoftSwiftUIShim"
build="$root/.build/native"
mkdir -p "$build"
build="$(cd "$build" && pwd -P)"
if [[ "$build" != "$root/.build/native" ]]; then
    echo "Native build directory must be inside this repository: $build" >&2
    exit 1
fi
output="$build/MicrosoftSwiftUIShim.xcframework"
run="$(mktemp -d "$build/build.XXXXXX")"
echo "Scratch: $run"
cleanup() {
    if [[ $? -eq 0 ]]; then
        rm -rf -- "$run"
    fi
}
trap cleanup EXIT

source_hashes() {
    (
        cd "$package"
        { printf '%s\0' Package.swift; find Sources -type f -name '*.swift' -print0; } |
            sort -z | xargs -0 shasum -a 256
    )
}
source_hashes > "$run/source.sha256"

archive() {
    local name="$1"
    local destination="$2"
    local architectures="$3"
    echo "Archiving $name ($architectures)"
    (
        cd "$package"
        xcodebuild archive \
            -scheme MicrosoftSwiftUIShim \
            -destination "$destination" \
            -archivePath "$run/$name.xcarchive" \
            -derivedDataPath "$run/DerivedData" \
            "ARCHS=$architectures" \
            ONLY_ACTIVE_ARCH=NO \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            CODE_SIGNING_ALLOWED=NO \
            -quiet
    )
}

framework() {
    local product
    product="$(find "$run/$1.xcarchive/Products" -maxdepth 6 \
        -type d -name MicrosoftSwiftUIShim.framework -print -quit)"
    if [[ -z "$product" ]]; then
        echo "Missing MicrosoftSwiftUIShim.framework in $1 archive" >&2
        return 1
    fi
    printf '%s\n' "$product"
}

archive ios-device "generic/platform=iOS" "arm64"
archive ios-simulator "generic/platform=iOS Simulator" "arm64 x86_64"
archive macos "generic/platform=macOS" "arm64 x86_64"

xcodebuild -create-xcframework \
    -framework "$(framework ios-device)" \
    -framework "$(framework ios-simulator)" \
    -framework "$(framework macos)" \
    -output "$run/MicrosoftSwiftUIShim.xcframework"

python3 - "$run/MicrosoftSwiftUIShim.xcframework/Info.plist" <<'PY'
import plistlib
import sys
from pathlib import Path

path = Path(sys.argv[1])
info = plistlib.loads(path.read_bytes())
info["AvailableLibraries"].sort(key=lambda library: library["LibraryIdentifier"])
path.write_bytes(plistlib.dumps(info, sort_keys=True))
PY

python3 "$root/scripts/verify-xcframework.py" "$run/MicrosoftSwiftUIShim.xcframework"
python3 "$root/scripts/inventory-xcframework.py" \
    "$run/MicrosoftSwiftUIShim.xcframework" > "$run/xcframework.inventory.json"
if ! source_hashes | cmp -s "$run/source.sha256" -; then
    echo "Native sources changed during the XCFramework build; scratch preserved: $run" >&2
    exit 1
fi

if [[ -e "$output" ]]; then
    previous_id="$(date -u +%Y%m%dT%H%M%SZ).$$"
    previous="$build/MicrosoftSwiftUIShim.previous.$previous_id.xcframework"
    mv "$output" "$previous"
    if [[ -f "$build/MicrosoftSwiftUIShim.provenance.txt" ]]; then
        mv "$build/MicrosoftSwiftUIShim.provenance.txt" \
            "$build/MicrosoftSwiftUIShim.previous.$previous_id.provenance.txt"
    fi
    echo "Previous artifact preserved at $previous"
fi
mv "$run/MicrosoftSwiftUIShim.xcframework" "$output"

{
    printf 'Generated (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'Source reference: maui-labs 0bce1594b4d113160274e6e9c4dd27d27405519c\n'
    xcodebuild -version
    swift --version
    printf '\nSource SHA-256:\n'
    cat "$run/source.sha256"
    printf '\nXCFramework SHA-256:\n'
    (
        cd "$output"
        shasum -a 256 Info.plist
        find . -type f -name MicrosoftSwiftUIShim -print0 |
            sort -z | xargs -0 shasum -a 256
    )
    printf '\nXCFramework inventory (JSON):\n'
    cat "$run/xcframework.inventory.json"
} > "$build/MicrosoftSwiftUIShim.provenance.txt"

if ! source_hashes | cmp -s "$run/source.sha256" -; then
    echo "Native sources changed during provenance recording; scratch preserved: $run" >&2
    exit 1
fi
echo "XCFramework: $output"
echo "Provenance: $build/MicrosoftSwiftUIShim.provenance.txt"
