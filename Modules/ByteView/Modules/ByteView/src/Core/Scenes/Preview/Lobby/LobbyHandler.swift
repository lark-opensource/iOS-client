//
//  LobbyHandler.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting

struct LobbyBody: RouteBody {
    static let pattern = "//client/videoconference/lobby"
    let session: MeetingSession
}

final class LobbyHandler: RouteHandler<LobbyBody> {

    override func handle(_ body: LobbyBody) -> UIViewController? {
        guard let vm = LobbyViewModel(session: body.session, lobbySource: .inLobby) else {
            return nil
        }
        let vc = PresentationViewController(router: vm.router, fullScreenFactory: { () -> UIViewController in
            return LobbyViewController(viewModel: vm)
        }, floatingFactory: {
            let viewController = FloatingPreMeetingVC(viewModel: vm.floatVM)
            viewController.camera = vm.camera
            return viewController
        })
        return vc
    }
}
