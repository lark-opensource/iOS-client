//
//  InMeetShareScreenBottomViewDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/9/20.
//

import Foundation

enum ShareScreenFreeToBrowseViewDisplayStyle {
    /// 不显示
    case hidden
    /// 显示，可点击
    case operable
    /// 显示，不可点击
    case disabled

    var isFreeToBrowseButtonHidden: Bool {
        return self == .hidden
    }
}
