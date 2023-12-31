//
//  main.swift
//  CompressPNG
//
//  Created by Crazy凡 on 2023/1/29.
//

/// 本脚本主要是调用pngquant进行图片压缩，内部会走一些缓存策略，提高整体脚本执行时间.
/// .compress_record.json是缓存文件，存放了已经压缩过的文件路径和压缩后的文件大小，
/// 每次压缩会进行判断，如果没有缓存文件记录或者当前文件大小比缓存记录大的话都会进行重新压缩。
///
/// pngquant重复调用png文件不会变化

import Foundation

private let cacheFileName = ".compress_record.json"

// MARK: - Options

struct Options {
    var projectPath: String = ""
    var cachePath: String = ""

    var ignoreNames: [String] = []

    var projectURL: URL {
        URL(fileURLWithPath: projectPath)
    }

    var cacheDirURL: URL {
        URL(fileURLWithPath: cachePath)
    }

    func isValid(_ error: inout String?) -> Bool {
        var message = ""
        var result = true

        if projectPath.isEmpty {
            message += "No project path specified.\n"
            result = false
        }

        if cachePath.isEmpty {
            message += "No cache path specified.\n"
            result = false
        }
        error = message

        return result
    }
}

extension Options {
    private static func checkFileExistAndIsDirectory(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    // parse input parameter

    // "-p"," --project": a project path
    // "-c", "--cache": cache file output path
    // "-h", "--help": print usage
    // "-i", "--ignore-names": Ignore name.
    static func parseArgs(arguments: ArraySlice<String>) throws -> Options {
        var option = Options()

        func printUsage() -> Never {
            print("Usage: compresspng -p <project_path> -o <output_path> [-i <name>]")
            print("    -h, --help: print usage")
            print("    -p, --project: specify project path, must be a directory, can be only onece.")
            print("    -c, --cache: specify cache path, must be a directory, can be only onece.")
            print("    -i, --ignore <name>")

            exit(0)
        }

        // expand path to full path
        func expand(path: String) -> String {
            if path.hasPrefix("/") {
                return path
            } else {
                return FileManager.default.currentDirectoryPath + "/" + path
            }
        }

        func path(after index: Array.Index) throws -> String {
            guard index + 1 <= arguments.endIndex else {
                print("Miss input parameter after \(arguments[index])")
                printUsage()
            }

            let path = expand(path: arguments[index + 1])

            if checkFileExistAndIsDirectory(path) {
                return path
            } else {
                fatalError("File not exit or is not a directory: \(path)")
            }
        }

        var index = arguments.startIndex
        while index < arguments.endIndex {
            let argument = arguments[index]
            switch argument {
            case "-p", "--project":
                option.projectPath = try path(after: index)
                index += 1

            case "-c", "--cache":
                option.cachePath = try path(after: index)
                index += 1

            case "-i", "--ignore":
                guard index + 1 <= arguments.endIndex else {
                    print("Miss input parameter after \(arguments[index])")
                    printUsage()
                }
                option.ignoreNames.append(arguments[index + 1])
                index += 1

            case "-h", "--help":
                printUsage()

            default:
                print("Unsupported argument: \(argument)")
            }

            index += 1
        }

        var errorMessage: String?
        if option.isValid(&errorMessage) {
            return option
        } else {
            print(errorMessage ?? "")
            printUsage()
        }
    }

    private static func buildDate() -> String {
        if let executablePath = Bundle.main.executablePath {
            let fileManager = FileManager.default
            let attributes = try! fileManager.attributesOfItem(atPath: executablePath)
            if let date = attributes[FileAttributeKey.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter.string(from: date)
            }
        }

        return "Unknown date"
    }
}

// MARK: - Shell

typealias RunShellResult = (output: String, status: Int32)
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

// MARK: - ENV
enum ENV {
    static subscript(key: String) -> String? {
        get { ProcessInfo.processInfo.environment[key] }
    }
}

// MARK: - FileSize
extension URL {
    var attributes: [FileAttributeKey: Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

// MARK: - Executable File
enum Tool {
    typealias CoompressResult = (file: String, fileSizeAfter: UInt64)

    /// 使用pngquant进行图片压缩
    /// - Parameters:
    ///   - file: 文件 FileURL
    ///   - executableFileURL: 可执行文件 FileURL
    /// - Returns: (图片路径，图片压缩后大小)
    static func pngquantPicture(_ file: URL, executableFileURL: URL) -> CoompressResult {
        shell("\(executableFileURL.path) -f --ext .png --strip --skip-if-larger --quality 50-70 \"\(file.path)\"")

        return (file.path, file.fileSize)
    }

    /// 读取指定文件夹的缓存信息
    /// - Parameter url: 文件夹
    /// - Returns: 缓存信息 [String: UInt64]
    static func getRecord(_ dirURL: URL) throws -> [String: UInt64]? {
        let recordFileURL = dirURL.appendingPathComponent(cacheFileName)
        if FileManager.default.fileExists(atPath: recordFileURL.path) {
            return try JSONSerialization.jsonObject(with: try Data(contentsOf: recordFileURL)) as? [String: UInt64]
        }
        return nil
    }

    static func d_name(of entry: UnsafeMutablePointer<dirent>) -> String {
        entry.pointer(to: \.d_name)!.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen), { pointer in
            String(cString: pointer )
        })
    }

    static func listdir(in name: UnsafePointer<CChar>, fileCheck: (String) -> Void) {
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
                listdir(in: &path, fileCheck: fileCheck)
            } else if entry.pointee.d_type == DT_REG {
                fileCheck(String(cString: absolute()))
            }
        }

        closedir(dir)
    }

    /// 记录缓存
    /// - Parameters:
    ///   - info: 压缩缓存信息
    ///   - dirURL: 存储缓存信息文件夹
    static func cacheRecord(_ info: [String: UInt64], _ dirURL: URL) throws {
        if info.isEmpty { return }

        let recordFileURL = dirURL.appendingPathComponent(cacheFileName)
        try JSONSerialization.data(withJSONObject: info).write(to: recordFileURL)
    }

    static func compress(_ option: Options) async throws {
        let exectableFileURL = try downloadPNGQuant()
        let record = try getRecord(option.cacheDirURL) ?? [: ]

        let newRecord: [String: UInt64] = try await withThrowingTaskGroup(of: CoompressResult?.self) { group in
            var name = Array(option.projectPath.utf8CString)
            listdir(in: &name) { filePath in
                guard filePath.lowercased().hasSuffix(".png"), filePath.contains(".xcassets") else {
                    return
                }

                group.addTask {
                    let fullURL = URL(fileURLWithPath: filePath)
                    if option.ignoreNames.contains(fullURL.lastPathComponent) {
                        NSLog("根据输入配置，忽略压缩图片: \(fullURL.lastPathComponent)")
                        return nil
                    } else {
                        if let cachedSize = record[fullURL.path], cachedSize >= fullURL.fileSize {
                            return nil
                        }

                        return pngquantPicture(fullURL, executableFileURL: exectableFileURL)
                    }
                }
            }

            actor _Context {
                var record: [String: UInt64]

                init(record: [String: UInt64]) {
                    self.record = record
                }

                func update(info: CoompressResult?) {
                    guard let info = info else { return }

                    record[info.0] = info.1
                }
            }

            let context = _Context(record: record)

            for try await info in group {
                await context.update(info: info)
            }

            return await context.record
        }

        try cacheRecord(newRecord, option.cacheDirURL)
    }

    static func downloadPNGQuant() throws -> URL {
        let downloadDir = URL(fileURLWithPath: ENV["TMPDIR"] ?? "/tmp/").appendingPathComponent("pngquant")
        try FileManager.default.createDirectory(atPath: downloadDir.path, withIntermediateDirectories: true)

        let downloadZipURL = downloadDir.appendingPathComponent("pngquant.tar.xz")
        let exectableFileURL = downloadDir.appendingPathComponent("pngquant/pngquant")

        if FileManager.default.fileExists(atPath: exectableFileURL.path) {
            return exectableFileURL
        }

        if !FileManager.default.fileExists(atPath: downloadZipURL.path) {
            shell("curl http://tosv.byted.org/obj/ee-infra-ios/tools/pngquant.tar.xz --output \(downloadZipURL.path)")
        }

        if FileManager.default.fileExists(atPath: downloadZipURL.path) {
            if shell("""
                tar zxvf \(downloadZipURL.path) -C \(downloadDir.path)
                chmod +x \(exectableFileURL.path)
                codesign -f -s - \(exectableFileURL.path)
                """).status != 0 {
                fatalError("pngquant 解压失败")
            }
        } else {
            fatalError("pngquant 下载失败")
        }

        return exectableFileURL
    }
}

// MARK: main
func main() async throws {
    let start = Date()
    NSLog("--- 图片压缩 start ---")

    let options = try Options.parseArgs(arguments: CommandLine.arguments[1...])

    try await Tool.compress(options)

    NSLog("--- 图片压缩 end 耗时 %.2lf s ---", Date().timeIntervalSince(start))
}

try await main()
