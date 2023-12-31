//
//  MyAIProfileSettingHandler.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import LarkNavigator
import LarkContainer
import LarkUIKit

/// 跳转自己的MyAI
final class MyAIProfileSettingHandler: UserTypedRouterHandler {

    func handle(_ body: MyAISettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        // TODO: @wanghaidong 这里可以不传 avatarKey 了，直接从 MyAIService 里拿
        let vm = MyAISettingViewModel(resolver: userResolver,
                                      myAiId: body.myAiId,
                                      myAiAvatarKey: body.avatarKey,
                                      myAiName: body.name)
        let vc = MyAIProfileSettingController(viewModel: vm)
        res.end(resource: vc)
    }
}
