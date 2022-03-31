# example: ./Scripts/release.sh 0.2
set -e

if [ $(git tag -l "$1") ]; then
    gh release delete 0.1
    git tag -d $1
    git push --delete origin $1
fi

swift build -c release
gh release create $1 .build/release/CoverageTracker --generate-notes -n "" -t ""