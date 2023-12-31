// longweiwei

import Foundation

public protocol TrackProxy: AnyObject {
    func handleMailTrackEvent(_ event: String,
                              params: [String: Any]?)
}
