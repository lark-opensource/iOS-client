//
//  CallInHandler.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/27.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting

final class CallInHandler: RouteHandler<CallInBody> {
    override func handle(_ body: CallInBody) -> UIViewController? {
        Logger.phoneCall.info("CallInHandler, callInType is \(body.callInType.type)")

        if let vm = CallInViewModel(meeting: body.session, isBusyRinging: false, viewType: .fullScreen) {
            return CallInPresentationViewController(viewModel: vm)
        }
        return nil
    }
}
