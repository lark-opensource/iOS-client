//
//  ProductGuidePushHandler.swift
//  LarkSDK
//
//  Created by sniperj on 2018/12/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer

public struct PushProductGuideMessage: PushMessage {
    public let guides: [String: Bool]

    public init(guides: [String: Bool]) {
        self.guides = guides
    }
}

final class ProductGuidePushHandler: BaseRustPushHandler<RustPB.Onboarding_V1_PushProductGuide> {

    private let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: RustPB.Onboarding_V1_PushProductGuide) {
        self.pushCenter.post(PushProductGuideMessage(guides: message.guides))
    }
}
