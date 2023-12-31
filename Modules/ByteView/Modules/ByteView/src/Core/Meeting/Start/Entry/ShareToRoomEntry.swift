//
//  ShareToRoomEntry.swift
//  ByteView
//
//  Created by kiri on 2023/6/18.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker

extension MeetingPrechecker {
    func handleShateToRoomEntry(_ session: MeetingSession, entryParams: ShareToRoomEntryParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        let context = MeetingPrecheckContext(service: service)
        let entrance = ShareToRoomEntrance(params: entryParams, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success:
                completion(.success(.shareToRoom))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func startSharingToRoom(_ params: ShareToRoomEntryParams) {
        let source = params.source
        log("startSharingToRoom(source: \(source))")
        if source == .groupPlus {
            VCTracker.post(name: .vc_meeting_entry_click, params: [.click: "share_screen", "during_meeting": MeetingManager.shared.hasActiveMeeting])
        }
        if let session = MeetingManager.shared.currentSession, let sharer = session.inMeetLocalContentSharer,
           sharer.shareScreenToRoom() {
            log("startSharingContentToRoom finished, to existed session \(session)")
            return
        }
        if let vm = LocalShareContentViewModel(source: source, session: self) {
            Util.runInMainThread {
                let vc = ShareContentViewController(viewModel: vm)
                params.fromVC?.presentDynamicModal(vc,
                                                   regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                   compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
            }
        } else {
            loge("create LocalShareContentViewModel failure")
        }
    }
}
