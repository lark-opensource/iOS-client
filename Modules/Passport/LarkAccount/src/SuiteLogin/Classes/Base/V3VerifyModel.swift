//
//  V3VerifyPageInfo.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/5/26.
//

import Foundation
import RxSwift

protocol VerifyAPIProtocol {

    func applyCode(
        serverInfo: ServerInfo,
        flowType: String?,
        contactType: Int?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func applyCode(
        sourceType: Int?,
        contactType: Int?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        password: String,
        rsaInfo: RSAInfo?,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func v3Verify(
        sourceType: Int?,
        code: String,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func verifyOtp(
        sourceType: Int?,
        code: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func v4VerifyOtp(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func recoverType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func retrieveGuideWay(
        serverInfo: ServerInfo,
        flowType: String?,
        action: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func verifyMo(
        serverInfo: ServerInfo,
        flowType: String?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

        
}

enum VerifyType: String, Codable {
    case code = "verify_code"
    case pwd = "verify_pwd"
    case forgetVerifyCode = "forget_verify_code"
    case otp = "verify_otp"
    case spareCode = "verify_code_spare"
    case mo = "verify_mo"
    case fido = "verify_fido"
}

struct VerifyTypeEnable: OptionSet, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let pwd = VerifyTypeEnable(rawValue: 1)
    public static let code = VerifyTypeEnable(rawValue: 1 << 1)
    public static let forgetVerifyCode = VerifyTypeEnable(rawValue: 1 << 2)
    public static let magicLink = VerifyTypeEnable(rawValue: 1 << 3)
    public static let verifyFace = VerifyTypeEnable(rawValue: 1 << 4)
    public static let otp = VerifyTypeEnable(rawValue: 1 << 5)
    public static let spareCode = VerifyTypeEnable(rawValue: 1 << 6)
    public static let mo = VerifyTypeEnable(rawValue: 1 << 7)
    public static let fido = VerifyTypeEnable(rawValue: 1 << 8)

    func verifyTypeCount() -> Int {
        // 按位计算验证方式下发的个数
        var verifySetRawValue = self.rawValue
        var verifySetCount = 0
        while verifySetRawValue != 0 {
            verifySetCount += verifySetRawValue % 2
            verifySetRawValue /= 2
        }
        return verifySetCount
    }
}

enum RecoverAccountMethod: Int, Codable {
    /// 未知类型
    case unknown = 0
    /// 三要素验证，正常认证
    case threeFactor = 1
    /// 账号申诉流程，无法正常走认证
    case appeal = 2
    /// PC/Web 提示移动端操作
    case reminderToMobile = 3
}

struct VerifyPageInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let title: String?
    let subTitle: String

    let inputBox: InputInfo?
    let nextButton: V4ButtonInfo?
    let passwordButton: V4ButtonInfo?
    let codeButton: V4ButtonInfo?
    let spareCodeButton: V4ButtonInfo?
    let otpButton: V4ButtonInfo?
    let forgetPasswordButton: V4ButtonInfo?
    let fidoButton: V4ButtonInfo?
    let moButton: V4ButtonInfo?
    let retrieveButton: V4ButtonInfo?

    let rsaInfo: RSAInfo?

    let contact: String?
    let verifyCodeTip: String?
    let sourceType: Int?
    let contactType: Int?

    let showRecoverAccount: Bool?
    let method: RecoverAccountMethod? // 账号找回认证方式
    let appealUrl: String?  // 账号申诉Url
    let unit: String?
    
    //短信上行相关
    let sendMoButton: V4ButtonInfo?
    let moTextList: [moTextBox]?

    enum CodingKeys: String, CodingKey {
        case flowType = "flow_type"
        case title = "title"
        case subTitle = "subtitle"
        case inputBox = "input_box"
        case nextButton = "next_button"
        case passwordButton = "pwd_button"
        case codeButton = "code_button"
        case spareCodeButton = "spare_code_button"
        case otpButton = "otp_button"
        case moButton = "mo_button"
        case fidoButton = "fido_button"
        case forgetPasswordButton = "forget_pwd_button"
        case retrieveButton = "retrieve_button"
        case sendMoButton = "send_mo_button"
        case rsaInfo = "rsa_info"
        case moTextList = "mo_text"
        case contact = "contact"
        case contactType = "contact_type"
        case verifyCodeTip = "verify_code_tip"
        case sourceType = "source_type"
        case showRecoverAccount = "show_recover_account"
        case unit = "unit"
        case method
        case appealUrl = "appeal_url"
        case usePackageDomain = "use_package_domain"
    }
}


struct moTextBox: Codable {
    let title: String?
    let content: String?
    let copyButton: V4ButtonInfo?
    
    enum CodingKeys: String, CodingKey {
        case title,content
        case copyButton = "button"
    }
}

protocol VerifyInfoProtocol: ServerInfo {
    static var contactPlaceholder: String { get }

    var defaultType: VerifyType { get }
    var enableChange: VerifyTypeEnable { get }
    var verifyCode: VerifyPageInfo? { get }
    var verifyPwd: VerifyPageInfo? { get }
    var verifyOtp: VerifyPageInfo? { get }
    var verifyCodeSpare: VerifyPageInfo? { get }
    var verifyMo: VerifyPageInfo? { get }
    var verifyFido: VerifyPageInfo? { get }
    var forgetVerifyCode: VerifyPageInfo? { get }
    var recoverAccount: VerifyPageInfo? { get }
    var enableClientLoginMethodMemory: Bool? { get }
}

extension VerifyInfoProtocol {
    static var contactPlaceholder: String {
         return "{{contact}}"
    }
}

class VerifyInfoBase<Step: RawRepresentable>: ServerInfo, VerifyInfoProtocol where Step.RawValue == String {

    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let defaultType: VerifyType
    let enableChange: VerifyTypeEnable
    let verifyCode: VerifyPageInfo?
    let verifyPwd: VerifyPageInfo?
    let verifyOtp: VerifyPageInfo?
    let verifyCodeSpare: VerifyPageInfo?
    let forgetVerifyCode: VerifyPageInfo?
    let recoverAccount: VerifyPageInfo?
    let verifyMo: VerifyPageInfo?
    let verifyFido: VerifyPageInfo?
    var enableClientLoginMethodMemory: Bool?

    enum CodingKeys: String, CodingKey {
        case defaultType = "type"
        case enableChange = "enable_change"
        case verifyCode = "verify_code"
        case verifyPwd = "verify_pwd"
        case verifyOtp = "verify_otp"
        case verifyFido = "verify_fido"
        case forgetVerifyCode = "forget_verify_code"
        case recoverAccount = "recover_account"
        case verifyCodeSpare = "verify_code_spare"
        case usePackageDomain = "use_package_domain"
        case verifyMo = "verify_mo"
        case enableClientLoginMethodMemory = "enable_client_login_method_memory"
    }

    init(
        defaultType: VerifyType,
        enableChange: VerifyTypeEnable,
        verifyCode: VerifyPageInfo?,
        verifyPwd: VerifyPageInfo?,
        verifyOtp: VerifyPageInfo?,
        verifyCodeSpare: VerifyPageInfo?,
        forgetVerifyCode: VerifyPageInfo?,
        recoverAccount: VerifyPageInfo?,
        verifyMo: VerifyPageInfo?,
        verifyFido: VerifyPageInfo?,
        enableClientLoginMethodMemory: Bool?
    ) {
        self.defaultType = defaultType
        self.enableChange = enableChange
        self.verifyCode = verifyCode
        self.verifyPwd = verifyPwd
        self.verifyOtp = verifyOtp
        self.forgetVerifyCode = forgetVerifyCode
        self.recoverAccount = recoverAccount
        self.verifyCodeSpare = verifyCodeSpare
        self.verifyMo = verifyMo
        self.verifyFido = verifyFido
        self.enableClientLoginMethodMemory = enableClientLoginMethodMemory
    }
}

class V4VerifyInfoBase<Step: RawRepresentable>: ServerInfo, VerifyInfoProtocol where Step.RawValue == String {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let defaultType: VerifyType
    let verifyCode: VerifyPageInfo?
    let verifyPwd: VerifyPageInfo?
    let verifyOtp: VerifyPageInfo?
    let verifyCodeSpare: VerifyPageInfo?
    let forgetVerifyCode: VerifyPageInfo?
    let recoverAccount: VerifyPageInfo?
    let verifyMo: VerifyPageInfo?
    let verifyFido: VerifyPageInfo?
    //是否使用本地存储的验证方式
    var enableClientLoginMethodMemory: Bool?
    //返回的时候是否回到 feed 页面;
    //https://meego.bytedance.net/larksuite/issue/detail/2768937?#detail
    let backToFeed: Bool?

    var enableChange: VerifyTypeEnable {
        var verifySet = VerifyTypeEnable(rawValue: 0)
        if verifyCode != nil {
            verifySet.update(with: .code)
        }
        if verifyOtp != nil {
            verifySet.update(with: .otp)
        }
        if verifyCodeSpare != nil {
            verifySet.update(with: .spareCode)
        }
        if verifyPwd != nil {
            verifySet.update(with: .pwd)
        }
        if verifyMo != nil {
            verifySet.update(with: .mo)
        }
        if verifyFido != nil {
            verifySet.update(with: .fido)
        }
        return verifySet
    }
//    let defaultVerifyItem: String?

    enum CodingKeys: String, CodingKey {

//        case enableChange = "enable_change"
        case verifyCode = "verify_code"
        case verifyPwd = "verify_pwd"
        case verifyOtp = "verify_otp"
        case verifyCodeSpare = "verify_code_spare"
        case verifyMo = "verify_mo"
        case verifyFido = "verify_fido"
        case forgetVerifyCode = "forget_verify_code"
        case recoverAccount = "recover_account"
        case defaultType = "default_verify_item"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case backToFeed = "back_to_feed"
        case enableClientLoginMethodMemory = "enable_client_login_method_memory"
    }

    init(
        type: VerifyType,
        verifyCode: VerifyPageInfo?,
        verifyPwd: VerifyPageInfo?,
        verifyOtp: VerifyPageInfo?,
        verifyMo: VerifyPageInfo?,
        verifyFido: VerifyPageInfo?,
        verifyCodeSpare: VerifyPageInfo?,
        forgetVerifyCode: VerifyPageInfo?,
        recoverAccount: VerifyPageInfo?,
        flowType: String?,
        enableClientLoginMethodMemory: Bool?

    ) {
        self.defaultType = type
        self.verifyCode = verifyCode
        self.verifyPwd = verifyPwd
        self.verifyOtp = verifyOtp
        self.verifyMo = verifyMo
        self.verifyFido = verifyFido
        self.forgetVerifyCode = forgetVerifyCode
        self.recoverAccount = recoverAccount
        self.flowType = flowType
        self.verifyCodeSpare = verifyCodeSpare
        self.backToFeed = false
        self.enableClientLoginMethodMemory = enableClientLoginMethodMemory
    }
}

//存储凭证与验证方式的映射
class MethodRecordMap : CanCompareByKey, Codable {

    var key: String = ""
    var verifyMethod: String

    init(key: String, verifyMethod rawValue: String) {
        self.key = key
        self.verifyMethod = rawValue
    }

    func isKeyEqual(other : MethodRecordMap) -> Bool {
        return self.key == other.key
    }
}


protocol CanCompareByKey {
    var key: String { get set }
    func isKeyEqual(other : Self) -> Bool
}

class LRUQueue<T : Codable & CanCompareByKey> : Codable {
    private var data = [T]()
    var capacity : Int

    public init(capacity: Int) {
        self.capacity = capacity
    }

    public func append(NewRecord: T) {
        var needRemoveIndex: Int?
        for index in 0 ..< data.count {
            let element = data[index]
            if element.isKeyEqual(other: NewRecord) {
                needRemoveIndex = index
                break
            }
        }
        if let needRemoveIndex = needRemoveIndex {
            data.remove(at: needRemoveIndex)
        }

        data.append(NewRecord)

        if data.count >= capacity {
            data.removeFirst()
        }

    }

    public func getRecord(From key: String) -> T?{
        for element in data {
            if element.key == key {
                return element
            }
        }
        return nil
    }

    enum CodingKeys: CodingKey {
        case data
        case capacity
    }

}
