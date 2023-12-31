//
//  BaseFeedsViewModel+MyAI.swift
//  LarkFeed
//
//  Created by Hayden on 2023/6/2.
//

import LarkContainer
import LarkMessengerInterface

extension BaseFeedsViewModel {

    var myAIService: MyAIService? {
        try? userResolver.resolve(assert: MyAIService.self)
    }
}
