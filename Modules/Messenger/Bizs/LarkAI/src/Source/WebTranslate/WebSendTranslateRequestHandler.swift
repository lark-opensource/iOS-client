//
//  WebSendTranslateRequestHandler.swift
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
import UniverseDesignToast

/// send translate request
final class WebSendTranslateRequestHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(WebSendTranslateRequestHandler.self, category: "Module.LarkAI")

    private let urlAPI: UrlAPI?
    private weak var translateViewModel: WebTranslateViewModel?
    private let disposeBag = DisposeBag()

    init(urlAPI: UrlAPI?, translateViewModel: WebTranslateViewModel) {
        self.urlAPI = urlAPI
        self.translateViewModel = translateViewModel
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        guard let targetLang = args["targetLang"] as? String,
            let originLang = args["originLang"] as? String,
            let words = args["words"] as? [String] else {
            return
        }
        let info = WebTranslateProcessInfo(originLangCode: originLang,
                                           targetLangCode: targetLang)
        translateViewModel?.updateTranslateProcessInfo(info)
        translateViewModel?.setEnableDisplayTranslateBar(true)
        guard let callback = args["callback"] as? String else { return }
        urlAPI?.translateWebXMLRequest(srcLanguage: originLang, srcContents: words, trgLanguage: targetLang)
            .subscribe(onNext: { [weak self] (res) in
                self?.callbackWith(api: api, funcName: callback, arguments: [[
                    "data": res.trgContents
                ]])
            }, onError: { (error) in
                DispatchQueue.main.async { [weak api] in
                    if let hudOn = api?.view.window {
                        UDToast.showTips(with: BundleI18n.LarkAI.Lark_ASLTranslation_WebTranslation_TranslationFailedTryLater_Toast, on: hudOn)
                    }
                }
                WebSendTranslateRequestHandler.logger.error("translateWebXMLRequest error", error: error)
            }).disposed(by: self.disposeBag)
        if let onFailed = args["onFailed"] as? String {
            self.callbackWith(api: api, funcName: onFailed, arguments: [[
                "error": "send transalte request error"
            ]])
        }
    }
}
