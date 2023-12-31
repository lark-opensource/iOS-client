//
//  SelectTranslateAPI.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/8.
//

import Foundation
import ServerPB
import RxSwift
import RustPB
public protocol SelectTranslateAPI {
    /// 文本类型请求翻译
    /// - Parameter query: 消息内容
    func selectTextTranslateInformation(selectText: String, trgLanguage: String) -> Observable<ServerPB.ServerPB_Translate_TranslateWebXMLResponse>
    func fetchResource(fileKey: String, fsUnit: String) -> Observable<RustPB.Media_V1_GetResourceWithFsUnitResponse>
    func detectTextsLanguageRequest(textList: [String]) -> Observable<RustPB.Im_V1_DetectTextsLanguageResponse>
}
