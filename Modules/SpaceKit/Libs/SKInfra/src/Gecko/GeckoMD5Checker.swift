//
//  File.swift
//  SpaceKit
//
//  Created by Webster on 2019/2/14.
//  swiftlint:disable file_length

import SKFoundation
import CommonCrypto

/// data source
protocol GeckoMD5CheckerDataSource: AnyObject {
    func geckoMD5RootPath(in channel: DocsChannelInfo) -> String?
    func targetMD5RootPath(in channel: DocsChannelInfo) -> SKFilePath
}

/// delegate
protocol GeckoMD5CheckerDelegate: AnyObject {
    func geckoMD5CheckerRequestClean(checker: GeckoMD5Checker, channel: [DocsChannelInfo])
}

/// MD5失败的原因
///
/// - shutdown: 校验关闭
/// - path: 返回md5空路径
/// - multi: 存在多个md5文件
/// - nullfile: 没有任何md5文件
/// - md5FileCalc: .md5文件的md5计算出错
/// - md5SelfFail: .md5校验不通过
/// - pass: 校验通过
enum Md5FailedReason: Int {
    case pass = 1
    case shutdown = 2
    case path = 3
    case multi = 4
    case nullfile = 5
    case md5FileCalc = 6
    case md5SelfFail = 7
    case md5NoPass = 8
    case specialFileLost = 9
    case specialFileMd5Failed = 10

    func details() -> String {
        switch self {
        case .pass:
            return "pass"
        case .shutdown:
            return "shutdown"
        case .path:
            return "path"
        case .multi:
            return "multi"
        case .nullfile:
            return "nullfile"
        case .md5FileCalc:
            return "md5FileCalc"
        case .md5SelfFail:
            return "md5SelfFail"
        case .md5NoPass:
            return "md5NoPass"
        case .specialFileLost:
            return "specialLost"
        case .specialFileMd5Failed:
            return "specialMd5Failed"
        }
    }
}

/// md5 checking result of special channel
struct MD5CheckResult {
    var type: GeckoChannleType = .webInfo
    var version: String = String()
    var failFilePath: String = ""
    var pass: Bool = false
    var failReason: Md5FailedReason = .pass
    init(type: GeckoChannleType, version: String, pass: Bool) {
        self.type = type
        self.version = version
        self.pass = pass
    }

    static func defaultPass(type: GeckoChannleType) -> MD5CheckResult {
        let obj = MD5CheckResult(type: type, version: "1.0.0", pass: true)
        return obj
    }
}

typealias LoopCheckResult = (pass: Bool, reason: Md5FailedReason, path: String)

class GeckoMD5Checker {

    /// datasource
    weak var dataSource: GeckoMD5CheckerDataSource?
    /// delegate
    weak var delegate: GeckoMD5CheckerDelegate?
    /// 总开关，是否开启md5校验
    private var featureEnable: Bool = false
    /// all the channels infos in gecko
    private var channels: [DocsChannelInfo] = []
    /// the channels which must do md5 check
    private var checkChannels: [DocsChannelInfo] = []
    /// channel check results
    private var checkerResult: [GeckoChannleType: MD5CheckResult] = [GeckoChannleType: MD5CheckResult]()
    /// 模板预加载的时候如果校验失败，就标志成下次启动要清空一下Gecko缓存
    private var requestDeleteGeckoCachesOnInit: Bool = false
    /// the serialization key prefix for md5 check failed count
    private let checkerNumberKeyPrefix = "com.bytedance.ee.docs.md5checker"
    /// md5校验失败重试的次数
    private let maxMD5FaildNumber: Int = 3

    /// init fun
    ///
    /// - Parameters:
    ///   - channels: all the channel gecko support
    ///   - checkChannels: all the channel need to check
    ///   - dataSource: datasource
    ///   - delegate: delegate
    init(channels: [DocsChannelInfo],
         checkChannels: [DocsChannelInfo],
         dataSource: GeckoMD5CheckerDataSource? = nil,
         delegate: GeckoMD5CheckerDelegate? = nil) {
        self.channels = channels
        self.checkChannels = checkChannels
        self.dataSource = dataSource
        self.delegate = delegate
    }

    /// remove the check result (called before gecko update )
    func cleanCheckResult() {
        checkerResult.removeAll()
    }

//    /// recored channel check result
//    ///
//    /// - Parameter result: md5 check result
//    func recordCheckResult(result: MD5CheckResult?) {
//        guard featureEnable else { return }
//        if let result = result {
//            checkerResult.updateValue(result, forKey: result.type)
//            //如果md5校验失败，对应版本的失败次数+1
//            if !result.pass {
//                increaseCheckNumber(channel: result.type.channelName(), version: result.version)
//            }
//        }
//    }

    // 所有的channel都校验结束的时候调用此方法，根据校验结果决定是否清除gecko记录
//    func applyCheckResult() {
//        guard featureEnable else { return }
//        //因为gecko kit只能执行全局的清除，在这要等所有资源都应用完毕才能进行资源的更新
//        guard checkerResult.count == channels.count else { return }
//
//        var shouldDeleteGeckoHistory = false
//        for result in checkerResult {
//            let matchItems = self.checkChannels.filter { $0.type == result.key }
//            guard !matchItems.isEmpty else { continue }
//
//            // 如果出现了失败(次数>=1),而且失败次数还没达到允许的最大失败次数.
//            // (失败的原因可能是网络没有下载完等等，所以允许有最大失败次数)
//            // 则删除本地 gecko 记录,下次重启会重新拉取.
//            let count = checkNumber(channel: result.key.channelName(), version: result.value.version)
//            if (1...maxMD5FaildNumber) ~= count {
//                shouldDeleteGeckoHistory = true
//                break
//            }
//        }
//
//        if shouldDeleteGeckoHistory {
//            delegate?.geckoMD5CheckerRequestClean(checker: self, channel: checkChannels)
//        }
//    }
//
//    /// check the package md5 in special channel
//    ///
//    /// - Parameter channel: channel name
//    /// - Returns: check result
//    func checkChannel(channel: DocsChannelInfo) -> MD5CheckResult {
//
//        guard featureEnable else {
//            var result = MD5CheckResult.defaultPass(type: channel.type)
//            result.failReason = .shutdown
//            return result
//        }
//        /// bitable暂未加入校验的逻辑，始终返回校验成功的结果
//        if channel.type == .bitable {
//            var defaultResult = MD5CheckResult(type: channel.type, version: "1.0.0", pass: true)
//            defaultResult.failReason = .pass
//            return defaultResult
//        }
//
//        var result = MD5CheckResult(type: channel.type, version: "unknow", pass: false)
//        //let logName = channel.name
//        ///查找Gecko当前channel的路径
//        guard let path = dataSource?.geckoMD5RootPath(in: channel) else {
//            result.failReason = .path
//            result.pass = false
//            //DocsLogger.info("gecko_md5: 找不到gecko根目录 in \(logName)")
//            return result
//        }
//        let logVersion = GeckoPackageManager.Folder.revision(in: path) ?? "unknow"
//        result.version = logVersion
//        guard md5FileCount(in: path) <= 1 else {
//            result.failReason = .multi
//            result.pass = true
//            return result
//        }
//        /// 不存在md5文件
//        guard let md5Path = md5FilePath(in: path), let md5URL = URL(string: md5Path) else {
//            //DocsLogger.info("gecko_md5: 资源包里没有md5文件 in \(logName) version:\(logVersion)")
//            result.failReason = .nullfile
//            result.pass = true
//            return result
//        }
//        ///计算本身md5记录文件的md5
//        guard let md5RecordFileMd5 = calcMD5(of: md5URL) else {
//            //DocsLogger.info("gecko_md5: md5记录文件损坏 in \(logName) version:\(logVersion)")
//            result.failReason = .md5FileCalc
//            result.pass = false
//            return result
//        }
//        ///校验本身md5记录文件的md5是否正确
//        guard md5Path.hasSuffix(md5RecordFileMd5 + ".md5") else {
//            //DocsLogger.info("gecko_md5: md5记录文件损坏 in \(logName) version:\(logVersion)")
//            result.failReason = .md5SelfFail
//            result.pass = false
//            return result
//        }
//        /// 校验md5文件里面提供的所有资源
//        let loopResult = loopCheckAllFile(rootPath: path, md5RecordPath: md5Path)
//        guard loopResult.pass else {
//            //DocsLogger.info("gecko_md5: md5校验不通过 in \(logName) version:\(logVersion)")
//            result.failReason = loopResult.reason
//            result.failFilePath = loopResult.path
//            result.pass = false
//            return result
//        }
//
//        result.pass = true
//        result.failReason = .pass
//
//        return result
//
//    }

    /// check the package md5 in special channel
    ///
    /// - Parameter channel: channel name
    /// - Returns: check result
    func checkTarget(channel: DocsChannelInfo) -> MD5CheckResult {

        guard featureEnable else {
            var result = MD5CheckResult.defaultPass(type: channel.type)
            result.failReason = .shutdown
            return result
        }

        var result = MD5CheckResult(type: channel.type, version: "unknow", pass: false)
        //let logName = channel.name
        ///查找当前资源包最终的应用路径
        guard let path = dataSource?.targetMD5RootPath(in: channel) else {
            //DocsLogger.info("gecko_md5: 找不到target根目录 in \(logName)")
            result.pass = false
            result.failReason = .path
            return result
        }
        let logVersion = GeckoPackageManager.Folder.revision(in: path) ?? "unknow"
        result.version = logVersion

        //多个md5文件
        guard md5FileCount(in: path) <= 1 else {
            result.pass = true
            result.failReason = .multi
            return result
        }
        /// 不存在md5文件
        guard let md5Path = md5FilePath(in: path) else {
            //DocsLogger.info("gecko_md5: target 资源包里没有md5文件 in \(logName) version:\(logVersion)")
            result.pass = true
            result.failReason = .nullfile
            return result
        }
        let md5URL = md5Path.pathURL
        ///计算本身md5记录文件的md5
        guard let md5RecordFileMd5 = calcMD5(of: md5Path) else {
            //DocsLogger.info("gecko_md5: target md5记录文件损坏 in \(logName) version:\(logVersion)")
            result.pass = false
            result.failReason = .md5FileCalc
            return result
        }
        ///校验本身md5记录文件的md5是否正确
        guard md5Path.pathString.hasSuffix(md5RecordFileMd5 + ".md5") else {
            //DocsLogger.info("gecko_md5: target md5记录文件损坏 in \(logName) version:\(logVersion)")
            result.pass = false
            result.failReason = .md5SelfFail
            return result
        }
        /// 校验md5文件里面提供的所有资源
        let loopResult = loopCheckAllFile(rootPath: path, md5RecordPath: md5Path)
        guard loopResult.pass else {
            //DocsLogger.info("gecko_md5: target md5校验不通过 in \(logName) version:\(logVersion)")
            result.failReason = loopResult.reason
            result.failFilePath = loopResult.path
            result.pass = false
            return result
        }

        result.pass = true
        result.failReason = .pass

        return result

    }

    /// 检查md5文件里面提供的md5文件列表的md5合法性
    ///
    /// - Parameters:
    ///   - rootPath: md5文件里的文件列表的文件的根路径
    ///   - md5RecordPath: MD5文件的全路径
    /// - Returns:  所有文件的校验结果
    private func loopCheckAllFile(rootPath: SKFilePath, md5RecordPath: SKFilePath) -> LoopCheckResult {
        var readyMd5Infos: String?
        do {
            readyMd5Infos = try String.read(from: md5RecordPath)
        } catch {
            return (false, .md5SelfFail, "")
        }
        guard let md5Txt = readyMd5Infos else {
            return (false, .md5SelfFail, "")
        }

        var lines: [String] = []
        md5Txt.enumerateLines { (line, _) in
            lines.append(line)
        }

        var md5AllPass: LoopCheckResult = (true, .pass, "")
        for item in lines {
            let subItems = item.split(separator: " ")
            guard subItems.count == 2 else { continue }
            var fileName = String(subItems[0])
            let relatedFile = fileName
            let md5 = String(subItems[1])
            let filePath = rootPath.appendingRelativePath(fileName)
            if filePath.exists {
                let realyMd5 = calcMD5(of: filePath) ?? "badMd5"
                if !realyMd5.elementsEqual(md5) {
                    DocsLogger.info("gecko_md5: md5校验不通过 in \(fileName)")
                    md5AllPass.pass = false
                    md5AllPass.reason = .specialFileMd5Failed
                    md5AllPass.path = relatedFile
                    break
                }
            } else {
                md5AllPass.pass = true
                md5AllPass.reason = .pass
                md5AllPass.path = ""
                break
            }
        }

        return md5AllPass
    }


//    static func checkAllFileExist(rootPath: String) -> Bool {
//        //寻找里面的md5文件
//        let pathURL = URL(fileURLWithPath: rootPath, isDirectory: true)
//        var fileNames: [String] = []
//        if let enumerator = FileManager.default.enumerator(atPath: rootPath) {
//            for file in enumerator {
//                guard let realFile = file as? String else { continue }
//                let filePath = URL(fileURLWithPath: realFile, relativeTo: pathURL).path
//                if filePath.hasSuffix(".md5") {
//                    fileNames.append(filePath)
//                }
//            }
//        }
//
//        guard fileNames.count == 1 else { return false }
//        //读取md5的内容
//        let md5FileURL = URL(fileURLWithPath: fileNames[0], isDirectory: false)
//        var readyMd5Infos: String?
//        do {
//            readyMd5Infos = try String(contentsOf: md5FileURL)
//        } catch {
//            return false
//        }
//        guard let md5Txt = readyMd5Infos else {
//            return false
//        }
//
//        var lines: [String] = []
//        md5Txt.enumerateLines { (line, _) in
//            lines.append(line)
//        }
//        var allExist = true
//        for item in lines {
//            let subItems = item.split(separator: " ")
//            guard subItems.count == 2 else { continue }
//            var fileName = String(subItems[0])
//            fileName = "/" + fileName
//            fileName = rootPath + fileName
//            if !FileManager.default.fileExists(atPath: fileName) {
//                allExist = false
//                break
//            }
//
//        }
//
//        return allExist
//    }

    /// 从path路径下寻找后缀名是.md5的文件
    ///
    /// - Parameter path: 寻找路径
    /// - Returns: md5文件的全路径
    private func md5FilePath(in path: SKFilePath) -> SKFilePath? {
        let pathURL = URL(fileURLWithPath: path.pathString, isDirectory: true)
        var fileNames: [SKFilePath] = []
        let enumerator = path.enumerator()
        for file in enumerator {
            let filePath = file.pathString
            if filePath.hasSuffix(".md5") {
                fileNames.append(file)
            }
        }
        return fileNames.count > 0 ? fileNames[0] : nil
        
    }
    /// 计算文件的md5值
    ///
    /// - Parameter url: 文件的url linke
    /// - Returns: md5 16进制串
    private func calcMD5(of filePath: SKFilePath) -> String? {
        let bufferSize = 1024 * 1024
        do {
            let file = try filePath.fileReadingHandle()
            defer {
                file.closeFile()
            }
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in
                        _ = CC_MD5_Update(&context, ptr.baseAddress, numericCast(data.count))
                    })
                    return true
                } else {
                    return false
                }
            }) { }
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) in
                let int8Ptr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                _ = CC_MD5_Final(int8Ptr, &context)
            })
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            return nil
        }
    }

    /// MD5数量个数
    ///
    /// - Parameter path: md5根路径
    /// - Returns: md5文件个数
    private func md5FileCount(in path: SKFilePath) -> Int {
        let pathURL = URL(fileURLWithPath: path.pathString, isDirectory: true)
        var fileNames: [String] = []
        let enumerator = path.enumerator()
        for file in enumerator {
            let filePath = URL(fileURLWithPath: file.pathString, relativeTo: pathURL).path
            if filePath.hasSuffix(".md5") {
                fileNames.append(filePath)
            }
        }
        return fileNames.count
    }
}

// MARK: - 失败计数
extension GeckoMD5Checker {
    /// 某个Channel下的某个version失败校验次数
    ///
    /// - Parameters:
    ///   - channel: gecko的channel名
    ///   - version: 包版本
    /// - Returns: 校验失败次数

//    private func checkNumber(channel: String, version: String) -> Int {
//        let key = checkNumberKey(channel: channel, version: version)
//        let v = UserDefaults.standard.integer(forKey: key)
//        return v
//    }

//    /// 增加校验失败次数 加一
//    ///
//    /// - Parameters:
//    ///   - channel: gecko channel
//    ///   - version: 包版本
//    private func increaseCheckNumber(channel: String, version: String) {
//        let v = 1 + checkNumber(channel: channel, version: version)
//        let key = checkNumberKey(channel: channel, version: version)
//        UserDefaults.standard.setValue(v, forKey: key)
//    }

//    /// 系列化失败次数到本地的key
//    ///
//    /// - Parameters:
//    ///   - channel:
//    ///   - version: gecko channel
//    ///   - Returns: 包版本
//    private func checkNumberKey(channel: String, version: String) -> String {
//        return "\(channel)_\(version)_\(checkerNumberKeyPrefix)"
//    }
}
