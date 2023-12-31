//
//  MyAIProfileHandler.swift
//  LarkContact
//
//  Created by ByteDance on 2023/4/17.
//

import Foundation
import LarkMessengerInterface
import LarkProfile
import LarkNavigator
import EENavigator
import LarkContainer

/// 跳转自己的MyAI
final class MyAIProfileHandler: UserTypedRouterHandler {
    func handle(_ body: MyAIProfileBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let data = LarkProfileData(chatterId: nil,
                                   chatterType: .ai,
                                   contactToken: "",
                                   chatId: "",
                                   fromWhere: .none,
                                   senderID: "",
                                   sender: "",
                                   sourceID: "",
                                   sourceName: "",
                                   subSourceType: "",
                                   source: .unknownSource,
                                   extraParams: [:],
                                   needToPushSetInformationViewController: false)
        let factory = try userResolver.resolve(assert: ProfileFactory.self)
        let tabVC = factory.createProfile(by: data)
        res.end(resource: tabVC)
    }
}
