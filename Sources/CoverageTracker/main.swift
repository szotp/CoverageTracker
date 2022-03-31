import Foundation

class Environment: DebugOverriding {
    lazy var appSlug = getEnvironmentVariable("BITRISE_APP_SLUG")
    lazy var token = getEnvironmentVariable("BITRISE_ACCESS_TOKEN")
    lazy var targetBranch = getEnvironmentVariable("BITRISEIO_GIT_BRANCH_DEST")
    lazy var resultPath = getEnvironmentVariable("BITRISE_XCRESULT_PATH")
    lazy var buildURL = getEnvironmentVariable("BITRISE_BUILD_URL")
    lazy var deployURL = getEnvironmentVariable("BITRISE_DEPLOY_DIR")
    
    lazy var percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.minimumFractionDigits = 1
        return percentFormatter
    }()
    
}

let environment = Environment()
environment.debugOverride()

runAsync {
    do {
        try await printCoverage()
    } catch {
        print("Failed to calculate coverage")
        throw error
    }
}

func printCoverage() async throws {
    let resultName = URL(fileURLWithPath: environment.resultPath).lastPathComponent
    let previousArtifact = try await downloadPreviousArtifact(title:resultName)
    
    let current = XCResult(path: environment.resultPath)
    let previous = XCResult(path: previousArtifact.url.path)
    
    let previousCoverage = try previous.getTargetCoverage()
    let currentCoverage = try current.getTargetCoverage()
    let difference = TargetCoverage.difference(before: previousCoverage, after: currentCoverage)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(currentCoverage)
    try? data.write(to: URL(fileURLWithPath: environment.deployURL).appendingPathComponent("coverage.json"))
    
    let changeFormatter = NumberFormatter()
    changeFormatter.positivePrefix = "+"
    changeFormatter.minimumFractionDigits = 1
    
    if difference.isEmpty {
        print("Coverage: no change")
    } else {
        print("Coverage:")
        for change in difference {
            let coverage = currentCoverage.first { coverage in
                coverage.name == change.name
            }!
            
            let emoji = change.lineCoverage > 0 ? "⬆" : "⬇"
            let percentage = environment.percentFormatter.string(from: .init(value: coverage.lineCoverage))!
            let change = changeFormatter.string(from: .init(value: change.lineCoverage * 100))!
            
            print("\(emoji) \(coverage.name) \(percentage) (\(change))")
        }
    }
    
    print("<details>")
    print("<summary>See more</summary>")
    print("")
    
    let previousBuild = "https://app.bitrise.io/build/\(previousArtifact.build.slug)"
    dlogCoverage(title: "[previous build](\(previousBuild)) (\(previousArtifact.previousHash))", items: previousCoverage)
    print("")
    dlogCoverage(title: "[current build](\(environment.buildURL)) (\(previousArtifact.currentHash))", items: currentCoverage)
    print("</details>")

}

func dlogCoverage(title: String, items: [TargetCoverage]) {
    print("Coverage for \(title)")
    for coverage in items {
        let percentage = environment.percentFormatter.string(from: .init(value: coverage.lineCoverage)) ?? "-"
        print("- \(coverage.name) \(percentage)")
    }
}
