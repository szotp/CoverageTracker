# usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/szotp/CoverageTracker/master/run.sh)"
# or just add lines below to bitrise

curl -L https://github.com/szotp/CoverageTracker/releases/latest/download/CoverageTracker > CoverageTracker
chmod +x CoverageTracker
COVERAGE=$(./CoverageTracker)
envman add --key "COVERAGE" --value "$COVERAGE"
