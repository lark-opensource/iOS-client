//
//  FeedLayoutConfig.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/4/17.
//

import Foundation
import RxSwift
import RxCocoa
import LarkOpenFeed

// MARK: - 提供Feed列表容器Size的能力,方便UI布局
final class FeedLayoutConfig: FeedLayoutService {
    let containerSizeChangeRelay = BehaviorRelay<CGSize>(value: CGSize.zero)

    // Feed列表容器视图的Size值
    var containerSize: CGSize {
        return containerSizeChangeRelay.value
    }
    // 监听Feed列表容器视图Size变化的信号
    var containerSizeChangeObservable: Observable<CGSize> {
        return containerSizeChangeRelay.asObservable().distinctUntilChanged()
    }
    // 存储Feed列表容器视图Size
    func storeContainerSize(_ size: CGSize) {
        containerSizeChangeRelay.accept(size)
    }
}
