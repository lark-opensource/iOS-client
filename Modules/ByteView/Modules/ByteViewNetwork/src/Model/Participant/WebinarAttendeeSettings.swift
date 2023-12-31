//
// Created by liujianlong on 2022/9/19.
//

import Foundation
import RustPB

public struct WebinarAttendeeSettings: Equatable {
    public var unmuteOffer: Bool?
    public var becomeParticipantOffer: Bool?
    public init(unmuteOffer: Bool? = nil, becomeParticipantOffer: Bool? = nil) {
        self.unmuteOffer = unmuteOffer
        self.becomeParticipantOffer = becomeParticipantOffer
    }
}

extension WebinarAttendeeSettings {
    var pbType: Videoconference_V1_WebinarAttendeeSettings {
       var settings = Videoconference_V1_WebinarAttendeeSettings()
        if let unmuteOffer = self.unmuteOffer {
            settings.unmuteOffer = unmuteOffer
        }
        if let becomeParticipantOffer = self.becomeParticipantOffer {
            settings.becomeParticipantOffer = becomeParticipantOffer
        }
        return settings
    }
}
