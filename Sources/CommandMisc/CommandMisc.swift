//
//  CommandMisc.swift
//  CommandMisc
//
//  Created by devedbox on 2018/1/21.
//

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif
import Dispatch
import Foundation

public typealias Result = Int32

public var Deferring: (() -> Void) = { }

/// Returns the environment variable path of the system if any.
public let envPaths = { () -> [String] in
    let env_paths = getenv("PATH")
    let char_env_paths = unsafeBitCast(env_paths, to: UnsafePointer<CChar>.self)
    #if swift(>=4.1)
    return
        String(validatingUTF8: char_env_paths)?
            .split(separator: ":")
            .compactMap { String($0) }
            ?? []
    #else
    return
    String(validatingUTF8: char_env_paths)?
    .split(separator: ":")
    .flatMap { String($0) }
    ?? []
    #endif
}()
/// Find the executable path with a path extension.
public func executable(_ name: String) -> String? {
    let paths =
        [FileManager.default.currentDirectoryPath] + envPaths
    return
        paths.map {
            name.hasPrefix("/")
                ? $0 + name
                : $0 + "/\(name)"
            }.first {
                FileManager.default.isExecutableFile(atPath: $0)
    }
}
/// Run the command with the given arguments.
///
/// - Parameter command: The command to run.
/// - Parameter arguments: The arguments for the command to run with.
///
/// - Returns: The stdoutput or stderror results.
@discardableResult
public func run(_ command: String,
                arguments: [String],
                at currentWorkingDirectory: String? = nil,
                stdout: Any? = nil) -> Result {
    // Creates a new process.
    let process = Process()
    // Changing the current working path if needed.
    if let cwd = currentWorkingDirectory {
        process.currentDirectoryPath = cwd
    }
    
    process.launchPath = executable(command)
    process.arguments = arguments
    process.standardOutput = stdout
    // Using custom output.
    process.launch()
    process.waitUntilExit()
    
    return process.terminationStatus
}
/// Run the command along with the arguments.
///
/// - Parameter commands: The command to run.
///
/// - Returns: The stdoutput or stderror results.
@discardableResult
public func run(_ commands: String,
                at currentWorkingDirectory: String? = nil,
                stdout: Any? = nil) -> Result {
    var compos = commands.split(separator: " ")
    return run(String(compos.removeFirst()),
               arguments: compos.map { String($0) },
               at: currentWorkingDirectory,
               stdout: stdout)
}
/// Returns the date description from current date.
public func describedDate(from format: String, date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
}
/// Execute a closure and pint the output is any or exit if the status is indicating an error.
public func execute(_ e:(() -> Result)) {
    let result = e()
    if  result != 0 {
        exit(result, deferring: Deferring)
    }
}
/// An operator to run the command.
prefix operator <>
/// An operator to append run env path.
infix  operator <<<: AdditionPrecedence
/// An operator to print object.
prefix operator <<<
/// An operator to read object.
infix  operator >>>: AdditionPrecedence

public prefix func <> (_ commands: String) -> String { return commands }

@discardableResult
public func <<< (_ commands: String, _ path: String) -> Pipe {
    let pipe = Pipe()
    let result = run(commands, at: path, stdout: pipe)
    execute { result }
    return pipe
}
public prefix func <<< (_ object: Any) { DispatchQueue.main.async { print(object) } }

public func >>> (_ pipe: Pipe, _ callback: ((Data) -> Void)) {
    let file = pipe.fileHandleForReading
    callback(file.readDataToEndOfFile())
}

/// Exit and execute a clearing closure before exiting.
internal func exit(_ exitCode: Int32, deferring: () -> Void) {
    deferring()
    exit(exitCode)
}
