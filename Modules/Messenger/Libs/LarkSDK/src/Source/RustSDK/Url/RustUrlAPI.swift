//
//  RustUrlAPI.swift
//  LarkSDK
//
//  Created by JackZhao on 2020/8/5.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface

final class RustUrlAPI: LarkAPI, UrlAPI {
   /// judge link is safe or not
   func judgeSecureLink(
       target: String,
       scene: String
   ) -> Observable<RustPB.Im_V1_JudgeSecureLinkResponse> {
       var requset = Im_V1_JudgeSecureLinkRequest()
       requset.target = target
       requset.scene = scene
       return self.client.sendAsyncRequest(requset)
   }
    /// detect language of testList
    func detectTextsLanguageRequest(
        textList: [String]
    ) -> Observable<RustPB.Im_V1_DetectTextsLanguageResponse> {
        var request = Im_V1_DetectTextsLanguageRequest()
        request.textList = textList
        return self.client.sendAsyncRequest(request)
    }

    /// web translate
    func translateWebXMLRequest(
        srcLanguage: String,
        srcContents: [String],
        trgLanguage: String
    ) -> Observable<RustPB.Im_V1_TranslateWebXMLResponse> {
        var request = Im_V1_TranslateWebXMLRequest()
        request.srcLanguage = srcLanguage
        request.srcContents = srcContents
        request.trgLanguage = trgLanguage
        request.contentType = .webXmlContentType

        return self.client.sendAsyncRequest(request)
    }

    /// set languages of webNotTranslate
    func setWebNotTranslateLanguagesRequest(
        notTranslateLanguage: String
    ) -> Observable<RustPB.Im_V1_SetWebNotTranslateLanguagesResponse> {
        var request = Im_V1_SetWebNotTranslateLanguagesRequest()
        request.notTranslateLanguage = notTranslateLanguage

        return self.client.sendAsyncRequest(request)
    }

    /// delete language of webNotTranslate
    func deleteWebNotTranslateLanguagesRequest (
        notTranslateLanguage: String
    ) -> Observable<RustPB.Im_V1_DeleteWebNotTranslateLanguagesResponse> {
        var request = Im_V1_DeleteWebNotTranslateLanguagesRequest()
        request.notTranslateLanguage = notTranslateLanguage

        return self.client.sendAsyncRequest(request)
    }

    /// get languages of webNotTranslate
    func getWebNotTranslateLanguagesRequest(
    ) -> Observable<RustPB.Im_V1_GetWebNotTranslateLanguagesResponse> {
        let request = Im_V1_GetWebNotTranslateLanguagesRequest()

        return self.client.sendAsyncRequest(request)
    }

    /// patch webTranslation config
    func patchWebTranslationConfigRequest(
        webTranslationConfig: RustPB.Im_V1_WebTranslationConfig
    ) -> Observable<RustPB.Im_V1_PatchWebTranslationConfigResponse> {
        var request = Im_V1_PatchWebTranslationConfigRequest()
        request.webTranslationConfig = webTranslationConfig

        return self.client.sendAsyncRequest(request)
    }
}
