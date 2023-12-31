import Foundation

public struct Tool {
    static let root: URL = {
        if CommandLine.arguments.count > 1 {
            let path = (CommandLine.arguments[1] as NSString).expandingTildeInPath
            guard FileManager.default.fileExists(atPath: path) else {
                print("路径不存在: \(path)")
                exit(0)
            }

            return URL(fileURLWithPath: path)
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }()

    public static func main() async throws {
        let url = root
        // url = URL(fileURLWithPath: "/Users/kkk/repo/lark/iOS-client") // Your debug project path
        let podspec = await podspecs(in: url)
        try writeBitsComponents(podspec, to: url.appendingPathComponent(".bits/bits_components.yaml"))
        try writeModuleJson(podspec, to: url.appendingPathComponent("modules.json"))
        try writeMboxConfig(podspec, to: url.appendingPathComponent(".mboxconfig"))
    }
}

extension Tool {
    typealias NameToPodspec = [String: URL]

    static func d_name(of entry: UnsafeMutablePointer<dirent>) -> String {
        entry.pointer(to: \.d_name)!.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen), { pointer in
            String(cString: pointer )
        })
    }

    static func listdir(in name: UnsafePointer<CChar>, _ handler: (String) -> Void) {
        guard let dir = opendir(name) else { return }
        while let entry = readdir(dir) {
            func absolute() -> [CChar] {
                var path: [CChar] = .init(repeating: 0, count: 1024)
                _ = snprintf(ptr: &path, 1024, "%s/%s", name, entry.pointer(to: \.d_name)!)
                return path
            }

            if entry.pointee.d_type == DT_DIR {
                let dname = d_name(of: entry)
                if dname.hasPrefix(".") || ["Pods", "Example", "Mock", "__MACOSX", "vendor"].contains(dname) {
                    continue
                }
                var path = absolute()
                listdir(in: &path, handler)
            } else if entry.pointee.d_type == DT_REG, d_name(of: entry).hasSuffix(".podspec") {
                handler(String(cString: absolute()))
            }
        }

        closedir(dir)
    }

    static func podspecs(in path: URL) async -> NameToPodspec {
        guard FileManager.default.fileExists(atPath: path.path) else {
            print("路径不存在: \(path.path)")
            exit(1)
        }

        var result = NameToPodspec()

        let count = path.path.count
        var name = Array(path.path.utf8CString)
        listdir(in: &name) { pathName in
            if let url = URL(string: String(pathName[pathName.index(pathName.startIndex, offsetBy: count + 1)...]), relativeTo: path) {
                result[url.deletingPathExtension().lastPathComponent] = url
            }
        }

        return result
    }

    static func writeBitsComponents(_ podspes: NameToPodspec, to path: URL) throws {
        try """
        ---
        components:
        \(podspes.keys.sorted().map { "- \($0)" }.joined(separator: "\n"))
        components_publish_config:
        \(podspes.map { (name, url) in
            """
              \(name):
                archive_source_mode: true
                archive_source_path: \(url.deletingLastPathComponent().relativePath)
                archive_podspec_file: \(url.relativePath)
            """
        }
        .sorted()
        .joined(separator: "\n"))

        """.write(to: path, atomically: true, encoding: .utf8)
    }

    static func writeModuleJson(_ podspes: NameToPodspec, to path: URL) throws {
        let components = podspes.keys.sorted().compactMap { (name: String) -> [String: AnyHashable]? in
            guard let url = podspes[name] else {
                assert(false, "找不到 \(name) 对应的 podspec 路径")
                return nil
            }

            return [
                "path": url.deletingLastPathComponent().relativePath + "/",
                "components": [
                    name
                ]
            ]
        }

        try JSONSerialization.data(
            withJSONObject: components,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        .write(to: path)
    }

    static func writeMboxConfig(_ podspes: NameToPodspec, to path: URL) throws {
        let config: [String: AnyHashable] = [
            "podfile": "./Podfile",
            "podlock": "./Podfile.lock",
            "xcodeproj": "./Lark.xcodeproj",
            "podspecs": podspes.keys.sorted()
                .compactMap { podspes[$0]?.relativePath },
            "plugins": [
                "MBoxLarkModManager": [
                    "required_minimum_version": "1.0.1"
                ]
            ]
        ]

        try JSONSerialization.data(
            withJSONObject: config,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        .write(to: path)
    }
}

try await Tool.main()
