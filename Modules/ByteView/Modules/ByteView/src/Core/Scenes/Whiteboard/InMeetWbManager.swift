//
//  InMeetWbManager.swift
//  ByteView
//
//  Created by helijian on 2022/4/23.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewNetwork
import ByteViewTracker
import Whiteboard

final class InMeetWbManager: InMeetShareDataListener {
    let meeting: InMeetMeeting
    private var wbViewController: WhiteboardViewController?
    private let logger = Logger.whiteboard
    // 配置跟随整个meeting
    var penBrushAndColor = BrushAndColorMemory(color: .black, brushType: .light)
    var highlighterBrushAndColor = BrushAndColorMemory(color: .red, brushType: .bold)
    var shapeTypeAndColor = ShapeTypeAndColor(shape: .rectangle, color: .black)
    required init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.meeting.shareData.addListener(self)
    }

    func storeWbViewController(_ vc: WhiteboardViewController) {
        self.wbViewController = vc
    }

    func getStoredVC() -> WhiteboardViewController? {
        logger.info("hasStoredVC \(wbViewController != nil)")
        wbViewController?.setLayerMiniScale()
        return wbViewController
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if !newScene.isWhiteboard {
            DispatchQueue.main.async {
                self.wbViewController?.dismissPresentedViewController()
                self.wbViewController = nil
            }
            logger.info("clear stored WbViewController")
        }
    }

}
