//
//  ShareMinutesBody.swift
//  MinutesNavigator
//
//  Created by Todd Cheng on 2021/2/4.
//

import EENavigator

public struct ShareMinutesBody: CodablePlainBody {
    public static let pattern = "//client/forward/shareMinutes"

    public let minutesURLString: String  // 飞书妙计链接

    public init(minutesURLString: String) {
        self.minutesURLString = minutesURLString
    }
}
