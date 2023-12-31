//
//  ReadListCellViewModel.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/30.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkModel

typealias DisplayNameProvider = (Chatter) -> String

final class ReadListCellViewModel {
    var chatter: Chatter
    var isUrgent: Bool
    var isAt: Bool
    var isUnread: Bool?
    var provider: DisplayNameProvider
    var filterKey: String?

    var rightIcon: UIImage? {
        if self.isAt {
            return Resources.iconAt
        } else {
            return nil
        }
    }

    var statusWeight: Int {
        var weight = 0
        if self.isUrgent {
            weight += 1
        }
        if self.isAt {
            weight += 1
        }
        return weight
    }

    init(chatter: Chatter, isUrgent: Bool, isAt: Bool, filterKey: String?, provider: @escaping DisplayNameProvider) {
        self.chatter = chatter
        self.isUrgent = isUrgent
        self.isAt = isAt
        self.filterKey = filterKey
        self.provider = provider
    }

    func chatterDisplayName() -> String {
        return self.provider(chatter)
    }
}
