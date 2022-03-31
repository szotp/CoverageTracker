//
//  File.swift
//  
//
//  Created by pszot on 29/03/2022.
//

import Foundation

struct TargetCoverage: Codable {
    let name: String
    let executableLines: Int
    let coveredLines: Int
    
    var lineCoverage: Double {
        return executableLines > 0 ? Double(coveredLines) / Double(executableLines) : 0
    }
    
    static func difference(before: [TargetCoverage], after: [TargetCoverage]) -> [TargetCoverageDiff] {
        let paired = pair(before, after, key: { $0.name })
        return paired.map { (name, before, after) in
            return TargetCoverageDiff(before: before, after: after)
        }
    }
}

struct TargetCoverageDiff {
    let before: TargetCoverage
    let after: TargetCoverage
    
    var change: Double {
        return after.lineCoverage - before.lineCoverage
    }
    
    var hasChanged: Bool {
        return change != 0
    }
}


private func pair<T>(_ lhs: [T], _ rhs: [T], key: (T) -> String) -> [(String, T, T)] {
    var dictionary: [String: T] = [:]
    
    for value in lhs {
        dictionary[key(value)] = value
    }
    
    let result = rhs.compactMap { (rightValue: T) -> (String, T, T)? in
        if let leftValue = dictionary[key(rightValue)] {
            return (key(rightValue), leftValue, rightValue)
        } else {
            return nil
        }
    }
    
    return result.sorted { lhs, rhs in
        return lhs.0 < rhs.0
    }
}

struct  XCResult {
    let path: String
    
    func getTargetCoverage() throws -> [TargetCoverage] {
        let json = try ShellTask("xcrun xccov view --report --only-targets --json \(path)").wait()
        return try JSONDecoder().decode([TargetCoverage].self, from: json)
    }
    /*
    func exportScreenshots() -> [URL] {
        let output = URL(fileURLWithPath: path).deletingLastPathComponent()
        
        return attachments.compactMap { attachment in
            guard attachment.uniformTypeIdentifier == "public.png", let name = attachment.filename else {
                return nil
            }
            
            let result = XCResultToolCommand.Export(withXCResult: self, attachment: attachment, outputPath: output.path).run()
            assert(result?.exitStatus == .terminated(code: 0))
            return output.appendingPathComponent(name).absoluteURL
        }
    }
    
    var attachments: [ActionTestAttachment] {
        var xcresult = self
        var result: [ActionTestAttachment] = []

        guard let invocationRecord = xcresult.invocationRecord else {
            return []
        }

        let actions = invocationRecord.actions.filter { $0.actionResult.testsRef != nil }
        for action in actions {
            guard let testRef = action.actionResult.testsRef else {
                continue
            }

            // Let's figure out the attachments to export
            guard let testPlanRunSummaries: ActionTestPlanRunSummaries = testRef.modelFromReference(withXCResult: xcresult) else {
                xcresult.console.writeMessage("Error: Unhandled test reference type \(String(describing: testRef.targetType?.getType()))", to: .error)
                continue
            }

            for testPlanRun in testPlanRunSummaries.summaries {
                let testableSummaries = testPlanRun.testableSummaries
                for testableSummary in testableSummaries {
                    let testableSummariesToTestActivity = testableSummary.flattenedTestSummaryMap(withXCResult: xcresult)
                    for (_, childActivitySummaries) in testableSummariesToTestActivity {
                        let filteredChildActivities = childActivitySummaries
                        let filteredAttachments = filteredChildActivities.flatMap { $0.attachments }
                        
                        result.append(contentsOf: filteredAttachments)
                    }

                }
            }
        }
        
        return result
    }
     */
}
