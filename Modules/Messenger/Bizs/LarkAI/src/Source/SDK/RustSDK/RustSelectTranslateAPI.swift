//
//  RustSelectTranslateAPI.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/8.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkRustClient
import LarkContainer
final class RustSelectTranslateAPI: SelectTranslateAPI, UserResolverWrapper {
    let userResolver: UserResolver
    let rustService: RustService?
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.rustService = try? userResolver.resolve(assert: RustService.self)
    }
    func selectTextTranslateInformation(selectText: String, trgLanguage: String) -> Observable<ServerPB.ServerPB_Translate_TranslateWebXMLResponse> {
        var request = ServerPB.ServerPB_Translate_TranslateWebXMLRequest()
        request.srcContents = [selectText]
        request.srcLanguage = ""
        request.trgLanguage = trgLanguage
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .translateWebXml) ?? .empty()
    }
    func fetchResource(fileKey: String, fsUnit: String) -> Observable<RustPB.Media_V1_GetResourceWithFsUnitResponse> {
        var request = RustPB.Media_V1_GetResourceWithFsUnitRequest()
        var resource = RustPB.Media_V1_RemoteResourceWithFsUnit()
        resource.fsUnit = fsUnit
        request.key = fileKey
        request.resource = resource
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }
    func detectTextsLanguageRequest(textList: [String]) -> Observable<RustPB.Im_V1_DetectTextsLanguageResponse> {
        var request = Im_V1_DetectTextsLanguageRequest()
        request.textList = textList
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }
}
