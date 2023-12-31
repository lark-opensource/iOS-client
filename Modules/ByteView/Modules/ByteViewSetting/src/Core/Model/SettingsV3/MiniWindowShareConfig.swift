import Foundation

public struct MiniwindowShareConfig: Decodable {
    static let `default` = MiniwindowShareConfig(shareUnsubscribeDelaySeconds: -1.0)
    public var shareUnsubscribeDelaySeconds: Float

    public init(shareUnsubscribeDelaySeconds: Float) {
        self.shareUnsubscribeDelaySeconds = shareUnsubscribeDelaySeconds
    }
}
