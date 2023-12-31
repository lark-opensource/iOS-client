//
//  PassportLogProxy.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import LarkContainer

/// PassportLog 日志代理
/// 会在日志 category 前添加 `Passport` 前缀，用于将审查后的日志再次抛回 forwardLogger ，最终由全局的默认 LogProxy 进行消费
final class PassportLogProxy: LKCommonsLogging.Log {

    let type: Any
    let category: String
    var forwardLogger: LKCommonsLogging.Log

    init(_ type: Any, _ category: String, forwardTo logger: Log) {

        self.type = type as? AnyClass ?? Logger.self
        self.category = category
        // 经此 Proxy 处理后，日志被转发到真正的 Log 对象上
        self.forwardLogger = logger
    }

    func log(event: LKCommonsLogging.LogEvent) {
        if PassportProbeHelper.shared.hasAssembled &&
            PassportLogHelper.shared.enableLogByOPMonitor &&
            valid(event) {
            flushOPMonitor(event)
        }

        forwardLogger.log(logId: event.logId,
                          event.message,
                          params: event.params,
                          tags: event.tags,
                          level: event.level,
                          time: event.time,
                          error: event.error,
                          file: event.file,
                          function: event.function,
                          line: event.line)
    }

    func isDebug() -> Bool {
        return forwardLogger.isDebug()
    }

    func isTrace() -> Bool {
        return forwardLogger.isTrace()
    }

    // MARK: Private

    /// 避免数量过大和冗余信息，只有遵循新帐号模型下格式定义的日志会被上报
    private func valid(_ event: LKCommonsLogging.LogEvent) -> Bool {
        if let tag = event.tags.first,
           tag == PassportLogDistributionMethod.local.rawValue {
            return false
        }
        return true
    }

    private func flushOPMonitor(_ event: LKCommonsLogging.LogEvent) {

        let commonHelper = PassportProbeHelper.shared
        let logHelper = PassportLogHelper.shared

        let item = OPMonitor(code)

        // 添加 log 通用内容
        item
            .addCategoryValue(ProbeConst.traceID, commonHelper.appLifeTrace)
            .addCategoryValue(ProbeConst.messageID, logHelper.fetchMessageID())
            .addCategoryValue(ProbeConst.logLevel, event.level)
            .addCategoryValue(ProbeConst.message, event.message)
            .addCategoryValue(ProbeConst.additionalData, event.additionalData)
            .addCategoryValue(ProbeConst.env, commonHelper.env)
            .addCategoryValue(ProbeConst.deviceID, commonHelper.deviceID)
            .addCategoryValue(ProbeConst.file, event.file)
            .addCategoryValue(ProbeConst.function, event.function)
            .addCategoryValue(ProbeConst.line, event.line)

        // 添加身份信息
        if let cp = commonHelper.contactPoint {
            // CP 内容外部已加密，这里不需要再调用加密方法
            item.addCategoryValue(ProbeConst.contactPoint, cp)
        } else {
            item.addCategoryValue(ProbeConst.contactPoint, generatePlaceholderCP())
        }

        if let userID = commonHelper.userID {
            item.addCategoryValue(ProbeConst.userID, userID)
        }
        if let tenantID = commonHelper.tenantID {
            item.addCategoryValue(ProbeConst.tenantID, tenantID)
        }

        // 添加节点信息
        if let step = commonHelper.currentStep {
            item.addCategoryValue(ProbeConst.step, step)
        }

        // 添加网络请求信息
        if let map = event.additionalData, let requestID = map[ProbeConst.xRequestID] {
            item.addCategoryValue(ProbeConst.xRequestID, requestID)
        }

        item.flush()
    }

    /// 生成占位的 CP 值，用于排查时没有搜索索引的时候
    /// 生成逻辑：是否有前台用户 + 平台常量 + 系统版本
    private func generatePlaceholderCP() -> String {
        let uid = PassportProbeHelper.shared.userID
        let userStatusFlag = uid == nil ? "0" : "1"
        let iOSConst = "66"
        let osVersion = UIDevice.current.systemVersion
        let result = userStatusFlag + iOSConst + osVersion
        return genMD5(result)
    }

    private let code = EPMClientPassportUniversalCode.passport_universal_log
}
