#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
project="$root/src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj"
verifier="$root/tests/Microsoft.SwiftUI.PackageVerifier/Microsoft.SwiftUI.PackageVerifier.csproj"
framework="$root/.build/native/MicrosoftSwiftUIShim.xcframework"
version="$(python3 - "$project" <<'PY'
import sys
import xml.etree.ElementTree as ET
print(ET.parse(sys.argv[1]).findtext("./PropertyGroup/Version"))
PY
)"
if [[ -z "$version" ]]; then
    echo "The binding project has no package version." >&2
    exit 1
fi
export SOURCE_DATE_EPOCH=1790475928

managed_sources() {
    find "$root/src/Microsoft.SwiftUI" -type f \
        \( -name '*.cs' -o -name '*.csproj' \) \
        ! -path '*/obj/*' ! -path '*/bin/*' -print0 |
        sort -z | xargs -0 shasum -a 256
}

python3 "$root/scripts/verify-xcframework.py" "$framework"
dotnet run --project "$verifier" -c Release -- --native-only "$root"
before="$(managed_sources)"
dotnet build "$project" -c Release -f net11.0-ios -t:Rebuild
dotnet build "$project" -c Release -f net11.0-macos -t:Rebuild
python3 "$root/scripts/normalize-resource-zips.py" \
    "$root/src/Microsoft.SwiftUI/bin/Release/net11.0-ios/Microsoft.SwiftUI.resources.zip" \
    "$root/src/Microsoft.SwiftUI/bin/Release/net11.0-macos/Microsoft.SwiftUI.resources.zip"
dotnet pack "$project" -c Release --no-build -o "$root/artifacts"
if [[ "$before" != "$(managed_sources)" ]]; then
    echo "Managed sources changed during the package build; refusing to verify." >&2
    exit 1
fi
dotnet run --project "$verifier" -c Release --no-build -- \
    "$root/artifacts/Microsoft.SwiftUI.$version.nupkg" "$root"
