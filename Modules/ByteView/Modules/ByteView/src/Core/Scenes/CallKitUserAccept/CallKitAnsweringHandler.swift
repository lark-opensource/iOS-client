//
//  CallKitAnsweringHandler.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting

struct CallKitAnsweringBody: RouteBody {
    static let pattern = "//client/videoconference/callKitAnswering"

    let session: MeetingSession
    let meetSetting: MicCameraSetting
}

final class CallKitAnsweringHandler: RouteHandler<CallKitAnsweringBody> {

    override func handle(_ body: CallKitAnsweringBody) -> UIViewController? {
        guard let vm = CallKitAnsweringVM(session: body.session, meetSetting: body.meetSetting) else { return nil }
        let vc = CallKitAnsweringVC(viewModel: vm)
        return vc
    }

}
