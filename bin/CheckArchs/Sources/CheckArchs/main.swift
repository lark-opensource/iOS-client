import Foundation

/// print color message
extension String {
    var yellow: String {
        return "\u{001B}[33m\(self)\u{001B}[0m"
    }

    var red: String {
        return "\u{001B}[31m\(self)\u{001B}[0m"
    }
}

extension ParseResult {
    struct Exception {
        var message: String
    }
}

enum CheckTask {
    case normalPath(String)
    case xcFramework(String)
}

// save the result of parsing
struct ParseResult {
    var errors: [Exception] = []
    var warnings: [Exception] = []

    func validate() -> Bool {
        return errors.isEmpty
    }

    func printWarningMessage() {
        guard !warnings.isEmpty else { return }

        print("\n\n")
        print("\(warnings.count) warnings".yellow)
        print(
            warnings.map { $0.message }
                .sorted()
                .joined(separator: "\n")
                .yellow
        )
    }

    func printErrorMessage() {
        guard !errors.isEmpty else { return }

        print("\n\n")
        print("\(errors.count) errors".red)
        print(
            errors.map { $0.message }
                .sorted()
                .joined(separator: "\n")
                .red
        )
    }
}

extension Options {
    enum Archs: String {
        case armv7
        case armv7s
        case arm64
        case arm64e
        case arm64_32
        case arm64_simulator
        case i386
        case i386_simulator
        case x86_64
    }
}

// input options parsed from command line
struct Options {
    var archs: [Options.Archs] = []
    var inputs: [String] = []
    var allowedSuffixs: [String] = []

    static func printUsage(autoExit: Bool = true) {
        print("Usage: check-archs [options]")
        print("")
        print("Options:")
        print("  -a, --arch <arch>  Check for the given archs (can be used multiple times)")
        print("                     Archs: armv7, armv7s, arm64, arm64_32, i386, x86_64")
        print("  -i, --input <path> Check for the given paths (can be used multiple times)")
        print("  -l, --allowed-suffix <suffix>")
        print("                     Check for the given suffix (can be used multiple times, can be comma separated)")
        print("  -h, --help         Show this help message")
        if autoExit {
            exit(0)
        }
    }

    static func parserInput(_ args: [String]) -> Options {
        var options = Options()

        var index = args.startIndex

        while index < args.endIndex {
            let arg = args[index]

            switch arg {
            case "-a", "--arch":
                index += 1
                if index < args.endIndex {
                    let arch = Options.Archs(rawValue: args[index])
                    if arch != nil {
                        options.archs.append(arch!)
                    } else {
                        fatalError("Unknown arch: \(args[index])")
                    }
                }

            case "-i", "--input":
                index += 1
                if index < args.endIndex {
                    let path = args[index]
                    if FileManager.default.fileExists(atPath: path) {
                        options.inputs.append(URL(fileURLWithPath: path).resolvingSymlinksInPath().relativePath)
                    } else {
                        fatalError("File not found: \(path)")
                    }
                } else {
                    fatalError("Missing argument for --input")
                }

            case "-l", "--allowed-suffix":
                index += 1
                if index < args.endIndex {
                    let suffix = args[index]
                    if suffix.contains(",") {
                        let suffixes = suffix.components(separatedBy: ",")
                        options.allowedSuffixs.append(contentsOf: suffixes)
                    } else {
                        options.allowedSuffixs.append(suffix)
                    }
                } else {
                    fatalError("Missing argument for --allowed-suffix")
                }

            case "-h", "--help":
                printUsage()

            default:
                fatalError("Unknown argument: \(arg)")
            }

            index += 1
        }
        return options
    }

    func valid() {
        if !archs.isEmpty, !inputs.isEmpty {
#if DEBUG
            print("Archs: \(archs)")
            print("Inputs: \(inputs)")
#endif
        } else {
            Options.printUsage(autoExit: false)
            fatalError("Missing required arguments")
        }
    }
}

typealias RunShellResult = (output: String, status: Int32)
/// run shell
@discardableResult
func shell(_ command: String, environment: [String: String]? = nil) -> RunShellResult {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe

    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    if let environment = environment {
        task.environment = ProcessInfo.processInfo.environment.merging(environment, uniquingKeysWith: { $1 })
    }
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    return (output, task.terminationStatus)
}

/// ignore the path with extension in the given suffixs
func checkPath(_ path: String) -> Bool {
    let pathExtensions: [String] = [
        "png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp", "ico", "icns", "svg",
        "swift", "m", "mm", "c", "cc", "cpp", "cxx", "h", "hh", "hpp", "hxx",
        "rb", "py", "pyc", "pyo", "pyd", "pyo", "pl", "pm", "php", "php3", "php4", "php5", "phtml",
        "sh", "js", "json", "css", "html", "htm", "xml", "xib", "storyboard", "xcdatamodeld",
        "json", "plist", "strings", "bundle", "xcodeproj", "xcworkspace", "xcconfig", "xcdatamodel",
        "yml", "yaml", "yml", "yaml", "txt", "md", "markdown", "mdown", "mkdown", "mkd", "markdown",
        "lock", "swiftinterface", "modulemap", "backup", "bak", "tmp", "tmp", "swiftmodule", "swiftdoc",
        "xcscheme", "erb", "swiftsourceinfo", "s"
    ]

    return !pathExtensions.contains(path.components(separatedBy: ".").last!)
}

func d_name(of entry: UnsafeMutablePointer<dirent>) -> String {
    entry.pointer(to: \.d_name)!.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen), { pointer in
        String(cString: pointer )
    })
}

func listdir(in name: UnsafePointer<CChar>, dirCheck: (String) -> Bool, fileCheck: (String) -> Void) {
    guard let dir = opendir(name) else { return }
    while let entry = readdir(dir) {
        func absolute() -> [CChar] {
            var path: [CChar] = .init(repeating: 0, count: 1024)
            _ = snprintf(ptr: &path, 1024, "%s/%s", name, entry.pointer(to: \.d_name)!)
            return path
        }

        if entry.pointee.d_type == DT_DIR {
            let dname = d_name(of: entry)
            if dname.hasPrefix(".") {
                continue
            }

            var path = absolute()
            if dirCheck(String(cString: path)) {
                listdir(in: &path, dirCheck: dirCheck, fileCheck: fileCheck)
            }
        } else if entry.pointee.d_type == DT_REG {
            fileCheck(String(cString: absolute()))
        }
    }

    closedir(dir)
}

// get all file-paths in the given path
func recursivelyTraversesPath(_ path: String) -> [CheckTask] {
    var paths: [CheckTask] = []

    var name = Array(path.utf8CString)
    listdir(in: &name) { dir in
        if dir.hasSuffix(".xcframework") {
            paths.append(.xcFramework(dir))
            return false
        }
        return true
    } fileCheck: { file in
        if checkPath(file) {
            paths.append(.normalPath(file))
        }
    }

    return paths
}

func canSkip(path: String, options: Options) -> Bool {
    guard !options.allowedSuffixs.isEmpty else { return false }

    for suffix in options.allowedSuffixs {
        if path.hasSuffix(suffix) {
            return true
        }
    }
    return false
}

func check(
    normalPath: String,
    options: Options,
    warning: (ParseResult.Exception) -> Void,
    error: (ParseResult.Exception) -> Void
) {
    let shellResult = shell("file \(normalPath)")

    if shellResult.status == 0, shellResult.output.contains("Mach-O") {
        for arch in options.archs {
            if !shellResult.output.contains("architecture \(arch.rawValue)"),
               !shellResult.output.contains("executable \(arch.rawValue)") {
                if canSkip(path: normalPath, options: options) {
                    warning(ParseResult.Exception(message: "Miss \(arch.rawValue): \(normalPath)"))
                } else {
                    error(ParseResult.Exception(message: "Miss \(arch.rawValue): \(normalPath)"))
                }
            }
        }
    }
}

// read support archs in xcframework
func readSupportArchs(_ path: String) throws -> [Options.Archs]? {
    let infoplistPath = URL(fileURLWithPath: path).appendingPathComponent("Info.plist")
    guard FileManager.default.fileExists(atPath: infoplistPath.path) else {
        throw NSError(domain: "Failed to read support archs", code: 0, userInfo: nil)
    }

    // read content of plist
    guard let data = try? Data(contentsOf: infoplistPath),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)  else {
        throw NSError(domain: "Failed to read support archs", code: 0, userInfo: nil)
    }

    return ((plist as? [String: Any])?["AvailableLibraries"] as? [[String: AnyHashable]])?
        .compactMap { $0["LibraryIdentifier"] as? String }
        .compactMap { string -> [Options.Archs]? in
            switch string {
            case "ios-arm64": return [.arm64]
            case "ios-arm64_armv7": return [.arm64, .armv7]
            case "ios-arm64_x86_64-simulator": return [.x86_64, .arm64_simulator]
            case "ios-x86_64-simulator": return [.x86_64]
            case "ios-arm64_i386_x86_64-simulator": return [.x86_64, .arm64_simulator, .i386_simulator]
            default:
                return nil
            }
        }
        .reduce([Options.Archs](), +)
}

// check if xcframewok support all arch in options.archs
func check(
    xcframwork: String,
    options: Options,
    warning: (ParseResult.Exception) -> Void,
    error: (ParseResult.Exception) -> Void
) {
    if options.archs.isEmpty {
        return
    }

    guard let archs = try? readSupportArchs(xcframwork) else {
        error(ParseResult.Exception(message: "Miss arch info: \(xcframwork)"))
        return
    }

    for arch in options.archs {
        if !archs.contains(arch) {
            if canSkip(path: xcframwork, options: options) {
                warning(ParseResult.Exception(message: "Miss \(arch.rawValue): \(xcframwork)"))
            } else {
                error(ParseResult.Exception(message: "Miss \(arch.rawValue): \(xcframwork)"))
            }
        }
    }
}

func check(
    task: CheckTask,
    options: Options,
    warning: (ParseResult.Exception) -> Void,
    error: (ParseResult.Exception) -> Void
) {
    switch task {
    case .normalPath(let path):
        check(normalPath: path, options: options, warning: warning, error: error)
    case .xcFramework(let path):
        check(xcframwork: path, options: options, warning: warning, error: error)
    }
}

func start(with options: Options) -> ParseResult {
    options.valid()

    let tasks: [CheckTask] = options.inputs
        .map { recursivelyTraversesPath($0) }
        .reduce([]) { $0 + $1 }
    var result = ParseResult()

    let queue = DispatchQueue(label: "write result")

    DispatchQueue.concurrentPerform(iterations: tasks.count) { index in
        autoreleasepool {
            let task = tasks[index]
            check(task: task, options: options, warning: { warning in
                queue.sync {
                    result.warnings.append(warning)
                }
            }, error: { error in
                queue.sync {
                    result.errors.append(error)
                }
            })
        }
    }

    return result
}

// parser input path
func main() {
    let options = Options.parserInput(Array(CommandLine.arguments[1...]))
    if options.archs.isEmpty || options.inputs.isEmpty {
        return
    }

    let result = start(with: options)

    result.printWarningMessage()
    result.printErrorMessage()

    if !result.validate() {
        exit(18)
    }
}

main()
