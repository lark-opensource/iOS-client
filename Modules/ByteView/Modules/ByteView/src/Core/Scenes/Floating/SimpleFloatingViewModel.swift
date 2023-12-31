//
//  SimpleFloatingViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/1.
//

import Foundation
import ByteViewMeeting

protocol SimpleFloatingViewModelDelegate: AnyObject {
    func statusTextDidChange(_ text: String)
}

class SimpleFloatingViewModel {
    let session: MeetingSession
    weak var delegate: SimpleFloatingViewModelDelegate?
    private static let callingText = I18n.View_G_Calling
    private static let ringingText = I18n.View_G_RingingDin
    var statusText = ""
    private var timer: Timer?
    private weak var meeting: InMeetMeeting?

    init(session: MeetingSession) {
        self.session = session
        session.addListener(self)
        setupStatusListener()
    }

    private func setupStatusListener() {
        if session.state == .calling {
            updateStatusText(Self.callingText)
        } else if  session.state == .ringing {
            updateStatusText(Self.ringingText)
        } else if session.state == .onTheCall, let meeting = session.component(for: OnTheCallState.self)?.meeting {
            self.meeting = meeting
            setupDurationTimer()
        }
    }

    private func updateStatusText(_ text: String) {
        Util.runInMainThread {
            self.statusText = text
            self.delegate?.statusTextDidChange(text)
        }
    }

    private func setupDurationTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] (t) in
            if let self = self {
                self.updateDuration()
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer
    }

    private func updateDuration() {
        guard let startTime = meeting?.startTime else { return }
        let time = Int(Date().timeIntervalSince(startTime))
        guard time >= 0 else {
            updateStatusText("")
            return
        }
        // disable-lint: magic number
        let hour = time / 3600
        let minute = (time % 3600) / 60
        let second = time % 60
        // enable-lint: magic number
        let s = hour > 0 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d", minute, second)
        updateStatusText(s)
    }
}

extension SimpleFloatingViewModel: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        setupStatusListener()
    }
}
