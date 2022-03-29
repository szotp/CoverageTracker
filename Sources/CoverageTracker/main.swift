import Foundation

class Environment: DebugOverriding {
    lazy var appSlug = getEnvironmentVariable("BITRISE_APP_SLUG")
    lazy var token = getEnvironmentVariable("BITRISE_ACCESS_TOKEN")
    lazy var targetBranch = getEnvironmentVariable("BITRISEIO_GIT_BRANCH_DEST")
    lazy var resultPath = getEnvironmentVariable("BITRISE_XCRESULT_PATH")
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
    let previousResultURL = try await downloadPreviousArtifact(title:resultName)
    
    let current = XCResult(path: environment.resultPath)
    let previous = XCResult(path: previousResultURL.path)
    
    let coverage = try current.getTargetCoverage()
    let difference = try TargetCoverage.difference(before: previous.getTargetCoverage(), after: coverage)
    
    let percentFormatter = NumberFormatter()
    percentFormatter.numberStyle = .percent
    percentFormatter.minimumFractionDigits = 1
    
    let changeFormatter = NumberFormatter()
    changeFormatter.positivePrefix = "+"
    changeFormatter.minimumFractionDigits = 1
    
    guard !difference.isEmpty else {
        print("Coverage: no change")
        return
    }
    
    print("Coverage: no change")
    for change in difference {
        let coverage = coverage.first { coverage in
            coverage.name == change.name
        }!
        
        let percentage = percentFormatter.string(from: .init(value: coverage.lineCoverage))!
        let change = changeFormatter.string(from: .init(value: change.lineCoverage * 100))!
        
        print("\(coverage.name) \(percentage) (\(change))")
    }
}
