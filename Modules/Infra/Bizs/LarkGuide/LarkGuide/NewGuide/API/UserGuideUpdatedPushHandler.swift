//
//  PushUserGuideUpdatedMessage.swift
//  LarkGuide
//
//  Created by zhenning on 2020/06/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer

final class UserGuideUpdatedPushHandler: BaseRustPushHandler<RustPB.Onboarding_V1_UserGuideUpdatedRequest> {

    private let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: RustPB.Onboarding_V1_UserGuideUpdatedRequest) {
        self.pushCenter.post(PushUserGuideUpdatedMessage(pairs: message.orderedPairs))
    }
}
