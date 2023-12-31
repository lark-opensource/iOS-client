//
//  FeedFilterBody.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation
import EENavigator

public struct FeedFilterBody: PlainBody {
    public static let pattern = "//client/feed/filter"

    public var hostProvider: UIViewController?

    public init(hostProvider: UIViewController?) {
        self.hostProvider = hostProvider
    }
}
