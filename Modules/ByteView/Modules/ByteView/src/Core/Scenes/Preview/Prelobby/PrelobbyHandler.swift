//
//  LobbyHandler.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import ByteViewMeeting

struct PrelobbyBody: RouteBody {
    static let pattern = "//client/videoconference/prelobby"
    let session: MeetingSession
}

final class PrelobbyHandler: RouteHandler<PrelobbyBody> {

    override func handle(_ body: PrelobbyBody) -> UIViewController? {
        guard let vm = LobbyViewModel(session: body.session, lobbySource: .preLobby) else {
            return nil
        }
        let vc = PresentationViewController(router: vm.service.router, fullScreenFactory: { () -> UIViewController in
            return PrelobbyViewController(viewModel: vm)
        }, floatingFactory: {
            let viewController = FloatingPreMeetingVC(viewModel: vm.floatVM)
            viewController.camera = vm.camera
            return viewController
        })
        return vc
    }
}
