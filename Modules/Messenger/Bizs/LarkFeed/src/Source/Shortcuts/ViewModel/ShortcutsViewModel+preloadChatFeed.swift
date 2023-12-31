//
//  ShortcutsViewModel+preloadChatFeed.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import Foundation
import RunloopTools

// MARK: feeds 预加载
extension ShortcutsViewModel {
    // 3.16 Rust接口优化，只有展开置顶，才做预加载(Only Once)
    // 前5个Rust已经预加载，从第6个开始
    // TODO: 要不要去掉
    func preloadChatFeed() {
        guard !isFirstExpand && dataSource.count > 5 else {
            return
        }
        isFirstExpand = true
        let ids = self.dataSource.suffix(from: 5).filter({ $0.preview.basicMeta.feedPreviewPBType == .chat }).map({ $0.preview.id })
        guard !ids.isEmpty else { return }
        RunloopDispatcher.shared.addTask(priority: .medium) { [weak self] in
            guard let self = self else { return }
            self.dependency.preloadChatFeed(by: ids)
        }.waitCPUFree()
    }
}
