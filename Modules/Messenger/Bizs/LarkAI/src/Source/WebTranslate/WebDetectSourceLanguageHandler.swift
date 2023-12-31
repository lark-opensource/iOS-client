//
//  WebDetectSourceLanguageHandler.swift
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

/// detect source language
final class WebDetectSourceLanguageHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebDetectSourceLanguageHandler.self, category: "Module.LarkAI")

    private let urlAPI: UrlAPI?
    private let configurationAPI: ConfigurationAPI?
    private let disposeBag = DisposeBag()

    init(urlAPI: UrlAPI?, configurationAPI: ConfigurationAPI?) {
        self.urlAPI = urlAPI
        self.configurationAPI = configurationAPI
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        guard let textList = args["textList"] as? [String], textList.isEmpty == false else { return }
        Self.logger.debug("handle detect src language")
        let callback = args["callback"] as? String
        let settingObsevable = configurationAPI?.fetchTranslateLanguageSetting(strategy: .forceServer).asObservable() ?? .empty()
        let detectTextsObservable = urlAPI?.detectTextsLanguageRequest(textList: textList).asObservable() ?? .empty()
        Observable.zip(settingObsevable, detectTextsObservable)
            .subscribe(onNext: { [weak self] (setting, result) in
                guard let language = result.language.first else { return }
                let name = setting.supportedLanguages[language]
                self?.callbackWith(api: api, funcName: callback, arguments: [[
                    "name": name,
                    "code": language
                ]])
            }, onError: { (error) in
                Self.logger.info("[detectTextsLanguageRequest]request count: \(textList.count)")
                Self.logger.error("zip settingObsevable & detectTextsObservable error", error: error)
            }).disposed(by: self.disposeBag)
    }
}
