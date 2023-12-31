//
//  PreparingState.swift
//  ByteView
//
//  Created by kiri on 2022/7/12.
//

import Foundation
import Reachability
import ByteViewMeeting
import ByteViewTracker
import AVFoundation
import ByteViewNetwork
import ByteViewUI

final class PreparingState: MeetingComponent {
    let session: MeetingSession
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let entry = event.params["entry"] as? MeetingEntry, let service = session.service else { return nil }
        self.session = session
        if service.setting.perfSampleConfig.isThreadBizMonitorEnabled {
            byteview_setup_thread_api()
        }
        service.setting.prefetch()
        NetworkErrorHandlerImpl.shared.setupRouter(service.larkRouter)
        let usage = ByteViewMemoryUsage.getCurrentMemoryUsage()
        CommonReciableTracker.trackMetricMeeting(event: .vc_metric_before_meeting,
                                                 appMemory: usage.appUsageBytes,
                                                 systemMemory: usage.systemUsageBytes,
                                                 availableMemory: usage.availableUsageBytes)

        session.precheck(entry: entry)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        if toState == .end { return }
        TrackContext.shared.updateContext(for: session.sessionId, block: { $0.isIdle = false })
        if !session.isPending {
            currentExit()
        }
    }

    private func currentExit() {
        if ReachabilityUtil.isCellular {
            Toast.show(I18n.View_G_UsingCellularData)
        }
        Reachability.shared.whenReachable = { r in
            if r.connection == .cellular {
                Toast.show(I18n.View_G_UsingCellularData)
            }
        }
    }
}
