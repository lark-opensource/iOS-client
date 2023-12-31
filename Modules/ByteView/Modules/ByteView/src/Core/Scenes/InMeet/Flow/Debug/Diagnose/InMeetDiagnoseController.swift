//
//  InMeetDiagnoseController.swift
//  ByteView
//
//  Created by liujianlong on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewRtcBridge

class InMeetDiagnoseController {
    private var snt: AnyObject?
    let gridChecker: ParticipantGridStatusChecker

    // ByteViewDebug 模块实现协议，注入 Container
    var gridDebugTool: ParticipantGridDebugToolProtocol?

    init(meetingID: String, collectionView: UICollectionView, rtc: InMeetRtcEngine) {
        self.gridChecker = ParticipantGridStatusChecker(meetingID: meetingID, collectionView: collectionView, rtc: RtcStatus(engine: rtc))
        self.gridDebugTool = ParticipantGridDebugToolResolver.resolve()
        self.gridDebugTool?.setup(collectionView: collectionView, statusChecker: gridChecker)
    }

    func start() {
        self.snt = NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: nil) { [weak self] _ in
            self?.handleScreenShotEvent()
        }
    }

    func stop() {
        if let obj = snt {
            NotificationCenter.default.removeObserver(obj)
            snt = nil
        }
    }

    deinit {
        stop()
        self.gridDebugTool?.destroy()
    }

    func handleScreenShotEvent() {
        let status = self.gridChecker.checkVisibleCellsStatus()
        Logger.grid.info("stream status \(status)")
        AladdinTracks.trackSnapshotDiagnosticLog("\(status)")
    }
}
