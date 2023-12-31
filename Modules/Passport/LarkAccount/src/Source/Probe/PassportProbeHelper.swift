//
//  PassportProbeHelper.swift
//  LarkAccount
//
//  Created by au on 2021/10/11.
//

import Foundation
import EEAtomic
import LKTracing
import AppContainer
import LarkEnv
import ThreadSafeDataStructure

/// 用于上报时组装通用内容的 Key
struct ProbeConst {
    // 通用 Key
    static let traceID = "trace_id"
    static let env = "env"
    static let deviceID = "device_id"
    static let messageID = "msg_id"
    static let userID = "user_id"
    static let tenantID = "tenant_id"
    static let contactPoint = "cp"
    static let step = "step"
    static let xRequestID = "x_request_id"
    static let xTTLogID = "x_tt_logid"
    static let file = "file"
    static let function = "function"
    static let line = "line"

    // 用于日志
    static let logLevel = "log_level"
    static let message = "msg"
    static let additionalData = "additional_data"

    static let eventNetworkRequest = "n_net_request"
    static let eventNetworkResponse = "n_net_response"
    static let eventNetworkError = "n_net_error"

    // 用于监控
    static let monitorScene = "monitor_scene"
    static let apiPath = "api_path"
    static let tagName = "tag_name"
    static let stepName = "step_name"
    static let stageName = "stage_name"
    static let nextStep = "next_step"
    static let loginStatus = "login_status"
    static let duration = "duration"
    static let loginType = "login_type"
    static let flowType = "flow_type"
    static let carrier = "carrier"
    static let qrloginState = "qrlogin_state"
    static let bizCode = "biz_code"

    // 自 v6.1 起启用的监控埋点 event
    static let monitorEventName = "passport_client_event"

    // login type
    static let type = "type"
    static let outside = "outside"
    static let inside = "inside"

    // idp channel
    static let channel = "channel"
    static let companyInfo = "company_info"
    static let idpEnterprise = "enterprise"
    static let idpGoogle = "google"
    static let idpApple = "apple"

    // logout
    static let logoutType = "logout_type"
    static let logoutUserType = "logout_user_type"
    static let logoutReason = "logout_reason"

    static let commonInternalErrorCode = "-1"
    static let commonUserActionErrorCode = "4233" // 由用户操作等原因导致的失败，不计入归因
    
    /// Authorization scene.
    static let authorizationType = "type"
    
    static let authorizationPageType = "page"
    
    static let scheme = "scheme"
}

// 用于区分用户操作导致的错误，例如密码输错等
struct ProbeUserOperationError {
    let errorCode: String
    let errorMsg: String

    static let userIsPending = ProbeUserOperationError(errorCode: "83001", errorMsg: "select user error: pending")
}

final class ProbeDurationHelper {

    @AtomicObject
    private static var starts = [String: Date]()

    static func startDuration(_ tag: String) {
        guard !tag.isEmpty else {
            assertionFailure("Tag is empty")
            return
        }
        Self.starts[tag] = Date()
    }

    static func stopDuration(_ tag: String, invalidate: Bool = true) -> Int {
        guard let start = Self.starts[tag] else {
            return 0
        }
        if invalidate {
            Self.starts.removeValue(forKey: tag)
        }
        return Int(Date().timeIntervalSince(start) * 1000)
    }
}

extension ProbeDurationHelper {
    static let logoutPrimaryFlow = "logoutPrimaryFlow"
    static let logoutRequestFlow = "logoutRequestFlow"
    static let logoutPostTaskFlow = "logoutPostTaskFlow"
    static let logoutRustFlow = "logoutRustFlow"
    static let logoutOfflinePrimaryFlow = "logoutOfflinePrimaryFlow"
    static let logoutOfflineRequestFlow = "logoutOfflineRequestFlow"

    static let loginQRCodeVerifyFlow = "loginQRCodeVerifyFlow"
    static let loginOneKeyTokenFlow = "loginOneKeyTokenFlow"
    static let loginOneKeyVerifyFlow = "loginOneKeyVerifyFlow"
    static let loginIdpPrepareFlow = "loginIdpPrepareFlow"
    static let loginIdpVerifyFlow = "loginIdpVerifyFlow"
    static let loginCommonFlow = "loginCommonFlow"

    static let chooseTenantFlow = "chooseTenantFlow"

    static let enterAppFlow = "enterAppFlow"

    static let oneKeyLoginPrepareFlow = "oneKeyLoginPrepareFlow"
    static let onekeyLoginNumberPrefetchFlow = "onekeyLoginNumberPrefetchFlow"
}

final class PassportProbeHelper {

    static let shared = PassportProbeHelper()

    /// 当前 CP，在 CP 输入页确认时更新
    var contactPoint: String?

    /// 当前 step，在各个页面 viewDidLoad 更新
    var currentStep: String?

    var userID: String?

    var tenantID: String?
    
    var deviceID: String {
        (useUniDID ? uniDeviceID : deviceIDMap.value[unit]) ?? "Empty Device ID"
    }
    //是否使用统一did
    var useUniDID: Bool
    //统一did
    @AtomicObject
    var uniDeviceID: String?

    var env: String { EnvManager.env.unit }

    var hasAssembled: Bool { BootLoader.isDidFinishLaunchingFinished }

    private var deviceIDMap: SafeAtomic<[String: String]> = [:] + .readWriteLock

    private var unit: String { EnvManager.env.unit }

    private init() {
        appLifeTrace = LKTracing.newSpan(traceId: Self.sourceTrace)
        deviceIDMap.value = PassportStore.shared.deviceIDMap ?? [:]
        useUniDID = PassportStore.shared.universalDeviceServiceUpgraded
        uniDeviceID = PassportStore.shared.deviceID
    }

    func setDeviceID(_ deviceID: String, for unit: String) {
        deviceIDMap.value[unit] = deviceID
    }

    // MARK: Private

    /// 由 sourceTrace 拼接生成的 traceID，每次冷启动唯一
    /// 形如 1-9c15e100
    @AtomicObject
    private(set) var appLifeTrace: String

    private static let sourceTrace = "1"

}

extension PassportProbeHelper {
    static func getErrorCode(_ error: Error) -> String {
        let errorCode: String
        if let loginError = error as? V3LoginError {
            if case .badServerCode(let info) = loginError {
                errorCode = "\(info.type.rawValue)"
            } else {
                errorCode = "\(loginError.errorCode)"
            }
        } else {
            errorCode = ProbeConst.commonInternalErrorCode
        }
        return errorCode
    }
}

extension String {
    /// 加密，将传入字符串通过 aes 处理 \
    /// 使用了原先 UploadLogManager 封装的方法，具体加密机制和更多加密方式可以跳转见详情
    func encrypted() -> String {
        if isEmpty {
            return ""
        }
        return genAES(self)
    }

    /// 脱敏
    /// 字符数建议大于等于 4，少于 4 的会全部变成 *
    func desensitized() -> String {
        // 如果小于等于 4，输出等长的全部「*」
        if count <= 4 {
            return String(repeating: "*", count: count)
        }
        // 如果大于 4，保留前后各 12 位
        if count > 36 {
            return sessionDesensitized()
        }

        let quarter: Int = count / 4
        let head = self[..<self.index(self.startIndex, offsetBy: quarter)]
        let tail = self[self.index(self.endIndex, offsetBy: -quarter)...]
        let middle = self.dropFirst(head.count).dropLast(tail.count)
        let maskedMiddle = String(repeating: "*", count: middle.count)
        return head + maskedMiddle + tail
    }

    /// 请直接使用 desensitized() \
    /// 脱敏 sessionKey 和 token 等内容 \
    /// 保留前后各 12 位，中间使用 * 遮蔽，和 Android 及服务端相同处理
    fileprivate func sessionDesensitized() -> String {
        let kept: Int = 12
        let head = self[..<self.index(self.startIndex, offsetBy: kept)]
        let tail = self[self.index(self.endIndex, offsetBy: -kept)...]
        let middle = self.dropFirst(head.count).dropLast(tail.count)
        let maskedMiddle = String(repeating: "*", count: middle.count)
        return head + maskedMiddle + tail
    }

    /// 脱敏可能出现的手机号和邮箱
    func desensitizeCredential() -> String {
        self.desensitizeEmail().desensitizePhone()
    }

    /// 涉及到服务端可能下发邮箱信息的日志脱敏
    func desensitizeEmail() -> String {
        let originStr = self
        var targetStr = originStr
        if let regex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: .caseInsensitive) {
            let matches = regex.matches(in: originStr, range: NSMakeRange(0, originStr.count))
            for matchItem in matches {
                let emailStr = originStr.substring(in: matchItem.range)

                if let emailStr = emailStr {
                    // @ 符号向前取4位为掩码区间
                    let indexOfAt = emailStr.firstIndex(of: "@") ?? emailStr.endIndex
                    let firstHideIndex = emailStr.index(indexOfAt, offsetBy: -4, limitedBy: emailStr.startIndex) ?? emailStr.startIndex

                    // 掩码区间字符用 * 替换
                    var needDesensitizedStr = emailStr.substring(with: firstHideIndex ..< indexOfAt)
                    needDesensitizedStr = String(repeating: "*", count: needDesensitizedStr.count)

                    let desensitizedEmailStr = emailStr.replacingCharacters(in: firstHideIndex ..< indexOfAt, with: needDesensitizedStr)
                    targetStr = targetStr.replacingOccurrences(of: emailStr, with: desensitizedEmailStr)
                }
            }
        }
        return targetStr
    }

    /// 对于类似+86 12345678910的手机号格式脱敏
    func desensitizePhone() -> String {
        let originStr = self
        var targetStr = originStr
        if let regex = try? NSRegularExpression(pattern: "\\+(?:\\d{1,3})\\s\\d{7,15}", options: .caseInsensitive) {
            let matches = regex.matches(in: targetStr, range: NSMakeRange(0, originStr.count))
            for matchItem in matches {
                let phoneStr = targetStr.substring(in: matchItem.range)

                if let phoneStr = phoneStr {
                    // 空格向后取8位为掩码区间
                    let indexOfAt = phoneStr.firstIndex(of: " ") ?? phoneStr.startIndex
                    let lastHideIndex = phoneStr.index(indexOfAt, offsetBy: 8, limitedBy: phoneStr.endIndex) ?? phoneStr.startIndex

                    // 掩码区间字符用 * 替换
                    var needDesensitizedStr = phoneStr.substring(with: indexOfAt ..< lastHideIndex)
                    needDesensitizedStr = String(repeating: "*", count: needDesensitizedStr.count)

                    let desensitizedPhoneStr = phoneStr.replacingCharacters(in: indexOfAt ..< lastHideIndex, with: needDesensitizedStr)
                    targetStr = targetStr.replacingOccurrences(of: phoneStr, with: desensitizedPhoneStr)
                }
            }
        }
        return targetStr
    }
}
