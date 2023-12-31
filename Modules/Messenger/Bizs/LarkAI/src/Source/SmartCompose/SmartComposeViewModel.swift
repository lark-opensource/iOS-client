//
//  SmartComposeViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/19.
//

import UIKit
import LarkSDKInterface
import LarkContainer
import RxSwift
import RustPB
import LarkMessengerInterface
import LarkLocalizations

class SmartComposeViewModel: NSObject {

    let countLimit: Int = 20
    let userResolver: UserResolver
    let aiServiceApi: AIServiceAPI

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.aiServiceApi = RustAIServiceAPI(resolver: resolver)
    }

    func getSmartComposeSuggestion(chatId: String, prefix: String, scene: SmartComposeScene) -> Observable<(String, Ai_V1_GetSmartComposeResponse)> {
        // TODO：缓存处理
        return aiServiceApi.getSmartCompose(chatId: chatId,
                                            prefix: prefix,
                                            scene: scene)
            .map { (response) -> (String, Ai_V1_GetSmartComposeResponse) in
                return (prefix, response)
            }
    }
}
