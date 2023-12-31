//
//  V4LoginEntity.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/2.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkEnv
import LarkReleaseConfig

private let logger = Logger.log(PassportStep.self, category: "SuiteLogin.V4LoginEntity")

//struct StepData: Codable {
//    var stepName: String?
//    var stepInfo: String?
//
//    enum CodingKeys: String, CodingKey {
//        case stepName = "next_step"
//        case stepInfo = "step_info"
//    }
//
////    func nextServerInfo() -> ServerInfo? {
////        if let stepName = stepName, let stepInfo = stepInfo {
////            let passportStep = PassportStep(rawValue: stepName)
////            if let jsonData = stepInfo.data(using: String.Encoding.utf8, allowLossyConversion: false) {
////                if let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers), let dict = json as? [String : Any] {
////                    return passportStep?.pageInfo(with: dict)
////                }
////            }
////        }
////        return nil
////    }
//}

struct V4StepData: Codable, ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    var stepName: String?
    var stepInfo: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case stepName = "next_step"
        case stepInfo = "step_info"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stepName = try values.decode(String.self, forKey: .stepName)
        if let jsonData = try? values.decode(Data.self, forKey: .stepInfo) {
            stepInfo = (try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]) ??  [String: Any]()
        } else {
            stepInfo = try values.decode([String: Any].self, forKey: .stepInfo)
        }
        if let flowType_temp = try? values.decode(String.self, forKey: .flowType) {
            flowType = flowType_temp
        } else {
            flowType = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepName, forKey: .stepName)
        guard let stepDict = stepInfo else { return }
        let data = try JSONSerialization.data(withJSONObject: stepDict)
        try container.encode(data, forKey: .stepInfo)
    }

    func nextServerInfo() -> ServerInfo? {
        if let stepName = stepName, let stepInfo = stepInfo {
            let passportStep = PassportStep(rawValue: stepName)
            return passportStep?.pageInfo(with: stepInfo)
        }
        return nil
    }
}

enum ActionIconType: Int, Codable {
    case unknown = -1
    case normal = 0
    case next = 1
    case register = 2
    case join = 3
    case joinScan = 4
    case joinCode = 5
    case createTenant = 6
    case createPersonal = 7
    case blockAppeal = 8
    case blockVerify = 9
    case blockKnown = 10
    case verifyEmail = 11
    case verifyMobile = 12

    case qrSingle = 13
    case qrMulti = 14
    case qrAuthz = 15

    case deprovKnown = 16  // 注销流程： 我知道了
    case deprovDeleteWallet = 17 // 注销流程： 注销钱包

    case detrieveNeedMobileCancel = 18 // 非移动端提示前往移动端或账号申诉：取消按钮
    case verifyCIdp = 19    // 认证c idp
    case verifyGoogle = 20  // 认证 Google账号
    case verifyAppleID = 21 // 认证 Apple ID
    case idpLoginPage = 22  // idp登陆页
    case verifyBIdp = 23    // 认证b idp

    // 授权免登
    case authAutoLoginConfirm = 36  // 确认授权
    case authAutoLoginCancel = 37   // 取消授权
    case authAutoLoginOK = 38       // 我知道了
    
    case verifyPwd = 41  //认证密码
    case verifyOTP = 42  //认证OTP
    case verifySpareCode = 43  //认证备用验证方式
    case verifyMo = 45 //认证短信上行
    case verifyFIDO = 53 //认证FIDO（安全密钥）
    case verifyOtherList = 54 //打开切换到其他验证方式的列表

    case qrLoginRiskContinue = 51   // 扫码登录风险拦截：继续授权
    case qrLoginRiskCancel = 52     // 扫码登录风控拦截：1.弹窗：我知道了 2：提醒页：取消授权

    static let defaultValue: ActionIconType = .unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        self = Self(rawValue: value) ?? .defaultValue
    }
}

public struct V4ButtonInfo: Codable {
    let text: String
    var actionType: ActionIconType?
    var next: V4StepData?

    enum CodingKeys: String, CodingKey {
        case text, next
        case actionType = "action_type"
    }

    static var placeholder: V4ButtonInfo {
        return V4ButtonInfo(actionType: .defaultValue, next: nil, text: "")
    }

    init(actionType: ActionIconType?, next: V4StepData?, text: String) {
        self.actionType = actionType
        self.next = next
        self.text = text
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        next = try? container.decode(V4StepData.self, forKey: .next)

        actionType = try? container.decode(ActionIconType.self, forKey: .actionType)

        if let text_temp = try? container.decode(String.self, forKey: .text) {
            text = text_temp
        } else {
            text = ""
        }
    }
}

struct Menu: Codable {
    let desc: String
    var actionType: ActionIconType?
    let next: V4StepData?
    let text: String

    enum CodingKeys: String, CodingKey {
        case desc, next, text
        case actionType = "action_type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        next = try? container.decode(V4StepData.self, forKey: .next)

        if let type = try? container.decode(ActionIconType.self, forKey: .actionType) {
            actionType = type
        } else {
            actionType = .defaultValue
        }

        if let text_temp = try? container.decode(String.self, forKey: .text) {
            text = text_temp
        } else {
            text = ""
        }

        if let desc_temp = try? container.decode(String.self, forKey: .desc) {
            desc = desc_temp
        } else {
            desc = ""
        }
    }
}

struct InputInfo: Codable {
    let label: String?
    let placeholder: String
    let prefill: String

    enum CodingKeys: String, CodingKey {
        case label
        case placeholder
        case prefill
    }
}

struct RegisterItem: Codable {
    let dispatchList: [V4DispatchMenuItem]?
    let title: String

    enum CodingKeys: String, CodingKey {
        case dispatchList = "dispatch_list"
        case title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        dispatchList = try container.decode([V4DispatchMenuItem].self, forKey: .dispatchList)
    }
}

/// 服务端返回的 Tenant 数据结构
/// V4ResponseTenant 可以在 Passport 内部流转，也推荐在 Passport 内部直接使用这个数据结构，但不会暴露到外部
/// 暴露到外部时使用 `Tenant`，通过 makeTenant() 方法可以将一个 V4ResponseTenant 转成 Tenant
struct V4ResponseTenant: Codable {

    let id: String
    let name: String
    let i18nNames: I18nName?
    let iconURL: String
    let iconKey: String
    let tag: TenantTag?
    let brand: TenantBrand
    let geo: String?
    let domain: String?
    let fullDomain: String?
    let isCertificated: Bool?

    var isFeishuBrand: Bool {
        return brand == TenantBrand.feishu
    }

    init(id: String, name: String, i18nNames: I18nName?, iconURL: String, iconKey: String, tag: TenantTag?, brand: TenantBrand, geo: String?, domain: String?, fullDomain: String?, isCertificated: Bool? = false) {
        self.id = id
        self.name = name
        self.i18nNames = i18nNames
        self.iconURL = iconURL
        self.iconKey = iconKey
        self.tag = tag
        self.brand = brand
        self.geo = geo
        self.domain = domain
        self.fullDomain = fullDomain
        self.isCertificated = isCertificated
    }
    
    /// 用一个原始的 Tenant 和 brand 构造一个新的 Tenant
    init(tenant: V4ResponseTenant, brand: TenantBrand) {
        self.init(id: tenant.id, name: tenant.name, i18nNames: tenant.i18nNames, iconURL: tenant.iconURL, iconKey: tenant.iconKey, tag: tenant.tag, brand: brand, geo: tenant.geo, domain: tenant.domain, fullDomain: tenant.fullDomain, isCertificated: tenant.isCertificated)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, geo
        case i18nNames = "i18n_names"
        case iconURL = "icon_url"
        case iconKey = "icon_key"
        case tag = "tenant_tag"
        case brand = "tenant_brand"
        case domain = "tenant_domain"
        case fullDomain = "tenant_full_domain"
        case isCertificated = "is_certificated"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        i18nNames = try? container.decode(I18nName.self, forKey: .i18nNames)
        iconURL = try container.decode(String.self, forKey: .iconURL)
        iconKey = try container.decode(String.self, forKey: .iconKey)
        tag = try? container.decode(TenantTag.self, forKey: .tag)
        // MultiGeo updated
        // 本地或服务端如果没有返回，根据包环境给到一个兜底
        let backupBrand: TenantBrand = ReleaseConfig.isLark ? TenantBrand.lark : TenantBrand.feishu
        brand = (try? container.decode(TenantBrand.self, forKey: .brand)) ?? backupBrand
        domain = try? container.decode(String.self, forKey: .domain)
        fullDomain = try? container.decode(String.self, forKey: .fullDomain)
        isCertificated = try? container.decode(Bool.self, forKey: .isCertificated) ?? false
        geo = try? container.decode(String.self, forKey: .geo)
    }

    func makeTenant() -> Tenant {
        var outputDomain = domain
        if outputDomain == nil {
            if id == Tenant.consumerTenantID {
                outputDomain = Tenant.consumerTenantDomain
            } else if id == Tenant.byteDancerTenantID {
                outputDomain = Tenant.byteDanceTenantDomain
            }
        }

        return Tenant(
            tenantID: id,
            tenantName: name,
            i18nTenantNames: i18nNames,
            iconURL: iconURL,
            tenantTag: tag,
            tenantBrand: brand,
            tenantGeo: geo,
            isFeishuBrand: isFeishuBrand,
            tenantDomain: outputDomain,
            tenantFullDomain: fullDomain,
            singleProductTypes: nil)
    }

    //把LocalName兜底逻辑统一做到这里 优先级：i18nName -> name
    func getCurrentLocalName() -> String {
        return self.i18nNames?.currentLocalName ?? self.name
    }
}

enum UserExpressiveStatus: Int, Codable {
    case unknown = -1
    case enable = 0         // 正常
    case forbidden = 1      // 已封禁
    case freeze = 2         // 已冻结
    case unactivated = 3    // 未激活
    case unauthorized = 4   // 凭证未验证
    case reviewing = 5      // 审核中
    case unjoined = 6       // 未加入

    static let defaultValue: UserExpressiveStatus = .unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        self = Self(rawValue: value) ?? .defaultValue
    }
}

/// 服务端返回的 User 数据结构，`不包含` session
struct V4ResponseUser: Codable {

    let id: String
    let name: String
    let i18nNames: I18nName?
    let displayName: String?
    let i18nDisplayNames: I18nName?
    var status: UserExpressiveStatus
    let avatarURL: String
    let avatarKey: String
    let tenant: V4ResponseTenant
    let createTime: TimeInterval
    let credentialID: String
    let unit: String?
    let geo: String
    let excludeLogin: Bool?
    var leanModeInfo: LeanModeInfo?
    let userCustomAttr: [UserCustomAttr]?
    let isTenantCreator: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, tenant, status, unit, geo
        case i18nNames = "i18n_names"
        case displayName = "display_name"
        case i18nDisplayNames = "i18n_display_names"
        case avatarURL = "avatar_url"
        case avatarKey = "avatar_key"
        case createTime = "create_time"
        case credentialID = "login_credential_id"
        case excludeLogin = "exclude_login"
        case leanModeInfo = "lean_mode_info"
        case userCustomAttr = "user_custom_attr"
        case isTenantCreator = "is_tenant_creator"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        i18nNames = try? container.decode(I18nName.self, forKey: .i18nNames)
        displayName = try? container.decode(String.self, forKey: .displayName)
        i18nDisplayNames = try? container.decode(I18nName.self, forKey: .i18nDisplayNames)
        status = try container.decode(UserExpressiveStatus.self, forKey: .status)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        avatarKey = try container.decode(String.self, forKey: .avatarKey)
        createTime = try container.decode(TimeInterval.self, forKey: .createTime)
        credentialID = try container.decode(String.self, forKey: .credentialID)
        unit = try? container.decode(String.self, forKey: .unit)
        excludeLogin = try? container.decode(Bool.self, forKey: .excludeLogin)
        leanModeInfo = try? container.decode(LeanModeInfo.self, forKey: .leanModeInfo)
        userCustomAttr = try? container.decode([UserCustomAttr].self, forKey: .userCustomAttr)
        isTenantCreator = try? container.decode(Bool.self, forKey: .isTenantCreator)
        
        // MultiGeo updated
        // 本地或服务端如果没有返回，根据 unit 给到一个兜底
        let backupGeo: String
        let backupBrand: TenantBrand
        let decodedTenant = try container.decode(V4ResponseTenant.self, forKey: .tenant)
        
        #if DEBUG || BETA || ALPHA
        switch unit {
        case "boecn":
            backupGeo = "boe-cn"
            backupBrand = .feishu
        case "boeva":
            backupGeo = "boe-us"
            backupBrand = .lark
        case "eu_nc":
            backupGeo = "cn"
            backupBrand = .feishu
        case "eu_ea":
            backupGeo = "us"
            backupBrand = .lark
        default:
            backupGeo = ReleaseConfig.isLark ? "us" : "cn"
            backupBrand = ReleaseConfig.isLark ? .lark : .feishu
        }
        #else
        switch unit {
        case "eu_nc":
            backupGeo = "cn"
            backupBrand = .feishu
        case "eu_ea":
            backupGeo = "us"
            backupBrand = .lark
        default:
            backupGeo = ReleaseConfig.isLark ? "us" : "cn"
            backupBrand = ReleaseConfig.isLark ? .lark : .feishu
        }
        #endif
        if let decodedGeo = try? container.decode(String.self, forKey: .geo) {
            geo = decodedGeo
            tenant = decodedTenant
        } else {
            // 如果 geo 没有拿到，说明是老数据结构，tenant 的 brand 也需要兜底
            geo = backupGeo
            tenant = V4ResponseTenant(tenant: decodedTenant, brand: backupBrand)
        }
        
    }

    init(id: String, name: String, displayName: String?, i18nNames: I18nName?, i18nDisplayNames: I18nName?, status: UserExpressiveStatus, avatarURL: String, avatarKey: String, tenant: V4ResponseTenant, createTime: TimeInterval, credentialID: String, unit: String?, geo: String, excludeLogin: Bool?, userCustomAttr: [UserCustomAttr]?, isTenantCreator: Bool?) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.i18nNames = i18nNames
        self.i18nDisplayNames = i18nDisplayNames
        self.status = status
        self.avatarURL = avatarURL
        self.avatarKey = avatarKey
        self.tenant = tenant
        self.createTime = createTime
        self.credentialID = credentialID
        self.unit = unit
        self.geo = geo
        self.excludeLogin = excludeLogin
        self.userCustomAttr = userCustomAttr
        self.isTenantCreator = isTenantCreator
    }

    //把LocalName和LocalDisplayName兜底逻辑统一做到这里 优先级：i18nDisplayName -> displayName -> i18nName -> name
    func getCurrentLocalName() -> String {
        return self.i18nNames?.currentLocalName ?? self.name
    }
    func getCurrentLocalDisplayName() -> String {
        if let displayName = self.displayName {
            return self.i18nDisplayNames?.currentLocalName ?? displayName
        } else {
            return self.i18nNames?.currentLocalName ?? name
        }
    }
}

/// 身份选择页面身份每个可供选择的 Item
struct V4UserItem: Codable {
    var button: V4ButtonInfo?
    var type: ItemType?
    var statusDesc: String?
    var tagDesc: String?
    let user: V4ResponseUser
    let loginDisabled: Bool?

    enum ItemType: Int, Codable {
        case normal = 0         // 正常
        case email = 1      // 可信邮箱

        static let defaultValue: ItemType = .normal

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .defaultValue
        }
    }

    static func getStatus(from rawValue: Int?) -> UserExpressiveStatus {
        if let status = rawValue {
            return UserExpressiveStatus(rawValue: status) ?? .defaultValue
        } else {
            return .enable
        }
    }

    enum CodingKeys: String, CodingKey {
        case button, user, type
        case tagDesc = "tag_desc"
        case loginDisabled = "login_disabled"
    }
}

extension V4UserItem {
    var isValid: Bool {
        if loginDisabled ?? false {
            return false
        }
        
        switch user.status {
        case .enable, .forbidden, .unactivated, .unjoined:
            return true
        case .unknown, .freeze, .reviewing, .unauthorized:
            return false
        }
    }
}

struct V4UserItemGroup: Codable {
    var subtitle: String?
    var userList: [V4UserItem]?

    enum CodingKeys: String, CodingKey {
        case subtitle
        case userList = "user_list"
    }
}

struct V4DispatchMenuItem: Codable {
    let text: String
    let desc: String
    var actionType: ActionIconType?
    var next: V4StepData?

    enum CodingKeys: String, CodingKey {
        case text, desc, next
        case actionType = "action_type"
    }
}

struct V4RegisterItem: Codable {
    let title: String
    var dispatchList: [V4DispatchMenuItem]?

    enum CodingKeys: String, CodingKey {
        case title
        case dispatchList = "dispatch_list"
    }
}

struct V4RefuseItem: Codable {
    let selectTitle: String?
    let selectButton: V4ButtonInfo?
    let refuseButton: V4ButtonInfo
    
    enum CodingKeys: String, CodingKey {
        case selectTitle = "select_title"
        case selectButton = "select_button"
        case refuseButton = "refuse_button"
    }
}

class V4SelectUserInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var title: String?
    var groupList: [V4UserItemGroup]?
    var joinButton: V4ButtonInfo?
    var registerButton: V4ButtonInfo?
    var registerItem: V4RegisterItem?
    var toast: String?
    var refuseItem: V4RefuseItem?
    var nextStep: NextStep?
    var userListType: Int?

    enum CodingKeys: String, CodingKey {
        case title, toast
        case flowType = "flow_type"
        case groupList = "group_list"
        case joinButton = "join_button"
        case registerButton = "register_button"
        case registerItem = "register_item"
        case refuseItem = "refuse_item"
        case nextStep = "next_step"
        case usePackageDomain = "use_package_domain"
        case userListType = "user_list_type"
    }
    
    struct NextStep: Codable{
        var event: String
        var info: [String: Any]?
        
        enum CodingKeys: String, CodingKey {
            case event = "next_step"
            case info = "step_info"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let data = try? container.decode([String:Any].self, forKey: .info)
            self.event = try container.decode(String.self, forKey: .event)
            self.info = data
        }
        public func encode(to encoder: Encoder) throws {}
    }
}

struct AppPermissionInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var title: String?
    var subtitle: String?
    var richSubtitle: RichText?
    var targetAppID: String
    var approvalType: String
    var groupList: [V4UserItemGroup]?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle = "sub_title"
        case richSubtitle = "rich_subtitle"
        case targetAppID = "target_app_id"
        case approvalType = "approval_type"
        case flowType = "flow_type"
        case groupList = "group_list"
        case usePackageDomain = "use_package_domain"
    }

    struct RichText: Codable {
        var plainText: String
        var links: [Link]?
        var boldTexts: [String]?

        enum CodingKeys: String, CodingKey {
            case plainText = "plain_string"
            case links
            case boldTexts = "bold_texts"
        }

        struct Link: Codable {
            var name: String
            var url: String

            enum CodingKeys: String, CodingKey {
                case name
                case url
            }
        }
    }
}

struct ApplyFormInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var form: [FormItem]
    var reviewers: [Reviewer]
    var appInfo: AppInfo
    var approvalCode: String
    var approvalType: String

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"

        case form
        case reviewers = "approval_users"
        case appInfo = "app_info"
        case approvalCode = "approval_code"
        case approvalType = "approval_type"
    }

    enum FormItemType: String, Codable {
        case input
    }

    struct FormItem: Codable {
        var customID: String
        var type: FormItemType

        enum CodingKeys: String, CodingKey {
            case customID = "custom_id"
            case type
        }
    }

    struct Reviewer: Codable {
        var userID: String
        var username: String
        var avatarURL: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case username = "user_name"
            case avatarURL = "avatar_url"
        }
    }

    struct AppInfo: Codable {
        var appID: String
        var appName: String

        enum CodingKeys: String, CodingKey {
            case appID = "app_id"
            case appName = "app_name"
        }
    }

}

struct V4InputPlaceholder: Codable {
    var placeholder: String?
    var prefill: String?

    enum CodingKeys: String, CodingKey {
        case placeholder
        case prefill
    }
}

class V3SetPwdInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var title: String?
    var subtitle: String?
    var rsaInfo: RSAInfo?
    var sourceType: Int?

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case rsaInfo = "rsa_info"
        case sourceType = "source_type"
    }
}

class V4PwdCheckCondition: Codable {
    var matchReg: [String]?  // 需要全部匹配，[a, b] => a & b
    var notMatchReg: [String]? // 需要全部不匹配， [a, b] => !a & !b
    var msg: String

    private func matchRegGroup(regGroup: [String]?, regMap: Dictionary<String, String>, text: String) -> Bool {
        guard let regGroup = regGroup else {
            return true
        }

        for regKey in regGroup {
            if let pattern = regMap[regKey] {
                if text.range(of: pattern, options: .regularExpression) == nil {
                    return false
                }
            } else {
                assertionFailure("Password pattern not found")
            }
        }

        return true
    }

    // https://bytedance.feishu.cn/docx/doxcncvOnPhC73vjVrnhrA9h6ad
    // matchReg： 每个正则都匹配
    // notMatchReg： 任意一个不匹配即可 <==> !(每个都匹配)
    func match(_ text: String, regMap: Dictionary<String, String>) -> Bool {
        return matchRegGroup(regGroup: matchReg, regMap: regMap, text: text)
        && !matchRegGroup(regGroup: notMatchReg, regMap: regMap, text: text)
    }
    
    enum CodingKeys: String, CodingKey {
        case matchReg = "match_reg"
        case notMatchReg = "not_match_reg"
        case msg
    }
}

class V4PwdCheckInfo: Codable {
    var regExpCommon: String
    var regExpMap: Dictionary<String, String>
    var pwdErr: [V4PwdCheckCondition]
    var pwdLevelMsg: String
    var pwdStrong: [V4PwdCheckCondition]  // 满足任意条件即可
    var pwdMiddle: [V4PwdCheckCondition]
    var pwdWeak: [V4PwdCheckCondition]
    
    enum CodingKeys: String, CodingKey {
        case regExpCommon = "reg_exp_common"
        case regExpMap = "reg_exp_map"
        case pwdErr = "pwd_err"
        case pwdLevelMsg = "pwd_level_msg"
        case pwdStrong = "pwd_strong"
        case pwdMiddle = "pwd_middle"
        case pwdWeak = "pwd_weak"
    }
}

class V4SetPwdInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var title: String?
    var subtitle: String?
    var skipButton: V4ButtonInfo?
    var nextButton: V4ButtonInfo?
    var rsaInfo: RSAInfo?
    var pwdPlaceholder: V4InputPlaceholder?
    var confirmPwdPlaceholder: V4InputPlaceholder?
    var regExp: String?
    var errText: String?
    var sourceType: Int?
    var disableBack: Bool?
    var pwdCheck: V4PwdCheckInfo

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case flowType = "flow_type"
        case skipButton = "skip_button"
        case nextButton = "next_button"
        case rsaInfo = "rsa_info"
        case pwdPlaceholder = "pwd"
        case confirmPwdPlaceholder = "confirm_pwd"
        case regExp = "reg_exp"
        case errText = "format_err_text"
        case sourceType = "source_type"
        case usePackageDomain = "use_package_domain"
        case disableBack = "disable_back"
        case pwdCheck = "pwd_check"
    }
}

struct V4PersonalInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String?
    let subtitle: String?
    let credentialInputList: [V4CredentialInputInfo]
    let nameInput: V4InputPlaceholder
    let privacyPolicy: String
    let nextButton: V4ButtonInfo?
    let unit: String?
    let tenantBrand: String?
    let tenantUnitDomain: String?
    let allowRegionList: [String]?
    let blockRegionList: [String]?

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case credentialInputList = "credential_input_list"
        case nameInput = "name_input"
        case privacyPolicy = "privacy_policy"
        case flowType = "flow_type"
        case nextButton = "next_button"
        case usePackageDomain = "use_package_domain"
        case unit = "unit"
        case tenantBrand = "tenant_brand"
        case tenantUnitDomain = "tenant_unit_domain"
        case allowRegionList = "allow_region_list"
        case blockRegionList = "block_region_list"
    }
}

struct V4CredentialInputInfo: Codable {
    let tabName: String
    let credentialType: CredentialType
    let credentialInput: V4InputPlaceholder

    enum CodingKeys: String, CodingKey {
        case tabName = "tab_name"
        case credentialType = "credential_type"
        case credentialInput = "credential_input"
    }

    enum CredentialType: Int, Codable {
        case unknown = 0
        case phoneNumber = 1
        case email = 2

        var method: SuiteLoginMethod {
            switch self {
            case .email:
                return .email
            case .phoneNumber:
                return .phoneNumber
            default:
                return .phoneNumber
            }
        }

        init(from decoder: Decoder) throws {
            self = try CredentialType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        }
    }
}

protocol V4CredentialInfoProtocol: Codable {
    var credential: String { get }
    var credentialType: Int { get }
}

struct V4CredentialInfo: V4CredentialInfoProtocol {
    let credential: String
    let credentialType: Int
    var shouldDisplayCredential: Bool = false
}

// MARK: - Join tenant : "dispatch_register"
class V4JoinTenantInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String?
    let dispatchList: [Menu]?
    let registerButton: V4ButtonInfo?
    let registerItem: RegisterItem?
    let toast: String?

    enum CodingKeys: String, CodingKey {
        case title, subtitle, toast
        case flowType = "flow_type"
        case dispatchList = "dispatch_list"
        case registerButton = "register_button"
        case registerItem = "register_item"
        case usePackageDomain = "use_package_domain"
    }

    //lynn
    enum JoinType: String, Codable {
        case inputTeamCode = "join_by_code"
        case scanQRCode = "join_by_scan"

        static let tokenJoin: String = "token_join"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dispatchList = try? container.decode([Menu].self, forKey: .dispatchList)

        registerButton = try? container.decode(V4ButtonInfo.self, forKey: .registerButton)

        registerItem = try? container.decode(RegisterItem.self, forKey: .registerItem)

        toast = try? container.decode(String.self, forKey: .toast)
        
        if let title_temp = try? container.decode(String.self, forKey: .title) {
            title = title_temp
        } else {
            title = ""
        }

        subtitle = try? container.decode(String.self, forKey: .subtitle)

        if let flowType_temp = try? container.decode(String.self, forKey: .flowType) {
            flowType = flowType_temp
        } else {
            flowType = ""
        }
    }
}

class V4SetNameInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String?
    let nameInput: InputInfo?
    let nextButton: V4ButtonInfo?

    let showOptIn: Bool
    let optTitle: String

    let nameType: NameType?  // single 时只有一个输入框，multiple 时有多个输入框（如 first name、last name）
    let larkNameInput: [InputInfo]? // 当 nameType 为 multiple 时展示的输入框信息
    let nameSeparator: String?  // 上传姓名时使用的分隔符

    enum NameType: Int, Codable {
        case single = 0
        case multiple = 1

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .single
        }
    }

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case nameInput = "name_input"
        case flowType = "flow_type"
        case nextButton = "next_button"
        case usePackageDomain = "use_package_domain"
        case showOptIn = "show_opt_in"
        case optTitle = "opt_title"
        case nameType = "name_type"
        case larkNameInput = "lark_name_input"
        case nameSeparator = "name_separator"
    }
}

class V4DispatchSetNameInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

class V4JoinTenantCodeInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String?
    let switchButton: V4ButtonInfo?
    let registerButton: V4ButtonInfo?
    let registerItem: RegisterItem?
    let nextButton: V4ButtonInfo
    let toast: String?

    enum CodingKeys: String, CodingKey {
        case title, subtitle, toast
        case switchButton = "switch_button"
        case registerButton = "register_button"
        case registerItem = "register_item"
        case nextButton = "next_button"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switchButton = try? container.decode(V4ButtonInfo.self, forKey: .switchButton)
        registerButton = try? container.decode(V4ButtonInfo.self, forKey: .registerButton)
        registerItem = try? container.decode(RegisterItem.self, forKey: .registerItem)
        toast = try? container.decode(String.self, forKey: .toast)

        if let nextBtn = try? container.decode(V4ButtonInfo.self, forKey: .nextButton) {
            nextButton = nextBtn
        } else {
            nextButton = V4ButtonInfo(actionType: .defaultValue, next: nil, text: "")
        }

        if let title_temp = try? container.decode(String.self, forKey: .title) {
            title = title_temp
        } else {
            title = ""
        }

        subtitle = try? container.decode(String.self, forKey: .subtitle)

        if let flowType_temp = try? container.decode(String.self, forKey: .flowType) {
            flowType = flowType_temp
        } else {
            flowType = ""
        }
    }
}

class V4JoinTenantReviewInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let button: V4ButtonInfo?
    let title: String
    let subtitle: String
    
    enum CodingKeys: String, CodingKey {
        case title, subtitle, button
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        button = try? container.decode(V4ButtonInfo.self, forKey: .button)
        if let title_temp = try? container.decode(String.self, forKey: .title) {
            title = title_temp
        } else {
            title = ""
        }
        if let subtitle_temp = try? container.decode(String.self, forKey: .subtitle) {
            subtitle = subtitle_temp
        } else {
            subtitle = ""
        }

        if let flowType_temp = try? container.decode(String.self, forKey: .flowType) {
            flowType = flowType_temp
        } else {
            flowType = ""
        }
    }
}

class V4JoinTenantScanInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String?

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct RSAInfo: Codable {
    let publicKey: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case token = "rsa_token"
    }
}

/// enter_app 返回的 step_info
struct V4EnterAppInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    let toast: String?

    let userList: [V4UserInfo]

    enum CodingKeys: String, CodingKey {
        case userList = "user_list"
        case toast = "toast_msg"
        case usePackageDomain = "use_package_domain"
    }
}

//struct V4UserListInfo: Codable {
//
//    let userList: [V4UserInfo]
//
//    enum CodingKeys: String, CodingKey {
//        case userList = "user_list"
//    }
//}

/// V4UserInfo 是 enter_app 返回的单条 User 数据
/// V4UserInfo 和 V3UserInfo 不同，V4UserInfo `包含` token、session 等信息
/// V4UserInfo 可以在 Passport 内部流转，也推荐在 Passport 内部直接使用这个数据结构，但不会暴露到外部
/// 暴露到外部时使用 `User`，通过 makeUser() 方法可以将一个 V4UserInfo 转成 User
/// 修改模型时注意 PassportStore 要同步更新
struct V4UserInfo: Codable, Hashable {

    let user: V4ResponseUser
    let currentEnv: String
    let logoutToken: String?
    let suiteSessionKey: String?
    // Example:
    // {
    //    "larksuite-boe.com": {
    //      "name": "session",
    //      "value": "XN0YXJ0-******************-WVuZA"
    //    }
    // }
    let suiteSessionKeyWithDomains: [String: [String: String]]?
    let deviceLoginID: String?
    var _invalidSessionFlag: Bool?
    let loginDisabled: Bool?

    /// 如果值为`true`，表示当前 session 是一个无效的占位 session
    /// 可能是由于验证等级不够等导致的账号的半验证状态，服务端返回
    let isAnonymous: Bool
    var isActive: Bool { userStatus == .normal }

    ///是否是第一次创建的session
    let isSessionFirstActive: Bool?

    // MARK: Convenient Properties

    var userID: String { user.id }
    var userGeo: String { user.geo }

    var isChinaMainlandGeo: Bool { EnvManager.validateCountryCodeIsChinaMainland(userGeo) }

    /// 将服务端返回的用户表现状态转换成侧边栏展示需要的状态
    var userStatus: UserStatus {
        var status: UserStatus = .normal
        switch user.status {
        case .enable:
            status = .normal
        case .unactivated:
            status = .new
        case .forbidden, .freeze, .unauthorized, .reviewing:
            status = .restricted
        default:
            status = .normal
        }
        if isAnonymous || suiteSessionKey == nil || (suiteSessionKey?.isEmpty ?? true) || (_invalidSessionFlag != nil) {
            status = .invalid
        }
        return status
    }

    // MARK: 非服务端返回属性

    /// 最近一次活跃时间，当用户成为前台用户时会刷新
    var latestActiveTime: TimeInterval = 0

    enum CodingKeys: String, CodingKey {
        case user = "user"
        case currentEnv = "current_env"
        case logoutToken = "logout_token"
        case suiteSessionKey = "suite_session_key"
        case suiteSessionKeyWithDomains = "suite_session_key_with_domains"
        case deviceLoginID = "device_login_id"
        case isAnonymous = "is_anonymous"
        case _invalidSessionFlag = "_invalidSessionFlag"
        case loginDisabled = "login_disabled"
        case isSessionFirstActive = "is_new_active"
    }

    func makeUser() -> User {
        let tenant = user.tenant.makeTenant()
        let leanModeInfo = user.leanModeInfo?.converToPublic()
        return User(userID: user.id, userStatus: userStatus, name: user.name, displayName: user.displayName, i18nNames: user.i18nNames, i18nDisplayNames: user.i18nDisplayNames,  userCustomAttr: user.userCustomAttr, avatarURL: user.avatarURL, avatarKey: user.avatarKey, logoutToken: logoutToken, tenant: tenant, createTime: user.createTime, enName: "", sessionKey: suiteSessionKey, sessionKeyWithDomains: suiteSessionKeyWithDomains, userEnv: nil, userUnit: user.unit, geo: userGeo, isChinaMainlandGeo: isChinaMainlandGeo, securityConfig: nil, isIdP: nil, isFrozen: false, isActive: false, isGuest: false, upgradeEnabled: nil, authMode: nil, isExcludeLogin: user.excludeLogin ?? false, leanModeInfo: leanModeInfo, isTenantCreator: user.isTenantCreator, deviceLoginID: deviceLoginID)
    }

    func makeAccount() -> Account {
        return Account(user: makeUser())
    }

    init(user: V4ResponseUser, currentEnv: String, logoutToken: String?, suiteSessionKey: String?, suiteSessionKeyWithDomains: [String: [String: String]]?, deviceLoginID: String?, isAnonymous: Bool, latestActiveTime: TimeInterval = 0, loginDisabled: Bool = false, isSessionFirstActive: Bool?) {
        self.user = user
        self.currentEnv = currentEnv
        self.logoutToken = logoutToken
        self.suiteSessionKey = suiteSessionKey
        self.suiteSessionKeyWithDomains = suiteSessionKeyWithDomains
        self.deviceLoginID = deviceLoginID
        self.isAnonymous = isAnonymous
        self.latestActiveTime = latestActiveTime
        self.loginDisabled = loginDisabled
        self.isSessionFirstActive = isSessionFirstActive
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
    }

    static func == (lhs: V4UserInfo, rhs: V4UserInfo) -> Bool {
        return lhs.userID == rhs.userID
    }

}

extension V4UserInfo {
    func toCUserNeedActive() -> Bool {
        return userStatus != .normal && user.tenant.id == "0"
    }
}

extension V4UserInfo: CustomStringConvertible, LogDesensitize {

    var description: String {
        return "\(desensitize())"
    }

    func desensitize() -> [String: String] {
        return [
            V4ResponseUser.CodingKeys.id.rawValue: userID,
            V4ResponseUser.CodingKeys.status.rawValue: SuiteLoginUtil.serial(value: user.status.rawValue),
        ]
    }
}

// MARK: - user operation center
struct V4ResponseCredential: Codable {
    var countryCode: Int32?
    var credential: String
    var credentialId: String
    var credentialType: Int8

    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case credential = "credential"
        case credentialId = "credential_id"
        case credentialType = "credential_type"
    }
}

struct CredentialBindingIdentities: Codable {
    var credential: V4ResponseCredential?
    var userList: [V4UserItem]

    enum CodingKeys: String, CodingKey {
        case credential = "credential"
        case userList = "user_list"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credential = try? container.decode(V4ResponseCredential.self, forKey: .credential)

        if let users = try? container.decode([V4UserItem].self, forKey: .userList) {
            userList = users
        } else {
            userList = []
        }
    }

    init(credential: V4ResponseCredential? = nil, userList: [V4UserItem]) {
        self.credential = credential
        self.userList = userList
    }
}

class V4UserOperationCenterInfo: ServerInfo {
    var flowType: String?
    var nextInString: String?
    var usePackageDomain: Bool?

    var createTenantStep: V4StepData?
    var joinTenantStep: V4StepData?
    var loginStep: V4StepData?
    var officialEmailTenantMap: [String: [V4ResponseTenant]]?
    var personalUseStep: V4StepData?
    var credentialBindingUserList: [CredentialBindingIdentities]
    var currentIdentityBindings: [CredentialBindingIdentities]?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case createTenantStep = "create_tenant_step"
        case joinTenantStep = "join_tenant_step"
        case loginStep = "login_step"
        case officialEmailTenantMap = "official_email_tenant_map"
        case personalUseStep = "personal_use_step"
        case credentialBindingUserList = "credential_binding_identities"
        case currentIdentityBindings = "current_identity_bindings"
        case usePackageDomain = "use_package_domain"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        createTenantStep = try? container.decode(V4StepData.self, forKey: .createTenantStep)
        joinTenantStep = try? container.decode(V4StepData.self, forKey: .joinTenantStep)
        loginStep = try? container.decode(V4StepData.self, forKey: .loginStep)
        officialEmailTenantMap = try? container.decode([String: [V4ResponseTenant]].self, forKey: .officialEmailTenantMap)
        personalUseStep = try? container.decode(V4StepData.self, forKey: .personalUseStep)

        if let unloginUsers = try? container.decode([CredentialBindingIdentities].self, forKey: .credentialBindingUserList) {
            credentialBindingUserList = unloginUsers
        } else {
            credentialBindingUserList = []
        }

        currentIdentityBindings = try? container.decode([CredentialBindingIdentities].self, forKey: .currentIdentityBindings)

        if let flowType_temp = try? container.decode(String.self, forKey: .flowType) {
            flowType = flowType_temp
        } else {
            flowType = ""
        }
    }
}

struct CollectionInfo: Codable {
    var eventKey: String
    var params: [String : String]?

    enum CodingKeys: String, CodingKey {
        case eventKey = "event_key"
        case params = "params"
    }
}

enum DialogScene {
    case unknown
    case sso
    case invalidSession
    case otpIn
}

struct V4ShowDialogStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    var title: String?
    var subTitle: String?
    var btnList: [ActionBtn]?
    var logoutReason: UserCheckSessionItem.LogoutReason?
    var logoutUserID: String?
    var collectionInfo: CollectionInfo?
    
    enum CodingKeys: String, CodingKey {
        case btnList = "button_list"
        case title = "title"
        case subTitle = "subtitle"
        case usePackageDomain = "use_package_domain"
        case logoutReason = "logout_reason"
        case logoutUserID = "logout_user_id"
        case collectionInfo = "collection_info"
    }
    
    struct ActionBtn: Codable {
        
        var actionType: ActionType?
        var nextStep: NextStep?
        var text: String?
        var collectionInfo: CollectionInfo?

        enum CodingKeys: String, CodingKey {
            case actionType = "action_type"
            case nextStep = "next"
            case text = "text"
            case collectionInfo = "collection_info"
        }
        
        enum ActionType: Int, Codable {
            case unknown = 0
            case appeal = 8         // 账号申诉
            case verify = 9         // 验证
            case gotIt = 10         // 我知道了
            case ssoLogin = 22      // sso登录
            case acceptOptIn = 24   // opt-in 接受
            case rejectOptIn = 25   // opt-in 拒绝
            case skipOptIn = 26     // opt-in 跳过
            case sessionReauthGuideDialog = 48      // 风险 session 弹框 (由带图片的大弹窗跳转二次确认小弹框)
            case sessionReauthSwitch = 49           // 风险 session 验证 (session被风控或管理员开启两步验证)
            case sessionReauthExemptRemind = 50     // 风险 session 稍后验证豁免
            case sessionReauthSetupPassword = 55    // 风险 session，管理员密码管控，提示用户前往设置密码或更新密码
            case sessionReauthCancel = 56           // 风险 session，二次确认弹框点击取消
            
            init(from decoder: Decoder) throws {
                let value = try decoder.singleValueContainer().decode(Int.self)
                self = Self(rawValue: value) ?? .unknown
            }
        }
        
        var description: String {
            return "actionType: \(actionType ?? .unknown), nextStep: \(nextStep?.event ?? "")"
        }
    }
    
    struct NextStep: Codable {
        var event: String
        var info: [String: Any]?
        
        enum CodingKeys: String, CodingKey {
            case event = "next_step"
            case info = "step_info"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let data = try? container.decode([String:Any].self, forKey: .info)
            self.event = try container.decode(String.self, forKey: .event)
            self.info = data
        }
        public func encode(to encoder: Encoder) throws {}
    }
}

/// 引导弹窗
struct GuideDialogStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String?
    let subtitle: String?
    let tips: String?
    let descList: [String]?
    let logoutCountDown: String?
    let buttonList: [V4ShowDialogStepInfo.ActionBtn]?
    let dialogType: GuideDialogType?
    let collectionInfo: CollectionInfo?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case title, subtitle, tips
        case descList = "desc_list"
        case logoutCountDown = "logout_count_down"
        case buttonList = "button_list"
        case dialogType = "dialog_type"
        case collectionInfo = "collection_info"
    }

    enum GuideDialogType: Int, Codable {
        case alert = 0
        case actionPanel = 1

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .alert
        }
    }
}

struct SwitchIdentityStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let userList: [SwitchIdentityUserInfo]

    enum CodingKeys: String, CodingKey {
        case userList = "user_list"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

// switch_identity 返回的 User 数据结构
struct SwitchIdentityUserInfo: Codable {
    let user: SwitchIdentityResponseUser
    let currentEnv: String?
    let logoutToken: String?
    let suiteSessionKey: String?
    let deviceLoginID: String?

    enum CodingKeys: String, CodingKey {
        case user = "user"
        case currentEnv = "current_env"
        case logoutToken = "logout_token"
        case suiteSessionKey = "suite_session_key"
        case deviceLoginID = "device_login_id"
    }
}

struct SwitchIdentityResponseUser: Codable {
    let id: String
    let name: String
    var status: UserExpressiveStatus
    let avatarURL: String?
    let avatarKey: String?
    let createTime: TimeInterval
    let credentialID: String
    let unit: String?
    let geo: String?
    let excludeLogin: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, status, unit, geo
        case avatarURL = "avatar_url"
        case avatarKey = "avatar_key"
        case createTime = "create_time"
        case credentialID = "login_credential_id"
        case excludeLogin = "exclude_login"
    }
}

struct ChooseOptInInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var optIn: Bool

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case optIn = "opt_in"
    }
}

// MARK: - 生物因素验证 begin
class V4BioAuthInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var agreeDoc: String?
    var nextButton: V4ButtonInfo? // 人脸识别button
    var switchButton: V4ButtonInfo? // 切换验证方式button
    var title: String?
    var subtitle: String?

    var policyVisible = false
    var policyDomain: String?
    
    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case flowType = "flow_type"
        case agreeDoc = "agree_doc"
        case nextButton = "next_button"
        case switchButton = "switch_button"
        case usePackageDomain = "use_package_domain"
        case policyVisible = "policy_visible"
        case policyDomain = "policy_domain"
    }
}

class V4BioAuthTicketInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var ticket: String?

    var sdkScene: String?
    var aid: String?
    
    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case ticket
        case aid
        case sdkScene = "sdk_scene"
    }
}

class AuthTypeInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    var title: String
    var subtitle: String
    var targetTenantIcon: String?
    var authTypeList: [Menu]
    
    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case authTypeList = "auth_type_list"
        case targetTenantIcon = "target_tenant_icon"
    }
}

struct QRCodeLoginInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let status: QRLoginStatus
    let token: String
    let user: V4ResponseUser?
}

struct QRCodeLoginConfirmInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let qrSource: String
    let suiteInfo: QRCodeLoginConfirmSuiteInfo
    let riskBlockInfo: QRCodeLoginConfirmRiskBlockInfo
    let buttonList: [V4ButtonInfo]?

    enum CodingKeys: String, CodingKey {
        case qrSource = "qr_source"
        case suiteInfo = "suite_info"
        case riskBlockInfo = "risk_block_info"
        case buttonList = "button_list"
    }
}

struct QRCodeLoginConfirmSuiteInfo: Codable {
    let title: String?
    let subtitle: String?
    let tips: String?

    enum CodingKeys: String, CodingKey {
        case title, subtitle, tips
    }
}

struct QRCodeLoginConfirmRiskBlockInfo: Codable {

    enum QRCodeLoginRiskLevel: String, Codable {
        case alert
        case danger
    }

    let riskLevel: QRCodeLoginRiskLevel?
    let riskReason: String?
    let location: String?
    let deviceType: String?
    let deviceName: String?

    enum CodingKeys: String, CodingKey {
        case riskLevel = "risk_level"
        case riskReason = "risk_reason"
        case location
        case deviceType = "device_type"
        case deviceName = "device_name"
    }
}

struct ResetOtpInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    var url: String?
}

struct GetAuthURLInfo: ServerInfo, RawStepInfoKeepable {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    /// 保存由服务端返回的原始 step info dictionary
    var rawStepInfo: [String: Any]?

    let tenantDomain: String?
    let channel: LoginCredentialIdpChannel?
    let userID: String?
    let targetSessionKey: String?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case tenantDomain = "tenant_domain"
        case channel
        case userID = "user_id"
        case targetSessionKey = "target_session_key"
        case usePackageDomain = "use_package_domain"
    }
}

struct OKInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct RealNameGuideWayInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    var appealType: Int?
    
    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case appealType = "appeal_type"
    }
}

struct SetCredentialInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String
    let credentialType: CredentialType
    let inputPlaceHolder: V4InputPlaceholder
    let rawCountryCode: String?
    var countryCode: String? {
        if let code = rawCountryCode, !code.isEmpty {
            return "+" + code
        }
        return nil
    }
    let unit: String?
    let tenantBrand: String?
    let allowRegionList: [String]?
    let blockRegionList: [String]?
    let tip: String?
    
    enum CredentialType: Int, Codable {
        case phone = 1
        case email = 2
    }

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case credentialType = "credential_type"
        case flowType = "flow_type"
        case inputPlaceHolder = "credential_input"
        case rawCountryCode = "country_code"
        case unit = "identity_unit"
        case tenantBrand = "tenant_brand"
        case usePackageDomain = "use_package_domain"
        case allowRegionList = "allow_region_list"
        case blockRegionList = "block_region_list"
        case tip
    }
}

struct CloseAllInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    let toast: String?
    
    enum CodingKeys: String, CodingKey {
        case toast = "toast_msg"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct VerificationCompletedInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    /// e.g. "verify_token_key": "0ea9f00d-67a3-4ff4-a210-449fce4264c6:verify_token"
    let verifyTokenKey: String?
    let scope: String?
    let mfaToken: String?
    let mfaCode: String?
    

    enum CodingKeys: String, CodingKey {
        case verifyTokenKey = "verify_token_key"
        case mfaToken = "mfa_token"
        case mfaCode = "mfa_code"
        case scope = "scope"
    }
}

class VerifyTokenCompletionWrapper: Codable {

    var completion: ((Result<VerifyToken, Error>) -> Void)?

    enum CodingKeys: CodingKey {
    }

    internal init(completion: ((Result<VerifyToken, Error>) -> Void)? = nil) {
        self.completion = completion
    }

}

struct CheckSecurityPasswordStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    let isOpen: Bool
    let nextStep: V4StepData
    
    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case isOpen = "is_open"
        case nextStep = "next_step"
        case usePackageDomain = "use_package_domain"
    }
}

struct VerifySecurityPasswordStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String
    let nextButton: V4ButtonInfo
    let forgetButton: V4ButtonInfo

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case flowType = "flow_type"
        case nextButton = "next_button"
        case forgetButton = "forget_sec_pwd_button"
        case usePackageDomain = "use_package_domain"
    }
}

struct SetSecurityPasswordStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String
    let subtitle: String
    let confirmTitle: String
    let confirmSubtitle: String
    let nextButton: V4ButtonInfo
    let pwdWeakRegExp: String
    let pwdWeakErrMsg: String

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case flowType = "flow_type"
        case confirmTitle = "confirm_title"
        case confirmSubtitle = "confirm_sub_title"
        case nextButton = "next_button"
        case usePackageDomain = "use_package_domain"
        case pwdWeakRegExp = "pwd_weak_reg_exp"
        case pwdWeakErrMsg = "pwd_weak_err_msg"
    }
    
}

struct AddMailStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    let title: String
    let subtitle: String
    let tip: String
    let nextButton: V4ButtonInfo
    let emailInput: V4InputPlaceholder
    
    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case title, subtitle, tip
        case nextButton = "next_button"
        case emailInput = "email_input"
    }
}

struct CheckABTestForUGResp: Codable {

    let enable: Bool

    enum CodingKeys: String, CodingKey {
        case enable = "is_ug_enable"
    }
}

struct UGCreateTenantInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct UGJoinByCodeInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    let tenantCode: String

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case tenantCode = "tenant_code"
        case usePackageDomain = "use_package_domain"
    }
}

struct ChangeGeoStepInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    let targetDomain: String

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case targetDomain = "target_domain"
    }
}

struct MFAStatusInfo: Codable {

    let status: MFATokenStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

struct MFACheckResponse: Codable {

    let stepInfo: MFAStatusInfo

    enum CodingKeys: String, CodingKey {
        case stepInfo = "step_info"
    }
}

struct MFANewCheckResponse: Codable {
    let tokenStatus: MFATokenNewStatus

    enum CodingKeys: String, CodingKey {
        case tokenStatus = "token_status"
    }
}

struct SetSpareCredentialInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    let title: String?
    let subtitle: String?
    let tenantBrand: String?
    let credentialInputList: [V4CredentialInputInfo]
    let nextButton: V4ButtonInfo?
    let skipButton: V4ButtonInfo?

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case tenantBrand = "tenant_brand"
        case credentialInputList = "credential_input_list"
        case flowType = "flow_type"
        case nextButton = "next_button"
        case skipButton = "skip_button"
        case usePackageDomain = "use_package_domain"
    }
}

struct ShowPageInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let imageType: ImageType
    let title: String?
    let subtitle: String?
    let buttonList: [V4ButtonInfo]
    let toast: String?

    enum ImageType: Int, Codable {
        case none = 0           // 不展示图片
        case joinInSuccess = 1  // 加入成功
        case notJoinedIn = 2    // 未加入企业

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value) ?? .none
        }
    }

    enum CodingKeys: String, CodingKey {
        case title, subtitle, toast
        case imageType = "image_type"
        case buttonList = "button_list"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
    }
}

struct LeanModeInfo: Codable {
    
    let deviceHaveAuthority: Bool
    let isLockScreenEnabled: Bool
    let lockScreenPwd: String?
    let allDevicesInLeanMode: Bool
    let canUseLeanMode: Bool
    let lockScreenCfgUpdateTime: Int64
    let leanModeCfgUpdateTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case deviceHaveAuthority = "device_have_authority"
        case isLockScreenEnabled = "is_lock_screen_enabled"
        case lockScreenPwd = "lock_screen_pwd"
        case allDevicesInLeanMode = "all_devices_in_lean_mode"
        case canUseLeanMode = "can_use_lean_mode"
        case lockScreenCfgUpdateTime = "lock_screen_cfg_update_time"
        case leanModeCfgUpdateTime = "lean_mode_cfg_update_time"
    }
    
    func converToPublic() -> LarkAccountInterface.LeanModeInfo {
        return LarkAccountInterface.LeanModeInfo(deviceHaveAuthority: deviceHaveAuthority,
                                                 isLockScreenEnabled: isLockScreenEnabled,
                                                 lockScreenPwd: lockScreenPwd,
                                                 allDevicesInLeanMode: allDevicesInLeanMode,
                                                 canUseLeanMode: canUseLeanMode,
                                                 lockScreenCfgUpdateTime: lockScreenCfgUpdateTime,
                                                 leanModeCfgUpdateTime: leanModeCfgUpdateTime
                                                )
    }
    
}

struct PassportGrayItem: Codable {
    let isOn: Bool
    let code: Int
    enum CodingKeys: String, CodingKey {
        case isOn = "is_gray"
        case code = "err_code"
    }
}
