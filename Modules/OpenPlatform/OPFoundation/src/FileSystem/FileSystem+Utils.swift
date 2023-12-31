//
//  FileSystem+Utils.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/3.
//

import Foundation
import ECOInfra
import ECOProbe
import LKCommonsLogging
import LarkContainer
import LarkSetting

private let defaultReadSize:  Int64 = 10 * 1024 * 1024 //10M
private let defaultWriteSize: Int64 = 10 * 1024 * 1024 //10M
private let fileSystemThresholdConfig = UserSettingKey.make(userKeyLiteral: "file_system_threshold_config")


public enum FileSystemEncoding: String {
    case ascii
    case base64
    case binary
    case hex
    case ucs2
    case ucs_2 = "ucs-2"
    case utf16le
    case utf_16le = "utf-16le"
    case utf_8 = "utf-8"
    case utf8
    case latin1
}

public final class FileSystemUtils {
    public static func encodeFileData(_ data: Data, encoding: FileSystemEncoding) -> String? {
        switch encoding {
        case .ascii:
            return String(data: data, encoding: .ascii)
        case .base64:
            return data.base64EncodedString()
        case .binary, .latin1:
            return String(data:data, encoding: .isoLatin1)
        case .hex:
            return data.toHexString()
        case .ucs2, .ucs_2, .utf16le, .utf_16le:
            return String(data:data, encoding: .utf16LittleEndian)
        case .utf8, .utf_8:
            return String(data:data, encoding: .utf8)
        }
    }

    public static func decodeFileDataString(_ dataString: String, encoding: FileSystemEncoding) -> Data? {
        switch encoding {
        case .ascii:
            return dataString.data(using: .ascii)
        case .base64:
            return Data(base64Encoded: dataString)
        case .binary, .latin1:
            return dataString.data(using: .isoLatin1)
        case .hex:
            return dataString.hexStringToData()
        case .ucs2, .ucs_2, .utf16le, .utf_16le:
            return dataString.data(using: .utf16LittleEndian)
        case .utf8, .utf_8:
            return dataString.data(using: .utf8)
        }
    }

    /// 判断 dest 是否是 src 的子路径
    ///
    /// - Note: 如果是 ttfile://user/xxx, ttfile://temp/xxx 这样的路径也可以判断，不用转换为真实路径。
    ///
    /// 测试用例:
    /// ("ttfile://user/aaa.png",   "ttfile://user/aaa.png/b")          -> true
    /// ("ttfile://user/a/b/c",     "ttfile://user/a/d/e/f")            -> false
    /// ("ttfile://user/",          "ttfile://user/")                   -> false
    /// ("ttfile://user/",          "ttfile://user")                    -> false
    /// ("ttfile://user",           "ttfile://user/")                   -> false
    /// ("ttfile://user",           "ttfile://user/a/b/c")              -> true
    /// ("/",                       "./")                               -> false
    /// ("./",                      "/")                                -> false
    /// ("/a/b/",                   "/a/b")                             -> false
    /// ("/a/b/c",                  "/a/b")                             -> false
    /// ("/a/b",                    "/a/b/c")                           -> true
    /// ("/a/b/c",                  "/a/b/c")                           -> false
    /// ("/user",                   "/user/a/b/c")                      -> true
    public static func isSubpath(src: String, dest: String) -> Bool {
        if src.isEmpty || dest.isEmpty {
            return false
        }
        let standardSrc = (src as NSString).standardizingPath
        let standardDest = (dest as NSString).standardizingPath

        if standardDest.hasPrefix(standardSrc) {
            return (standardSrc as NSString).pathComponents.count < (standardDest as NSString).pathComponents.count
        }

        return false
    }

    /// 标准 API 迁移开关判断
    /// - Parameter feature: 迁移的 feature
    /// - Returns: 是否打开
    public static func isEnableStandardFeature(_ feature: String) -> Bool {
        let fgEnable = EMAFeatureGating.boolValue(forKey: "ecosystem.sandbox.standardize.enable")
        if (!fgEnable) {
            return false
        }

        let configService = Injected<ECOConfigService>().wrappedValue
        let config = configService.getDictionaryValue(for: "ecosystem_sandbox_standard_config")
        if let applyAll = config?["apply_all"] as? Bool, applyAll {
            return true
        }

        if let featureList = config?["feature_list"] as? [String] {
            return featureList.contains(feature)
        }
        return false
    }
    

    /// 文件部分api Monitor 优化开关，默认false,走优化
    /// - Returns: 是否打开
    static var isMonitorOptimizeDisable : Bool = {
        let monitorOptimizeDisable = EMAFeatureGating.boolValue(forKey: "openplatform.api.filesystem.monitor_optimize.disable")
        logger.info("get isMonitorOptimizeDisable:\(monitorOptimizeDisable)")
        return monitorOptimizeDisable
    }()

    /// 文件部分写入系统数据到沙箱，补偿创建目录fg
    /// - Returns: 是否打开
    public static func writeSystemDataCreateEnable() -> Bool{
        let isEnable = EMAFeatureGating.boolValue(forKey: "openplatform.api.filesystem.write_system_data.create_dir")
        return isEnable
    }
    
    /// 获取文件信息兜底开关，false走新方式
    public static func getFileSizeDisable() -> Bool{
        let isDisEnable = EMAFeatureGating.boolValue(forKey: "openplatform.api.filesystem.getfilesize.new.disable")
        return isDisEnable
    }
    /// 文件读阈值
    public static func readSizeThreshold(uniqueId: OPAppUniqueID) -> Int64 {
        do {
            // TODOZJX
            let config: [String: Any] = try SettingManager.shared.setting(with: fileSystemThresholdConfig)
            guard let readThreshold = config["read_threshold"] as? [String:Any] else{
                logger.info("get read_threshold fail")
                return defaultReadSize
            }
            let appID = uniqueId.appID
            if let apps = readThreshold["apps"] as? [String:Int64], let sizeThreshold = apps[appID], sizeThreshold > 0 {
                return sizeThreshold
            }
            
            if let readDefault = readThreshold["default"] as? Int64, readDefault > 0 {
                return readDefault
            }
            return defaultReadSize
        } catch {
            logger.info("get file_system_threshold_config fail")
            return defaultReadSize
        }
        
    }
    
    /// 文件写阈值
    public static func writeSizeThreshold(uniqueId: OPAppUniqueID) -> Int64 {
        do {
            // TODOZJX
            let config: [String: Any] = try SettingManager.shared.setting(with: fileSystemThresholdConfig)
            guard let writeThreshold = config["write_threshold"] as? [String:Any] else{
                logger.info("get write_threshold fail")
                return defaultWriteSize
            }
            let appID = uniqueId.appID
            if let apps = writeThreshold["apps"] as? [String:Int64], let sizeThreshold = apps[appID], sizeThreshold > 0 {
                return sizeThreshold
            }
            
            if let writeDefault = writeThreshold["default"] as? Int64, writeDefault > 0 {
                return writeDefault
            }
            return defaultWriteSize
        } catch {
            logger.info("get file_system_threshold_config fail")
            return defaultWriteSize
        }

    }
    
    /// 文件加解密配置
    struct CryptoConfig {
        /// 禁用加解密 toast 提示
        public var disableToast: Bool

        /// 禁用加密接口
        public var disableEncrypt: Bool

        /// 禁用解密接口
        public var disableDecrypt: Bool

        /// 是否开启文件日志
        public var enableFileLog: Bool

        /// 端上默认配置
        /// 5.1 - 5.x 端上默认配置为关闭（disable）
        /// 5.x+ 版本，文件收敛全量 + 旧代码下线后，端上默认配置变更为开启
        static let `default` = CryptoConfig(disableToast: true, disableEncrypt: true, disableDecrypt: true, enableFileLog: false)
    }

    /// 获取文件加解密配置
    static func getCryptoConfig() -> CryptoConfig {
        let configService = Injected<ECOConfigService>().wrappedValue
        guard let config = configService.getDictionaryValue(for: "ttfile_crypto_config"),
              let disableToast = config["crypto_toast_disable"] as? Bool,
              let disableEncrypt = config["encrypt_disable"] as? Bool,
              let disableDecrypt = config["decrypt_disable"] as? Bool,
              let enableFileLog = config["enable_file_log"] as? Bool else {
            return CryptoConfig.default
        }
        return CryptoConfig(
            disableToast: disableToast,
            disableEncrypt: disableEncrypt,
            disableDecrypt: disableDecrypt,
            enableFileLog: enableFileLog
        )
    }
}

// legacy
extension FileSystemUtils {
    static let logger = Logger.oplog(FileSystemUtils.self, category: "FileSystemUtils")

    public static func fileExist(with uniqueID: OPAppUniqueID, fileInfo: BDPLocalFileInfo) -> Bool {
        if fileInfo.isInPkg {
            if let pkgPath = fileInfo.pkgPath,
               let reader = BDPCommonManager.shared()?.getCommonWith(uniqueID)?.reader {
                return reader.fileExistsInPkg(atPath: pkgPath)
            } else {
                return false
            }
        } else {
            if let path = fileInfo.path {
                return LSFileSystem.fileExists(filePath: path)
            } else {
                return false
            }
        }
    }
    
    /// 生成随机文件名的private_tmp下路径
    /// - return `/.../private_tmp/aADAWF5qhoSFA.pathExtension`
    public static func generateRandomPrivateTmpPath(with sandbox: BDPMinimalSandboxProtocol, pathExtension: String? = nil) -> String? {
        guard let privateTmpPath = sandbox.privateTmpPath() else {
            return nil
        }
        var fileName = BDPRandomString(15)
        if let ext = pathExtension {
            fileName += ".\(ext)"
        }
        return (privateTmpPath as NSString).appendingPathComponent(fileName)
    }
    
    /// 生成随机一层路径的private_tmp下路径
    /// - return `/.../private_tmp/aADAWF5qhoSFA/
    public static func generatePrivateTmpRandomInnerPath(with sandbox: BDPMinimalSandboxProtocol) -> String? {
        guard let privateTmpPath = sandbox.privateTmpPath() else {
            return nil
        }
        
        var tmpFilePath: String = ""
        do {
            tmpFilePath = (privateTmpPath as NSString).appendingPathComponent(BDPRandomString(15))
            if !LSFileSystem.fileExists(filePath: tmpFilePath) {
                try LSFileSystem.main.createDirectory(atPath: tmpFilePath, withIntermediateDirectories: true)
            }
        } catch {
            return nil
        }
        return tmpFilePath
    }

    public static func shouldAddPath(with uniqueID: BDPUniqueID, from srcInfo: BDPLocalFileInfo, to destInfo: BDPLocalFileInfo) -> Bool {
        let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self)
        guard let storageModule = module as? BDPStorageModuleProtocol else {
            return false
        }

        let fileManager = storageModule.sharedLocalFileManager()
        let sandboxPathObjc = OPUnsafeObject(fileManager.appSandboxPath(with: uniqueID))

        guard let sandboxPath = sandboxPathObjc, !sandboxPath.isEmpty else {
            logger.error("sandboxPath is empty with \(uniqueID)")
            return false
        }

        if destInfo.path?.hasPrefix(sandboxPath) ?? false {
            var size = LSFileSystem.fileSize(path: sandboxPath)
            if srcInfo.isInPkg {
                if let pkgPath = srcInfo.pkgPath {
                    let reader = BDPCommonManager.shared()?.getCommonWith(uniqueID)?.reader
                    size += reader?.fileSizeInPkg(atPath: pkgPath) ?? 0
                } else {
                    return false
                }
            } else {
                if let srcPath = srcInfo.path {
                    size += LSFileSystem.fileSize(path: srcPath)
                } else {
                    return false
                }
            }
            return size < BDP_MAX_MICRO_APP_FILE_SIZE
        }

        return true
    }
}

extension FileAttributeType {
    var monitorTypeString: String {
        switch self{
        case .typeBlockSpecial:
            return "block_device"
        case .typeCharacterSpecial:
            return "character_device"
        case .typeDirectory:
            return "directory"
        case .typeSymbolicLink:
            return "symbolic_link"
        case .typeRegular:
            return "regular_file"
        case .typeSocket:
            return "scoket"
        case .typeUnknown:
            return "unknown"
        default:
            return "unknown"
        }
    }
}
