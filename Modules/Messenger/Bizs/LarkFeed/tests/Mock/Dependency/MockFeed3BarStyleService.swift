//
//  MockFeed3BarStyleService.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/18.
//

import Foundation
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkSDKInterface
import LarkOpenFeed
import LarkContainer
import LarkAvatar
@testable import LarkFeed

final class MockFeed3BarStyleService: Feed3BarStyleService {
    private var style: Feed3BarStyle
    private var status: Bool?
    let styleSubject = PublishSubject<Feed3BarStyle>()
    let padUnfoldStatusSubject = PublishSubject<Bool?>()
    let currentFilterText: BehaviorRelay<String> = BehaviorRelay(value: "")

    init(style: Feed3BarStyle) {
        self.style = style
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
