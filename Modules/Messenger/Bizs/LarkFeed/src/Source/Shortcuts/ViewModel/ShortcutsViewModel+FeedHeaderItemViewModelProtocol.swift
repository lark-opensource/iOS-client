//
//  ShortcutsViewModel+FeedHeaderItemViewModelProtocol.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkOpenFeed

// MARK: FeedHeaderItemViewModelProtocol
extension ShortcutsViewModel: FeedHeaderItemViewModelProtocol {
    var type: FeedHeaderItemType {
        .shortcut
    }

    var displayDriver: Driver<Bool> {
        return displayRelay.asDriver()
    }

    var display: Bool {
        displayRelay.value
    }

    var updateHeightDriver: Driver<CGFloat> {
        return updateHeightRelay.asDriver()
    }

    var viewHeight: CGFloat {
        expanded ? maxHeight : minHeight
    }
}
