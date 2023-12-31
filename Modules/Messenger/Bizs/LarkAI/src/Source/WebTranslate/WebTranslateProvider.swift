//
//  WebTranslateProvider.swift
//  LarkAI
//
//  Created by liushuwei on 2020/11/13.
//

import Foundation
import WebBrowser
import Swinject
import LarkSDKInterface

public final class WebTranslateProvider {

    public static func getTranslateApiDict(urlAPI: UrlAPI?, configurationAPI: ConfigurationAPI?,
                                           userGeneralSettings: UserGeneralSettings?,
                                           translateViewModel: WebTranslateViewModel) -> [String: () -> LarkWebJSAPIHandler] {
        let apiDict: [String: () -> LarkWebJSAPIHandler] = [
            "biz.larkWebTranslate.getDetectSetting": {
                return WebGetDetectSettingHandler(webTranslateAppSetting: translateViewModel.webTranslateAppSetting)
            },
            "biz.larkWebTranslate.detectSourceLanguage": {
                return WebDetectSourceLanguageHandler(urlAPI: urlAPI, configurationAPI: configurationAPI)
            },
            "biz.larkWebTranslate.getTranslateSettings": {
                return WebGetTranslateSettingsHandler(urlAPI: urlAPI, configurationAPI: configurationAPI,
                                                      translateViewModel: translateViewModel)
            },
            "biz.larkWebTranslate.sendTranslateRequest": {
                return WebSendTranslateRequestHandler(urlAPI: urlAPI, translateViewModel: translateViewModel)
            },
            "biz.larkWebTranslate.changeBanner": {
                return WebChangeBannerHandler(translateViewModel: translateViewModel)
            },
            "biz.larkWebTranslate.updateTranslateStatus": {
                return WebUpdateTranslateStatusHandler(translateViewModel: translateViewModel)
            }
        ]
        return apiDict
    }
}
