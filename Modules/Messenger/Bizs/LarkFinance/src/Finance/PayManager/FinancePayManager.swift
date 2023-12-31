//
//  FinancePayManager.swift
//  LarkFinance
//
//  Created by lichen on 2018/11/13.
//

import UIKit
import LarkStorage
import LarkContainer

#if canImport(CJPay)
import CJPay
import LarkEnv
import Foundation
import LarkUIKit
import LarkLocalizations
import LKCommonsLogging
import CJPay
import CJPayDebugTools
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkFoundation
import LarkAccountInterface
import LarkContainer
import LarkSetting
import LarkPrivacySetting

public final class FinancePayManager: NSObject, PayManagerService, UserResolverWrapper {
    static let logger = Logger.log(FinancePayManager.self, category: "finance.pay.manager")

    static let payTokenKey: String = "tp_lark_token"

    static var liveness: PayManagerFaceLiveness = {
        let liveness = PayManagerFaceLiveness()
        CJPayProtocolManager.bindObject(liveness, to: CJPayFaceLivenessProtocol.self)
        return liveness
    }()

    public var userResolver: LarkContainer.UserResolver
    let disposeBag: DisposeBag = DisposeBag()

    let trackerProxy: PayManagerTrackerProxy

    let bizWebImpl: PayManagerBizWebImpl

    public var payToken: String? {
        didSet {
            if payToken == nil {
                FinancePayManager.logger.info("clear paytoken")
            } else {
                FinancePayManager.logger.info("set paytoken")
            }
        }
    }

    public let currentUserID: String
    public let appID: String
    public let deviceID: String
    public let installID: String

    public let testEnv: Bool
    private let redPacketAPI: RedPacketAPI

    // 记录是否已经初始化过 cjpay
    private var cjPayHadInit: Bool = false

    private var payCallback: PayManagerCallBack?

    private var closeDouyinPayFG: Bool { userResolver.fg.dynamicFeatureGatingValue(with: "lark.redpacket.douyin.pay.close") }

    /// e.g: pay.feishu.cn
    private var hongbaoHost: String {
        let host = DomainSettingManager.shared.currentSetting[.cjHongbao]?.first ?? ""
        assert(!host.isEmpty)
        if host.isEmpty {
            Self.logger.error("Hongbao host is empty.")
        }
        return host
    }

    /// e.g: .feishu.cn
    private var hongbaoDomain: String {
        let host = hongbaoHost
        if let indexOfPoint = host.firstIndex(of: ".") {
            return String(host[indexOfPoint...])
        }
        assert(false, "HongbaoHost is not vailed.")
        return ""
    }

    public func handle(open url: URL) -> Bool {
        let result = CJPayAPI.canProcessURL(url)
        FinancePayManager.logger.info("handle open url result \(result)")
        return result
    }

    public func fetchPayTokenIfNeeded() {
        // 获取权限SDK支付开关，默认打开，无权限则不拉取token
        let isPay = LarkPayAuthority.checkPayAuthority()
        FinancePayManager.logger.info("fetchPayTokenIfNeeded isPay: \(isPay)")
        if self.payToken == nil, isPay {
            FinancePayManager.logger.info("fetchPaytoken")
            self.fetchPaytoken(callBack: nil)
        }
    }

    public func cjpayInitIfNeeded(callback: ((Error?) -> Void)?) {
        self.setupCookie(callBack: callback)
    }

    public func pay(paramsString: String, referVc: UIViewController, payCallback: PayManagerCallBack, paymentMethod: PaymentMethod) {
        self.setupCookie { [weak self] (error) in
            guard let `self` = self else { return }

            if let err = error {
                Self.logger.info("set up cookie error: \(err) ")
                payCallback.callDeskCallback(false)
                return
            }

            FinancePayManager.logger.info("pay", additionalData: ["paytokenLength": "\(self.payToken?.count ?? 0)",
                                                                  "paymentMethod": "\(paymentMethod)"])

            self.payCallback = nil

            switch paymentMethod {
            case .caijingPay, .unknown:
                //老的聚合支付收银台目前已废弃，后期统一治理
                guard let urlComponents = URLComponents(string: paramsString) else {
                    Self.logger.info("paramsString URLString is malformed")
                    payCallback.callDeskCallback(false)
                    return
                }
                let queryItems = urlComponents.queryItems ?? []
                let params: [String: Any] = queryItems.reduce([String: String]()) { (result, item) -> [String: Any] in
                    var result = result
                    result[item.name] = item.value
                    return result
                }
                self.payCallback = payCallback
                Self.logger.info("open pay desk for caijingPay")
                CJPayAPI.openPayDesk(withConfig: [CJPayPropertyReferVCKey: referVc], orderParams: params, with: self)
            case .bytePay:
                guard let data = paramsString.data(using: .utf8),
                      let dic = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                    Self.logger.info("paramsString json serialization failure")
                    payCallback.callDeskCallback(false)
                    return
                }
                self.payCallback = payCallback
                Self.logger.info("open bdPay desk for bytePay")
                CJPayAPI.openBDPayDesk(withConfig: [CJPayPropertyReferVCKey: referVc, CJPayPropertyIsHiddenLoadingKey: true], orderParams: dic, delegate: self)
            @unknown default:
                break
            }
        }
    }

    public func openTransaction(referVc: UIViewController) {
        self.setupCookie { (error) in
            if error != nil { return }
            CJPayAPI.open(
                withConfig: [CJPayPropertyReferVCKey: referVc],
                scheme: SchemeFactory.generate(for: .transaction),
                with: nil
            )
        }
    }

    public func openPaySecurity(referVc: UIViewController) {
        self.setupCookie { (error) in
            if error != nil { return }
            let appidNSStr = NSString(string: WalletInfo.appID)
            appidNSStr.cjpay_referViewController = referVc
            CJPayAPI.open(
                withConfig: [CJPayPropertyReferVCKey: referVc],
                scheme: SchemeFactory.generate(for: .security),
                with: nil
            )
        }
    }

    // 打开网页
    public func open(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)?) {
        self.setupCookie { [weak self] (error) in
            guard let self = self else { return }
            if error != nil { return }
            FinancePayManager.logger.info("open url", additionalData: ["paytokenLength": "\(self.payToken?.count ?? 0)"])
            CJPayAPI.open(withConfig: [CJPayPropertyReferVCKey: referVc], scheme: url, with: CJPayAPICallBack(callBack: { (response) in
                guard let callback = closeCallBack else { return }
                callback(response.data ?? [:])
            }))
        }
    }

    // open bank card list view controller
    public func openBankCardList(referVc: UIViewController) {
        self.setupCookie { [weak self] (error) in
            guard let self = self else { return }
            if error != nil { return }
            let merchantID = NSString(string: WalletInfo.merchantID)
            merchantID.cjpay_referViewController = referVc
            CJPayAPI.open(
                withConfig: [CJPayPropertyReferVCKey: referVc],
                scheme: SchemeFactory.generate(for: .bankcard(userID: self.currentUserID)),
                with: nil
            )
        }
    }

    // open withdraw desh view Controller
    public func openWithdrawDesk(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)? = nil) {
        self.setupCookie { (error) in
            if error != nil { return }
            CJPayAPI.open(
                withConfig: [CJPayPropertyReferVCKey: referVc],
                scheme: SchemeFactory.generate(for: .withdraw),
                with: CJPayAPICallBack(callBack: { response in
                    guard let callback = closeCallBack, response.scene == .balanceWithdraw else { return }
                    callback(response)
                })
            )
        }
    }

    public func getCJSDKConfig() -> String {
        return CJPayAPI.getVersion()
    }

    public func payUpgrade(businessScene: PayBusinessScene) {
        guard !closeDouyinPayFG else {
            Self.logger.info("payUpgrade return closeDouyinPayFG:\(closeDouyinPayFG)")
            return
        }
        self.cjpayInitIfNeeded { [weak self] error in
            if let err = error {
                Self.logger.error("payUpgrade setup cjpay failed with error \(String(describing: err))")
                return
            }
            guard let self = self else { return }
            Self.logger.info("call payUpgrade businessScene:\(businessScene)")
            let params = ["app_id": WalletInfo.appID, "merchant_id": WalletInfo.merchantID, "business_scene": businessScene.rawValue]
            CJPayAPI.openPayUpgrade(withParams: params, with: self)
        }
    }

    public func getWalletScheme(callback: ((String?) -> Void)?) {
        guard !closeDouyinPayFG else {
            Self.logger.info("getWalletScheme return closeDouyinPayFG:\(closeDouyinPayFG)")
            callback?(nil)
            return
        }
        self.cjpayInitIfNeeded { error in
            if let err = error {
                Self.logger.error("get walletScheme setup cjpay failed with error \(String(describing: err))")
                return
            }
            let params = ["app_id": WalletInfo.appID, "merchant_id": WalletInfo.merchantID]
            Self.logger.info("start get wallet scheme")
            CJPayAPI.getWalletUrl(withParams: params) { walletUrl in
                Self.logger.info("end get wallet scheme walletUrl:\(walletUrl)")
                callback?(walletUrl)
            }
        }
    }

    public init(
        appID: String,
        deviceID: String,
        installID: String,
        currentUserID: String,
        redPacketAPI: RedPacketAPI,
        testEnv: Bool,
        resolver: UserResolver) {
        self.currentUserID = currentUserID
        self.appID = appID
        self.deviceID = deviceID
        self.installID = installID
        self.redPacketAPI = redPacketAPI
        self.testEnv = testEnv
        self.trackerProxy = PayManagerTrackerProxy()
        self.bizWebImpl = PayManagerBizWebImpl(userResolver: resolver)
        self.userResolver = resolver
        super.init()
    }

    private func fetchPaytoken(callBack: ((String, Error?) -> Void)?) {
        FinancePayManager.logger.debug("fetch pay token")
        self.redPacketAPI.getPayToken()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (payToken) in
                FinancePayManager.logger.info("set up pay token success", additionalData: ["paytokenLength": "\(payToken.count)"])
                self?.payToken = payToken
                callBack?(payToken, nil)
            }, onError: { (error) in
                FinancePayManager.logger.error("set up pay token failed", error: error)
                callBack?("", error)
            }).disposed(by: disposeBag)
    }

    // 获取 paytoken 并且 初始化 cjpay
    private func setupCookie(callBack: ((Error?) -> Void)?) {
        FinancePayManager.logger.info("set up cookie")
        if let payToken = self.payToken, !payToken.isEmpty {

            let block = { [weak self] in
                guard let `self` = self else {
                    return
                }
                if !self.cjPayHadInit {
                    self.setupCJPay()
                } else {
                    self.plantPayToken()
                }
                callBack?(nil)
            }

            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async {
                    block()
                }
            }
        } else {
            self.fetchPaytoken { [weak self] (_, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.setupCJPay()
                    }
                    callBack?(error)
                }
            }
        }
    }

    // 初始化 cjpay
    private func setupCJPay() {

        let appName = Bundle.main.infoDictionary?["CFBundleName"] ?? ""

        let appInfoConfig = CJPayAppInfo()
        appInfoConfig.appID = self.appID
        appInfoConfig.appName = appName as? String ?? ""
        let deviceID = self.deviceID
        appInfoConfig.deviceIDBlock = {() -> String in
            return deviceID
        }

        let versionCode = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        appInfoConfig.reskInfoBlock = {() -> [String: Any]  in
            return [
                "version_code": versionCode,
                "user_agent": LarkFoundation.Utils.userAgent,
                "iid": self.installID,
                "app_name": appName
            ]
        }

        CJPayAPI.configHost("https://\(hongbaoHost)")
        Self.logger.info("hongbaoHost is \(hongbaoHost)")

        let isStaging = EnvManager.env.isStaging
        if isStaging {
            CJPayBaseRequest.setGBDPayConfigHost("http://bytepay-boe.byted.org")
        } else {
            CJPayBaseRequest.setGBDPayConfigHost("https://cashier.ulpay.com")
        }
        appInfoConfig.adapterIpadStyle = true

        CJPayAPI.syncOffline(with: self.appID)
        if isStaging {
            // 开启BOE环境
            CJPayDebugManager.enableBoe()
            // 设置boe环境的参数,updateBoeCookies方法会使用这里设置的参数更新cookie，默认为 @{@"x-tt-env" : @"prod"}
            CJPayDebugManager.setupBoeEnvDictionary(["x-tt-env": "prod"])
        }

        CJPayAPI.register(appInfoConfig)

        self.plantPayToken()

        // 设置语言
        let lanuage: CJPayLocalizationLanguage
        switch LanguageManager.currentLanguage {
        case .zh_CN: lanuage = .zhhans
        case .en_US, .ja_JP: lanuage = .en
        default:
            lanuage = .en
        }

        FinancePayManager.logger.info("set up lanuage \(lanuage)")
        CJPayAPI.setupLanguage(lanuage)
        CJPayTracker.shared().trackerDelegate = self.trackerProxy
        CJPayAPI.register(self.bizWebImpl)
        _ = FinancePayManager.liveness
        Self.setupBullet()

        self.cjPayHadInit = true
    }

    /// 由宿主程序注入财经相关 cookie,
    /// https://bytedance.feishu.cn/docs/doccnvOdIlDtcOkDTB82EhHk1bf#
    private func plantPayToken() {
        FinancePayManager.logger.info("plant pay token")
        let payTokenKey = FinancePayManager.payTokenKey
        let payToken = self.payToken ?? ""
        self.plantCookie(token: payToken, domain: hongbaoDomain, name: payTokenKey)
        self.plantCookie(token: payToken, domain: ".ulpay.com", name: payTokenKey)
        if EnvManager.env.isStaging {
            self.plantCookie(token: payToken, domain: ".byted.org", name: payTokenKey)
        }
        FinancePayManager.logger.info("set up CJPay", additionalData: ["paytokenLength": "\(payToken.count)"])
    }

    @discardableResult
    private func plantCookie(token: String, domain: String, name: String) -> Bool {
        let properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: token,
            .path: "/",
            .domain: domain,
            .expires: cookieExpiresDate
        ]
        if let cookie = HTTPCookie(properties: properties) {
            HTTPCookieStorage.shared.setCookie(cookie)
            return true
        }
        return false
    }

    private lazy var cookieExpiresDate: Date = {
        if let oneYearAfter = Calendar.current.date(byAdding: .year, value: 1, to: Date()) {
            return oneYearAfter
        }
        let year = Calendar.autoupdatingCurrent.component(.year, from: Date())
        return self.date(year: year + 2, month: 1, day: 1)
    }()

    private func date(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0

        return Calendar.current.date(from: dateComponents) ?? Date()
    }
}

extension FinancePayManager: CJPayAPIDelegate {
    public func callState(_ success: Bool, from scene: CJPayScene) {
        if scene == .pay || scene == .bdPay {
            FinancePayManager.logger.info("call pay desk success \(success)")
            if success {
                self.payCallback?.callDeskCallback(true)
            } else {
                RedPacketReciableTrack.sendRedPacketLoadNetworkError(errorCode: 0, errorMessage: "callDeskFailure", isCJPay: true)
                self.payCallback?.callDeskCallback(false)
                self.payCallback = nil
            }
        }
    }

    public func onResponse(_ response: CJPayAPIBaseResponse) {
        handleCJPayResponse(response)
        handleOpenUpgradeResponse(response)
    }

    func handleCJPayResponse(_ response: CJPayAPIBaseResponse?) {
        let errorMessage = response?.error?.localizedDescription ?? ""
        FinancePayManager.logger.info("handle CJPay resultType \(errorMessage) scene:\(String(describing: response?.scene))")
        let errorCode = (response?.error as NSError?)?.code ?? 0
        RedPacketReciableTrack.sendRedPacketLoadNetworkError(errorCode: Int(errorCode), errorMessage: errorMessage, isCJPay: true)
        var error: Error?
        if response?.scene == .pay || response?.scene == .bdPay {
            guard let code = (response?.error as NSError?)?.code, let resultType = CJPayErrorCode(rawValue: code) else { return }
            switch resultType {
            case .cancel:
                self.payCallback?.cacncelBlock()
                self.payCallback = nil
                return
            case .fail, .callFailed:
                error = PayErrorType.payFailed
            case .orderTimeOut:
                error = PayErrorType.timeout
            case .processing, .success:
                break
            case .hasOpeningDesk:
                error = PayErrorType.hasOpeningDesk
            case .unLogin, .authrized, .authQueryError,
                 .unnamed, .unknown, .insufficientBalance:
                error = PayErrorType.payFailed
            @unknown default:
                break
            }

            if let payCallback = self.payCallback {
                payCallback.payCallback(error)
                self.payCallback = nil
            }
        }
    }

    func handleOpenUpgradeResponse(_ response: CJPayAPIBaseResponse?) {
        let resultData = response?.data
        let callbackId = resultData?["callback_id"]
        let service = resultData?["service"]
        let data = resultData?["data"] as? [String: Any]
        let code = data?["code"]
        let dataMsg = data?["msg"] as? [String: Any]
        let upgradeStatus = dataMsg?["upgrade_status"] //'ignore' | 'success' | 'fail' string类型
        let process = dataMsg?["process"]
        Self.logger.info("open upgrade result code:\(String(describing: code)) upgradeStatus:\(String(describing: upgradeStatus)) process:\(String(describing: process)) ")
        Self.logger.info("open upgrade result callbackId:\(String(describing: callbackId)) service:\(String(describing: service))")
    }

    public func needLogin(_ callback: ((CJBizWebCode) -> Void)!) {
        FinancePayManager.logger.info("needLogin")
        assertionFailure()
        self.payCallback?.callDeskCallback(false)
        self.payCallback = nil
        callback(.closeDesk)
    }

    // MARK: - User Phone info
    /// 判断用户是否已经添加过 +86 的手机信息
    /// 优先判断本地数据，如果本地没有数据，向服务端拉取数据
    /// 如果拉取过程中出现错误，当做用户已经存在手机信息，返回 true
    // nolint: duplicated_code -- 检测误报，方法实现不同
    public func fetchUserPhoneInfo() -> Observable<Bool> {
        /// 存储当前用户是否添加过电话信息
        @KVConfig(key: "phone", default: false, store: KVStore.userStore(userID: userResolver.userID))
        var userAddPhoneInfo: Bool

        if userAddPhoneInfo {
            return Observable<Bool>.just(true)
        }
        guard let passportUserService = try? self.userResolver.resolve(assert: PassportUserService.self) else {
            return Observable<Bool>.just(true)
        }
        /// 如果发生错误，按照正确返回
        return passportUserService.getAccountPhoneNumbers()
            .map({ (list) -> Bool in
                if let first = list.first,
                    first.contryCode == "86",
                    !first.phoneNumber.isEmpty {
                    userAddPhoneInfo = true
                    return true
                }
                return false
            })
            .do(onNext: { (result) in
                FinancePayManager.logger.info("get user phone info success \(result)")
            }, onError: { (error) in
                FinancePayManager.logger.error("get user phone info failed", error: error)
            })
            .catchErrorJustReturn(true)
    }
}

// MARK: - Private
/// 生成 scheme 字符串
private final class SchemeFactory {
    enum ScemeType {
        case transaction
        case security
        case bankcard(userID: String)
        case withdraw
    }
    static func generate(for type: ScemeType) -> String {
        switch type {
        case .transaction:
            return "https://cashier.ulpay.com/usercenter/transaction/list?merchant_id=\(WalletInfo.merchantID)&app_id=\(WalletInfo.appID)"
        case .security:
            return "https://cashier.ulpay.com/usercenter/paymng?merchant_id=\(WalletInfo.merchantID)&app_id=\(WalletInfo.appID)&native_bank=1"
        case .bankcard(userID: let userID):
            return "sslocal://cjpay/bankcardlist?app_id=\(WalletInfo.appID)&merchant_id=\(WalletInfo.merchantID)&uid=\(userID)"
        case .withdraw:
            return "sslocal://cjpay/bdwithdrawaldesk?app_id=\(WalletInfo.appID)&merchant_id=\(WalletInfo.merchantID)"
        }
    }
}
#else
import Foundation
import LarkUIKit
import LarkLocalizations
import LKCommonsLogging
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkFoundation
import LarkAccountInterface

final class MockPayManagerService: NSObject, PayManagerService, UserResolverWrapper {
    func payUpgrade(businessScene: PayBusinessScene) {}

    func getWalletScheme(callback: ((String?) -> Void)?) {}

    static let logger = Logger.log(MockPayManagerService.self, category: "finance.pay.manager")

    var userResolver: LarkContainer.UserResolver
    var payToken: String?
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func fetchPayTokenIfNeeded() {}
    func cjpayInitIfNeeded(callback: ((Error?) -> Void)?) {}
    func pay(paramsString: String, referVc: UIViewController, payCallback: PayManagerCallBack, paymentMethod: PaymentMethod) {}
    func open(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)?) {}
    func handle(open url: URL) -> Bool {
        return false
    }
    func openBankCardList(referVc: UIViewController) {
    }
    func openTransaction(referVc: UIViewController) {}
    func openPaySecurity(referVc: UIViewController) {}
    func openWithdrawDesk(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)?) {}
    func fetchUserPhoneInfo() -> Observable<Bool> {
        /// 存储当前用户是否添加过电话信息
        @KVConfig(key: "phone", default: false, store: KVStore.userStore(userID: userResolver.userID))
        var userAddPhoneInfo: Bool

        if userAddPhoneInfo {
            return Observable<Bool>.just(true)
        }
        guard let passportUserService = try? self.userResolver.resolve(assert: PassportUserService.self) else {
            return Observable<Bool>.just(true)
        }
        /// 如果发生错误，按照正确返回
        return passportUserService.getAccountPhoneNumbers()
            .map({ (list) -> Bool in
                if let first = list.first,
                    first.contryCode == "86",
                    !first.phoneNumber.isEmpty {
                    userAddPhoneInfo = true
                    return true
                }
                return false
            })
            .do(onNext: { (result) in
                MockPayManagerService.logger.info("get user phone info success \(result)")
            }, onError: { (error) in
                MockPayManagerService.logger.error("get user phone info failed", error: error)
            })
            .catchErrorJustReturn(true)
    }
    func getCJSDKConfig() -> String {
        return ""
    }
}

#endif
