#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
agent="${1:-${AILOHA_AGENT_XCFRAMEWORK:-}}"
if [[ -z "$agent" ]]; then
    echo "Pass the externally verified AilohaAgent.xcframework path." >&2
    exit 2
fi
mkdir -p "$root/.build"
fake="$(mktemp -d "$root/.build/scratch-cleanup-test.XXXXXX")"
trap 'rm -rf -- "$fake"' EXIT
for tool in xcodebuild xcrun; do
    printf '#!/usr/bin/env bash\nexit 73\n' > "$fake/$tool"
    chmod +x "$fake/$tool"
done

scratch_path() {
    sed -n 's/^Scratch: //p' <<< "$1"
}

verify_failure() {
    local script="$1" expected_dir="$2" output scratch
    shift 2
    if output="$(PATH="$fake:$PATH" bash "$root/scripts/$script" "$@" 2>&1)"; then
        echo "Expected injected $script failure." >&2
        exit 1
    fi
    scratch="$(scratch_path "$output")"
    if [[ "$scratch" != "$root/.build/$expected_dir/build."* || ! -d "$scratch" ]]; then
        echo "Failed $script did not preserve its own scratch directory: $output" >&2
        exit 1
    fi
    echo "Failed $script preserved $scratch"
    rm -rf -- "$scratch"
}

verify_success() {
    local script="$1" expected_dir="$2" output scratch
    shift 2
    if ! output="$(bash "$root/scripts/$script" "$@" 2>&1)"; then
        echo "$output" >&2
        exit 1
    fi
    scratch="$(scratch_path "$output")"
    if [[ "$scratch" != "$root/.build/$expected_dir/build."* || -e "$scratch" ]]; then
        echo "Successful $script did not clean its own scratch directory: $output" >&2
        exit 1
    fi
    echo "Successful $script cleaned $scratch"
}

verify_failure build-xcframework.sh native
verify_success build-xcframework.sh native
python3 "$root/scripts/verify-xcframework.py" "$root/.build/native/MicrosoftSwiftUIShim.xcframework"
verify_failure build-ailoha-debug.sh ailoha-debug "$agent"
verify_success build-ailoha-debug.sh ailoha-debug "$agent"
python3 "$root/scripts/verify-xcframework.py" \
    "$root/.build/ailoha-debug/AilohaDebugShim.xcframework" AilohaDebugShim
