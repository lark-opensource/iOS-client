//
//  AIServiceAPI.swift
//  LarkSDK
//
//  Created by bytedance on 2020/7/14.
//

import Foundation
import RxSwift
import LarkSDKInterface
import RustPB
import LKCommonsLogging
import LarkModel
import LarkRustClient
import LarkContainer
import LarkLocalizations
import ServerPB
import LarkMessengerInterface
import LarkUIKit

final class RustAIServiceAPI: AIServiceAPI, UserResolverWrapper {
    let userResolver: UserResolver
    let rustService: RustService?
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.rustService = try? userResolver.resolve(assert: RustService.self)
    }
    func getSmartCompose(chatId: String, prefix: String, scene: SmartComposeScene) -> Observable<Ai_V1_GetSmartComposeResponse> {
        var request = Ai_V1_GetSmartComposeRequest()
        request.scene = Ai_V1_GetSmartComposeRequest.Scene(rawValue: scene.rawValue) ?? Ai_V1_GetSmartComposeRequest.Scene()
        request.prefix = prefix
        request.locale = LanguageManager.currentLanguage.localeIdentifier
        var messagerContext = Ai_V1_ClientMessengerContext()
        messagerContext.chatID = chatId
        request.messengerContext = messagerContext
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }

    func getSmartCorrect(chatID: String, texts: [String], scene: String) -> Observable<ServerPB_Correction_AIGetTextCorrectionResponse> {
        var request = ServerPB_Correction_AIGetTextCorrectionRequest()
        request.texts = texts
        request.scene = scene
        request.chatID = chatID
        request.sessionID = chatID
        request.userLanguage = LanguageManager.currentLanguage.localeIdentifier
        request.platform = Display.pad ? "ipad" : "iphone"
        request.isFinal = false
        request.isRecall = false
        request.lastMessagePosition = ""
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .getAiTextCorrection) ?? .empty()
    }
}
