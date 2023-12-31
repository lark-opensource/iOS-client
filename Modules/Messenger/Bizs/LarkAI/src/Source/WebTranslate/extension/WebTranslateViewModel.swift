//
//  WebTranslateViewModel.swift
//  LarkAI
//
//  Created by liushuwei on 2020/11/24.
//

import Foundation
import WebBrowser
import Swinject
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkActionSheet
import LKCommonsLogging
import Homeric
import LKCommonsTracker
import UniverseDesignToast
import RxSwift
import LarkModel
import LarkExtensions
import RustPB

//网页翻译功能的ViewModel部件
public final class WebTranslateViewModel {
    static let logger = Logger.log(WebTranslateViewModel.self, category: "Module.AI")
    let userResolver: UserResolver
    var userGeneralSettings: UserGeneralSettings?
    var urlAPI: UrlAPI?
    var configAPI: ConfigurationAPI?

    public private(set) weak var webviewApi: WebBrowser?
    public private(set) var translateBarStateChangeSubject = PublishSubject<Bool>()
    public private(set) var currentTranslateInfoSubject = PublishSubject<WebTranslateProcessInfo>()
	public private(set) var openWebTranslateSettingSubject = PublishSubject< (translateLanguageSetting: TranslateLanguageSetting,
																			 notTranslateLanguages: [String],
																			 currentTranslateInfo: WebTranslateProcessInfo) >()
    public private(set) var showChooseLanguageSubject = PublishSubject<WebTranslateProcessInfo>()
    public private(set) var manualTranslateEventSubject = PublishSubject<[String: Any]>()
    public private(set) var translateLanguageSetting: TranslateLanguageSetting?
    public private(set) var translateBarEnable: Bool = false

    // 网页翻译过程中的当前上下文信息
    public private(set) var currentTranslateInfo: WebTranslateProcessInfo?
    private var notTranslateLanguages: [String]?
    private var disposeBag = DisposeBag()
    var webTranslateAppSetting: WebTranslateAppSettingHelper

    public init(userResolver: UserResolver, webviewApi: WebBrowser) {
        self.userResolver = userResolver
        self.webviewApi = webviewApi
        self.userGeneralSettings = try? userResolver.resolve(assert: UserGeneralSettings.self)
        self.urlAPI = try? userResolver.resolve(assert: UrlAPI.self)
        self.configAPI = try? userResolver.resolve(assert: ConfigurationAPI.self)
        self.webTranslateAppSetting = WebTranslateAppSettingHelper(userResolver: userResolver)
    }

    public func currentURL() -> String {
        return self.webviewApi?.webView.url?.host ?? ""
    }

    public var isBarClose: Bool {
        return !translateBarEnable
    }

    public func setup() {
        self.observeToTransalteBarEvent()
        self.driveTranslateLanguageSetting()
    }

    public func sendTranslateBarStateChangedEvent(_ isShow: Bool) {
        self.translateBarStateChangeSubject.onNext(isShow)
    }

    public func sendManualTranslateEvent(_ info: [String: Any]) {
        self.manualTranslateEventSubject.onNext(info)
    }

    private func driveTranslateLanguageSetting() {
        // 监听翻译设置更新的push
        self.userGeneralSettings?.translateLanguageSettingDriver
            .drive(onNext: { [weak self] (setting) in
                self?.setTranslateSetting(setting)
                self?.fetchWebNotTranslateLanguages()
            }).disposed(by: self.disposeBag)
    }

    private func fetchWebNotTranslateLanguages() {
        self.urlAPI?.getWebNotTranslateLanguagesRequest()
            .subscribe(onNext: { [weak self] (res) in
                self?.notTranslateLanguages = res.notTranslateLanguages
            }, onError: { (error) in
                Self.logger.error("getWebNotTranslateLanguagesRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    public func setTranslateSetting(_ setting: TranslateLanguageSetting) {
        DispatchQueue.main.async {
            self.translateLanguageSetting = setting
        }
    }

    public func onBrowserTranslateMenuClick() {
        guard let info = self.currentTranslateInfo, webTranslateAppSetting.isUrlEnable(url: webviewApi?.browserURL) else {
            if let hudOn = self.webviewApi?.view.window {
                UDToast.showTips(with: BundleI18n.LarkAI.Lark_ASLTranslation_WebTranslation_UnableToTranslatePage_Toast, on: hudOn)
            }
            return
        }
        Self.logger.debug("translateItem = \(String(describing: info))")
        if info.originLangCode == info.targetLangCode || info.status == .target {
            self.showChooseLanguageSubject.onNext(info)
            return
        }
        let originLang = ["name": info.originLangName,
                          "code": info.originLangCode]
        let targetLang = ["name": info.targetLangName,
                          "code": info.targetLangCode]
        let eventInfo: [String: Any] = ["type": "translate",
                                       "originLang": originLang,
                                       "targetLang": targetLang]
        self.sendManualTranslateEvent(eventInfo)
    }

    public func setWebNotTranslateLanguages(_ languages: [String]) {
        DispatchQueue.main.async {
            self.notTranslateLanguages = languages
        }
    }

    private func observeToTransalteBarEvent() {
        self.manualTranslateEventSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] info in
                guard let self = self else { return }
                Self.logger.info("action observeToTapExitOnTransalteBar")
                let originlang = info["originLang"] as? [String: String] ?? [:]
                let targetlang = info["targetLang"] as? [String: String] ?? [:]
                let type = info["type"] as? String ?? ""
                let data: [String: Any] = ["translateType": type,
                    "originLang": originlang,
                    "targetLang": targetlang
                ]
                let message: [String: Any] = ["func": "biz.larkWebTranslate.onManualTranslate",
                                              "param": data
                ]
                let json = JSONStringWithObject(object: message)
                var way = ""
                if type == "translate" {
                    way = "manual"
                } else if type == "revert" || type == "updateTargetLang"{
                    way = "guide"
                }
                self.setEnableDisplayTranslateBar(true)
                Tracker.post(TeaEvent(Homeric.WEB_TRANSLATE, params: ["way": way]))
                self.webviewApi?.webView.evaluateJavaScript("window.LKWebTranslateJSB._dispatchEventFromNative(\(json))") { (_, error) in
                    if let error = error {
                        Self.logger.error("excuted JS error after recieving TapExitOnTransalteBar event", error: error)
                    }
                }
           }).disposed(by: self.disposeBag)
    }

    // 验证数据是否存在再去打开网页设置actionSheet
    public func webSettingTapped() {
        // 如果没有翻译的上下文信息直接返回
        guard self.currentTranslateInfo != nil else {
            Self.logger.info("self.currentTranslateInfo is nil")
            return
        }

        let translateLanguageSettingSubject = PublishSubject<Void>()
        let notTranslateLanguagesSubject = PublishSubject<Void>()

        // translateLanguageSetting和notTranslateLanguages必须有值才能跳转
        // 没有则去服务端拉取后在跳转
        Observable.of(translateLanguageSettingSubject, notTranslateLanguagesSubject)
            .merge()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                // 如果缺失相关配置直接返回
                guard let translateLanguageSetting = self?.translateLanguageSetting else { return }
                guard let notTranslateLanguages = self?.notTranslateLanguages else { return }
                guard let currentTranslateInfo = self?.currentTranslateInfo else { return }
                self?.openWebTranslateSettingSubject.onNext((translateLanguageSetting: translateLanguageSetting,
                                                             notTranslateLanguages: notTranslateLanguages,
                                                             currentTranslateInfo: currentTranslateInfo))
            }, onError: { (error) in
                Self.logger.error("merge transSettingSubject and notTansLanguagesSubject error, error = \(error)")
            }).disposed(by: self.disposeBag)

        // 如果translateLanguageSetting没有则去服务端拉
        if self.translateLanguageSetting == nil {
            self.configAPI?.fetchTranslateLanguageSetting(strategy: .forceServer)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (setting) in
                    translateLanguageSettingSubject.onNext(())
                    self?.translateLanguageSetting = setting
                }, onError: { (error) in
                    Self.logger.error("fetchTranslateLanguageSetting error, error = \(error)")
                }).disposed(by: self.disposeBag)
        } else {
            translateLanguageSettingSubject.onNext(())
        }

        // 如果notTranslateLanguages没有则去服务端拉
        if self.notTranslateLanguages == nil {
            self.urlAPI?.getWebNotTranslateLanguagesRequest()
                .subscribe(onNext: { [weak self] (res) in
                    notTranslateLanguagesSubject.onNext(())
                    self?.notTranslateLanguages = res.notTranslateLanguages
                }, onError: { (error) in
                    Self.logger.error("getWebNotTranslateLanguagesRequest error, error = \(error)")
                }).disposed(by: self.disposeBag)
        } else {
            notTranslateLanguagesSubject.onNext(())
        }
    }

    public func openAutoTranslateTapped() {
        guard let scope = self.translateLanguageSetting?.translateScope,
              self.translateLanguageSetting?.webXmlSwitch == false else { return }

        let newScope = scope + RustPB.Im_V1_TranslateScopeMask.webXml.rawValue
        self.updateAutoTranslateScope(newScope: newScope, desc: BundleI18n.LarkAI.Lark_Chat_OpenWebAutoTranslateSuccess)
    }

    public func neverTranslateThisLangTapped(originLangCode: String, toSelect: Bool, onSuccess: @escaping (Bool) -> Void) {
        if toSelect {
            self.urlAPI?.setWebNotTranslateLanguagesRequest(
                notTranslateLanguage: originLangCode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.notTranslateLanguages?.append(originLangCode)
                if let hudOn = self?.webviewApi?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkAI.Lark_Chat_SetUntranslateWebSuccess, on: hudOn)
                }
                onSuccess(toSelect)
            }, onError: { (error) in
                Self.logger.error("setWebNotTranslateLanguagesRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
        } else {
            Tracker.post(TeaEvent(Homeric.SET_UNTRANSLATE_LANGUAGE))
            self.urlAPI?.deleteWebNotTranslateLanguagesRequest(
                notTranslateLanguage: originLangCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.notTranslateLanguages?.removeAll(where: { (language) -> Bool in
                        return language == originLangCode
                    })
                    if let hudOn = self?.webviewApi?.view.window {
                        UDToast.showTips(with: BundleI18n.LarkAI.Lark_Chat_SetUntranslateWebSuccess, on: hudOn)
                    }
                }, onError: { (error) in
                    Self.logger.error("setWebNotTranslateLanguagesRequest error, error = \(error)")
                }).disposed(by: self.disposeBag)
        }
    }

    public func neverTranslateThisSiteTapped(urlHost: String, toSelect: Bool, onSuccess: @escaping (Bool) -> Void) {
        var webTranslationConfig = RustPB.Im_V1_WebTranslationConfig()
        var blackDomains = self.translateLanguageSetting?.webTranslationConfig.blackDomains ?? []
        if toSelect {
            blackDomains.append(urlHost)
        } else {
            blackDomains.removeAll { (str) -> Bool in
                return str == urlHost
            }
        }
        webTranslationConfig.blackDomains = blackDomains
        self.urlAPI?.patchWebTranslationConfigRequest(
            webTranslationConfig: webTranslationConfig)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.translateLanguageSetting?.webTranslationConfig.blackDomains = blackDomains
                if let hudOn = self?.webviewApi?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkAI.Lark_Chat_SetUntranslateWebSuccess, on: hudOn)
                }
                onSuccess(toSelect)
            }, onError: { (error) in
                Self.logger.error("patchWebTranslationConfigRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    public func updateAutoTranslateScope(newScope: Int, desc: String) {
        self.configAPI?.updateAutoTranslateScope(scope: newScope)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                if let hudOn = self?.webviewApi?.view.window {
                    UDToast.showTips(with: desc, on: hudOn)
                }
            }, onError: { (error) in
                Self.logger.error("updateAutoTranslateScope error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    public func setTranslateProcessInfo(_ info: WebTranslateProcessInfo) {
        Self.logger.debug("set translate info \(info)")
        self.currentTranslateInfo = info
    }

    public func updateTranslateProcessInfo(_ info: WebTranslateProcessInfo) {
        guard self.currentTranslateInfo != nil else { return }
        if info.status != .unknown {
            self.currentTranslateInfo?.status = info.status
        }
        if !info.supportedLanguages.isEmpty {
            self.currentTranslateInfo?.supportedLanguages = info.supportedLanguages
        }
        let supportedLanguages = self.currentTranslateInfo?.supportedLanguages
        if !info.originLangCode.isEmpty {
            self.currentTranslateInfo?.originLangCode = info.originLangCode
            if !info.originLangName.isEmpty {
                self.currentTranslateInfo?.originLangName = info.originLangName
            } else {
                self.currentTranslateInfo?.originLangName = supportedLanguages?[info.originLangCode] ?? ""
            }
        }
        if !info.targetLangCode.isEmpty {
            self.currentTranslateInfo?.targetLangCode = info.targetLangCode
            if !info.targetLangName.isEmpty {
                self.currentTranslateInfo?.targetLangName = info.targetLangName
            } else {
                self.currentTranslateInfo?.targetLangName = supportedLanguages?[info.targetLangCode] ?? ""
            }
        }
        self.currentTranslateInfo.flatMap { self.currentTranslateInfoSubject.onNext($0) }
    }

    public func setEnableDisplayTranslateBar(_ enable: Bool) {
        self.translateBarEnable = enable
    }
}
