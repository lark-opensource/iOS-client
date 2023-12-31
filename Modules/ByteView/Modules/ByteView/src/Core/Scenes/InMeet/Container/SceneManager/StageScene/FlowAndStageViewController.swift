//
//  FlowAndStageViewController.swift
//  ByteView
//
//  Created by liujianlong on 2023/3/11.
//

import UIKit

class InMeetFlowAndStageViewController: InMeetFlowAndShareContainerViewControllerV2 {

    convenience init(gridViewModel: InMeetGridViewModel,
                     stageVC: InMeetFlowAndShareProtocol) {
        self.init(gridViewModel: gridViewModel, shareVC: stageVC, hasShrinkView: false)
    }

    override func updateBackgroundColor() {
        // NOTE: 舞台布局横屏无需修改背景色
    }
}
