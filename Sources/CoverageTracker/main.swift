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
    
    var coveredLines = 0
    var executableLines = 0
    
    for item in difference {
        coveredLines += item.after.coveredLines
        executableLines += item.after.executableLines
    }
    
    let total = TargetCoverage(name: "total", executableLines: executableLines, coveredLines: coveredLines)
    
    print("<details><summary>Coverage (\(total.percentString))</summary>")
    print("")
    let previousBuild = "https://app.bitrise.io/build/\(previousArtifact.build.slug)"
    let previousTitle = "[previous build](\(previousBuild)) (\(previousArtifact.previousHash))"
    let currentTitle = "[current build](\(environment.buildURL)) (\(previousArtifact.currentHash))"
    
    print("| Target | \(previousTitle) | \(currentTitle) |")
    print("| --- | --- | --- |")
    
    for item in difference {
        print("| \(item.after.name) | \(item.before.percentString) | \(item.after.percentString) |")
    }
    
    print("")

    for item in difference where item.hasChanged {
        let emoji = item.change > 0 ? "⬆" : "⬇"
        let percentage = item.after.percentString
        
        print("\(emoji) \(item.after.name) \(percentage) (\(item.changeString))")
    }
}

extension TargetCoverage {
    var percentString: String {
        return environment.percentFormatter.string(from: NSNumber(value: lineCoverage)) ?? "-"
    }
}

extension TargetCoverageDiff {
    var changeString: String {
        let changeFormatter = NumberFormatter()
        changeFormatter.positivePrefix = "+"
        changeFormatter.minimumFractionDigits = 1
        
        return changeFormatter.string(from: .init(value: change)) ?? "-"
    }
}
