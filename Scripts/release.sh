# example: ./Scripts/release.sh 0.2
set -e
swift build -c release
gh release create $1 .build/release/CoverageTracker --generate-notes -n "" -t ""