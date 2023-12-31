//
//  PreviewHandler.swift
//
//
//  Created by yangyao on 2020/9/25.
//

import Foundation
import ByteViewMeeting

final class PreviewHandler: RouteHandler<PreviewBody> {
    override func handle(_ body: PreviewBody) -> UIViewController? {
        guard body.session.state == .preparing,
              let vm = PreviewMeetingViewModel(session: body.session, joinParams: body.joinParams) else { return nil }

        let vc = PreviewMeetingViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }
}
