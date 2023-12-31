//
//  GetAppLanguage.swift
//  LarkWeb
//
//  Created by qihongye on 2018/12/13.
//

import LarkLocalizations
import LKCommonsLogging
import WebBrowser

class GetAppLanguage: JsAPIHandler {
    static let logger = Logger.log(GetAppLanguage.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        callback.callbackSuccess(param: [
            "code": LanguageManager.currentLanguage.localeIdentifier,
            "name": LanguageManager.currentLanguage.displayName
        ])
    }
}
