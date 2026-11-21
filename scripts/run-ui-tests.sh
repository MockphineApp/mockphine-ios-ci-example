#!/bin/sh
# Starts the mock server, runs the UI tests on an iOS simulator, saves the
# mock's Request Log, stops the server, and exits with the tests' status.
#
# Environment:
#   MOCKPHINE     path to the mockphine CLI (default: the CLI inside Mockphine.app)
#   DEVICE_ID     simulator to use (default: an iPhone on the newest iOS runtime)
#   RECORD_VIDEO  set to 1 to record the simulator to build/ui-tests.mp4
set -u

MOCKPHINE="${MOCKPHINE:-/Applications/Mockphine.app/Contents/Helpers/mockphine}"
WORKSPACE="mocks/Shop.mockphine"
SERVER_ID="ec372f8c-2148-4b98-8623-3e6d4b09101a"
BASE_URL="http://127.0.0.1:47861"
export DO_NOT_TRACK=1

mkdir -p build

DEVICE_ID="${DEVICE_ID:-$(xcrun simctl list devices available --json | python3 scripts/pick-simulator.py)}"
if [ -z "$DEVICE_ID" ]; then
  echo "No iPhone simulator is available."
  exit 1
fi

"$MOCKPHINE" server start --workspace "$WORKSPACE" --server-id "$SERVER_ID" > build/mock.log 2>&1 &
tries=0
until "$MOCKPHINE" server status --workspace "$WORKSPACE" --server-id "$SERVER_ID" | grep -q '^running'; do
  tries=$((tries + 1))
  if [ "$tries" -gt 50 ]; then
    echo "The mock server did not start:"
    cat build/mock.log
    exit 1
  fi
  sleep 0.2
done
echo "Mock server is running at $BASE_URL"

RECORDER=""
if [ "${RECORD_VIDEO:-0}" = "1" ]; then
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null
  xcrun simctl bootstatus "$DEVICE_ID" -b > /dev/null
  xcrun simctl io "$DEVICE_ID" recordVideo --codec h264 --force build/ui-tests.mp4 &
  RECORDER=$!
fi

echo "Running UI tests on simulator $DEVICE_ID"
TEST_RUNNER_MOCK_BASE_URL="$BASE_URL" xcodebuild test \
  -project ShopSample.xcodeproj -scheme ShopSample \
  -destination "id=$DEVICE_ID" \
  -parallel-testing-enabled NO \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/UITests.xcresult > build/xcodebuild.log 2>&1
STATUS=$?
grep -E "Test Case .* (passed|failed)|Executed [0-9]+ tests|\*\* TEST" build/xcodebuild.log | sort -u
if [ "$STATUS" -ne 0 ]; then
  echo "xcodebuild failed with status $STATUS. Last lines of build/xcodebuild.log:"
  tail -40 build/xcodebuild.log
fi

if [ -n "$RECORDER" ]; then
  kill -INT "$RECORDER" 2>/dev/null
  wait "$RECORDER" 2>/dev/null
fi

"$MOCKPHINE" logs list --workspace "$WORKSPACE" --server-id "$SERVER_ID" > build/mock-requests.txt
"$MOCKPHINE" server stop --workspace "$WORKSPACE" --server-id "$SERVER_ID"
echo "Requests the mock answered:"
cat build/mock-requests.txt
exit "$STATUS"
