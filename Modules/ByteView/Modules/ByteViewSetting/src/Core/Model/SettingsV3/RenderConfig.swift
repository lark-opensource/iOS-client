//
//  RenderConfig.swift
//  ByteView
//
//  Created by liujianlong on 2023/2/28.
//

import Foundation

public struct SharedDisplayLinkConfig: Decodable {
    public var enabled: Bool
    public var fpsList: [Int]
    public var maxFps: Int
}

// disable-lint: magic number
public struct UnsubscribeDelayConfig: Decodable {
    public var maxStreamCount: Int
    public var video: Float
    public var screen: Float

    public static let `default` = UnsubscribeDelayConfig(maxStreamCount: 10, video: 0.5, screen: 2.5)
}

public struct RenderConfig: Decodable {
    public var sharedDisplayLink: SharedDisplayLinkConfig?
    public var unsubscribeDelay: UnsubscribeDelayConfig?

    static let `default` = RenderConfig(sharedDisplayLink: nil, unsubscribeDelay: .default)
}
