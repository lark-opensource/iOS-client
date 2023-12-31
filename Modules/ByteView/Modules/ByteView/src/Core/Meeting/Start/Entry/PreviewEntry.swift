//
//  PreviewEntry.swift
//  ByteView
//
//  Created by kiri on 2022/7/21.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork
import ByteViewUI

extension MeetingPrechecker {
    func handlePreviewEntry(_ session: MeetingSession, params: PreviewEntryParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else {
            log.error("handlePreviewEntry cancelled, service is nil")
            return
        }
        let logger = Logger.meeting.withContext(session.sessionId).withTag(session.description)
        logger.info("handlePreviewEntry start, params = \(params)")
        let context = MeetingPrecheckContext(service: service, slaTracker: session.slaTracker)
        let entrance = PreviewEntrance(params: params, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success(let params):
                completion(.success(.preview(params)))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func startPreviewMeeting(_ params: PreviewEntranceOutputParams) {
        if let vendorType = params.vendorType {
            precheckVendorType = vendorType
        }
        precheckRtcRuntimeParams = params.rtcParameterDict
        isE2EeMeeting = params.isE2EeMeeting
        self.executeInQueue(source: "startPreviewMeeting") {
            if self.state == .preparing {
                self.log("startPreviewMeeting success, previewViewParams = \(params.previewViewParams)")
                self.audioDevice?.lockState()
                PreviewReciableTracker.startEnterPreviewForPure()
                DevTracker.post(.criticalPath(.start_preview).category(.meeting).params([.env_id: self.sessionId]))
                self.service?.router.startRoot(PreviewBody(session: self, params: params.previewViewParams))
            } else {
                params.tracker.onError(MeetingStateError.unexpectedStatus)
                self.loge("startPreviewMeeting failed, current state is \(self.state)")
            }
        }
    }
}
