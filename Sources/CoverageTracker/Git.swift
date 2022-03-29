//
//  File.swift
//  
//
//  Created by pszot on 29/03/2022.
//

import Foundation

class Git {
    func currentBranchHasCommit(hash: String) -> Bool {
        do {
            _ = try ShellTask("git merge-base --is-ancestor \(hash) HEAD", printer: SilentPrinter()).wait()
            return true
        } catch {
            return false
        }
    }
    
    func getCurrentHash() throws -> String {
        return try ShellTask("git rev-parse HEAD").waitForString().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
