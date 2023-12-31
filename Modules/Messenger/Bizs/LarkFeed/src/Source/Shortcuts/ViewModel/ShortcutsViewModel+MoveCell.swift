//
//  ShortcutsViewModel+MoveCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import RustPB
import LarkSDKInterface

// MARK: 移动 cell 相关
extension ShortcutsViewModel {
    /// 移动置顶位置处理逻辑
    func updateItemPosition(sourceIndexPath: IndexPath, destinationIndexPath: IndexPath, on vc: UIViewController?) {
        if sourceIndexPath.row == destinationIndexPath.row {
            return
        }
        var dataSource = self.dataSource
        let shortcut = dataSource[sourceIndexPath.row]
        let destinationShortcut = dataSource[destinationIndexPath.row]
        dataSource.remove(at: sourceIndexPath.row)
        dataSource.insert(shortcut, at: destinationIndexPath.row)
        FeedContext.log.info("feedlog/shortcut/dataflow/move. remove: \(sourceIndexPath.row), insert: \(destinationIndexPath.row)")

        // 通知后端shortcut位置变更
        self.dependency.update(shortcut: shortcut.shortcut, newPosition: Int(destinationShortcut.position))
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self, weak vc] (error) in
                guard let vc = vc,
                      let error = error.underlyingError as? APIError,
                      Int(error.code) == FeedSDKErrorCode.outOfGroup else { return }

                var channel = Basic_V1_Channel()
                channel.type = .chat
                channel.id = shortcut.id

                self?.dependency.removeFeedCard(channel: channel,
                                                feedPreviewPBType: shortcut.preview.basicMeta.feedPreviewPBType,
                                             from: vc)
            }).disposed(by: disposeBag)

        // 直接在主线程替换UI数据源数组 (跳过reload)
        self.fireRefresh(ShortcutViewModelUpdate.skipped(dataSource))
    }
}
