//
//  FeedThreeColumnConfig.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/18.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkOpenFeed

// Feed模块内使用, 记录三栏结构状态信息, 方便判断「Phone与Pad」以及Pad「R视图与C视图」
// Feed模块外使用 FeedThreeBarService 来取值
protocol Feed3BarStyleService {
    var currentFilterText: BehaviorRelay<String> { get }
    var styleSubject: PublishSubject<Feed3BarStyle> { get }
    var currentStyle: Feed3BarStyle { get }
    func updateStyle(_ compact: Bool)

    var padUnfoldStatusSubject: PublishSubject<Bool?> { get }
    var padUnfoldStatus: Bool? { get }
    func updatePadUnfoldStatus(_ unfold: Bool?)
}

final class Feed3BarStyleServiceImpl: Feed3BarStyleService {
    private var style: Feed3BarStyle
    private var status: Bool?
    let styleSubject = PublishSubject<Feed3BarStyle>()
    let padUnfoldStatusSubject = PublishSubject<Bool?>()
    let currentFilterText: BehaviorRelay<String> = BehaviorRelay(value: "")

    init() {
        if Display.pad {
            style = .padRegular
        } else {
            style = .phone
        }
    }

    func updateStyle(_ compact: Bool) {
        if style == .padRegular || style == .padCompact {
            style = compact ? .padCompact : .padRegular
            styleSubject.onNext(style)
        }
    }

    var currentStyle: Feed3BarStyle {
        return style
    }

    func updatePadUnfoldStatus(_ unfold: Bool?) {
        status = unfold
        padUnfoldStatusSubject.onNext(unfold)
    }

    var padUnfoldStatus: Bool? {
        return status
    }
}

// MARK: Feed 三栏配置
final class FeedThreeColumnConfig {
    // 常用分组栏最多展示
    static let fixedItemsMaxNum: Int = 3
}
