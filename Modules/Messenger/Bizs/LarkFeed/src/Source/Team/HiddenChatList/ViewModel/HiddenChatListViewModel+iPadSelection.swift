//
//  HiddenChatListViewModel+iPadSelection.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RxSwift
import LarkUIKit

extension HiddenChatListViewModel {
    /// 设置选中
    func setSelected(feedId: String?) {
        self.dependency.setSelected(feedId: feedId)
    }

    /// iPad选中态监听
    func observeSelect() -> Observable<String?> {
        self.dependency.observeSelect()
    }

    /// 是否需要跳过: 避免重复跳转
    func shouldSkip(feedId: String, traitCollection: UIUserInterfaceSizeClass?) -> Bool {
        return false
    }
}
