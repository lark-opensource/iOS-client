//
//  EventFeedHeaderViewModel+FeedHeaderItemViewModelProtocol.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkOpenFeed

extension EventFeedHeaderViewModel: FeedHeaderItemViewModelProtocol {
    var viewHeight: CGFloat {
        displayRelay.value ? maxHeight : 0
    }

    var type: FeedHeaderItemType {
        .event
    }

    var display: Bool {
        displayRelay.value
    }

    // 是否显示
    var displayDriver: Driver<Bool> {
        return displayRelay.asDriver()
    }

    // 高度变化
    var updateHeightDriver: Driver<CGFloat> {
        return updateHeightRelay.asDriver()
    }
}
