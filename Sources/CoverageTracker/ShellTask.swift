//
//  File.swift
//  
//
//  Created by pszot on 27/03/2022.
//

import Foundation

class ShellTask {
    struct ExecutionError: Error {
        let code: Int32
        let errorString: String
    }
    
    enum Printing {
        case dots(String)
        case full(String?)
        case none
    }
    
    private let task = Process()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private let group = DispatchGroup()
    private var data = Data()
    let printer: ShellTaskPrinter
    
    init(_ command: String, printer: ShellTaskPrinter? = nil, currentDirectory: String? = nil) {
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-c", command]
        task.currentDirectoryURL = currentDirectory?.fileURL ?? files.currentDirectoryPath.fileURL
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        let printer = printer ?? ShellTaskPrinter(label: command)
        self.printer = printer
        
        try! task.run()
        printer.didBegin(command: command)

        group.enter()
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                self.outputPipe.fileHandleForReading.readabilityHandler = nil
                self.group.leave()
                return
            }
            
            self.data.append(chunk)
            self.printer.didAppend(data: chunk)
        }
    }
    
    @discardableResult func wait() throws -> Data {
        while group.wait(timeout: .now() + 0.5) == .timedOut {
            self.printer.didWait()
        }
        
        task.waitUntilExit()
        self.printer.didFinish(output: data, terminationStatus: task.terminationStatus)
        
        guard task.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "unknown error"
            throw ExecutionError(code: task.terminationStatus, errorString: errorString)
        }
        
        return data
    }
    
    func waitForString() throws -> String {
        return try wait().string
    }
}

class ShellTaskPrinter {
    let label: String
    
    init(label: String) {
        self.label = label
    }
    
    func didBegin(command: String) {}
    func didAppend(data: Data) {}
    func didFinish(output: Data, terminationStatus: Int32) {
        if terminationStatus != 0 {
            print(output.string)
            print("failed \(label)")
        }
    }
    func didWait() {}
}

class SilentPrinter: ShellTaskPrinter {
    init() {
        super.init(label: "")
    }
    
    override func didFinish(output: Data, terminationStatus: Int32) {
        
    }
}

class FullPrinter: ShellTaskPrinter {
    var filter: (prefixString: String, interval: TimeInterval)?
    var filterDate = Date.distantPast
    
    override func didBegin(command: String) {
        print("running \(label)")
    }
    
    override func didAppend(data: Data) {
        let line = data.string
        
        if let (filterPrefix, filterInterval) = filter, line.starts(with: filterPrefix) {
            if Date().timeIntervalSince(filterDate) < filterInterval {
                return
            }
            
            filterDate = .init()
        }
        
        print(line)
    }
}
