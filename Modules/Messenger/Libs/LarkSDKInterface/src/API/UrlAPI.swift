//
//  UrlAPI.swift
//  LarkSDKInterface
//
//  Created by JackZhao on 2020/8/5.
//

import Foundation
import LarkModel
import RxSwift
import RustPB

public protocol UrlAPI {
    /// judge link is safe or not
    func judgeSecureLink(
        target: String,
        scene: String
    ) -> Observable<RustPB.Im_V1_JudgeSecureLinkResponse>

    /// 目前以下六个接口只在AI module使用
    /// 接下来需要把相关代码迁移到AI module
    /// detect language of testList
    func detectTextsLanguageRequest(
        textList: [String]
    ) -> Observable<RustPB.Im_V1_DetectTextsLanguageResponse>

    /// web translate
    func translateWebXMLRequest(
        srcLanguage: String,
        srcContents: [String],
        trgLanguage: String
    ) -> Observable<RustPB.Im_V1_TranslateWebXMLResponse>

    /// set language of webNotTranslate
    /// 设置某一个语言不自动翻译，即加入语言黑名单
    func setWebNotTranslateLanguagesRequest(
        notTranslateLanguage: String
    ) -> Observable<RustPB.Im_V1_SetWebNotTranslateLanguagesResponse>

    /// delete language of webNotTranslate
    /// 允许某个语言自动翻译，即把某个语言移出语言黑名单
    func deleteWebNotTranslateLanguagesRequest (
        notTranslateLanguage: String
    ) -> Observable<RustPB.Im_V1_DeleteWebNotTranslateLanguagesResponse>

    /// get languages of webNotTranslate
    /// 加载所有不自动翻译的语言，即load整个语言黑名单
    func getWebNotTranslateLanguagesRequest(
    ) -> Observable<RustPB.Im_V1_GetWebNotTranslateLanguagesResponse>

    /// add blackDomains
    func patchWebTranslationConfigRequest(
        webTranslationConfig: RustPB.Im_V1_WebTranslationConfig
    ) -> Observable<RustPB.Im_V1_PatchWebTranslationConfigResponse>
}
