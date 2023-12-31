//
//  V3InputCredentialViewModel.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
//

import Foundation
import RxRelay
import RxSwift
import LKCommonsLogging
import Homeric
import CoreTelephony
import LarkContainer
import LarkPerf
import ECOProbeMeta
import LarkAccountInterface
import LarkReleaseConfig

enum Process: String {
    case login
    case register
    case join
}

enum SuiteLoginMethod: String, Codable {
    case phoneNumber = "mobile"
    case email = "email"

    // CredentialType 是用户的登录凭证类型，1手机号 2邮箱
    func toCredentialType() -> Int {
        switch self {
        case .phoneNumber:
            return 1
        case .email:
            return 2
        }
    }
}

struct V3InputCredentialConfig {
    let loginType: SuiteLoginMethod // 默认的登录方式
    let countryCode: String
    let emailRegex: String
    let enableMobileReg: Bool
    let enableEmailReg: Bool
    let registerType: SuiteLoginMethod // 默认的注册方式
    let registerCountryCode: String // 默认使用的国家码
    let enableLoginJoinType: Bool // login page support join team
    let enableRegisterJoinType: Bool // register page support join team
}

class V3InputCredentialBaseViewModel: V3ViewModel {
    let logger = Logger.plog(V3InputCredentialBaseViewModel.self, category: "SuiteLogin.vm.input.credential")
    public var method: BehaviorRelay<SuiteLoginMethod>
    public var process: BehaviorRelay<Process>

    /// 手机区号 +86
    public var credentialRegionCode: BehaviorRelay<String>
    /// 手机号（不带区号） 155 5555 5555
    public var credentialPhone: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 邮箱
    public var credentialEmail: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 姓名，目前仅团队注册信息填写页需要
    public var name: BehaviorRelay<String> = BehaviorRelay(value: "")

    @Provider var api: LoginAPI

    /// 页面配置
    public let config: V3InputCredentialConfig

    @Provider var ugService: AccountServiceUG
    /// 是否走 ug 的注册流程; 默认为 true
    public var ugRegistEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)

    private(set) var inputInfo: V3InputInfo?

    lazy public var emailRegex: NSPredicate = {
        return NSPredicate(format: "SELF MATCHES %@", config.emailRegex)
    }()

    public var isTextFieldFocus = false

    /// oneKeyLogin when from Lauch Guide
    var fromLaunchGuide: Bool = false
    /// oneKeyLogin when from User Center
    var fromUserCenter: Bool = false

    public let simplifyLogin: Bool

    @Provider var idpService: IDPServiceProtocol

    /// 保存快照值
    public lazy var resultSupportChannel = {
        idpService.resultSupportCIdPChannels
    }()

    public init(
        step: String,
        process: Process,
        config: V3InputCredentialConfig,
        inputInfo: V3InputInfo? = nil,
        simplifyLogin: Bool = false,
        context: UniContextProtocol
    ) {
        var method: SuiteLoginMethod
        var regionCode: String
        switch process {
        case .login:
            method = config.loginType
            regionCode = config.countryCode
        case .register, .join:
            method = config.registerType
            regionCode = config.registerCountryCode
        }

        self.method = BehaviorRelay(value: method)
        self.process = BehaviorRelay(value: process)
        self.config = config
        self.credentialRegionCode = BehaviorRelay(value: regionCode)
        self.simplifyLogin = simplifyLogin

        if let info = inputInfo {
            // 检查与config的是否冲突
            if info.method == .email && config.enableEmailReg {
                self.inputInfo = info
            }
            if info.method == .phoneNumber && config.enableMobileReg {
                self.inputInfo = info
            }
            if let value = self.inputInfo {
                // 有设置 更新 method
                self.method.accept(value.method)
            }
        }
        super.init(step: step, stepInfo: PlaceholderServerInfo(), context: context)
        ugService.getTCCValueForGlobalRegist { [weak self] result in
            self?.ugRegistEnable.accept(result)
        }
    }

    private let cellularData = CTCellularData()

    private var credentialPhoneNoWhiteSpace: String {
        return credentialPhone.value.replacingOccurrences(of: " ", with: "")
    }

    private var credentialRegionCodeNoPlus: String {
        return credentialRegionCode.value.replacingOccurrences(of: "+", with: "")
    }

    private var credential: String {
        switch method.value {
        case .email:
            return credentialEmail.value
        case .phoneNumber:
            return credentialRegionCode.value + credentialPhoneNoWhiteSpace
        }
    }

    public func storeLoginConfig() {
        let method = self.method.value
        let regionCode = self.credentialRegionCode.value
        service.storeLoginConfig(method, regionCode: regionCode)
    }

    public func clickNextButton() -> Observable<()> {
        let credential = self.credential
        let method = self.method.value
        let regionCode = self.credentialRegionCode.value
        let name = self.name.value
        switch method {
        case .email:
            UploadLogManager.shared.contactPoint = self.credentialEmail.value
            self.context.credential.cp = UploadLogManager.shared.contactPoint
        case .phoneNumber:
            UploadLogManager.shared.contactPoint = "+" + self.credentialRegionCodeNoPlus + self.credentialPhoneNoWhiteSpace
            self.context.credential.cp = UploadLogManager.shared.contactPoint
        }
        PassportProbeHelper.shared.contactPoint = UploadLogManager.shared.contactPoint
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.login_page_goto_next_click, context: context)

        return doType(
            serverInfo: stepInfo,
            contact: credential,
            method: method,
            regionCode: regionCode,
            name: name
        )
    }

    func doType(
        serverInfo: ServerInfo,
        contact: String,
        method: SuiteLoginMethod,
        regionCode: String,
        name: String
    ) -> Observable<Void> {
        assertionFailure("must impl by subclass")
        return .just(())
    }

    func currentInputInfo() -> V3InputInfo? {
        var contact = ""
        switch method.value {
        case .email:
            contact = credentialEmail.value
        case .phoneNumber:
            contact = credentialPhoneNoWhiteSpace
        }

        // save from next button
        if contact.isEmpty, let userLoginConfig = service.userLoginConfig {
            return V3InputInfo(contact: "", countryCode: userLoginConfig.regionCode, method: userLoginConfig.loginType)
        } else {
            return V3InputInfo(contact: contact, countryCode: credentialRegionCode.value, method: method.value)
        }
    }

    func doJoinType() -> Observable<Void> {
        logger.info("do join type")
        return api
            .joinType()
            .post(V3LoginAdditionalInfo(trackPath: TrackConst.pathJoin), context: context)
    }


    func fetchPrepareTenantInfo() -> Observable<Void> {
        logger.info("do prepare tenant")
        return api.fetchPrepareTenantInfo(context: context).post(context: UniContextCreator.create(.register))
    }

    #if BYTEST_AUTO_LOGIN
    func autoLogin(phoneNumber: String, password: String, code: String) -> Observable<()> {
        let loginSceneInfo = [
          MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterContact.rawValue,
          MultiSceneMonitor.Const.type.rawValue: "login",
          MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        var serverInfo: VerifyInfoProtocol?
        let autoLoginContext = UniContextCreator.create()
        return api.loginType(contact: phoneNumber, sceneInfo: loginSceneInfo, context: autoLoginContext)
              .do { (resp) in
                //post会返回Observable<Void>，进入验证页面，没有获取到账号验证的返回值，所以直接提前一步将resp的内容保存在serverInfo中
                serverInfo = PassportStep(rawValue: resp.stepData.nextStep)?.pageInfo(with: resp.stepData.stepInfo) as? VerifyInfoProtocol
              }
              .post(context: autoLoginContext)
              .flatMap({ _ -> Observable<()> in
                if let verifyInfo = serverInfo {
                  if verifyInfo.type == .code {
                    let sceneInfo = [
                      MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyCode.rawValue,
                      MultiSceneMonitor.Const.type.rawValue: verifyInfo.type == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                      MultiSceneMonitor.Const.result.rawValue: "success"
                    ]
                    //验证码验证
                    return self.api.verify(sourceType: verifyInfo.verifyCode?.sourceType, code: code, contactType: nil, sceneInfo: sceneInfo, context: autoLoginContext).post(context: autoLoginContext)
                  } else if verifyInfo.type == .pwd {
                    let sceneInfo = [
                      MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyPWD.rawValue,
                      MultiSceneMonitor.Const.type.rawValue: verifyInfo.type == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                      MultiSceneMonitor.Const.result.rawValue: "success"
                    ]
                    //密码验证
                    return self.api.verify(password: password, rsaInfo: verifyInfo.verifyPwd?.rsaInfo, contactType: nil, sceneInfo: sceneInfo, context: autoLoginContext)
                      .do { (resp) in
                        //原因同上
                        serverInfo = PassportStep(rawValue: resp.stepData.nextStep)?.pageInfo(with: resp.stepData.stepInfo) as? VerifyInfoProtocol
                      }
                      .post(context: autoLoginContext)
                      .flatMap { (_) -> Observable<()> in
                        if let verifyInfo = serverInfo,
                          verifyInfo.type == .code {
                          //密码验证-》验证码验证
                          return self.api.verify(sourceType: verifyInfo.verifyCode?.sourceType, code: code, contactType: nil, sceneInfo: nil, context: autoLoginContext).post(context: autoLoginContext)

                        }
                        return Observable.just(())
                      }
                  }
                }
                return Observable.just(())
              })
         }
    #endif
}

// MARK: VM

extension V3InputCredentialBaseViewModel {
    var processName: String {
        return process.value.rawValue
    }

    func shouldShowAgreementAlertForCurrentEnv() -> Bool {
        return true
        //return PassportConf.shared.featureSwitch.bool(for: .suiteSoftwareUserAgreement)
        //    && PassportConf.shared.featureSwitch.bool(for: .suiteSoftwarePrivacyAgreement)
    }
}

// swiftlint:disable ForceUnwrapping
enum Link {
    static var registerURL = URL(string: "//register")!
    static var loginURL = URL(string: "//login")!
    static var resetPwdURL = URL(string: "//reset")!
    static var recoverAccountCarrierURL = URL(string: "//recoverAccountCarrier")!
    static var retrieveAction = URL(string: "//retrieveAction")!
    static var termURL = URL(string: "//serviceTerm")!
    static var privacyURL = URL(string: "//privacy")!
    static var alertTermURL = URL(string: "//alertServiceTerm")!
    static var alertPrivacyURL = URL(string: "//alertPrivacy")!
    static var personalUseURL = URL(string: "https://personal_use")!
    static var oneKeyLoginPolicyURL = URL(string: "//oneKeyLoginPolicy")!
    static var alertOneKeyLoginPolicyURL = URL(string: "//alertOneKeyLoginPolicy")!
    static var joinMeetingURL = URL(string: "//joinMeeting")!
    static var accountAppealURL = URL(string: "//accountAppeal")!
    static var identityURL = URL(string: "//identity")!
    static var faceIdURL = URL(string: "//face-id")!
}
// swiftlint:enable ForceUnwrapping
