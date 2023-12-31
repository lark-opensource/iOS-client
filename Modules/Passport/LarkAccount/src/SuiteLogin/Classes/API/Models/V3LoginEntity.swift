//
//  PassportStepEntity.swift
//  SuiteLogin
//
//  Created by lixiaorui on 2019/9/21.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkEnv

private let logger = Logger.log(PassportStep.self, category: "SuiteLogin.V3LoginEntity")

protocol PassportStepInfoProtocol {
    func pageInfo(with stepInfo: [String: Any]) -> ServerInfo?
}

// MARK: Server

enum V3LoginError: LocalizedError, CustomStringConvertible {
    case badServerCode(V3LoginErrorInfo)
    case clientError(String)
    case fetchDeviceIDFail(String)
    case resetEnvFail(String)
    /// 无法转换服务器返回的数据
    case badResponse(String)
    case server(Error)
    case transformJSON(Error)
    case badLocalData(String)
    case networkTimeout
    // Bool 控制是否显示无网络下提示 alert
    case networkNotReachable(Bool)
    case toastError(String)
    case alertError(String)

    case accountAppeal
    case userCanceled

    static let errorCodeUnknown: Int = -1
    static let errorCodeDefault: Int = 0

    static let errorCodeClient: Int = 20_001
    static let errorCodeFetchDeviceId: Int = 20_002
    static let errorCodeResetEnvFail: Int = 20_003
    static let errorCodeBadResponse: Int = 20_004
    static let errorCodeServer: Int = 20_005
    static let errorCodeTransformJSON: Int = 20_006
    static let errorCodeBadLocalData: Int = 20_007
    static let errorCodeNetworkNotReachable: Int = 20_008
    static let errorCodeToastError: Int = 20_009
    static let errorCodeAccountAppeal: Int = 20_010
    static let errorCodeUserCanceled: Int = 20_011
    static let errorCodeNetworkTimeout: Int = 20_012
    static let errorCodeAlertError: Int = 20_013

    // MARK: Convenience
    static let badServerData: V3LoginError = .badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData)

    public var loggerInfo: String {
        switch self {
        case .badServerCode: return"badServerCode"
        case .clientError: return "clientError"
        case .fetchDeviceIDFail: return "fetchDeviceIDFail"
        case .resetEnvFail: return "resetEnvFail"
            /// 无法转换服务器返回的数据
        case .badResponse: return "badResponse"
        case .server: return "server"
        case .transformJSON: return "transformJSON"
        case .badLocalData: return "badLocalData"
        case .networkNotReachable: return "networkNotReachable"
        case .toastError: return "toastError"
        case .accountAppeal: return  "accountAppear"
        case .userCanceled: return "userCanceled"
        case .networkTimeout: return "networkTimeout"
        case .alertError: return "alertError"
        }
    }

    public var description: String {
        switch self {
        case .badServerCode(let info):
            return "V3LoginError.badServerCode: \(info)"
        case .clientError(let des):
            return "V3LoginError.clientError: \(des)"
        case .fetchDeviceIDFail(let des):
            return "V3LoginError.fetchDeviceIDFail: \(des)"
        case .resetEnvFail(let des):
            return "V3LoginError.resetEnvFail: \(des)"
        /// 无法转换服务器返回的数据
        case .badResponse(let des):
            return "V3LoginError.badResponse: \(des)"
        case .server(let err):
            return "V3LoginError.server: \(err)"
        case .transformJSON(let err):
            return "V3LoginError.transformJSON: \(err)"
        case .badLocalData(let des):
            return "V3LoginError.badLocalData: \(des)"
        case .networkNotReachable:
            return "V3LoginError.networkNotReachable"
        case .networkTimeout:
            return "V3LoginError.networkTimeout"
        case .toastError(let msg):
            return "V3LoginError.toastError: \(msg)"
        case .accountAppeal:
            return "V3LoginError.accountAppear"
        case .userCanceled:
            return "V3LoginError.userCanceled"
        case .alertError(let msg):
            return "V3LoginError.alertError: \(msg)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .badResponse(let errorString):
            return errorString
        case .fetchDeviceIDFail(let errorString):
            return errorString
        case .server(let error):
            if (error as NSError).code != NSURLErrorCancelled {
                return error.localizedDescription
            } else {
                return nil
            }
        case .transformJSON(let error):
            return I18N.Lark_Passport_BadServerData
        case .resetEnvFail(let errorString):
            return errorString
        case .badServerCode(let errorInfo):
            return errorInfo.message
        case .networkNotReachable:
            return I18N.Lark_Login_ErrorMessageOfInternalNetwork
        case .networkTimeout:
            return I18N.Lark_Core_LoginNetworkErroe_Toast
        case .toastError(let msg):
            return msg
        case .alertError(let msg):
            return msg
        case .userCanceled:
            return ""
        default:
            return nil
        }
    }
}

/// 实现CustomNSError 支持桥接到 NSError 时有明确的 code、domain
/// 使用场景：OPMonitor 设置 Error 包含明确的code、domain，后端数据处理做error聚类
extension V3LoginError: CustomNSError {
    static var errorDomain: String { "client.passport" }

    /// The error code within the given domain.
    var errorCode: Int {
        switch self {
        case .badServerCode(let info):
            if let bizCode = info.bizCode {
                return Int(bizCode)
            } else {
                return Self.errorCodeUnknown
            }
        case .clientError:
            return Self.errorCodeClient
        case .fetchDeviceIDFail:
            return Self.errorCodeFetchDeviceId
        case .resetEnvFail:
            return Self.errorCodeResetEnvFail
        case .badResponse:
            return Self.errorCodeBadResponse
        case .server(let error):
            if (error as NSError).code == Self.errorCodeDefault {
                return Self.errorCodeServer
            } else {
                return (error as NSError).code
            }
        case .transformJSON:
            return Self.errorCodeTransformJSON
        case .badLocalData:
            return Self.errorCodeBadLocalData
        case .networkNotReachable:
            return Self.errorCodeNetworkNotReachable
        case .networkTimeout:
            return Self.errorCodeNetworkTimeout
        case .toastError:
            return Self.errorCodeToastError
        case .accountAppeal:
            return Self.errorCodeAccountAppeal
        case .userCanceled:
            return Self.errorCodeUserCanceled
        case .alertError:
            return Self.errorCodeAlertError
        }
    }

    /// The user-info dictionary.
    var errorUserInfo: [String: Any] {
        return [:]
    }
}

enum V3ServerBizError: Int32 {
    // 授权登录其他三个Code：1000 确认成功 1001 检查成功 1002 取消成功 目前成功 Code 都是 0 不使用这个
    case repeatedScan = 1003    // 授权登录 重复的扫码
    case isLoggingIn = 1004     // 授权登录 正在登录
    case tokenExpired = 1005    // 授权登录 Token 失效
    case rescanNeeded = 1006    // 授权登录 需要重新扫码

    case securityPasswordRetryLimited = 2001 // 安全密码重试太频繁
    case securityPasswordWrong = 2002   // 安全密码错误
    
    case securityCodeTooOften = 2008    // 安全密码功能，获取验证码太频繁
    case notCredentialContact = 4201    // 输入非账号，但是联系方式，弹窗提示用户使用关联账号或去注册的弹窗
    case verifyCodeError = 4202         // 验证码:已过期/错误
    case passwordError = 4203           // 密码错误
    case needCrossUnit = 4205       // 进行对端
    case applyCodeTooOften = 4206       // 获取验证码过于频繁，需要X秒后才能获取
    case loginMobileIllegal = 4208      // 飞书白板用户登录时输入非+86手机的case
    case contextExpired = 4209          // 上下文过期
    case captchaRequired = 4210         // 需要captcha
    case switchUserContextExpired = 4219// 切换租户上下文过期
    case rsaDecryptError = 4220         // 服务端RSA解密出错（目前传输密码使用）
    case noMobileCredential = 4222      // 没有手机登录凭证
    case oneKeyLoginServiceError = 4223 // 一键登录运营商服务异常
    case needNormalSwitch = 4224        // 需要从快切转为慢切
    case needTuringVerify = 4233        // 图灵验证（人机滑块验证）

    case linkIsWaitingForClick = 4251   // Magic Link 等待用户确认
    case linkIsExpired = 4253           // Magic Link 已失效

    case invalidUser = 4300             // user无效（不可登录，可能在上一步跳转到enter_app间状态发生了变化）

    case normalFormError = 4400         // 通用的表单错误，data中是出错的输入表单，可以在对应的输入框下直接展示message或者标红
    case normalToastError = 4401        // 通用的toast提示，直接展示message; 包括但不限于：
                                        // 请求无效（body无法解析、参数无法解析、参数不合法等，理论上不应发生）；
                                        // token失效（登录流程上下文丢失，可能是时间太长过期）
    case normalAlertError = 4402        // 通用的弹窗提示，直接展示message和确定点击按钮

    case serverError = 4500             // 服务器内部错误（包括但不限于数据库故障、redis故障等）
    case unknown = -1                   // 未知错误,暂定给-1
}

typealias EventBusVCHandler = (UIViewController?) -> Void
protocol V3LoginEntity {
    /// 服务端返回的信息, 从response的stepInfo解析出来的相应业务结构体
    var serverInfo: Codable? { get set }
    /// 客户端需要的额外的上下文信息，端上自己实现结构体
    var additionalInfo: Codable? { get set }
    /// 处理VC方式
    var vcHandler: EventBusVCHandler? { get set }
    /// 优先处理pop
    var backFirst: Bool? { get set }
    /// context
    var context: UniContextProtocol? { get set }
}

// MARK: - Base model



/*
class V3JoinTenantInfo: ServerInfo {
    var nextInString: String?
    let title: String
    let subtitle: String?
    let description: String?
    let joinTypes: [JoinTypeInfo]

    enum JoinType: Int, Codable {
        case inputTeamCode = 0
        case scanQRCode = 1

        static let tokenJoin: Int = 2 // 通过口令 join team
    }

    struct JoinTypeInfo: Codable {
        let title: String
        let type: JoinType
    }

    enum CodingKeys: String, CodingKey {
        case title, subtitle, description
        case joinTypes = "join_types"
    }

}
 */

struct V3LoginContext: V3LoginEntity {
    var serverInfo: Codable?
    var additionalInfo: Codable?
    var vcHandler: EventBusVCHandler?
    var backFirst: Bool?
    var context: UniContextProtocol?

    init(
        serverInfo: Codable? = nil,
        additionalInfo: Codable? = nil,
        vcHandler: EventBusVCHandler? = nil,
        backFirst: Bool? = nil,
        context: UniContextProtocol? = nil
    ) {
        self.serverInfo = serverInfo
        self.additionalInfo = additionalInfo
        self.vcHandler = vcHandler
        self.backFirst = backFirst
        self.context = context
    }
}

struct V3RawLoginContext {
    let stepInfo: [String: Any]?
    let additionalInfo: Codable?
    let vcHandler: EventBusVCHandler?
    let backFirst: Bool?
    let context: UniContextProtocol?

    init(
        stepInfo: [String: Any]? = nil,
        additionalInfo: Codable? = nil,
        vcHandler: EventBusVCHandler? = nil,
        backFirst: Bool? = nil,
        context: UniContextProtocol?
    ) {
        self.stepInfo = stepInfo
        self.additionalInfo = additionalInfo
        self.vcHandler = vcHandler
        self.backFirst = backFirst
        self.context = context
    }
}

// 服务端返回的错误信息，从response解析出来的错误信息结构体
struct V3LoginErrorInfo: CustomStringConvertible {
    var type: V3ServerBizError
    var message: String = ""
    var detail: [String: Any] = [:]
    var rawCode: Int32 = -1
    var bizCode: Int32?
    var logID: String?

    init?(dic: [String: Any]) {
        guard let code = dic[V3.Const.code] as? Int32 else {
            logger.error("V3LoginErrorInfo: can not init with code: \(String(describing: dic[V3.Const.code]))")
            return nil
        }
        if let bizCode = dic[V3.Const.bizCode] as? Int32 {
            self.bizCode = bizCode
        }
        self.type = V3ServerBizError(rawValue: code) ?? .unknown
        self.rawCode = code
        message = dic[V3.Const.message] as? String ?? ""
        // 取不到data, 取整个返回, 兼容V2接口
        detail = dic[V3.Const.data] as? [String: Any] ?? dic
    }

    init(type: V3ServerBizError) {
        self.type = type
    }

    init(type: V3ServerBizError, message: String) {
        self.type = type
        self.message = message
    }

    init(rawCode: Int32) {
        self.type = V3ServerBizError(rawValue: rawCode) ?? .unknown
        self.rawCode = rawCode
    }

    public var description: String {
        return "V3LoginErrorInfo type:\(type) message:\(message) detail:\(detail)"
    }

    // 脱敏后生成一个新的ErrorInfo，用于日志、埋点
    public var desensitizedInfo: V3LoginErrorInfo {
        var errorInfo = self
        errorInfo.message = errorInfo.message.desensitizeCredential()
        var desnsitizeDetail = detail
        for (key, value) in detail {
            if let str = value as? String {
                desnsitizeDetail[key] = str.desensitizeCredential()
            }
        }
        errorInfo.detail = desnsitizeDetail

        return errorInfo
    }
}

// 状态机 业务相关
class V3LoginInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    init(nextInString: String? = nil, flowType: String? = nil, usePackageDomain: Bool? = nil) {
        self.nextInString = nextInString
        self.flowType = flowType
        self.usePackageDomain = usePackageDomain
    }

    static let `default` = V3LoginInfo(nextInString: nil)
}

class V3VerifyInfo: VerifyInfoBase<PassportStep> {}

class V4VerifyInfo: V4VerifyInfoBase<PassportStep> {}

class V3RecoverAccountCarrierInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case sourceType = "source_type"
        case unit = "unit"
        case rsaInfo = "rsa_info"
        case method
        case appealUrl = "appeal_url"
        case flowType = "flow_type"
    }

    var title: String?
    var subTitle: String?
    var sourceType: Int?
    var unit: String?
    var rsaInfo: RSAInfo
    var method: RecoverAccountMethod?
    var appealUrl: String?

    init(rsaInfo: RSAInfo) {
        self.rsaInfo = rsaInfo
    }
}

class V4RetrieveOpThreeInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "sub_tile"
        case nameInputDeco = "name_input"
        case idInputDeco = "id_input"
        case policyPrefix = "policy_describe_prefix"
        case policyName = "policy_name"
        case policyDomain = "policy_domain"
        case appealHint = "bottom_hint"
        case unit = "unit"
        case appealUrl = "appeal_url"
        case rsaKey = "public_key"
        case rsaToken = "rsa_token"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }

    var title: String?
    var subTitle: String?
    var nameInputDeco: inputDeco?
    var idInputDeco: inputDeco?
    var policyPrefix: String?
    var policyName: String?
    var policyDomain: String
    var appealHint: String?
    var appealUrl: String?
    var rsaKey: String?
    var rsaToken: String?
    var unit: String?
    
    struct inputDeco: Codable{
        var placeholder: String?
        
        enum CodingKeys: String, CodingKey {
            case placeholder = "placeholder"
        }
    }
}

class V3RecoverAccountBankInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case name = "name"
        case rsaInfo = "rsa_info"
    }

    var title: String?
    var subTitle: String?
    var name: String?
    var rsaInfo: RSAInfo
}

class V3RecoverAccountFaceInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case identityNumber = "identity_number"
        case ticket = "ticket"
        case sourceType = "source_type"
    }

    var name: String?
    var identityNumber: String?
    var ticket: String?
    var sourceType: Int?
}

class V3RecoverAccountChooseInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case name = "name"

        case bottomTitle = "bottom_title"
        case buttonTitle = "button_title"
        case sourceType = "source_type"
    }

    var title: String?
    var subTitle: String?
    var name: String?

    /// verify face
    var bottomTitle: String?
    var buttonTitle: String?
    var sourceType: Int?

    var recoverAccountBankInfo: V3RecoverAccountBankInfo?
    var verifyFaceInfo: V3RecoverAccountFaceInfo?
}

class V3SetInputCredentialInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var title: String?
    var subTitle: String?
    var sourceType: Int?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case sourceType = "source_type"
        case flowType = "flow_type"
    }
}

struct V3TenantInfo: Codable {
    let id: String
    let name: String
    let iconUrl: String
    let domain: String
    let fullDomain: String?
    let tip: String?
    let tag: TenantTag?
    let status: Int?
    let singleProductTypes: [TenantSingleProductType]?

    enum CodingKeys: String, CodingKey {
        case id = "tenant_id"
        case name
        case iconUrl = "icon_url"
        case domain = "tenant_domain"
        case fullDomain = "suite_full_domain"
        case tip
        case tag
        case status
        case singleProductTypes = "single_product_types"
    }

    enum Status: Int, Codable {
        case normal
        case full

        static let defaultValue: Status = .normal

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .defaultValue
        }
    }
}

extension V3TenantInfo: CustomStringConvertible, LogDesensitize {
    struct Const {
        static let emptyValue: String = "empty"
    }
    var description: String {
        return "\(desensitize())"
    }

    func desensitize() -> [String: String] {
        let tagValue: String
        if let tag = tag {
            tagValue = "\(tag)"
        } else {
            tagValue = Const.emptyValue
        }
        return [
            CodingKeys.id.rawValue: id,
            CodingKeys.domain.rawValue: domain,
            CodingKeys.tag.rawValue: tagValue
        ]
    }
}

struct V3SecurityConfigItem: Codable {
    enum CodingKeys: String, CodingKey {
        case switchStatus = "switch_status"
        case moduleInfoJSON = "module_info"
    }
    public let switchStatus: Int
    public let moduleInfoJSON: String

    public var moduleInfo: [String: String] {
        do {
            let info = try moduleInfoJSON.asDictionary()
            return info as? [String: String] ?? V3SecurityConfigItem.moduleInfoDefaultValue
        } catch {
            return V3SecurityConfigItem.moduleInfoDefaultValue
        }
    }

    public static let statusDefaultValue: Int = 1
    public static let statusIsOn: Int = 1
    public static let statusIsOff: Int = 0
    public static let moduleInfoJSONDefaultValue: String = "{}"
    public static let moduleInfoDefaultValue: [String: String] = [:]

    public var isOn: Bool {
        return switchStatus == V3SecurityConfigItem.statusIsOn
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let status = try? container.decode(Int.self, forKey: .switchStatus) {
            switchStatus = status
        } else {
            switchStatus = V3SecurityConfigItem.statusDefaultValue
        }
        // from server
        if let moduleInfo = try? container.decode([String: Any].self, forKey: .moduleInfoJSON).jsonString() {
            moduleInfoJSON = moduleInfo
        // from locale storage
        } else if let moduleInfo = try? container.decode(String.self, forKey: .moduleInfoJSON) {
            moduleInfoJSON = moduleInfo
        } else {
            moduleInfoJSON = V3SecurityConfigItem.moduleInfoJSONDefaultValue
        }
    }

    public init(status: Int, moduleInfo: [String: String]) {
        self.switchStatus = status
        self.moduleInfoJSON = moduleInfo.jsonString()
    }

    public static var placeholder: V3SecurityConfigItem {
        return V3SecurityConfigItem(
            status: V3SecurityConfigItem.statusDefaultValue,
            moduleInfo: V3SecurityConfigItem.moduleInfoDefaultValue
        )
    }

}

struct V3SecurityConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case modifyPwd = "module_modify_pwd"
        case accountManagement = "module_account_management"
        case securityVerification = "module_security_verification"
        case deviceManagement = "module_device_management"
        case twoFactorAuth = "module_2fa"
        case bioAuthLogin = "module_bio_auth_login"
        case bioAuth = "module_bio_auth"
    }

    public let modifyPwd: V3SecurityConfigItem
    public let accountManagement: V3SecurityConfigItem
    public let securityVerification: V3SecurityConfigItem
    public let deviceManagement: V3SecurityConfigItem
    public let twoFactorAuth: V3SecurityConfigItem
    public let bioAuthLogin: V3SecurityConfigItem
    public let bioAuth: V3SecurityConfigItem

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modifyPwd = (try? container.decode(V3SecurityConfigItem.self, forKey: .modifyPwd)) ?? .placeholder
        accountManagement = (try? container.decode(V3SecurityConfigItem.self, forKey: .accountManagement)) ?? .placeholder
        securityVerification = (try? container.decode(V3SecurityConfigItem.self, forKey: .securityVerification)) ?? .placeholder
        deviceManagement = (try? container.decode(V3SecurityConfigItem.self, forKey: .deviceManagement)) ?? .placeholder
        twoFactorAuth = (try? container.decode(V3SecurityConfigItem.self, forKey: .twoFactorAuth)) ?? .placeholder
        bioAuthLogin = (try? container.decode(V3SecurityConfigItem.self, forKey: .bioAuthLogin)) ?? .placeholder
        bioAuth = (try? container.decode(V3SecurityConfigItem.self, forKey: .bioAuth)) ?? .placeholder
    }

    public init(
        modifyPwd: V3SecurityConfigItem,
        accountManagement: V3SecurityConfigItem,
        securityVerification: V3SecurityConfigItem,
        deviceManagement: V3SecurityConfigItem,
        twoFactorAuth: V3SecurityConfigItem,
        bioAuthLogin: V3SecurityConfigItem,
        bioAuth: V3SecurityConfigItem
    ) {
        self.modifyPwd = modifyPwd
        self.accountManagement = accountManagement
        self.securityVerification = securityVerification
        self.deviceManagement = deviceManagement
        self.twoFactorAuth = twoFactorAuth
        self.bioAuthLogin = bioAuthLogin
        self.bioAuth = bioAuth
    }

    public static var placeholder: V3SecurityConfig {
        return V3SecurityConfig(
            modifyPwd: .placeholder,
            accountManagement: .placeholder,
            securityVerification: .placeholder,
            deviceManagement: .placeholder,
            twoFactorAuth: .placeholder,
            bioAuthLogin: .placeholder,
            bioAuth: V3SecurityConfigItem(
                status: V3SecurityConfigItem.statusIsOn,
                moduleInfo: V3SecurityConfigItem.moduleInfoDefaultValue
            )
        )
    }
}

extension V3SecurityConfig: CustomStringConvertible {
    public var description: String {
        let content: [String: Bool] = [
            CodingKeys.modifyPwd.rawValue: modifyPwd.isOn,
            CodingKeys.accountManagement.rawValue: accountManagement.isOn,
            CodingKeys.securityVerification.rawValue: securityVerification.isOn,
            CodingKeys.deviceManagement.rawValue: deviceManagement.isOn,
            CodingKeys.twoFactorAuth.rawValue: twoFactorAuth.isOn
        ]
        return content.description
    }
}

struct V3DerivedUser: Codable {
    /// session for a user
    let suiteSessionKey: String
    /// sessions for a user to plant cookie
    ///  e.g. {
    ///        "larksuite.com": {
    ///            "name": "session",
    ///            "value": "XN0YXJ0-784dccfa-5d29-44a5-b59e-dc20598a90dg-WVuZA"
    ///        }
    ///      }
    let suiteSessionKeys: [String: [String: String]]
    /// logout token for a user
    let logoutToken: String

    enum CodingKeys: String, CodingKey {
        case suiteSessionKey = "suite_session_key"
        case suiteSessionKeys = "suite_session_keys"
        case logoutToken = "logout_token"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suiteSessionKey = try container.decode(String.self, forKey: .suiteSessionKey)
        suiteSessionKeys = (try? container.decode([String: [String: String]].self, forKey: .suiteSessionKeys)) ?? [:]
        logoutToken = try container.decode(String.self, forKey: .logoutToken)
    }

    init(
        suiteSessionKey: String,
        suiteSessionKeys: [String: [String: String]],
        logoutToken: String
    ) {
        self.suiteSessionKey = suiteSessionKey
        self.suiteSessionKeys = suiteSessionKeys
        self.logoutToken = logoutToken
    }
}

extension V3DerivedUser: CustomStringConvertible, LogDesensitize {
    struct Const {
        static let sessionKeyLength: String = "session_key_length"
        static let sessionKeysLength: String = "session_keys_length"
        static let logoutTokenLength: String = "logout_token_length"
    }
    var description: String { "\(desensitize())" }

    func desensitize() -> [String: String] {
        return [
            Const.sessionKeyLength: "\(suiteSessionKey.count)",
            Const.sessionKeysLength: "\(V3DerivedUser.desensitize(suiteSessionKeys))",
            Const.logoutTokenLength: "\(logoutToken.count)"
        ]
    }
    static func desensitize(_ sessionKeys: [String: [String: String]]) -> [String: [String: String]] {
        return sessionKeys.mapValues { $0.mapValues { "\($0.count)" } }
    }
}

public struct V3UserInfo: Codable {

    struct Const {
        static let defaultTenanttId: String = "0"
        static let defaultSession: String = ""
        static let defaultSubDomain: String = "www"
        static let defaultTenantIconUrl: String = ""
        static let emptyValue: String = "empty"
        static let defaultIsBIdp: Bool = false
        static let defaultIsGuest: Bool = false
    }

    /// id
    var id: String
    /// 用户名
    var name: String
    /// 国际化用户名
    var i18nName: I18nName?
    /// 激活
    var active: Bool
    /// 冻结
    var frozen: Bool
    /// c端用户
    var c: Bool?
    /// 头像url
    var avatarUrl: String
    /// 头像资源key
    var avatarKey: String
    /// 用户的环境，仅在Passport内使用
    /// - value: feishu、lark
    /// - 用途: passport v3 config, 根据env确定使用的配置
    var env: String
    /// 用户数据的数据单元
    var unit: String?
    /// 租户信息
    var tenant: V3TenantInfo?
    var status: Int?
    var tip: String?
    /// B端 IdP 用户
    var bIdp: Bool?
    /// 游客User
    var guest: Bool?
    /// 账号设置
    var securityConfig: V3SecurityConfig?
    /// 用户 的 Session
    var session: String?
    /// Cross Unit 种Cookie使用的Session
    var sessions: [String: [String: String]]?
    /// 离线登出Token
    var logoutToken: String?
    /// 是否可以升级团队
    /// 场景：教育需求，家长不能升级团队
    var upgradeEnabled: Bool?
    /// 认证模式
    /// - https://bytedance.feishu.cn/docs/doccnwHy8dE79Yz8YpyZklsMR8b
    /// - value: strict、general
    ///     - strict: 切换到IdP认证
    ///     - general: 无需认证直接切换
    var authnMode: String?

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "name"
        case i18nName = "i18n_name"
        case active = "is_active"
        case frozen = "is_frozen"
        case c = "is_c"
        case avatarUrl = "avatar_url"
        case avatarKey = "avatar_key"
        case env = "user_env"
        case unit = "user_unit"
        case tenant = "tenant"
        case status = "user_status"
        case tip
        case bIdp = "is_idp"
        case guest = "is_guest"
        case securityConfig = "account_security_config"
        case session = "session"
        case sessions = "sessions"
        case logoutToken = "logout_token"
        case upgradeEnabled = "upgrade_enabled"
        case authnMode = "authn_mode"
    }

    var cUser: Bool {
        if let isC = c {
            return isC
        }
        guard let tenant = tenant else {
            return true
        }
        if tenant.id.isEmpty {
            return true
        }
        if tenant.id == Const.defaultTenanttId {
            return true
        }
        return false
    }

    var canUpgradeTeam: Bool {
        upgradeEnabled ?? (tenant?.tag == .simple)
    }

    var singleProductTypes: [TenantSingleProductType]? {
        return tenant?.singleProductTypes
    }

    func getTenantId() -> String {
        return tenant?.id ?? Const.defaultTenanttId
    }

    func getStatus() -> Status {
        return V3UserInfo.getStatus(from: status)
    }

    static func getStatus(from rawValue: Int?) -> Status {
        if let status = rawValue {
            return Status(rawValue: status) ?? .defaultValue
        } else {
            // empty raw value (low version) as enable user
            return .enable
        }
    }

    enum Status: Int, Codable {
        case unknown = -1
        case enable = 0
        case suspended = 1
        case pending = 2
        case forbidden = 3

        static let defaultValue: Status = .unknown

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .defaultValue
        }
    }

    public func merge(userInfo: V3UserInfo) -> V3UserInfo {
        var currentUserInfo = self
        currentUserInfo.id = userInfo.id
        currentUserInfo.tenant = userInfo.tenant
        if let session = userInfo.session,
            !session.isEmpty {
            currentUserInfo.session = userInfo.session
        }
        if let sessions = userInfo.sessions,
            !sessions.isEmpty {
            currentUserInfo.sessions = userInfo.sessions
        }
        if let logoutToken = userInfo.logoutToken {
            currentUserInfo.logoutToken = logoutToken
        }
        currentUserInfo.env = userInfo.env
        if let unit = userInfo.unit {
            currentUserInfo.unit = unit
        }
        if let securityConfig = userInfo.securityConfig {
            currentUserInfo.securityConfig = securityConfig
        }
        if let bIdp = userInfo.bIdp {
            currentUserInfo.bIdp = bIdp
        }
        currentUserInfo.frozen = userInfo.frozen
        currentUserInfo.active = userInfo.active
        if let guest = userInfo.guest {
            currentUserInfo.guest = guest
        }
        if let upgradeEnable = userInfo.upgradeEnabled {
            currentUserInfo.upgradeEnabled = upgradeEnable
        }
        return currentUserInfo
    }
}

extension V3UserInfo {

    var isActive: Bool {
        return active
    }

    var isFrozen: Bool {
        return frozen
    }

    var tenantID: String {
        return getTenantId()
    }

    var userEnv: String? {
        return env
    }

    static func getUserUnit(_ userUnit: String?, userEnv: String?) -> String {
        if let unit = userUnit {
            return unit
        } else if let env = userEnv {
            switch env {
            case V3ConfigEnv.feishu:
                return Unit.NC
            case V3ConfigEnv.lark:
                return Unit.EA
            default:
                V3LoginService.logger.info("unknown userEnv, fall through use EnvManager unit")
                return EnvManager.env.unit
            }
        } else {
            V3LoginService.logger.info("empty userEnv, fall through use EnvManager unit")
            return EnvManager.env.unit
        }
    }
}

extension V3UserInfo: CustomStringConvertible, LogDesensitize {

    public var description: String {
        return "\(desensitize())"
    }

    func desensitize() -> [String: String] {
        return [
            CodingKeys.id.rawValue: id,
            CodingKeys.active.rawValue: SuiteLoginUtil.serial(value: active),
            CodingKeys.c.rawValue: SuiteLoginUtil.serial(value: c),
            CodingKeys.avatarKey.rawValue: avatarKey,
            CodingKeys.env.rawValue: SuiteLoginUtil.serial(value: env),
            CodingKeys.unit.rawValue: SuiteLoginUtil.serial(value: unit),
            CodingKeys.tenant.rawValue: SuiteLoginUtil.serial(value: tenant),
            CodingKeys.status.rawValue: SuiteLoginUtil.serial(value: status),
            CodingKeys.securityConfig.rawValue: SuiteLoginUtil.serial(value: securityConfig),
            CodingKeys.bIdp.rawValue: SuiteLoginUtil.serial(value: bIdp),
            CodingKeys.upgradeEnabled.rawValue: SuiteLoginUtil.serial(value: upgradeEnabled),
            CodingKeys.authnMode.rawValue: SuiteLoginUtil.serial(value: authnMode)
        ]
    }
}

struct V3UserGroup: Codable {
    let users: [V3UserInfo]

    enum CodingKeys: String, CodingKey {
        case users
    }
}

class V3UserListInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String?
    let subTitle: String?
    let currentEnv: String
    let lastUsrId: String
    let userGroup: V3UserGroup?
    let extraIdentity: ExtraIdentity?
    let innerIdentity: V3InnerIdentity?
    let currentUserId: String?  // 服务端指定当前应该登录哪个User

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case currentEnv = "current_env"
        case lastUsrId = "last_user_id"
        case userGroup = "user_list"
        case innerIdentity = "inner_identity"
        case extraIdentity = "extra_identity"
        case currentUserId = "current_user_id"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }

    var users: [V3UserInfo] {
        if let userGroup = userGroup {
            return userGroup.users.filter({ $0.getStatus() != .unknown })
        }
        return []
    }

    var enableUsers: [V3UserInfo] {
        return users.filter { $0.getStatus() == .enable }
    }
}

// MARK: - InnerIdentity
struct V3InnerIdentity: Codable {
    let xPassportToken: String
    let identification: String?

    enum CodingKeys: String, CodingKey {
        case xPassportToken = "X-Passport-Token"
        case identification = "identification"
    }
}

class IDPLoginInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let url: String
    let securityId: String?
    let openMethod: String?
    let landURL: String?
    let preConfigJSON: String
    let authenticationChannel: LoginCredentialIdpChannel?
    let stateTokenKey: String?
    let sourceType: Int? // 1: 登录认证；2：切换租户认证；3: idp登录凭证管理
    let queryScope: String?

    init(url: String, securityId: String?, openMethod: String?, landURL: String?, preConfigJSON: String, authenticationChannel: LoginCredentialIdpChannel?, stateTokenKey: String?, sourceType: Int?, queryScope: String?, flowType: String? = nil, usePackageDomain: Bool? = nil) {
        self.url = url
        self.securityId = securityId
        self.openMethod = openMethod
        self.landURL = landURL
        self.preConfigJSON = preConfigJSON
        self.authenticationChannel = authenticationChannel
        self.stateTokenKey = stateTokenKey
        self.sourceType = sourceType
        self.queryScope = queryScope
        self.flowType = flowType
    }

    static func from(_ dict: [String: Any]) -> IDPLoginInfo {
        if (dict["url"] as? String) == nil {
            V3LoginService.logger.error("not has url in stepInfo")
        }

        let url = dict["url"] as? String ?? ""
        let securityId = dict["security_id"] as? String
        let openMethod = dict["open_with"] as? String
        let landURL = dict["land_url"] as? String
        let preConfig = dict["pre_config"] as? [String: Any] ?? [:]
        let authenticationChannel = LoginCredentialIdpChannel(rawValue: dict["channel"] as? String ?? "")
        let stateTokenKey = dict["state_token_key"] as? String ?? ""
        let sourceType = dict["source_type"] as? Int
        let queryScope = dict["query_scope"] as? String ?? ""
        return IDPLoginInfo(url: url, securityId: securityId, openMethod: openMethod, landURL: landURL, preConfigJSON: preConfig.jsonString(), authenticationChannel: authenticationChannel, stateTokenKey: stateTokenKey, sourceType: sourceType, queryScope: queryScope)
    }
}

class V3CreateTenantInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String?      // success b use so use optional
    let subTitle: String?   // success b use so use optional
    let img: String?
    let userId: String?
    let userUnit: String?
    let tenantNameInput: V3InputContainerInfo?
    let userNameInput: V3InputContainerInfo?
    let staffSizeInput: V3InputContainerInfo?
    let industryTypeInput: V3InputContainerInfo?
    let supportedRegionInput: V3InputContainerInfo?
    let staffSizeList: [V3StaffScale]?
    let industryTypeList: [V3Industry]?
    let supportedRegionList: [Region]?
    let topRegionList: [Region]?
    let currentRegion: String?
    let beforeSelectRegionText: String?
    let afterSelectRegionText: String?
    var name: String?
    var tenantType: Int?    // V3TenantInfo.Tag
    let nextButton: V4ButtonInfo?

    var needOptIn: Bool?
    var optInText: String?
    var optIn: Bool?

    var showTrustedMail: Bool?
    var trustedMailTitle: String?
    var trustedMailHover: String?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subTitle = "subtitle"
        case img = "img"
        case userId = "user_id"
        case userUnit = "user_unit"
        case tenantNameInput = "tenant_name_input"
        case userNameInput = "name_input"
        case staffSizeInput = "staff_size_input"
        case industryTypeInput = "industry_type_input"
        case supportedRegionInput = "supported_region_input"
        case staffSizeList = "staff_size_list"
        case industryTypeList = "industry_type_list"
        case supportedRegionList = "supported_region_list"
        case topRegionList = "top_region_list"
        case currentRegion = "current_region"
        case beforeSelectRegionText = "before_select_region_text"
        case afterSelectRegionText = "after_select_region_text"
        case name = "name"
        case tenantType = "tenant_type"
        case nextButton = "next_button"

        case needOptIn = "need_opt_in"
        case optInText = "opt_in_text"
        case optIn = "opt_in"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"

        case showTrustedMail = "show_trusted_mail"
        case trustedMailTitle = "trusted_mail_title"
        case trustedMailHover = "trusted_mail_hover"
    }

    var inputContainerInfoList: [V3InputContainerInfo] {
        var result: [V3InputContainerInfo] = []
        if var item = tenantNameInput {
            item.type = V3InputContainerType.tenantName
            result.append(item)
        }

        if var item = userNameInput {
            item.type = V3InputContainerType.userName
            result.append(item)
        }

        if var item = industryTypeInput {
            item.type = V3InputContainerType.industryType
            result.append(item)
        }

        if var item = staffSizeInput {
            item.type = V3InputContainerType.staffSize
            result.append(item)
        }

        if var item = supportedRegionInput,
           let list = supportedRegionList,
           !list.isEmpty {
            item.type = V3InputContainerType.region
            result.append(item)
        }

        return result
    }
}

struct V3Industry: Codable {
    let code: String
    let name: String
    let children: [V3Industry]?

    enum CodingKeys: String, CodingKey {
        case code
        case name = "i18n"
        case children
    }
}

struct V3StaffScale: Codable {
    let code: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case code
        case content = "i18n"
    }
}

struct V3InputContainerInfo: Codable, Equatable {
    var type: V3InputContainerType = .none
    let placeholder: String

    enum CodingKeys: String, CodingKey {
        case placeholder
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type && lhs.placeholder == rhs.placeholder
    }
}

enum V3InputContainerType: Int, Codable {
    case none
    case tenantName
    case userName
    case staffSize
    case industryType
    case region
}

// OneKeyLogin config https://bytedance.feishu.cn/docs/doccnC40ItPtYKTagysyz5tsSpe#
struct V3OneKeyLoginConfig: Codable {
    let policyURL: PolicyURL?
    let needPrefetch: NeedPrefetch?
    let sdkConfig: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case sdkConfig = "sdk_config"
        case policyURL = "policy_urls"
        case needPrefetch = "need_prefetch"
    }

    init(policyURL: PolicyURL? = nil,
         needPrefetch: NeedPrefetch? = nil,
         sdkConfig: [String: Any]? = nil) {
        self.policyURL = policyURL
        self.sdkConfig = sdkConfig
        self.needPrefetch = needPrefetch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.policyURL = try? container.decode(PolicyURL.self, forKey: .policyURL)
        self.sdkConfig = try? container.decode([String: Any].self, forKey: .sdkConfig)
        self.needPrefetch = try? container.decode(NeedPrefetch.self, forKey: .needPrefetch)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(policyURL, forKey: .policyURL)
        try container.encode(needPrefetch, forKey: .needPrefetch)
        // ignore other
    }

    struct PolicyURL: Codable {
        let mobile: String?
        let telecom: String?
        let unicom: String?
        static let defaultMobile = "https://wap.cmpassport.com/resources/html/contract.html"
        static let defaultTelecom = "https://e.189.cn/sdk/agreement/detail.do?hidetop=true"
        static let defaultUnicom = "https://opencloud.wostore.cn/authz/resource/html/disclaimer.html?fromsdk=true"
    }

    #if ONE_KEY_LOGIN
    func getPolicyURL(_ service: OneKeyLoginService) -> String {
        switch service {
        case .mobile: return policyURL?.mobile ?? PolicyURL.defaultMobile
        case .telecom: return policyURL?.telecom ?? PolicyURL.defaultTelecom
        case .unicom: return policyURL?.unicom ?? PolicyURL.defaultUnicom
        }
    }
    #endif

    struct NeedPrefetch: Codable {
        let mobile: Bool?
        let unicom: Bool?
        let telecom: Bool?

        static let defaultMobile: Bool = true
        // 目前联通连续两次取号稳定失败 不适用当前预取号策略 不进行预取号
        static let defaultUnicom: Bool = false
        static let defaultTelecom: Bool = true

        static let `default` = NeedPrefetch(mobile: Self.defaultMobile, unicom: Self.defaultUnicom, telecom: Self.defaultTelecom)
    }

    static let `default` = V3OneKeyLoginConfig()
}

/// 客户端配置的Config，服务端不关心，透传过来，服务不会给默认值
struct V3ClientBizConfig: Codable {
    struct GrayConfig: Codable {
        /// Per mille ‰
        let perMille: Int16

        enum CodingKeys: String, CodingKey {
            case perMille = "per_mille"
        }
        // 默认值全量关闭
        static let placeholder: GrayConfig = .init(perMille: 0)
    }
    let joinTeamHostWhitelist: [String]?
    let oneKeyLoginConfig: V3OneKeyLoginConfig?
    let h5URLConfig: [String: String]?
    let useAppLogDid: GrayConfig?
    let clearAppLogDid: GrayConfig?
    let recoverScene: String?
    let recoverAppId: String?
    let bioAuthScene: String?
    let bioAuthAppId: String?
    let realNameScene: String?
    let realNameAppId: String?
    let logByOPMonitor: Bool?
    let brandFromForegroundUser: Bool?
    let exportClientLogFile: Bool?
    let usePassportNavigator: Bool?
    let useNewSwitchInterruptProcess: Bool?
    let enableUserScope: Bool?
    let disableSessionInvalidDialogDuringLaunch: Bool?
    let enableInstallIDUpdatedSeparately: Bool?
    let enableUUIDAndNewStoreReset: Bool?
    let enableLazySetupEventRegister: Bool?
    let enableChangeGeo: Bool?
    let switchUserSwitchIdentityTimeout: Int?
    let tnsAuthURLRegex: String?
    let enableFetchDeviceIDForAllRequests: Bool?
    let enableLeftNaviButtonsRootVCOpt: Bool?
    let enableWebauthnNativeRegister: Bool?
    let enableWebauthnNativeAuth: Bool?
    let globalRegistrationTimeout: Int?
    let turingUsePkgDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case joinTeamHostWhitelist = "join_team_host_whitelist"
        case oneKeyLoginConfig = "onekey_login_config"
        case h5URLConfig = "h5_url_config"
        case useAppLogDid = "use_app_log_did"
        case clearAppLogDid = "clear_app_log_did"
        case recoverScene = "recover_scene"
        case recoverAppId = "recover_appid"
        case bioAuthScene = "bioauth_scene"
        case bioAuthAppId = "bioauth_appid"
        case realNameScene = "realname_scene"
        case realNameAppId = "realname_appid"
        /// 5.0 新启用，原 log_by_opmonitor 4.11 起上报数据量过大，永久关闭
        case logByOPMonitor = "log_by_opmonitor_ver_50"
        /// feishu 5.7.1 & lark 5.9 启用，控制 mg brand 修复
        case brandFromForegroundUser = "brand_from_foreground_user"
        /// 5.13 启用，控制状态栏点击 5 下导出日志功能
        case exportClientLogFile = "export_client_log_file"
        /// 是否启用 passport navigator 逻辑。主要改为用 keyWindow
        case usePassportNavigator = "use_passport_navigator"
        /// 5.16 启用，是否开启新的处理中断信号的流程；默认 true
        case useNewSwitchInterruptProcess = "use_new_switch_interrupt_process"
        /// 5.21 启用，是否启用用户态容器，默认 true
        case enableUserScope = "enable_user_scope"
        /// 关闭启动期间禁用session失效弹窗的逻辑
        case disableSessionInvalidDialogDuringLaunch = "ios_disable_session_invalid_show_dialog_during_launch"
        /// 5.22 启用，是否走新 iid 更新逻辑，默认 true
        case enableInstallIDUpdatedSeparately = "enable_install_id_updated_separately"
        /// 5.24 启用，是否开启UUID和新的passport store reset 时机
        case enableUUIDAndNewStoreReset = "ios_enable_uuid_and_new_store_reset"
        /// 5.27 启用，是否开启延迟设置 event registry，用于优化启动速度，默认 true
        case enableLazySetupEventRegister = "enable_lazy_setup_event_registry"
        /// 5.27 启用，是否开启 changeGeo，默认 true
        case enableChangeGeo = "enable_change_geo"
        /// 5.28启用，切换租户流程的switch identity接口请求超时时间
        case switchUserSwitchIdentityTimeout = "switch_user_switch_identity_timeout"
        /// 5.30 启用，匹配 TNS 页面后使用 Passport web 容器打开使其可以使用人脸 JSAPI
        case tnsAuthURLRegex = "tns_auth_url_regex"
        /// 5.33 启用，如果开启则所有接口请求都添加 fetchDeviceID
        case enableFetchDeviceIDForAllRequests = "enable_fetch_did_for_all_requests"
        /// 6.01 启用，如果开启则在Passport场景下web容器如果作为根视图会去掉导航栏关闭buttons
        case enableLeftNaviButtonsRootVCOpt = "enable_left_navi_buttons_root_vc_opt"
        /// 6.09 启用，如果开启则FIDO（Webauthn）注册中在 iOS16以上使用原生方案
        case enableWebauthnNativeRegister = "enable_webauthn_native_register"
        /// 6.09 启用，如果开启则FIDO（Webauthn）认证中在 iOS16以上使用原生方案
        case enableWebauthnNativeAuth = "enable_webauthn_native_auth"
        /// 7.01启用，控制LarkGlobal注册流程的超时时间
        case globalRegistrationTimeout = "global_registration_timeout"
        /// 7.04启用，控制是否图灵滑块认证使用包域名
        case turingUsePkgDomain = "turing_use_pkg_domain"
    }
}

struct V3NormalConfig: Codable {

    let defaultCountryCode: String
    let enableMobileRegister: Bool
    let enableEmailRegister: Bool
    let enableChangeRegionCode: Bool
    let emailRegex: String
    let enableCaptchaToken: Bool?
    private let topCountryList: [String]?
    private let blackCountryList: [String]?
    private let defaultRegisterRegionCode: String?
    let defaultHostDomain: String?
    let supportedSSODomainList: [String]?
    let ssoDomains: [String]?
    let ssoHelpUrl: [String: String]?
    let idpSwitch: [String: Bool]?
    let enableLoginJoinType: Bool?
    let enableRegisterJoinType: Bool?
    let enableRegisterEntry: Bool?
    let clientConfigList: V3ClientBizConfig?
    let suffixEmailMap: [String: String]?
    let passportOfflineConfig: PassportOfflineConfig?

    static let defaultEnableCaptchaToken: Bool = true
    static let defaultLarkBlackCountryList: [String] = ["IR", "SY", "KP", "CU"]
    static let defaultLarkTopCountryList: [String] = ["US", "JP", "SG"]
    static let defaultFeishuBlackCountryList: [String] = ["IR", "SY", "KP", "CU"]
    static let defaultFeishuTopCountryList: [String] = ["CN", "HK", "MO", "TW"]

    static let defaultFeishuRegisterRegionCode: String = CommonConst.chinaRegionCode
    static let defaultLarkRegisterRegionCode: String = CommonConst.USRegionCode

    static let defaultFeishuHostDomain: String = "feishu.cn"
    static let defaultSSODomains: [String] = ["feishu.cn", "sg.feishu.cn", "jp.feishu.cn",
                                              "larksuite.com", "sg.larksuite.com", "jp.larksuite.com"]
    static let defaultFeishuIdpSwitch: [String: Bool] = [
        LoginCredentialIdpChannel.apple_id.rawValue: false,
        LoginCredentialIdpChannel.google.rawValue: false,
        LoginCredentialIdpChannel.facebook.rawValue: false
    ]
    static let defaultLarkHostDomain: String = "larksuite.com"
    static let defaultLarkIdpSwitch: [String: Bool] = [
        LoginCredentialIdpChannel.apple_id.rawValue: true,
        LoginCredentialIdpChannel.google.rawValue: true,
        LoginCredentialIdpChannel.facebook.rawValue: true
    ]
    static let defaultLarkSupportedSSODomainList = ["jp.larksuite.com", "sg.larksuite.com", "larksuite.com"]

    static let defaultFeiShuRecoverScene: String = "passport_account_recovery"
    static let defaultFeiShuRecoverAppId: String = "161471"
    static let defaultFeiShuBioAuthScene: String = "passport_bio_auth"
    static let defaultFeiShuBioAuthAppId: String = "161471"
    static let defaultFeiShuRealNameScene: String = "passport_real_name"
    static let defaultFeiShuRealNameAppId: String = "161471"
    
    static let defaultEnableLoginJoinType: Bool = false
    static let defaultEnableRegisterJoinType: Bool = true
    static let defaultEnableLogByOPMonitor: Bool = false
    static let defaultEnableBrandFromForegroundUser: Bool = true
    static let defaultEnableExportClientLogFile: Bool = true
    static let defaultEnablePassportNavigator: Bool = true
    static let defaultEnableNewSwitchInterruptProcess: Bool = true
    static let defaultEnableUserScope: Bool = true
    static let defaultDisableSessionInvalidDialogDuringLaunch: Bool = true
    static let defaultEnableInstallIDUpdatedSeparately: Bool = true
    static let defaultEnableChangeGeo: Bool = true
    static let defaultEnableUUIDAndNewStoreReset: Bool = true
    static let defaultEnableLazySetupEventRegister: Bool = true
    static let defaultEnableRegisterEntry: Bool = false
    static let defaultEnableWebauthnNativeRegister: Bool = false
    static let defaultEnableWebauthnNativeAuth: Bool = false
    static let defaultGlobalRegistrationTimeout: Int = 5
    static let minSwitchUserSwitchIdentityTimeout: Int = 10
    static let maxSwitchUserSwitchIdentityTimeout: Int = 60
    static let defaultPassportOfflineConfig: PassportOfflineConfig = .defaultConfig
    static let defaultTuringUsePkgDomain: Bool = true
    static let defaultSuffixEmailMap: [String: String] = [
        "126.com": "https://www.126.com",
        "163.com": "https://mail.163.com",
        "gmail.com": "https://www.google.com/gmail",
        "outlook.com": "https://outlook.live.com",
        "qq.com": "https://mail.qq.com",
        "yahoo.com": "https://mail.yahoo.com"
    ]
    static let defaultTNSAuthURLRegex = #"https:\/\/([A-Za-z0-9\-]+)\.(feishu|larksuite)(-boe|-pre)?\.(cn|net|com)\/tns\/cust\/lark_authn\/.*"#
    static let defaultEnableFetchDeviceIDForAllRequests = true
    static let defaultEnableLeftNaviButtonsRootVCOpt: Bool = false

    //TODO: 上线前需要同步一下最终配置
    static let defaultH5URLConfig: [String: String] = [
        "account_deactivate": "/accounts/security/page/account_deactivate/?op_platform_service=hide_navigator",
        "account_management": "/accounts/security/page/account_management/?op_platform_service=hide_navigator",
        "account_security_center": "/accounts/security/page/?op_platform_service=hide_navigator",
        "device_management": "/accounts/security/page/device_management/?op_platform_service=hide_navigator",
        "password_setting": "/accounts/security/page/password_setting/?op_platform_service=hide_navigator",
        "security_password_setting": "/accounts/security/page/security_password_setting/?op_platform_service=hide_navigator"
    ]

    enum CodingKeys: String, CodingKey {
        case defaultCountryCode = "default_region_code"
        case enableMobileRegister = "enable_mobile_register"
        case enableEmailRegister = "enable_email_register"
        case enableChangeRegionCode = "enable_region_code_change"
        case emailRegex = "email_regex"
        case enableCaptchaToken = "enable_sec_captcha_id"
        case topCountryList = "top_country_list"
        case blackCountryList = "black_country_list"
        case defaultRegisterRegionCode = "default_register_region_code"
        case ssoDomains = "sso_domains"
        case defaultHostDomain = "default_host_domain"
        case supportedSSODomainList = "supported_sso_domain_list"
        case ssoHelpUrl = "sso_help_url"
        case idpSwitch = "idp_switch"
        case enableLoginJoinType = "enable_login_join_type"
        case enableRegisterJoinType = "enable_register_join_type"
        case clientConfigList = "client_biz_config_list"
        case suffixEmailMap = "suffix_email_map"
        case enableRegisterEntry = "enable_register_entry"
        case passportOfflineConfig = "passport_offline_config"
    }

    func topCountryList(for configEnv: String) -> [String] {
        switch configEnv {
        case V3ConfigEnv.lark:
            return topCountryList ?? V3NormalConfig.defaultLarkTopCountryList
        case V3ConfigEnv.feishu:
            return topCountryList ?? V3NormalConfig.defaultFeishuTopCountryList
        default:
            return topCountryList ?? V3NormalConfig.defaultFeishuTopCountryList
        }
    }

    func recoverScene(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.recoverScene
        case V3ConfigEnv.feishu:
            return clientConfigList?.recoverScene ?? V3NormalConfig.defaultFeiShuRecoverScene
        default:
            return clientConfigList?.recoverScene ?? V3NormalConfig.defaultFeiShuRecoverScene
        }
    }

    func recoverAppId(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.recoverAppId
        case V3ConfigEnv.feishu:
            return clientConfigList?.recoverAppId ?? V3NormalConfig.defaultFeiShuRecoverAppId
        default:
            return clientConfigList?.recoverAppId ?? V3NormalConfig.defaultFeiShuRecoverAppId
        }
    }

    func bioAuthScene(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.bioAuthScene
        case V3ConfigEnv.feishu:
            return clientConfigList?.bioAuthScene ?? V3NormalConfig.defaultFeiShuBioAuthScene
        default:
            return clientConfigList?.bioAuthScene ?? V3NormalConfig.defaultFeiShuBioAuthScene
        }
    }

    func bioAuthAppId(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.bioAuthAppId
        case V3ConfigEnv.feishu:
            return clientConfigList?.bioAuthAppId ?? V3NormalConfig.defaultFeiShuBioAuthAppId
        default:
            return clientConfigList?.bioAuthAppId ?? V3NormalConfig.defaultFeiShuBioAuthAppId
        }
    }
    
    func realNameScene(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.realNameScene
        case V3ConfigEnv.feishu:
            return clientConfigList?.realNameScene ?? V3NormalConfig.defaultFeiShuRealNameScene
        default:
            return clientConfigList?.realNameScene ?? V3NormalConfig.defaultFeiShuRealNameScene
        }
    }
    
    func realNameAppId(for configEnv: String) -> String? {
        switch configEnv {
        case V3ConfigEnv.lark:
            return clientConfigList?.realNameAppId
        case V3ConfigEnv.feishu:
            return clientConfigList?.realNameAppId ?? V3NormalConfig.defaultFeiShuRealNameAppId
        default:
            return clientConfigList?.realNameAppId ?? V3NormalConfig.defaultFeiShuRealNameAppId
        }
    }

    func blackCountryList(for configEnv: String) -> [String] {
        switch configEnv {
        case V3ConfigEnv.lark:
            return blackCountryList ?? V3NormalConfig.defaultLarkBlackCountryList
        case V3ConfigEnv.feishu:
            return blackCountryList ?? V3NormalConfig.defaultFeishuBlackCountryList
        default:
            return blackCountryList ?? V3NormalConfig.defaultFeishuBlackCountryList
        }
    }

    func registerRegionCode(for configEnv: String) -> String {
        switch configEnv {
        case V3ConfigEnv.lark:
            return defaultRegisterRegionCode ?? V3NormalConfig.defaultLarkRegisterRegionCode
        case V3ConfigEnv.feishu:
            return defaultRegisterRegionCode ?? V3NormalConfig.defaultFeishuRegisterRegionCode
        default:
            return defaultRegisterRegionCode ?? V3NormalConfig.defaultFeishuRegisterRegionCode
        }
    }

    func defaultHostDomain(for configEnv: String) -> String {
        switch configEnv {
        case V3ConfigEnv.lark:
            return defaultHostDomain ?? V3NormalConfig.defaultLarkHostDomain
        case V3ConfigEnv.feishu:
            return defaultHostDomain ?? V3NormalConfig.defaultFeishuHostDomain
        default:
            return defaultHostDomain ?? V3NormalConfig.defaultFeishuHostDomain
        }
    }

    func getSSODomains() -> [String] {
        return ssoDomains ?? V3NormalConfig.defaultSSODomains
    }
    
    func getSupportedSSODomainList(for configEnv: String) -> [String] {
        switch configEnv {
        case V3ConfigEnv.lark:
            return supportedSSODomainList ?? V3NormalConfig.defaultLarkSupportedSSODomainList
        case V3ConfigEnv.feishu:
            return supportedSSODomainList ?? []
        default:
            return supportedSSODomainList ?? []
        }
    }

    func getEnableLoginJoinType() -> Bool {
        return enableLoginJoinType ?? V3NormalConfig.defaultEnableLoginJoinType
    }

    func getEnableRegisterJoinType() -> Bool {
        return enableRegisterJoinType ?? V3NormalConfig.defaultEnableRegisterJoinType
    }

    func getJoinTeamHostWhitelist() -> [String]? {
        return clientConfigList?.joinTeamHostWhitelist
    }

    func getOneKeyLoginConfig() -> V3OneKeyLoginConfig {
        return clientConfigList?.oneKeyLoginConfig ?? V3OneKeyLoginConfig.default
    }

    func getEnableLogByOPMonitor() -> Bool {
        return clientConfigList?.logByOPMonitor ?? V3NormalConfig.defaultEnableLogByOPMonitor
    }
    
    func getEnableBrandFromForegroundUser() -> Bool {
        return clientConfigList?.brandFromForegroundUser ?? V3NormalConfig.defaultEnableBrandFromForegroundUser
    }
    
    func getEnableExportClientLogFile() -> Bool {
        return clientConfigList?.exportClientLogFile ?? V3NormalConfig.defaultEnableExportClientLogFile
    }

    func getEnablePassportNavigator() -> Bool {
        return clientConfigList?.usePassportNavigator ?? V3NormalConfig.defaultEnablePassportNavigator
    }

    func getEnableNewSwitchInterruptProcess() -> Bool {
        return clientConfigList?.useNewSwitchInterruptProcess ?? V3NormalConfig.defaultEnableNewSwitchInterruptProcess
    }

    func getEnableUserScope() -> Bool {
        return clientConfigList?.enableUserScope ??
            V3NormalConfig.defaultEnableUserScope
    }
    
    func getEnableInstallIDUpdatedSeparately() -> Bool {
        return clientConfigList?.enableInstallIDUpdatedSeparately ?? V3NormalConfig.defaultEnableInstallIDUpdatedSeparately
    }

    func getDisableSessionInvalidDialogDuringLaunch() -> Bool {
        return clientConfigList?.disableSessionInvalidDialogDuringLaunch ?? V3NormalConfig.defaultDisableSessionInvalidDialogDuringLaunch
    }
    
    func getSwitchUserSwitchIdentityTimeout() -> Int {
        
        if let timeout = clientConfigList?.switchUserSwitchIdentityTimeout {
            let minTimeout = V3NormalConfig.minSwitchUserSwitchIdentityTimeout
            let maxTimeout = V3NormalConfig.maxSwitchUserSwitchIdentityTimeout
            
            //TCC 生效timeout需要在 5 ~ 60 之间
            if timeout > minTimeout && timeout <= maxTimeout {
                return timeout
            }
            return minTimeout
        }
        return V3NormalConfig.minSwitchUserSwitchIdentityTimeout
    }

    static var clientConfigList: V3ClientBizConfig? {
        return PassportStore.shared.configInfo?.config().clientConfigList
    }

    static var enableChangeGeo: Bool {
        return clientConfigList?.enableChangeGeo ?? V3NormalConfig.defaultEnableChangeGeo
    }

    func getEnableUUIDAndNewStoreReset() -> Bool {
        return clientConfigList?.enableUUIDAndNewStoreReset ??
            V3NormalConfig.defaultEnableUUIDAndNewStoreReset
    }

    func getEnableLazySetupEventRegister() -> Bool {
        return clientConfigList?.enableLazySetupEventRegister ??
            V3NormalConfig.defaultEnableLazySetupEventRegister
    }

    func getH5URLConfig() -> [String: String] {
        return clientConfigList?.h5URLConfig ?? V3NormalConfig.defaultH5URLConfig
    }

    func getTNSAuthURLRegex() -> String {
        return clientConfigList?.tnsAuthURLRegex ?? V3NormalConfig.defaultTNSAuthURLRegex
    }

    func getEnableFetchDeviceIDForAllRequests() -> Bool {
        return clientConfigList?.enableFetchDeviceIDForAllRequests ?? V3NormalConfig.defaultEnableFetchDeviceIDForAllRequests
    }

    func getEnableLeftNaviButtonsRootVCOpt() -> Bool {
        return clientConfigList?.enableLeftNaviButtonsRootVCOpt ?? V3NormalConfig.defaultEnableLeftNaviButtonsRootVCOpt
    }

    func getEnableRegisterEntry() -> Bool {
        return enableRegisterEntry ?? V3NormalConfig.defaultEnableRegisterEntry
    }

    func getEnableWebauthnNativeRegister() -> Bool {
        return clientConfigList?.enableWebauthnNativeRegister ?? V3NormalConfig.defaultEnableWebauthnNativeRegister
    }

    func getEnableWebauthnNativeAuth() -> Bool {
        return clientConfigList?.enableWebauthnNativeAuth ?? V3NormalConfig.defaultEnableWebauthnNativeAuth
    }

    func getGlobalRegistrationTimeout() -> Int {
        return clientConfigList?.globalRegistrationTimeout ?? V3NormalConfig.defaultGlobalRegistrationTimeout
    }

    func getPassportOfflineConfig() -> PassportOfflineConfig {
        return passportOfflineConfig ?? V3NormalConfig.defaultPassportOfflineConfig
    }

    func getTuringUsePkgDomain() -> Bool {
        return clientConfigList?.turingUsePkgDomain ?? V3NormalConfig.defaultTuringUsePkgDomain
    }

    func webUrl(for step: String, host: String) -> URL? {
        var host = host
        if host.hasSuffix("/") {
            host = String(host.dropLast())
        }
        let config = getH5URLConfig()
        if let path = (config[step] ?? config[WebUrlKey.accountSecurityCenter.rawValue]) {
            return URL(string: host + path)
        } else {
            return nil
        }
    }

    init(
        defaultCountryCode: String,
        enableMobileRegister: Bool,
        enableEmailRegister: Bool,
        enableChangeRegionCode: Bool,
        emailRegex: String,
        enableCaptchaToken: Bool?,
        topCountryList: [String]?,
        blackCountryList: [String]?,
        defaultRegisterRegionCode: String?,
        defaultHostDomain: String,
        ssoDomains: [String],
        supportedSSODomainList: [String],
        idpSwitch: [String: Bool]?,
        enableLoginJoinType: Bool,
        enableRegisterJoinType: Bool,
        suffixEmailMap: [String: String],
        clientConfigList: V3ClientBizConfig?,
        enableRegisterEntry: Bool?,
        enableWebauthnNativeRegister: Bool?,
        enableWebauthnNativeAuth: Bool?,
        passportOfflineConfig: PassportOfflineConfig?
    ) {
        self.defaultCountryCode = defaultCountryCode
        self.enableMobileRegister = enableMobileRegister
        self.enableEmailRegister = enableEmailRegister
        self.enableChangeRegionCode = enableChangeRegionCode
        self.emailRegex = emailRegex
        self.enableCaptchaToken = enableCaptchaToken
        self.topCountryList = topCountryList
        self.blackCountryList = blackCountryList
        self.defaultRegisterRegionCode = defaultRegisterRegionCode
        self.defaultHostDomain = defaultHostDomain
        self.ssoDomains = ssoDomains
        self.supportedSSODomainList = supportedSSODomainList
        self.ssoHelpUrl = nil
        self.idpSwitch = idpSwitch
        self.enableLoginJoinType = enableLoginJoinType
        self.enableRegisterJoinType = enableRegisterJoinType
        self.clientConfigList = clientConfigList
        self.suffixEmailMap = suffixEmailMap
        self.enableRegisterEntry = enableRegisterEntry
        self.passportOfflineConfig = passportOfflineConfig
    }
}

extension V3NormalConfig: CustomStringConvertible {
    var description: String {
        return "\(json())"
    }

    func json() -> [String: String] {
        let emptyValue = "empty"
        let enableCaptchaTokenValue: String
        if let enableCaptchaToken = enableCaptchaToken {
            enableCaptchaTokenValue = "\(enableCaptchaToken)"
        } else {
            enableCaptchaTokenValue = emptyValue
        }
        return [
            CodingKeys.defaultCountryCode.rawValue: defaultCountryCode,
            CodingKeys.enableMobileRegister.rawValue: "\(enableMobileRegister)",
            CodingKeys.enableEmailRegister.rawValue: "\(enableEmailRegister)",
            CodingKeys.enableChangeRegionCode.rawValue: "\(enableChangeRegionCode)",
            CodingKeys.emailRegex.rawValue: emailRegex,
            CodingKeys.enableCaptchaToken.rawValue: enableCaptchaTokenValue
        ]
    }
}

struct V3ConfigInfo: Codable {
    let feishuConfig: V3NormalConfig
    let larkConfig: V3NormalConfig

    enum CodingKeys: String, CodingKey {
        case feishuConfig = "feishu"
        case larkConfig = "lark"
    }

    func config() -> V3NormalConfig {
        return config(for: PassportStore.shared.configEnv)
    }

    func config(for userEnv: String) -> V3NormalConfig {
        switch userEnv {
        case V3ConfigEnv.lark:
            return larkConfig
        case V3ConfigEnv.feishu:
            return feishuConfig
        default:
            return feishuConfig
        }
    }
}

extension V3ConfigInfo: CustomStringConvertible {
    var description: String {
        return "\(json())"
    }

    func json() -> [String: String] {
        return [
            CodingKeys.feishuConfig.rawValue: "\(feishuConfig)",
            CodingKeys.larkConfig.rawValue: "\(larkConfig)"
        ]
    }
}

struct V3UserLoginConfig: Codable {
    let loginType: SuiteLoginMethod
    let regionCode: String

    enum CodingKeys: String, CodingKey {
        case loginType
        case regionCode
    }

    init(type: SuiteLoginMethod, code: String) {
        self.loginType = type
        self.regionCode = code
    }
}

// enter app 相关
struct V3EnterAppInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let user: V3UserInfo
    let logoutToken: String
    let suiteSessionKeys: [String: [String: String]]?
    let derivedUsers: [String: V3DerivedUser]?
    let deviceLoginId: String?
    var isStdLark: Bool?

    enum CodingKeys: String, CodingKey {
        case user = "user"
        case logoutToken = "logout_token"
        case suiteSessionKeys = "suite_session_keys"
        case derivedUsers = "derived_users"
        case deviceLoginId = "device_login_id"
        case isStdLark = "is_std_lark"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct V3EnterAppAdditional: Codable {
    let users: [V3UserInfo]?
    let sceneInfo: [String: String]
}

struct V3AccountAppeal: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let appealUrl: String

    enum CodingKeys: String, CodingKey {
        case appealUrl = "appeal_url"
    }

    init(appealUrl: String) {
        self.appealUrl = appealUrl
    }
}

struct MigrateSwitchInfo: Codable {
    let logoutToken: String
    let suiteSessionKey: String
    let suiteSessionKeys: [String: [String: String]]
    let derivedUsers: [String: V3DerivedUser]
    let deviceLoginId: String?
    var isStdLark: Bool?

    enum CodingKeys: String, CodingKey {
        case logoutToken = "logout_token"
        case suiteSessionKey = "suite_session_key"
        case suiteSessionKeys = "suite_session_keys"
        case derivedUsers = "derived_users"
        case deviceLoginId = "device_login_id"
        case isStdLark = "is_std_lark"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        logoutToken = try container.decode(String.self, forKey: .logoutToken)
        suiteSessionKey = try container.decode(String.self, forKey: .suiteSessionKey)
        suiteSessionKeys = (try? container.decode([String: [String: String]].self, forKey: .suiteSessionKeys)) ?? [:]
        derivedUsers = (try? container.decode([String: V3DerivedUser].self, forKey: .derivedUsers)) ?? [:]
        deviceLoginId = try? container.decode(String.self, forKey: .deviceLoginId)
        isStdLark = try? container.decode(Bool.self, forKey: .isStdLark)
    }
}

extension V3ConfigInfo {
    static var defaultConfig: V3ConfigInfo {
        return V3ConfigInfo(
                feishuConfig: V3NormalConfig(
                        defaultCountryCode: "+86",
                        enableMobileRegister: true,
                        enableEmailRegister: false,
                        enableChangeRegionCode: false,
                        emailRegex: ".+@.+\\..+",
                        enableCaptchaToken: V3NormalConfig.defaultEnableCaptchaToken,
                        topCountryList: V3NormalConfig.defaultFeishuTopCountryList,
                        blackCountryList: V3NormalConfig.defaultFeishuBlackCountryList,
                        defaultRegisterRegionCode: V3NormalConfig.defaultFeishuRegisterRegionCode,
                        defaultHostDomain: V3NormalConfig.defaultFeishuHostDomain,
                        ssoDomains: V3NormalConfig.defaultSSODomains,
                        supportedSSODomainList: [],
                        idpSwitch: V3NormalConfig.defaultFeishuIdpSwitch,
                        enableLoginJoinType: V3NormalConfig.defaultEnableLoginJoinType,
                        enableRegisterJoinType: V3NormalConfig.defaultEnableRegisterJoinType,
                        suffixEmailMap: V3NormalConfig.defaultSuffixEmailMap,
                        clientConfigList: nil,
                        enableRegisterEntry: false,
                        enableWebauthnNativeRegister: false,
                        enableWebauthnNativeAuth: false,
                        passportOfflineConfig: .defaultConfig
                ),
                larkConfig: V3NormalConfig(
                        defaultCountryCode: "+1",
                        enableMobileRegister: true,
                        enableEmailRegister: true,
                        enableChangeRegionCode: true,
                        emailRegex: ".+@.+\\..+",
                        enableCaptchaToken: V3NormalConfig.defaultEnableCaptchaToken,
                        topCountryList: V3NormalConfig.defaultLarkTopCountryList,
                        blackCountryList: V3NormalConfig.defaultLarkBlackCountryList,
                        defaultRegisterRegionCode: V3NormalConfig.defaultLarkRegisterRegionCode,
                        defaultHostDomain: V3NormalConfig.defaultLarkHostDomain,
                        ssoDomains: V3NormalConfig.defaultSSODomains,
                        supportedSSODomainList: V3NormalConfig.defaultLarkSupportedSSODomainList,
                        idpSwitch: V3NormalConfig.defaultLarkIdpSwitch,
                        enableLoginJoinType: V3NormalConfig.defaultEnableLoginJoinType,
                        enableRegisterJoinType: V3NormalConfig.defaultEnableRegisterJoinType,
                        suffixEmailMap: V3NormalConfig.defaultSuffixEmailMap,
                        clientConfigList: nil,
                        enableRegisterEntry: false,
                        enableWebauthnNativeRegister: false,
                        enableWebauthnNativeAuth: false,
                        passportOfflineConfig: .defaultConfig
                )
        )
    }
}

// MARK: native step
enum V3NativeStep: String {
    case simpleWeb
    case enterpriseLogin
    case directOpenIDP
    case logout
    case qrCodeLogin
}

struct V3SimpleWebInfo: Codable {
    let url: URL
    init(url: URL) {
        self.url = url
    }
}

// not required
struct V3InputInfo: Codable, V3TrackPathProtocol {
    let contact: String
    let countryCode: String
    let method: SuiteLoginMethod
    var trackPath: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case contact
        case method
        case countryCode
        case trackPath
        case name
    }

    init(contact: String, countryCode: String, method: SuiteLoginMethod, name: String? = nil) {
        self.contact = contact
        self.method = method
        self.countryCode = countryCode
        self.name = name
    }
}

struct V3ButtonInfo: Codable {
    let text: String
    let enable: Bool
    let visible: Bool?

    var isVisible: Bool {
        return visible ?? true
    }

    static var placeholder: V3ButtonInfo {
        return V3ButtonInfo(text: "", enable: false, visible: false)
    }
}

struct V3EnterpriseInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let isAddCredential: Bool

    enum CodingKeys: String, CodingKey {
        case isAddCredential
    }
}

class PlaceholderServerInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
}

struct V3MagicLinkInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String
    let contact: String
    let sourceType: Int?
    let tip: String?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case contact
        case sourceType = "source_type"
        case tip
    }
}

protocol V3TrackPathProtocol {
    var trackPath: String? { get }
}

extension V3TrackPathProtocol {
    var path: String { trackPath ?? TrackConst.defaultPath }
}

struct V3LoginAdditionalInfo: Codable, V3TrackPathProtocol {
    var trackPath: String?
    var from: String?
}

typealias V3RegisterTypeRaw = Int

enum V3RegisterType: V3RegisterTypeRaw {
    // 待定（指注册类型待定，用户未选择）
    case undefine = 0
    // 加入可信邮箱团队
    case officialEmail = 1
    // 用团队码/扫码加入新团队
    case joinTenant = 2
    // 创建新团队
    case createTeam = 3
    // 个人使用
    case personalUsage = 4
    // 升级团队
    case upgradeTeam = 5

   static func getType(_ type: V3RegisterTypeRaw) -> V3RegisterType? {
       return V3RegisterType(rawValue: type)
   }
}

class V3WebStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let stepInfoJSON: String
    let url: String

    init(url: String, stepInfoJSON: String) {
        self.url = url
        self.stepInfoJSON = stepInfoJSON
    }

    static func from(_ dict: [String: Any]) -> V3WebStepInfo {
        if (dict["url"] as? String) == nil {
            V3LoginService.logger.error("not has url in stepInfo")
        }
        return V3WebStepInfo(url: dict["url"] as? String ?? "", stepInfoJSON: dict.jsonString())
    }
}
