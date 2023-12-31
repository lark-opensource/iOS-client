//
//  ConnectFailedHandler.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting

struct ConnectFailedBody: RouteBody {
    static let pattern = "//client/videoconference/connectFailed"

    let session: MeetingSession
}

final class ConnectFailedHandler: RouteHandler<ConnectFailedBody> {
    override func handle(_ body: ConnectFailedBody) -> UIViewController? {
        return ConnectFailedViewController(viewModel: ConnectFailedViewModel(session: body.session))
    }
}
