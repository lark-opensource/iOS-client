//
//  MeetingSessionHelper.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/6/1.
//

import Foundation
import EEAtomic

final class MeetingSessionHelper {
    let sessionType: MeetingSessionType
    private init(sessionType: MeetingSessionType) {
        self.sessionType = sessionType
    }

    private var envOnceToken: AtomicOnce?
    var adapter: MeetingAdapter.Type? {
        didSet {
            envOnceToken = AtomicOnce()
        }
    }

    func initializeEnvOnce() {
        envOnceToken?.once {
            adapter?.handleMeetingEnvInitialization()
        }
    }
}

/// 不用map存，以免频繁lock
private extension MeetingSessionHelper {
    static let vc = MeetingSessionHelper(sessionType: .vc)
}

extension MeetingSession {
    var helper: MeetingSessionHelper { self.sessionType.helper }
}

extension MeetingSessionType {
    var helper: MeetingSessionHelper {
        switch self {
        case .vc:
            return .vc
        }
    }
}
