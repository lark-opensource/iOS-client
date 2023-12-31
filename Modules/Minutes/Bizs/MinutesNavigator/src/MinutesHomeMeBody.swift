//
//  MinutesHomeMeBody.swift
//  Minutes
//
//  Created by admin on 2021/2/24.
//

import Foundation
import EENavigator

public enum MinutesHomeFromSource: String {
    case sideBar = "side_bar"
    case meetingTab = "meeting_tab"
    case autoDelete = "auto_delete"
    case others = "others"
}

public struct MinutesHomeMeBody: PlainBody {
    public static var pattern: String = "//client/minutes/me"

    public let fromSource: MinutesHomeFromSource

    public init(fromSource: MinutesHomeFromSource) {
        self.fromSource = fromSource
    }
}
