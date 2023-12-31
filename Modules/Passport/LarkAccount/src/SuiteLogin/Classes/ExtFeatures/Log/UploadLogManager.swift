//
// Created by Yiming Qu on 2019-06-25.
//

import Foundation
import LarkFoundation
import LarkExtensions
import Reachability
import CoreTelephony
import CommonCrypto
import CryptoSwift
import LKCommonsLogging
import LKTracing
import LarkReleaseConfig
import LarkAccountInterface
import LarkContainer
import LarkEnv

@inline(__always)
func genMD5(_ key: String, salt: String? = "EE") -> String {
    var keyValue = "\(key)"
    if let salt = salt, !salt.isEmpty {
        keyValue = "\(key)\(salt)"
    }

    guard let str = keyValue.cString(using: String.Encoding.utf8) else {
        return ""
    }
    let strLen = CC_LONG(keyValue.lengthOfBytes(using: String.Encoding.utf8))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
    CC_MD5(str, strLen, result)
    let hash = NSMutableString()
    for i in 0..<digestLen {
        hash.appendFormat("%02x", result[i])
    }
    result.deallocate()

    return String(format: hash as String)
}

@inline(__always)
func genAES(_ value: String) -> String {
    let keyString = CommonConst.aesKey
    if let keyData = keyString.data(using: String.Encoding.utf8),
        let toEncryptData = value.data(using: String.Encoding.utf8),
        let aes = try? AES(key: [UInt8](keyData), blockMode: ECB(), padding: .pkcs7),
        let res = try? aes.encrypt([UInt8](toEncryptData)) {
        let encrypted = Data(res).base64EncodedString()
        return encrypted
    }
    return ""
}

enum AESOP {
    case encrypt
    case decrypt
}

@inline(__always)
func aes(_ op: AESOP, _ data: Data) throws -> Data {
    let keyString = CommonConst.aesKey
    guard let keyData = keyString.data(using: String.Encoding.utf8) else {
        throw V3LoginError.badLocalData("wrong key")
    }
    do {
        let aes = try AES(key: [UInt8](keyData), blockMode: ECB(), padding: .pkcs7)
        let bytes: [UInt8]
        switch op {
        case .encrypt:
            bytes = try aes.encrypt([UInt8](data))
        case .decrypt:
            bytes = try aes.decrypt([UInt8](data))
        }
        let outData = Data(bytes)
        return outData
    } catch {
        switch op {
        case .encrypt:
            V3LoginService.logger.error("encrypt fail len: \(data.count)", error: error)
        case .decrypt:
            V3LoginService.logger.error("decrypt fail len: \(data.count)", error: error)
        }
        throw error
    }
}

let UploadLogFlushTime: TimeInterval = 3
let UploadLogFlushLogSizeLimit: Int = 50

class UploadLogManager: UploadLog {

    @Provider var envManager: EnvironmentInterface

    static let shared: UploadLogManager = UploadLogManager()

    let traceId: String

    private var _appVersion: String?
    var appVersion: String {
        if _appVersion == nil {
            _appVersion = Utils.appVersion
        }
        return _appVersion ?? ""
    }
    var env: Env {
        return envManager.env
    }
    var redirectService: Bool = false

    internal static let reach: Reachability? = {
        // swiftlint:disable ForceUnwrapping
        let reachability = Reachability()
        // swiftlint:enable ForceUnwrapping

        try? reachability?.startNotifier()
        return reachability
    }()

    var networkType: String {
        let network: String
        guard let reach = UploadLogManager.reach else { return "unknown" }
        switch reach.connection {
        case .none: network = "Offline"
        case .wifi: network = "Wifi"
        case .cellular:
            switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
            case .📶2G: network = "2G"
            case .📶3G: network = "3G"
            case .📶4G: network = "4G"
            case .📶5G: network = "5G"
            default: network = "unknown"
            }
        @unknown default:
            network = "unknown"
        }
        return network
    }

    private var _contactPoint: String?
    var contactPoint: String? {
        set {
            if let nv = newValue {
                _contactPoint = genMD5(nv)
            }
        }
        get {
            return _contactPoint
        }
    }

    var userId: String?

    var cpId: String?

    var seqId: Int64 = 0

    var appId: String { ReleaseConfig.appId }

    lazy var displayName: String  = {
        return (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
    }()

    private var logQueue: [DataModel] = []
    private var scheduleEnable: Bool = false
    private let lock: NSLock = NSLock()
    private let dispatchQueue = DispatchQueue(label: "SuiteLogin.Upload.Queue")

    private var httpTool: LogHTTPTool
    private var retryManager: UploadLogRetryManager

    private static let dateFormatter: DateFormatter = DateFormatter()

    static let logger = Logger.plog(UploadLogManager.self, category: "UploadLogManager")

    private let userDefault: UserDefaults

    private static let installIdKey = "SuiteLoginInstallId"

    /// a unique id for each installation
    /// because DeviceService InstallId store in keychain, not satisfied
    private var installId: String {
        if let id = PassportStore.shared.logInstallID {
            return id
        } else if let iid = userDefault.string(forKey: UploadLogManager.installIdKey) {
            return iid
        } else {
            let iid = UUID().uuidString
            PassportStore.shared.logInstallID = iid
            return iid
        }
    }

    init() {
        traceId = UniContext.rootTraceId
        httpTool = LogHTTPTool()
        userDefault = SuiteLoginUtil.userDefault()
        UploadLogManager.dateFormatter.dateFormat = "yyyy-MM-dd\'T\'HH:mm:ss.SSSSSSXXXXX"

        retryManager = UploadLogRetryManager(httpTool: self.httpTool)
        retryManager.delegate = self
    }

    func log(_ log: LogModel) {
        lock.lock()
        let dataData = getDataData(log)
        let data = getData(dataData.JSONString())
        logQueue.append(data)

        if !scheduleEnable {
            scheduleFlush()
            scheduleEnable = true
        }
        lock.unlock()

    }

    // MARK: log queue

    func scheduleFlush() {
        dispatchQueue.asyncAfter(deadline: .now() + UploadLogFlushTime) {
            var logs: [DataModel]?
            self.lock.lock()
            if !self.logQueue.isEmpty {
                logs = self.filteredIfNeeded(self.logQueue)
                self.logQueue = []
                self.scheduleEnable = false
            }
            self.lock.unlock()
            if let ls = logs, !ls.isEmpty {
                let header = self.getHeader()
                let body = UploadLogRequestBody(header: header, data: ls)
                self.httpTool.request(body: body, success: { [weak self] () in
                    guard let self = self else {
                        return
                    }
                    self.retryManager.success(body: body)
                }, failure: { [weak self] (_) in
                    guard let self = self else {
                        return
                    }
                    self.retryManager.failure(body: body)
                })
            }
        }
    }

    /**
     一次上报日志超过UploadLogFlushLogSizeLimit条，去除多余日志
    */
    func filteredIfNeeded(_ ls: [DataModel]) -> [DataModel] {
        var logs = ls
        let toSub = ls.count - UploadLogFlushLogSizeLimit
        if toSub > 0 && UploadLogFlushLogSizeLimit > 0 {
            logs = [DataModel](logs[0...(UploadLogFlushLogSizeLimit - 1)])
            logs.append(getDataModelRecordFiltered())
        }
        return logs
    }

    // MARK: construct request body

    static func getLogModel(msg: String, level: Level = Level.info, file: String = #fileID, line: Int = #line) -> LogModel {
        return LogModel(level: level.rawValue,
                        msg: msg,
                        file: file,
                        line: line,
                        h5Log: false,
                        time: UploadLogManager.getTime(),
                        thread: Thread.current.name ?? "unknown")
    }

    static func getTime() -> String {
        return UploadLogManager.dateFormatter.string(for: Date()) ?? ""
    }

    func getDataModelRecordFiltered(file: String = #fileID, line: Int = #line) -> DataModel {
        let log = LogModel(level: Level.warn.rawValue,
                           msg: "filtered log over limit: \(UploadLogFlushLogSizeLimit)",
                           file: file,
                           line: line,
                           h5Log: false,
                           time: UploadLogManager.getTime(),
                           thread: Thread.current.name ?? "unknown")
        let dataData = getDataData(log)
        let data = getData(dataData.JSONString())
        return data
    }

    func getHeader() -> HeaderModel {
        /// 使用vip deviceid(不会被graylogs过滤) 全量上传graylog
        let deviceId = "43891908782"
        var userId = ""
        if let uid = self.userId {
            userId = uid.encrypted()
        }
        return HeaderModel(deviceId: deviceId,
                           userId: userId,
                           tenantId: "",
                           appVersion: self.appVersion,
                           displayName: self.displayName,
                           aid: self.appId)
    }

    func getData(_ dataDataJSONString: String) -> DataModel {
        return DataModel(data: dataDataJSONString)
    }

    func getDataData(_ log: LogModel) -> DataDataModel {
        let deviceId = PassportDeviceServiceWrapper.shared.deviceId
        let message = Message(businessMsg: log.msg,
                              cPoint: self.contactPoint ?? "",
                              traceId: self.traceId,
                              env: "\(self.env)",
                              redirect: self.redirectService,
                              network: self.networkType,
                              h5Log: log.h5Log,
                              cpId: self.cpId ?? "",
                              seqId: self.seqId,
                              rid: deviceId,
                              installId: self.installId)
        self.seqId += 1
        let messageStr = message.serialize()
        let dataData = DataDataModel(message: messageStr,
                                     time: log.time,
                                     thread: log.thread,
                                     file: log.file,
                                     level: log.level,
                                     line: log.line)
        return dataData
    }

}

// MARK: UploadLogRetryManagerDelegate

extension UploadLogManager: UploadLogRetryManagerDelegate {
    func didDowngradeRust(_ limit: UInt) {
        let msg = "downgrade rust to native limit: \(limit)"
        UploadLogManager.logger.info(msg)
        self.log(UploadLogManager.getLogModel(msg: msg, level: .warn))
    }
}

extension UploadLogManager: PassportStoreMigratable {
    func startMigration() -> Bool {
        PassportStore.shared.logInstallID = installId
        
        userDefault.removeObject(forKey: UploadLogManager.installIdKey)
        
        return true
    }
}
