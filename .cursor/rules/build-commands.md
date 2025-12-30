# SwiftPM Build, Test, and Code Coverage Commands

## Build Command

```bash
swift build \
  --disable-sandbox \
  > .cursor/temp/build-log.txt 2>&1
```

## Code Coverage Summary

```bash
CODE_COV_DIR=$(find .build -type d -name "codecov" | head -1)
if [ -z "$CODE_COV_DIR" ] || [ ! -d "$CODE_COV_DIR" ] || [ -z "$(ls -A "$CODE_COV_DIR"/*.profraw 2>/dev/null)" ]; then
  echo "❌ No coverage data found. Run 'swift_test_coverage' first."
  exit 1
fi

echo "📊 Merging coverage data..."
xcrun llvm-profdata merge -sparse "$CODE_COV_DIR"/*.profraw -o "$CODE_COV_DIR/default.profdata" 2>&1

XCTEST_PATH=$(find .build -name "*PackageTests.xctest" -type d | head -1)
if [ -z "$XCTEST_PATH" ]; then
  echo "❌ Test bundle not found. Run 'swift_test_coverage' first."
  exit 1
fi

BINARY_PATH="$XCTEST_PATH/Contents/MacOS/$(basename "$XCTEST_PATH" .xctest)"
ARCH=$(uname -m)

echo "📈 Code Coverage Summary:"
echo ""
xcrun llvm-cov report "$BINARY_PATH" \
  -instr-profile="$CODE_COV_DIR/default.profdata" \
  -ignore-filename-regex='Tests/' \
  -arch="$ARCH" 2>&1 | tail -10
```

## Detailed Code Coverage Report

```bash
CODE_COV_DIR=$(find .build -type d -name "codecov" | head -1)
if [ -z "$CODE_COV_DIR" ] || [ ! -d "$CODE_COV_DIR" ] || [ -z "$(ls -A "$CODE_COV_DIR"/*.profraw 2>/dev/null)" ]; then
  echo "❌ No coverage data found. Run 'swift_test_coverage' first."
  exit 1
fi

echo "📊 Merging coverage data..."
xcrun llvm-profdata merge -sparse "$CODE_COV_DIR"/*.profraw -o "$CODE_COV_DIR/default.profdata" 2>&1 > /dev/null

XCTEST_PATH=$(find .build -name "*PackageTests.xctest" -type d | head -1)
if [ -z "$XCTEST_PATH" ]; then
  echo "❌ Test bundle not found. Run 'swift_test_coverage' first."
  exit 1
fi

BINARY_PATH="$XCTEST_PATH/Contents/MacOS/$(basename "$XCTEST_PATH" .xctest)"
ARCH=$(uname -m)

echo "📈 Generating line-by-line coverage report for all files..."
echo "Output: .cursor/temp/coverage-detailed.txt"
echo ""
xcrun llvm-cov show "$BINARY_PATH" \
  -instr-profile="$CODE_COV_DIR/default.profdata" \
  -show-line-counts-or-regions \
  -show-instantiations=false \
  -ignore-filename-regex='Tests/' \
  -arch="$ARCH" 2>&1 > .cursor/temp/coverage-detailed.txt

echo "✅ Detailed coverage report saved to .cursor/temp/coverage-detailed.txt"
echo "Use: grep -A 5 -B 5 '<filename>' .cursor/temp/coverage-detailed.txt to view specific file"
```

