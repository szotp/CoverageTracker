//
//  File.swift
//  
//
//  Created by pszot on 27/03/2022.
//

import Foundation
import CryptoKit

extension String {
    func matches(for regex: String) -> [Substring] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.flatMap { (match) -> [Substring] in
                return (0..<match.numberOfRanges).map { index in
                    let range = match.range(at: index)
                    return self[Range(range, in: self)!]
                }
            }
        } catch let error {
            Swift.print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func splitByLineTrimming() -> [String] {
        let lines = self.split(separator: "\n")
        return lines.map { x in
            return x.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func trimmedToLength(_ length: Int) -> String {
        if length > count {
            return self
        }
        
        return self[startIndex ..< self.index(startIndex, offsetBy: length)].string
    }
    
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }
    
    func toFileURL(base: String) -> URL {
        return base.fileURL.appendingPathComponent(self)
    }
}

extension Data {
    var string: String {
        return String(data: self, encoding: .utf8) ?? description
    }
}

extension Substring {
    var string: String {
        return "\(self)"
    }
}

func isDebuggerAttached() -> Bool {
    return getppid() != 1
}

let files = FileManager.default

/**
 Adjust current directory to ios-base
 */
func setCurrentDirectoryForDebugging() {
    var current = URL(fileURLWithPath: "\(#file)")
    
    
    while current.lastPathComponent != "Scripts" {
        current = current.deletingLastPathComponent()
    }
    current = current.deletingLastPathComponent()
    files.changeCurrentDirectoryPath(current.path)
}

/**
 Returns something like `swiftlang-1300.0.31.1 clang-1300.0.29.1`
 */
func getCachePrefix() throws -> String {
    // parse something like this
    // Apple Swift version 5.5 (swiftlang-1300.0.31.1 clang-1300.0.29.1)
    // Target: x86_64-apple-macosx12.0
    let output = try ShellTask("xcrun swift --version 2> /dev/null").waitForString()
    return output.matches(for: "\\((.*)\\)").last!.replacingOccurrences(of: " ", with: "-")
}

func getCartfileHash() -> String {
    let data = try! Data(contentsOf: URL(fileURLWithPath: "Cartfile"))
    let hash = SHA256.hash(data: data)
    let string = Data(hash).hexEncodedString().trimmedToLength(8)
    return "cartfile-\(string)"
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

protocol DebugOverriding {
    func debugOverride()
}

extension DebugOverriding {
    func debugOverride() {}
}

func runAsync(_ block: @escaping() async throws -> Void) {
    Task {
        do {
            try await block()
        } catch {
            print(error)
        }

        exit(0)
    }
    RunLoop.main.run()
}

func getEnvironmentVariable(_ key: String) -> String {
    if let value = ProcessInfo.processInfo.environment[key] {
        if value == "" {
            fatalError("\(key) is empty")
        }
        
        return value
    }
    
    fatalError("Failed to read variable: \(key)")
}
