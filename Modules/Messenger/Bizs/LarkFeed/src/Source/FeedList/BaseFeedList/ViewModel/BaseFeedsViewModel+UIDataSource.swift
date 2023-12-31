//
//  BaseFeedsViewModel+UIDataSource.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/24.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK

// MARK: - Datas

extension BaseFeedsViewModel {
    /// 获取所有UI数据
    func allItems(_ section: Int = 0) -> [FeedCardCellViewModel] {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        guard section < sections.count else { return [] }
        return sections[section].items
    }

    /// 更新UI数据: 应在feedRelay信号监听中调用(performBatchUpdates需要在动画block中更新数据源)
    /// 不要在其他地方调用，因为originItems应和UI数据保持一致，否则diff将失效
    func setItems(_ sections: [SectionHolder]) {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        self.sections = sections
        let showEmptyView = allItems().isEmpty
        showEmptyViewRelay.accept(showEmptyView)
    }

    func cellRowHeight(_ indexPath: IndexPath) -> CGFloat? {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        guard indexPath.section < self.sections.count,
            indexPath.row < sections[indexPath.section].items.count else { return nil }
        return sections[indexPath.section].items[indexPath.row].cellRowHeight
    }

    func cellViewModel(_ indexPath: IndexPath) -> FeedCardCellViewModel? {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        guard indexPath.section < self.sections.count,
            indexPath.row < sections[indexPath.section].items.count else { return nil }
        return sections[indexPath.section].items[indexPath.row]
    }
}
