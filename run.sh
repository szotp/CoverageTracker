# usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/szotp/CoverageTracker/master/run.sh)"

curl -L https://github.com/szotp/CoverageTracker/releases/download/latest/CoverageTracker > CoverageTracker
chmod +x CoverageTracker
COVERAGE=$(./CoverageTracker)

# git -C CoverageTracker pull || git clone git@github.com:szotp/CoverageTracker.git
# cd CoverageTracker
# swift build -c release
# cd ..
# COVERAGE=$(./CoverageTracker/.build/release/CoverageTracker)
envman add --key "COVERAGE" --value "$COVERAGE"
