//
//  SystemCallingManager.swift
//  ByteView
//
//  Created by admin on 2022/11/18.
//

import Foundation
import ByteViewNetwork

protocol SystemCallingDelegate: AnyObject {
    func systemCallingDidChange(state: MicIconState, sessionID: String)
}

class SystemCallingManager {
    static let shared = SystemCallingManager()
    static let logger = Logger.getLogger("sysCallManager")
    private let listerners = Listeners<SystemCallingDelegate>()
    private var currentMicState: MicIconState?

    private init() {}

    func setMicState(state: MicIconState, sessionID: String) {
        DispatchQueue.main.async {
            self.listerners.forEach { $0.systemCallingDidChange(state: state, sessionID: sessionID) }
        }
    }

    func addListener(_ listener: SystemCallingDelegate) {
        listerners.addListener(listener)
    }

    func removeListener(_ listener: SystemCallingDelegate) {
        listerners.removeListener(listener)
    }
}

extension SystemCallingManager {
    static func changeMobileCallingStatus(meeting: InMeetMeeting, status: ParticipantSettings.MobileCallingStatus) {
        Self.logger.info("\(#function) request begin \(status)")

        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.mobileCallingStatus = status
        meeting.httpClient.send(request, options: .retry(3, owner: nil)) { result in
            switch result {
            case .success:
                Self.logger.info("changeMobileCallingStatus request success")
            case .failure(let error):
                Self.logger.info("changeMobileCallingStatus request error \(error)")
            }
        }
    }
}
