//
//  Provider+MyAI.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2023/6/8.
//

import UIKit
import RustPB
import LKCommonsTracker
import LarkMessengerInterface

extension LarkProfileDataProvider {

    var isAIEnabled: Bool {
        myAIService?.enable.value ?? false
    }

    var isAIProfile: Bool {
        data.chatterType == .ai
    }

    var isMyAIProfile: Bool {
        guard isAIProfile else { return false }
        // UGLY: 如果是通过 MyAIService.openProfile 进入，没有传 chatterId，可以判断为自己的 AI
        return data.chatterId == nil || data.chatterId == myAIService?.info.value.id
    }

    var isOthersAIProfile: Bool {
        isAIProfile && !isMyAIProfile
    }

    var aiShadowID: String {
        data.chatterId ?? myAIService?.info.value.id ?? ""
    }

    var aiDefaultAvatar: UIImage? {
        myAIService?.defaultResource.iconSmall
    }

    @objc
    func didTapMyAISettingButton() {
        guard let fromVC = self.profileVC else {
            return
        }
        guard let aiInfo = userProfile?.userInfoProtocol as? Contact_V2_AIProfile else {
            assertionFailure("Unexpected userProfile")
            return
        }
        // 从 Profile 打开 AI Setting 页面
        let body = MyAISettingBody(myAiId: aiInfo.id,
                                   avatarKey: aiInfo.avatarKey,
                                   name: aiInfo.name)
        self.userResolver.navigator.push(body: body, from: fromVC)

        // 点击 AIProfile 右上角”设置“的埋点
        Tracker.post(TeaEvent("profile_ai_main_click", params: [
            "shadow_id": aiShadowID,
            "contact_type": isMyAIProfile ? "self" : "none_self",
            "setting": "setting"
        ]))
    }
}
