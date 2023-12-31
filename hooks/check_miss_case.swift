import Foundation
import zlib

struct Log {
    var name: String
    var startTime: Double
    var endTime: Double

    init?(dic: [String: Any]) {
        guard let name = dic["fileName"] as? String,
            let startTime = dic["timeStartedRecording"] as? Double,
            let endTime = dic["timeStoppedRecording"] as? Double
            else {
                return nil
        }

        // more log
        print(name, startTime, endTime)

        self.name = name
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - unzip
extension Data {
    public func gunzipped() throws -> Data {
        guard !isEmpty else {
            return Data()
        }

        var stream = z_stream()
        var status: Int32

        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))

        guard status == Z_OK else {
            throw NSError(domain: String(validatingUTF8: stream.msg) ?? "", code: Int(status), userInfo: nil)
        }

        var data = Data(capacity: count * 2)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += count / 2
            }

            let inputCount = count
            let outputCount = data.count

            withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)

                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)

                    status = inflate(&stream, Z_SYNC_FLUSH)

                    stream.next_out = nil
                }

                stream.next_in = nil
            }
        } while status == Z_OK

        guard inflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw NSError(domain: String(validatingUTF8: stream.msg) ?? "", code: Int(status), userInfo: nil)
        }

        data.count = Int(stream.total_out)

        return data
    }
}

// MARK: - read log
func getLogDir() throws -> URL {
    guard let path = ProcessInfo.processInfo.environment["BUILT_PRODUCTS_DIR"],
        var url = URL(string: path) else {
            throw NSError(domain: "Get log root path error", code: -1, userInfo: nil)
    }

    url.deleteLastPathComponent()
    url.deleteLastPathComponent()
    url.deleteLastPathComponent()

    url.appendPathComponent("Logs/Build")

    return url
}

func getLogFile(with rootDir: URL) throws -> URL {
    let configURL = rootDir.appendingPathComponent("LogStoreManifest.plist")
    guard let logsInfo = NSDictionary(contentsOfFile: configURL.path),
        let logs = logsInfo["logs"] as? [String: [String: AnyHashable]] else {
        throw NSError(domain: "Get log info error", code: -1, userInfo: nil)
    }

    let log = logs.compactMap { Log(dic: $1) }
    .sorted { $0.startTime > $1.startTime }
    .first

    guard let logName = log?.name else {
        throw NSError(domain: "Get log name", code: -1, userInfo: nil)
    }

    return rootDir.appendingPathComponent(logName)
}

func main() throws {
    let start = Date()

    let file: URL
    let data: Data
    if CommandLine.arguments.count >= 2 {
        file = URL(fileURLWithPath: CommandLine.arguments[1])
        data = try NSData(contentsOfFile: file.path) as Data
    } else {
        let dir = try getLogDir()
        file = try getLogFile(with: dir)
        data = try (try NSData(contentsOfFile: file.path) as Data).gunzipped()
    }
    print("after build -- log file path: \(file)")

    if data.range(of: "warning: switch must be exhaustive".data(using: .utf8)!) != nil {
        let errorMessage = """

            ❌❌ Failed: Error:（这一行为了方便搜索日志）

            看这里 看这里 看这里 看这里 看这里 看这里 看这里
            ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓

            看到该错误说明是出现了switch有些case没处理，
            可能是引入更新了一些依赖库导致的，比如更新了RustPB；

            请在日志中搜索警告：“switch must be exhaustive”并处理。
            详细说明，请参考文档: https://bytedance.feishu.cn/docs/doccnqrqFTLhoowaTFYfb130sEh#

            ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
            看这里 看这里 看这里 看这里 看这里 看这里 看这里
            """
        throw NSError(domain: errorMessage, code: -1, userInfo: nil)
    }
    print("after build -- time: \(Date().timeIntervalSince1970 - start.timeIntervalSince1970)")
    exit(0)
}

do {
    try main()
} catch {
    let space = (0...5).map { _ in "\n" }.joined()
    print(space + error.localizedDescription + space)
    exit(1)
}
