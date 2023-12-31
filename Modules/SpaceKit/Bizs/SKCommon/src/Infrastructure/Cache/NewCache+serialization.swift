//
//  NewCache+serialization.swift
//  SKCommon
//
//  Created by ByteDance on 2023/8/25.
//

import Foundation
import UIKit
import LarkSetting
import LarkContainer
import SKFoundation
import ThreadSafeDataStructure

enum NewCacheSerializeType: Int {
    case nsCoding
    case json
}

protocol NewCacheSerializationDelegate: AnyObject {
    
    func didEncode(type: NewCacheSerializeType, error: Error?)
    
    func didDecode(type: NewCacheSerializeType, error: Error?)
}

enum NewCacheSerializeError: LocalizedError {
    
    struct CustomKey {
        /// NSData字节数, Int
        static let dataSize = "newcache_datasize"
        /// model类型, String
        static let modelType = "newcache_modeltype"
    }
    
    case jsonInvalid
    
    var errorDescription: String? {
        switch self {
        case .jsonInvalid:
            return "json invalid"
        }
    }
    
    var nsError: NSError {
        switch self {
        case .jsonInvalid:
            return NSError(domain: "newcache.serialize.error",
                           code: -100,
                           userInfo: [NSLocalizedDescriptionKey: errorDescription ?? ""])
        }
    }
}

// https://bytedance.feishu.cn/wiki/A8mvwa76Ri7WoKkLsWAcunnkne1
// 序列化器
final class NewCacheSerializer {

    /// 头部标志位
    private lazy var headerBytes: Data = {
        let uuid = "1B3D33A6-49EF-51BB-8BFF-A63FA6313743" // 随机生成的
        let string = "ccm_h5record_coding_is_json_" + uuid
        return string.data(using: .utf8) ?? Data()
    }()
    
    weak var delegate: NewCacheSerializationDelegate?
    
    private var reporter: NewCacheSerializeReporter?
    
    private let config: ConfigProvider
    
    init(userID: String) {
        self.config = ConfigProvider(userID: userID)
        if self.config.reportConfigValid {
            self.reporter = NewCacheSerializeReporter(config: config)
            self.delegate = reporter
        } else {
            self.reporter = nil
            self.delegate = nil
        }
    }
    
    /// 仅供单测使用
    func setJsonSerializationEnabeld(_ enabeld: Bool) {
        config.setJSONEnabled(enabeld)
    }
}

extension NewCacheSerializer {
    
    /// 编码: NSCoding -> Data
    func encodeObject(_ payload: NSCoding) throws -> Data {
        let function: (NSCoding) throws -> Data
        let type: NewCacheSerializeType
        if config.jsonEnabled {
            function = new_encodeObject
            type = .json
        } else {
            function = old_encodeObject
            type = .nsCoding
        }
        
        do {
            let data = try function(payload)
            delegate?.didEncode(type: type, error: nil)
            return data
        } catch {
            var nsError = error as NSError
            var userInfo: [String: Any] = [:]
            userInfo[NewCacheSerializeError.CustomKey.modelType] = "\(Swift.type(of: payload))"
            nsError = nsError.mergedUserInfo(userInfo)
            delegate?.didEncode(type: type, error: nsError)
            throw nsError
        }
    }
    
    /// 解码: Data -> Object
    func decodeData(_ data: Data) throws -> Any {
        let header = data.prefix(headerBytes.count)
        let isJSONEncoded = (header == headerBytes)
        
        let function: (Data) throws -> Any
        let type: NewCacheSerializeType
        if isJSONEncoded {
            function = new_decodeData
            type = .json
        } else {
            function = old_decodeData
            type = .nsCoding
        }
        
        do {
            let bodyData = isJSONEncoded ? data.dropFirst(headerBytes.count) : data
            let object = try function(bodyData)
            delegate?.didDecode(type: type, error: nil)
            return object
        } catch {
            var nsError = error as NSError
            var userInfo: [String: Any] = [:]
            userInfo[NewCacheSerializeError.CustomKey.dataSize] = data.count
            nsError = nsError.mergedUserInfo(userInfo)
            delegate?.didDecode(type: type, error: nsError)
            throw nsError
        }
    }
}

// MARK: 编码
private extension NewCacheSerializer {
    
    func new_encodeObject(_ payload: NSCoding) throws -> Data {
        if isValidJSON(payload) {
            var options: JSONSerialization.WritingOptions = [.fragmentsAllowed]
            if #available(iOS 13, *) {
                options.insert(.withoutEscapingSlashes)
            }
            let body = try JSONSerialization.data(withJSONObject: payload, options: options)
            return headerBytes + body
        } else {
            // 多上报一次error
            var nsError = NewCacheSerializeError.jsonInvalid.nsError
            var userInfo: [String: Any] = [:]
            userInfo[NewCacheSerializeError.CustomKey.modelType] = "\(Swift.type(of: payload))"
            nsError = nsError.mergedUserInfo(userInfo)
            delegate?.didEncode(type: .json, error: nsError)
            
            return try old_encodeObject(payload)
        }
    }
    
    func old_encodeObject(_ payload: NSCoding) throws -> Data {
        let data = try NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true)
        return data
    }
    
    func isValidJSON(_ payload: NSCoding) -> Bool {
        if payload is NSString || payload is NSNull {
            return true
        }
        if payload is NSNumber { // NSNumber不能作为top level object, 所以用数组包一层
            return JSONSerialization.isValidJSONObject(NSArray(object: payload))
        }
        return JSONSerialization.isValidJSONObject(payload)
    }
}

// MARK: 解码
private extension NewCacheSerializer {
    
    func new_decodeData(_ data: Data) throws -> Any {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return object
    }
    
    func old_decodeData(_ data: Data) throws -> Any {
        let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) // NSCoding
        return object as Any // 注意object可能是nil
    }
}

// MARK: 埋点
private struct ConfigConst {
    // FG
    static let fgKey = CCMFGKeys.CS.h5RecordCodingOpt
    // Setting
    static let reportConfig = "h5record_serialize_report_config"
    static let reportInterval = "report_interval"
    static let errorReportCount = "error_report_count"
    static let errorPrintCount = "error_print_count"
    // Tea埋点
    static let teaEvent = "ccm_h5record_coding_opt_dev"
    static let fgEnable = "json_enable"
    static let total = "total_count"
    static let operation = "operation_type"
    static let success = "success_count"
    static func errCode(_ i: Int) -> String { "error_top_\(i)_code" }
    static func errCount(_ i: Int) -> String { "error_top_\(i)_count" }
}

/// 相关配置项，用户生命周期内不变
private class ConfigProvider {
    /// JSONSerialization 编码优化开启
    private(set) var jsonEnabled: Bool
    /// 上报间隔秒数
    let reportInterval: Int
    /// 错误上报个数
    let errorReportCount: Int
    /// 错误写入日志个数
    let errorPrintCount: Int
    
    /// 上报配置是否有效
    var reportConfigValid: Bool { reportInterval > 0 }
    
    init(userID: String) {
        let compatible = CCMUserScope.compatibleMode
        guard let userResolver = try? Container.shared.getUserResolver(userID: userID, compatibleMode: compatible) else {
            jsonEnabled = false
            reportInterval = 0
            errorReportCount = 0
            errorPrintCount = 0
            return
        }
        let fgValue = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: ConfigConst.fgKey))
        jsonEnabled = fgValue
        
        let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_powerlog_config")
        let settingValue = (try? userResolver.settings.staticSetting(with: settingKey)) ?? [:]
        let config = settingValue[ConfigConst.reportConfig] as? [String: Any] ?? [:]
        reportInterval = config[ConfigConst.reportInterval] as? Int ?? 0
        errorReportCount = config[ConfigConst.errorReportCount] as? Int ?? 3
        errorPrintCount = config[ConfigConst.errorPrintCount] as? Int ?? 100
        
        DocsLogger.info("config updated. jsonEnabled:\(jsonEnabled), config:\(config)", component: LogComponents.newCache)
    }
    
    /// 仅供单测使用
    func setJSONEnabled(_ enabled: Bool) {
        jsonEnabled = enabled
    }
}

private class NewCacheSerializeReporter: NewCacheSerializationDelegate {
    
    private var nscodingEncodeRecord = Record(operationType: "nscoding_encode")
    private var nscodingDecodeRecord = Record(operationType: "nscoding_decode")
    private var jsonEncodeRecord = Record(operationType: "json_encode")
    private var jsonDecodeRecord = Record(operationType: "json_decode")
    
    private var lastReportDate = Date.distantPast // 上次上报时间
    
    private let config: ConfigProvider
    
    private struct Record {
        let operationType: String
        var totalCount: SafeAtomic<Int> = 0 + .semaphore // 总次数
        var successCount: SafeAtomic<Int> = 0 + .semaphore // 成功次数
        var errorList = SafeArray<Error>([], synchronization: .semaphore) // 失败记录
        
        mutating func clear() {
            totalCount.value = 0
            successCount.value = 0
            errorList.removeAll()
        }
    }
    
    init(config: ConfigProvider) {
        self.config = config
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func didEncode(type: NewCacheSerializeType, error: Error?) {
        var record: Record
        switch type {
        case .nsCoding:
            record = nscodingEncodeRecord
        case .json:
            record = jsonEncodeRecord
        }
        updateRecord(&record, error: error)
    }
    
    func didDecode(type: NewCacheSerializeType, error: Error?) {
        var record: Record
        switch type {
        case .nsCoding:
            record = nscodingDecodeRecord
        case .json:
            record = jsonDecodeRecord
        }
        updateRecord(&record, error: error)
    }
    
    private func updateRecord(_ record: inout Record, error: Error?) {
        record.totalCount.value = record.totalCount.value + 1
        if let error = error {
            record.errorList.append(error)
        } else {
            record.successCount.value = record.successCount.value + 1
        }
    }
    
    @objc
    private func onEnterForeground() {
        guard config.reportConfigValid else {
            DocsLogger.info("reportInterval inValid", component: LogComponents.newCache)
            return
        }
        let interval = config.reportInterval
        let needReport = Date().timeIntervalSince(lastReportDate) > TimeInterval(interval)
        if needReport {
            lastReportDate = Date()
            DispatchQueue.global().async { // 避免卡主线程
                self.report()
            }
        }
    }
}

extension NewCacheSerializeReporter {
    
    private func report() {
        reportSingle(record: nscodingEncodeRecord)
        reportSingle(record: nscodingDecodeRecord)
        reportSingle(record: jsonEncodeRecord)
        reportSingle(record: jsonDecodeRecord)
        
        nscodingEncodeRecord.clear()
        nscodingDecodeRecord.clear()
        jsonEncodeRecord.clear()
        jsonDecodeRecord.clear()
    }
    
    private func reportSingle(record: Record) {
        var params = [String: Any]()
        // FG状态
        params[ConfigConst.fgEnable] = config.jsonEnabled ? 1 : 0
        // 总次数
        params[ConfigConst.total] = record.totalCount.value
        // 操作类型
        params[ConfigConst.operation] = record.operationType
        // 成功次数
        params[ConfigConst.success] = record.successCount.value
        // 失败Tops
        var errorDict = [Int: [Error]]() // key: 错误码, value: Error数组
        record.errorList.forEach { error in
            let code = (error as NSError).code
            var array = errorDict[code] ?? []
            array.append(error)
            errorDict[code] = array
        }
        let sortedErrors = errorDict.sorted { pair1, pair2 in
            pair1.value.count > pair2.value.count // 按次数多->少排序
        }
        let errorReportMaxCount = config.errorReportCount
        let errorPrintMaxCount = config.errorPrintCount
        sortedErrors.enumerated().forEach { item in
            let i = item.offset
            if i < errorReportMaxCount {
                params[ConfigConst.errCode(i)] = "\(item.element.key)"
                params[ConfigConst.errCount(i)] = item.element.value.count
            }
            item.element.value.enumerated().forEach { errorItem in
                if errorItem.offset < errorPrintMaxCount {
                    let nsError = errorItem.element as NSError
                    var logDict = nsError.userInfo
                    logDict["code"] = nsError.code
                    logDict["domain"] = nsError.domain
                    logDict["errDesc"] = nsError.localizedDescription
                    DocsLogger.info(logDict.description, component: LogComponents.newCache)
                }
            }
        }
        DocsTracker.newLog(event: ConfigConst.teaEvent, parameters: params) // Tea埋点
        DocsLogger.info("report [\(ConfigConst.teaEvent)], params:\(params)", component: LogComponents.newCache)
    }
}

// MARK: Extension
private extension NSError {
    
    func mergedUserInfo(_ dict: [String: Any]) -> NSError {
        var currentUserInfo = userInfo
        dict.forEach { (key, value) in
            currentUserInfo[key] = value
        }
        return NSError(domain: domain, code: code, userInfo: currentUserInfo)
    }
}
