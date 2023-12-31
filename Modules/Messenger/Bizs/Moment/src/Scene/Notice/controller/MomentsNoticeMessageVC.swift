//
//  MomentsNoticeMessageVC.swift
//  Moment
//
//  Created by bytedance on 2021/2/25.
//

import Foundation
import UIKit

final class MomentsNoticeMessageVC: MomentsNoticeBaseVC {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func listDidAppear() {
        Tracer.trackCommunityNotificationPageView(type: .interaction)
        MomentsTracer.trackNotificationPageViewWith(isInteraction: true, circleId: viewModel.circleId)
    }
}
