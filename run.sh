# usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/szotp/CoverageTracker/master/run.sh)"

git -C CoverageTracker pull || git clone git@github.com:szotp/CoverageTracker.git
cd CoverageTracker
swift build -c release
cd ..
COVERAGE=$(./CoverageTracker/.build/release/CoverageTracker)
envman add --key "COVERAGE" --value "$COVERAGE"
