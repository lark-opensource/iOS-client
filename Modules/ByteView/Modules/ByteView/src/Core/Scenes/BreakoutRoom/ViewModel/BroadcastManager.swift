//
//  BroadcastManager.swift
//  ByteView
//
//  Created by wulv on 2021/9/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol BroadcastManagerObserver: AnyObject {
    /// 收到广播
    func broadcastChange(_ message: String?)
}

final class BroadcastManager {
    private var message: String?
    private var dismissTimer: Timer?
    private let timeInterval: TimeInterval = 15
    private let meeting: InMeetMeeting
    init(meeting: InMeetMeeting, transition: TransitionManager) {
        self.meeting = meeting
        NoticeService.shared.addListener(self)
        transition.addObserver(self)
    }

    deinit {
        dismissTimer?.invalidate()
    }

    private let observsers = Listeners<BroadcastManagerObserver>()
    func addObserver(_ observer: BroadcastManagerObserver, fireImmediately: Bool = true) {
        observsers.addListener(observer)
        if fireImmediately, let m = message {
            observer.broadcastChange(m)
        }
    }

    func didClose(_ broadcast: String) {
        if broadcast == message {
            message = nil
        }
    }

    private func dismissBroadcast() {
        guard message != nil else { return }
        message = nil
        observsers.forEach { $0.broadcastChange(nil) }
    }

    private func invalidDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        Util.runInMainThread {
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: false) { [weak self] _ in
                self?.dismissBroadcast()
            }
        }
    }
}

// MARK: - MeetingNoticeListener
extension BroadcastManager: MeetingNoticeListener {

    func didReceiveBreakoutRoomBroadcast(_ message: String) {
        self.message = message
        observsers.forEach { $0.broadcastChange(message) }
        resetDismissTimer()
    }
}

// MARK: - BreakoutRoomManagerObserver
extension BroadcastManager: BreakoutRoomManagerObserver {

    func breakoutRoomIsOpenChanged(_ open: Bool) {
        if !open {
            dismissBroadcast()
        }
    }
}

// MARK: - TransitionManagerObserver
extension BroadcastManager: TransitionManagerObserver {

    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        if isTransition {
            dismissBroadcast()
        }
    }
}
