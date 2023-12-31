//
//  ShortcutViewModel+Storage.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/8/18.
//

import UIKit
import Foundation
import RunloopTools

// 将数据中的一部分存储在端上.feed缓存方案 https://bytedance.feishu.cn/docs/doccnsUow00r25XJEqjkFlmlXfg#
extension ShortcutsViewModel {

    func observeApplicationNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.saveShortcuts()
            }).disposed(by: disposeBag)
    }

    func loadShortcutsCache() {
        guard let shortcuts = FeedKVStorage(userId: userId).getLocalShortcuts() else { return }
        handleDataFromShortcut(shortcuts, source: .load)
    }

    func saveShortcuts() {
        FeedKVStorage(userId: userId).saveShortcuts(dataSource)
    }
}
