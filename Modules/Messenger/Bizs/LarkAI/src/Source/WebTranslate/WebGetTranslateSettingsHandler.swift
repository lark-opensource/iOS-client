//
//  WebGetTranslateSettingsHandler.swift
//  JsSDK
//
//  Created by JackZhao on 2020/8/17.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import RxSwift
import Swinject
import LarkSDKInterface
import Homeric
import LKCommonsTracker

/// get current account translation setting
final class WebGetTranslateSettingsHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebGetTranslateSettingsHandler.self, category: "Module.LarkAI")

    private let urlAPI: UrlAPI?
    private let configurationAPI: ConfigurationAPI?
    private weak var translateViewModel: WebTranslateViewModel?
    private let disposeBag = DisposeBag()

    init(urlAPI: UrlAPI?, configurationAPI: ConfigurationAPI?, translateViewModel: WebTranslateViewModel) {
        self.urlAPI = urlAPI
        self.configurationAPI = configurationAPI
        self.translateViewModel = translateViewModel
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        Self.logger.debug("handle getTranslateSetting")
        guard let urlString = args["url"] as? String,
            let url = URL(string: urlString) else { return }
        let originLan = args["originLan"] as? String
        let callback = args["callback"] as? String
        let getWebNotTranslateLanguagesObservable = urlAPI?.getWebNotTranslateLanguagesRequest() ?? .empty()
        let fetchTranslateLanguageSettingObservable = configurationAPI?.fetchTranslateLanguageSetting(strategy: .forceServer) ?? .empty()
        Observable.zip(getWebNotTranslateLanguagesObservable, fetchTranslateLanguageSettingObservable)
            .subscribe(onNext: { [weak self] (languages, setting) in
                guard let self = self else { return }
                let info = WebTranslateProcessInfo(supportedLanguages: setting.supportedLanguages,
                    originLangName: setting.supportedLanguages[originLan ?? ""] ?? "",
                    originLangCode: originLan ?? "",
                    targetLangName: setting.supportedLanguages[setting.targetLanguage] ?? "",
                    targetLangCode: setting.targetLanguage)
                // set up some info to webVC
                self.translateViewModel?.setTranslateProcessInfo(info)
                self.translateViewModel?.setTranslateSetting(setting)
                self.translateViewModel?.setWebNotTranslateLanguages(languages.notTranslateLanguages)
                // Use the original language of the website to determine whether to translate
                let isNotTranslate = languages.notTranslateLanguages.contains(where: { (language) -> Bool in
                    return language == originLan
                })
                guard setting.targetLanguage != originLan else { return }
                let blackDomains = setting.webTranslationConfig.blackDomains
                // judge is in block domins
                let isInBlackDomains = blackDomains.contains { (domin) -> Bool in
                    return domin == url.host
                }
                let type = (isInBlackDomains || isNotTranslate) ? "disable" : (setting.webXmlSwitch ? "auto" : "manual")
                let name = setting.supportedLanguages[setting.targetLanguage] ?? ""
                let targetLang = ["name": name, "code": setting.targetLanguage]
                if type != "disable" {
                    if setting.webXmlSwitch {
                        Tracker.post(TeaEvent(Homeric.WEB_TRANSLATE, params: ["way": "auto"]))
                    }
                    self.callbackWith(api: api, funcName: callback, arguments: [[
                        "targetLang": targetLang,
                        "type": type
                    ]])
                }
            }, onError: { (error) in
                WebGetTranslateSettingsHandler.logger.error("zip getWebNotTransLanguagesObservable &  fetchTranslateLanguageSettingObservable error", error: error)
            }).disposed(by: self.disposeBag)

        if let onFailed = args["onFailed"] as? String {
            api.call(funcName: onFailed, arguments: [[
                "error": "get transalte setting error"
            ]])
        }
    }
}
