//longweiwei

import Foundation
import MailSDK
import RustPB
import SwiftProtobuf
import LKCommonsTracker

class TrackProvider: TrackProxy {

    func handleMailTrackEvent(_ event: String, params: [String: Any]?) {
        if MailTracker.shared.eventPlatform(event).tea {
            Tracker.post(TeaEvent(event, params: params ?? [:]))
        }

        if MailTracker.shared.eventPlatform(event).slardar {
            Tracker.post(SlardarEvent(
                name: event,
                metric: params ?? [:],
                category: [:],
                extra: [:])
            )
        }
    }
}
