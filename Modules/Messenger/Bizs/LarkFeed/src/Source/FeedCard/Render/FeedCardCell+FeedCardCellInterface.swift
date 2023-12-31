//
//  FeedCardCell+FeedCardCellInterface.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/22.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkSceneManager
import LarkModel
import LarkUIKit
import UniverseDesignTheme

extension FeedCardCell: FeedCardCellInterface {
    // 填充Cell内容
    func set(cellViewModel: FeedCardViewModelInterface) {
        guard let cellViewModel = cellViewModel as? FeedCardCellViewModel else { return }
        render(cellVM: cellViewModel)
    }

    // 点击feed操作
    func didSelectCell(from: UIViewController) {
        didSelectCell(from: from, trace: FeedListTrace.genDefault(), filterType: .unknown)
    }

    // 用于返回 cell 拖拽手势
    func supportDragScene() -> Scene? {
        guard let cellViewModel = cellViewModel else { return nil }
        return self.module?.supportDragScene(feedPreview: cellViewModel.feedPreview)
    }

    // cell 将要展示时，可以在这里触发业务方预加载逻辑
    func willDisplay() {
        self.module?.willDisplay()
        postEvent(eventType: .willDisplay, value: .none)
    }

    func didEndDisplay() {
        postEvent(eventType: .didEndDisplay, value: .none)
    }
}
