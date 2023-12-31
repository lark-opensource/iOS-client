//
//  ForwardViewModel.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/9/22.
//

import Foundation
import LarkMessengerInterface

struct ForwardState {
    var recentForwardItems: [ForwardItem]
    var recentViewItems: [ForwardItem]
}

final class ForwardViewModel {
    static func filterForwardItems(recentForwardItems: [ForwardItem], recentViewItems: [ForwardItem], noRepeat: Bool?) -> ForwardState {
        if noRepeat == true {
            let recentForwardIds = recentForwardItems.map { $0.id }
            let filterRecentViewItems = recentViewItems.filter {
                if $0.type == .chat { return !recentForwardIds.contains($0.id) }
                if $0.type == .user { return !recentForwardIds.contains($0.id) }
                if $0.type == .myAi { return !recentForwardIds.contains($0.id) }
                return true
            }
            return ForwardState(recentForwardItems: recentForwardItems, recentViewItems: filterRecentViewItems)
        } else {
            return ForwardState(recentForwardItems: recentForwardItems, recentViewItems: recentViewItems)
        }
    }
}
