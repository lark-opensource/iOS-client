//
//  VoIPHandlers.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
import Foundation
import EENavigator
import LarkAccountInterface
import UniverseDesignToast
import LKCommonsTracker
import LarkVoIP
import Homeric
import ByteViewInterface
import LarkNavigator

/// VoIP
struct CallVoIPBody: CodablePlainBody {
    /// /client/byteview/callvoip
    static let pattern: String = "//client/byteview/callvoip"

    let userID: String
}

final class CallVoIPHandler: UserTypedRouterHandler {
    func handle(_ body: CallVoIPBody, req: EENavigator.Request, res: Response) {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_VOIP_CALLBACK))
        if let module = try? userResolver.resolve(assert: ClientMutexService.self).currentModule {
            if let from = req.context.from()?.fromViewController {
                let text = module.isRinging ? I18n.View_G_IncomingCallCannotCall : I18n.View_G_CurrentlyInCall
                UDToast.showTips(with: text, on: from.view, delay: 3.0)
            }
        } else {
            try? userResolver.resolve(assert: VoIPService.self).createCallToUser(userID: body.userID, secureChatId: nil, callback: nil)
        }
        res.end(resource: EmptyResource())
    }
}


struct PullVoIPCallBody: CodablePlainBody {
    static let pattern: String = "//client/videochat/pullvoipcall"
}

final class PullVoIPCallHandler: UserTypedRouterHandler {
    func handle(_ body: PullVoIPCallBody, req: EENavigator.Request, res: Response) {
        try? userResolver.resolve(assert: VoIPService.self).pullCurrentCall(sourceType: .longConnectionLoss)
        res.end(resource: EmptyResource())
    }
}
