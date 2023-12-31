//
//  TopBarViewModel+FeedHeaderItemViewModelProtocol.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/8.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkOpenFeed

extension TopBarViewModel: FeedHeaderItemViewModelProtocol {
    var viewHeight: CGFloat {
        displayRelay.value ? Cons.viewHeight as CGFloat : 0
    }

    var type: FeedHeaderItemType {
        .topBar
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

    enum Cons {
        static let viewHeight: CGFloat = 42.0
    }
}
