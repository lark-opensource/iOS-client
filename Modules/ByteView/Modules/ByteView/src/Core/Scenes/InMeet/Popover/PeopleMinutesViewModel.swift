//
//  PeopleMinutesViewModel.swift
//  ByteView
//
//  Created by wulv on 2022/1/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

final class PeopleMinutesViewModel {
    static let dismissSeconds: TimeInterval = 5
    private var dismissTimer: Timer?
    private var openSeq: Int64 = -1

    private let popoverShowRelay = BehaviorRelay<Bool>(value: false)
    private(set) lazy var popoverShowDriver: Driver<Bool> = popoverShowRelay.asDriver()
    private lazy var minutesOpenedRelay = BehaviorRelay<Bool>(value: meeting.data.isPeopleMinutesOpened)
    private(set) lazy var minutesOpenedDriver: Driver<Bool> = minutesOpenedRelay.distinctUntilChanged().asDriver(onErrorJustReturn: false)

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    private let statusManager: InMeetStatusManager
    init(meeting: InMeetMeeting, context: InMeetViewContext, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.context = context
        self.statusManager = resolver.resolve()!
        self.statusManager.addListener(self)
    }

    func clickBackgroundCover() {
        dismissPopover()
    }

    func peopleMinutesStateChange(open: Bool, seq: Int64) {
        if open {
            VCTracker.post(name: .vc_meeting_onthecall_view,
                           params: [
                            "is_sharing": context.meetingContent.isShareContent,
                            "is_show_interview_record": true])
            context.fullScreenDetector?.postInterruptEvent(anmited: false)

            guard !context.cancledPeopleMinutesPopovers.contains(seq) else { return } // 小窗->大窗
            popoverShowRelay.accept(true)
            openSeq = seq
            dismissTimer?.invalidate()
            let timer = Timer(timeInterval: Self.dismissSeconds, repeats: false) { [weak self] _ in
                self?.dismissPopover()
            }
            RunLoop.main.add(timer, forMode: .common)
            dismissTimer = timer
        } else {
            popoverShowRelay.accept(false)
        }
    }

    private func dismissPopover() {
        context.cancledPeopleMinutesPopovers.insert(openSeq)
        popoverShowRelay.accept(false)
    }

    deinit {
        dismissTimer?.invalidate()
    }
}

extension PeopleMinutesViewModel: InMeetStatusManagerListener {
    func statusDidChange(type: InMeetStatusType) {
        guard type == .interviewRecord else { return }
        Util.runInMainThread {
            let isOpen = self.meeting.data.isPeopleMinutesOpened
            self.peopleMinutesStateChange(open: isOpen, seq: self.meeting.data.peopleMinutesSeq)
            self.minutesOpenedRelay.accept(isOpen)
        }
    }
}
extension PeopleMinutesViewModel {
    static func stopPeopleMinutes(meeting: InMeetMeeting, isShareing: Bool, onConfirm: (() -> Void)? = nil) {
        let meetingId = meeting.meetingId
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "stop_record",
                                "is_sharing": isShareing,
                                .target: TrackEventName.vc_meeting_popup_view])

        let track: ((Bool) -> Void) = { stop in
            VCTracker.post(name: .vc_meeting_popup_click,
                           params: [.click: stop ? "stop" : "cancel", .content: "stop_interview_record"])
        }

        let cancel: ((ByteViewDialog) -> Void) = { _ in
            track(false)
        }

        let httpClient = meeting.httpClient
        let closeMinutes: ((ByteViewDialog) -> Void) = { _ in
            track(true)
            onConfirm?()
            httpClient.send(UpdateMinutesStatusRequest(meetingID: meetingId, status: .close)) { r in
                switch r {
                case .success: break
                    // 面试速记停止后，服务端通过PUSH_VIDEO_CHAT_NOTICE推Toast: View_G_EndedWrittenRecording_Toast
                case .failure(let error):
                    Logger.meeting.error("changeMinutesStatus error: \(error)")
                    Util.runInMainThread {
                        Toast.show(I18n.View_G_UnableEndRecordTryTry_Toast)
                    }
                }
            }
        }

        ByteViewDialog.Builder()
            .id(.peopleMinutes)
            .needAutoDismiss(true)
            .colorTheme(.redLight)
            .title(I18n.View_G_ConfirmEndWrittenRecord_PopUpWindowTitle)
            .message(I18n.View_G_ConfirmEndWrittenRecord_PopUpWindowExplain)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler(cancel)
            .rightTitle(I18n.View_G_ConfirmEndWrittenRecord_EndButton)
            .rightHandler(closeMinutes)
            .show()
    }
}
