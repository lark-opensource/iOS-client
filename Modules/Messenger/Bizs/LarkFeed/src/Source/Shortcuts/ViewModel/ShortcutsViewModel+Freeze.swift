//
//  ShortcutsViewModel+Freeze.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 控制冻结
import Foundation
extension ShortcutsViewModel {

    // 在用户进行UI操作时，防止数据的变动引起UI的变化
    func freeze(_ isSuspended: Bool) {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        queue.isSuspended = isSuspended
        FeedContext.log.info("feedlog/shortcut/dataflow/queue. isSuspended: \(isSuspended)")
    }
}
