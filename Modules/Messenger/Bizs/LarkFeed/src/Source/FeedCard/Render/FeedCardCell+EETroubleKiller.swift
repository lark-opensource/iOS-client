//
//  FeedCardCell+EETroubleKiller.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/19.
//

import Foundation
import EETroubleKiller

// 截屏/录屏日志
extension FeedCardCell: CaptureProtocol & DomainProtocol {
    var isLeaf: Bool {
        return true
    }

    var domainKey: [String: String] {
        guard let card = cellViewModel?.feedPreview else { return [:] }
        return [card.id: card.description]
    }
}
