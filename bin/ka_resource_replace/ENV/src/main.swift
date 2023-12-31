//
//  main.swift
//  ka_config_env_export
//
//  Created by Crazy凡 on 2021/11/23.
//

import Foundation

// 整体规则参照 https://bytedance.feishu.cn/docs/doccnpwKtIU1g4gJmUxPLYAlsqd#v4If74

enum ToolError: Error {
    case missChannel

    case urlInitFailed
    case loadConfigDataFailed(String, Error)
    case parseJsonFailed
    case cannotFound(String)

    case missSearcKey

    case missVariables([String])
    case missENV(String)
    case readVersionFailed

    case updateLarkSettingFailed
    case shellFailed(Error)
}

// Color Log
enum ANSIColors: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case clean = "\u{001B}[0;0m"

    static func all() -> [ANSIColors] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white]
    }
}

enum ENVKeys: String, CaseIterable {
    case buildProductType = "BUILD_PRODUCT_TYPE"
    case deployMode = "DEPLOY_MODEO" // typo for old config, will fix in the future
    case loginType = "LOGIN_TYPE"
    case kaChannl = "KA_TYPE" // source config is KA_CHANNEL
    case jsonConfig = "KA_INFO_EXPORT_FILE"
    case defaultUnit = "DEFAULT_UNIT"
}

func + (left: String, right: ANSIColors) -> String {
    return right.rawValue + left + ANSIColors.clean.rawValue
}

extension String {
    var black: String { self + .black }
    var red: String { self + .red }
    var green: String { self + .green }
    var yellow: String { self + .yellow }
    var blue: String { self + .blue }
    var magenta: String { self + .magenta }
    var cyan: String { self + .cyan }
    var white: String { self + .white }
}

/// 方便快速的读取JsonObject
extension AnyHashable {
    subscript(key: String) -> AnyHashable? {
        guard let data = self as? [String: AnyHashable] else { return nil }
        return data[key]
    }
}

enum Tool {
    typealias RunShellResult = (String, Int32)
    static var __base: String?

    /// run shell
    @discardableResult
    static func shell(_ command: String, environment: [String: String]? = nil) -> RunShellResult {
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

    /// 读取 env 的环境变量
    static func env(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    /// 根据脚本路径找到 ios-client 跟目录
    static func basePath() -> String {
        if let path = __base {
            return path
        }

        @inline(__always)
        func save(_ path: String) -> String {
            __base = path
            return path
        }

        if let path = env("DEBUG_WITH_XCODE_ROOT_PATH") {
            return save(URL(fileURLWithPath: path).path)
        }

        let url = URL(fileURLWithPath: CommandLine.arguments[0])
            .deletingLastPathComponent() // Lark
            .deletingLastPathComponent() // bin
            .deletingLastPathComponent() // ka_resource_replace
            .deletingLastPathComponent() // ENV
            .deletingLastPathComponent() // project

        return save(url.path)
    }

    /// 从 info.plist 读取版本号
    static func version() throws -> String? {
        let infoPlistPath = URL(fileURLWithPath: basePath()).appendingPathComponent("Lark/Info.plist")

        let infoPlistData = try Data(contentsOf: infoPlistPath)

        if let dict = try PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any] {
            return (dict["CFBundleShortVersionString"] as? String)?
                .components(separatedBy: "-")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    /// https://internal-api-lark-api.feishu.cn/settings/static
    static func loadKAList() throws -> [String] {
        guard let url = URL(string: "https://internal-api-lark-api.feishu.cn/settings/static?unit=eu_nc") else {
            throw ToolError.urlInitFailed
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ToolError.loadConfigDataFailed("_list", error)
        }

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyHashable] else {
            throw ToolError.parseJsonFailed
        }

        guard let list = json["data"]?["ka_info"] as? [[String: Any]] else {
            throw ToolError.cannotFound("ka_info")
        }

        return list.compactMap { ka in
            guard let name = ka["display_name"] as? String, let channel = ka["channel"] as? String else {
                return nil
            }

            return "KA: \(name), CHANNEL: \(channel)"
        }
    }

    /// 加载 KA 对应的 channel 的配置
    static func loadJsonConfig(by channel: String) throws -> [String: AnyHashable] {

        guard let versionString = try version() else {
            throw ToolError.readVersionFailed
        }

        let parameters: String = [
            "channel": channel,
            "platform": "ios",
            "version": versionString
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        guard let url = URL(string: "https://cloudapi.bytedance.net/faas/services/tttswszxlemb2szaz8/invoke/getKAClientBuildData?\(parameters)") else {
            throw ToolError.urlInitFailed
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ToolError.loadConfigDataFailed(channel, error)
        }
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyHashable] else {
            throw ToolError.parseJsonFailed
        }

        guard let errorCode = json["errorCode"] as? Int, errorCode == 0 else {
            throw ToolError.readVersionFailed
        }

        guard let result = json["data"] as? [String: AnyHashable] else {
            throw ToolError.readVersionFailed
        }

        return result
    }

    /// 从 Config 读取配置
    static func environmentVariables(
        from config: [String: AnyHashable],
        with channel: String
    ) throws -> [String: AnyHashable] {

        guard var variables = config["client_build_env"] as? [String: AnyHashable] else {
            throw ToolError.missVariables(["ALL"])
        }

        variables["IS_CUSTOMIZED_KA"] = true
        variables["SHOW_UPGRADE"] = true
        variables["CHANNEL_NAME"] = "Enterprise"

        // 检查必要的Key存在
        let requireKeys = Set([
            "RELEASE_CHANNEL",
            "PUSH_CHANNEL",
            "AppId",
            "EXTENSION_GROUP",
            "AMAP_KEY",
            "SSAppID",
            "IS_CUSTOMIZED_KA",
            "CHANNEL_NAME",
            "SHOW_UPGRADE",
            "APP_BRAND_NAME",
            "DEPLOY_MODE",
            "CHANNEL_NAME",
            "BUILD_PRODUCT_TYPE"
        ]).subtracting(variables.keys)

        if !requireKeys.isEmpty {
            throw ToolError.missVariables(Array(requireKeys))
        }

        let deployMode = variables["DEPLOY_MODE"] ?? variables["DEPLOY_MODEO"] // should fix typo and useage in the future
        variables["KA_DEPLOY_MODEO"] = deployMode // should fix typo in the future
        variables["KA_DEPLOY_MODE"] = deployMode

        // 删除非必要的Key
        [
            "PACKAGE_NAME_SUFFIX",
            "PUSH_HW_APP_ID",
            "PUSH_MEIZU_APP_ID",
            "PUSH_MEIZU_APP_KEY",
            "PUSH_MIPUSH_APP_ID",
            "PUSH_MIPUSH_APP_KEY",
            "PUSH_OPPO_APP_KEY",
            "PUSH_OPPO_APP_SECRET",
            "PUSH_SMARTISAN_PUSH_ID",
            "PUSH_VIVO_APP_ID",
            "PUSH_VIVO_APP_KEY",
            "THIRD_MAP_AMAP_ANDROID",
            "THIRD_SHARE_KEY_WEIBO_ANDROID",
            "THIRD_SHARE_KEY_QQ_ANDROID",
            "THIRD_SHARE_KEY_WECHAT_ANDROID",
            "PACKAGE_NAME"
        ].forEach { variables.removeValue(forKey: $0) }

        // 填充 CFBundleURLTypes
        if let value = variables["Sns_Wechat_AppID"] as? String, !value.isEmpty {
            let wechatURLTypes: [String: AnyHashable] = [
                "CFBundleTypeRole": "Editor",
                "CFBundleURLName": "wechat",
                "CFBundleURLSchemes": [value]
            ]

            variables["CFBundleURLTypes"] = [
                wechatURLTypes
            ]
        }

        return variables
    }

    /// 将 Config 写入JSON文件
    static func writeJsonConfig(_ config: [String: AnyHashable]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])

        let url = URL(fileURLWithPath: "\(basePath())/bin/ka_resource_replace/.tmp/\(UUID().uuidString).ka.debug.config")

        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try data.write(to: url)

        return url.path
    }

    /// 从 Config 中获取ENV
    static func loadENV(from config: inout [String: AnyHashable], and channel: String) throws -> [ENVKeys: String] {
        var result: [ENVKeys: String] = [:]

        // 固定值
        result[.kaChannl] = channel

        let envKeys: [ENVKeys] = [
            .buildProductType,
            .loginType,
            .deployMode
        ]

        try envKeys.forEach { key in
            if let value = (config.removeValue(forKey: key.rawValue) as? String) {
                result[key] = key == .buildProductType ? value : value.lowercased()
                config.removeValue(forKey: key.rawValue)
            } else {
                throw ToolError.missENV(key.rawValue)
            }
        }

        // 可选值
        result[.defaultUnit] = config.removeValue(forKey: ENVKeys.defaultUnit.rawValue) as? String

        return result
    }

    static func readENV() throws -> [ENVKeys: String] {
        try ENVKeys.allCases.reduce(into: [ENVKeys: String]()) { result, key in
            if let value = Self.env(key.rawValue) {
                result[key] = value
            } else {
                throw ToolError.missENV(key.rawValue)
            }
        }
    }

    static func passShellResult(_ result: RunShellResult, info: String) throws {
        if result.1 != 0 {
            throw ToolError.shellFailed(
                NSError(domain: info, code: Int(result.1), userInfo: ["shell output": result.0])
            )
        }
    }

    static func runShellToDownloadAndReplaceZeusResources(_ env: [String: String]) throws {
        guard let channel = env[ENVKeys.kaChannl.rawValue] else { throw ToolError.missChannel }

        let arguments = """
            ruby <(curl http://tosv.byted.org/obj/ee-infra-ios/ka_script/fetch_ka_resource.rb) \
            \(basePath()) \
            \(channel) \
            > /dev/null
        """
        try passShellResult(shell(arguments, environment: env), info: "Fetch Zeus Resource failed.")
    }

    /// 更新 LarkSetting 配置文件
    /// equal: `sh "python3 ../bin/gen_static_lark_settings.py -c #{ENV['KA_TYPE']} -p ../Modules/Infra/Libs/LarkSetting/Resources/ -o iphone -v #{version} > /dev/null" || exit(1)`
    static func updateLarkSetting(_ env: [String: String]) throws {
        // Bits 环境跳过这里。
        guard self.env("WORKFLOW_JOB_ID") == nil else { return }

        guard let channel = env[ENVKeys.kaChannl.rawValue],
              let versionString = try version(),
              let deployMode = env[ENVKeys.deployMode.rawValue],
              let defaultUnit = env[ENVKeys.defaultUnit.rawValue] else { throw ToolError.updateLarkSettingFailed }

        let arguments = """
            python3 \(basePath())/bin/gen_static_lark_settings.py \
            -c \(channel) \
            -p \(basePath())/Modules/Infra/Libs/LarkSetting/Resources/ \
            -o iphone \
            -v \(versionString) \
            -m \(deployMode) \
            -u \(defaultUnit)
            > /dev/null
        """
        try passShellResult(shell(arguments, environment: env), info: "Update LarkSetting failed.")
    }

    /// 更新 SKResorces 下的eesz文件; @xuwei.calvin@bytedance.com @kongkaikai@bytedance.com
    /// equal: `sh ../bin/ka_resource_replace/ka_post_pod_install.sh || echo '\033[31m ❌❌❌ 如果不是强关心 CCM 的 eesz 资源文件可以忽略这一条 \033[0m'`
    static func updateCCMResources(_ env: [String: String]) throws {
        let resultOfReplaceZeusResource = shell(
          "\(basePath())/bin/ka_resource_replace/replace_zeus_resources.sh > /dev/null",
          environment: env
        )
        let resultOfKaPostPodInstall = shell(
          "ruby \(basePath())/bin/ka_resource_replace/ka_post_pod_install.rb > /dev/null",
          environment: env
        )

        if (resultOfReplaceZeusResource.1 != 0) || (resultOfKaPostPodInstall.1 != 0) {
          NSLog("❌❌❌ 更新CCM资源失败，如果非强关心CCM的eesz资源文件可以忽略".red)
        }
    }

    /// KA动态化集成pods, 详情参考:Lark iOS KA动态化集成Pod方案
    /// equal: sh "ruby ../bin/ruby_script/dynamic_ka_pods.rb"
    static func dynamicKAPods(_ env: [String: String]) throws {
        let dynamicPods = "ruby \(basePath())/bin/ruby_script/dynamic_ka_pods.rb > /dev/null"
        try passShellResult(shell(dynamicPods, environment: env), info: "Dynamic KA pods failed.")
      }

    /// 执行pod install
    static func podInstall(_ env: [String: String]) throws {
        let podInstall = "cd \(basePath()); bundle exec pod install --clean-install --repo-update"
        try passShellResult(shell(podInstall, environment: env), info: "Bundle exec pod install failed.")
    }

    static func run<RunResult>(mark: String, _ event: () throws -> RunResult) rethrows -> RunResult {
        return try autoreleasepool {
            let start = Date()
            NSLog("Start: \(mark).".green)
            let result: RunResult = try event()
            NSLog("End: \(mark), duration: %.2lfms".green, start.distance(to: Date()) * 1000)
            return result
        }
    }
}

func main() throws {
    let start = Date()
    let mark = "Config KA ENV"
    NSLog("Start: \(mark).".green)
    guard let channel = Tool.env("KA_CHANNEL") else {
        throw ToolError.missChannel
    }

    if channel.hasPrefix("_list") {
        try Tool.run(mark: "Load ka list") {
            try Tool.loadKAList().forEach { NSLog($0.cyan) }
        }

        // skip others
        return
    }

    if channel.hasPrefix("_search") {
        try Tool.run(mark: "Load ka list") {
            guard channel.contains("-"), let name = channel.split(separator: "-").last else {
                throw ToolError.missSearcKey
            }

            let list = try Tool.loadKAList()
                .filter { $0.contains(name) }

            if list.isEmpty {
                NSLog("❎❎❎ Can not find KA with name: \(name)")
            } else {
                list.forEach { NSLog($0.cyan) }
            }
        }

        // skip others
        return
    }

    let env: [ENVKeys: String]

    if Tool.env("KA_INFO_EXPORT_FILE") != nil {
        env = try Tool.run(mark: "Read env for ci build job", { try Tool.readENV() })
    } else {
        // load all config
        let config = try Tool.run(mark: "Load config for ka: \(channel)") { try Tool.loadJsonConfig(by: channel) }

        // load info.plist patch config
        var patchConfig = try Tool.run(mark: "Read config patch config") { try Tool.environmentVariables(from: config, with: channel) }

        // load env config
        var innerENV = try Tool.run(mark: "Load ENV") { try Tool.loadENV(from: &patchConfig, and: channel) }

        // write config to cache file
        let configURLString = try Tool.run(mark: "Write plist patch to file") { try Tool.writeJsonConfig(patchConfig) }

        innerENV[.jsonConfig] = configURLString
        env = innerENV
    }

    var s2sENV: [String: String] = env.reduce(into: [String: String](), { $0[$1.key.rawValue] = $1.value })

    try Tool.run(mark: "Download and repalce zeus resources") { try Tool.runShellToDownloadAndReplaceZeusResources(s2sENV) }

    s2sENV.removeValue(forKey: ENVKeys.jsonConfig.rawValue)
    try Tool.run(mark: "Update LarkSetting config file") { try Tool.updateLarkSetting(s2sENV) }

    try Tool.run(mark: "Upload CCM resource: eesz") { try Tool.updateCCMResources(s2sENV) }

    try Tool.run(mark: "Write ka env setup.sh") {
        try s2sENV.reduce(into: "", { $0 += "export \($1.key)=\($1.value) \n" })
            .write(toFile: "/tmp/ka_env_setup.sh", atomically: true, encoding: .utf8)
    }

    try Tool.run(mark: "Dynamic ka pods") { try Tool.dynamicKAPods(s2sENV) }

    try Tool.run(mark: "Bundle exec pod install") { try Tool.podInstall(s2sENV) }

    NSLog("End: \(mark), duration: %.2lfms".green, start.distance(to: Date()) * 1000)
}

do {
    try main()
} catch {
    if let error = error as? ToolError {
        let message: String
        switch error {
        case .missChannel:
           message = "缺失环境变量"
        case .urlInitFailed:
            message = "访问配置的URL初始化失败"
        case .loadConfigDataFailed(let string, let error):
            message = "KA: \(string), 数据加载失败，Error: \(error)"
        case .parseJsonFailed:
            message = "下发的配置不是标准的Json格式"
        case .cannotFound(let string):
            message = "配置中缺失对应的子项: \(string)"
        case .missVariables(let array):
            message = "配置中缺失以下必要配置项目: \(array.joined(separator: ", "))"
        case .missENV(let string):
            message = "配置中缺失以下必要配置项目: \(string)"
        case .readVersionFailed:
            message = "从本地读取版本号失败"
        case .updateLarkSettingFailed:
            message = "更新LarkSetting失败"
        case .shellFailed(let error):
            message = "Shell 执行出错, Error: \(error)"
        case .missSearcKey:
            message = "搜索指令缺少搜索内容，例: `bundle exec fastlane ios KA_DEBUG ka:_search-标品`"
        }
        NSLog("❌❌❌ Error: \(message)".red)
    } else {
        NSLog("❌❌❌ Error: 未知的错误类型, rawError: \(error)".red)
    }

    exit(1)
}
