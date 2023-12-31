//
//  SelectedModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import RxSwift
import LarkUIKit
import LarkMessengerInterface

// 设置feed的选中状态

final class SelectedModule {
    private let dependency: LabelDependency
    private let disposeBag = DisposeBag()
    private var selectedItem: EntityItem? // 选中状态
    private let viewDataStateModule: LabelMainListViewDataStateModule

    init(dependency: LabelDependency,
         viewDataStateModule: LabelMainListViewDataStateModule) {
        self.viewDataStateModule = viewDataStateModule
        self.dependency = dependency
    }

    /// iPad选中态监听
    var selectFeedObservable: Observable<FeedSelection?> {
        self.dependency.selectFeedObservable
    }

    /// 取消选中
    func cancelSelected() {
        self.dependency.setSelected(feedId: nil)
    }
}

extension SelectedModule {

    // 记录当前filter下，被选中的feed
    func storeSelectedItem(_ item: EntityItem?) {
        self.selectedItem = item
    }

    func isSelected(feedId: String, labelId: Int) -> Bool {
        guard let selectedItem = self.selectedItem else { return false }
        return selectedItem.parentId == labelId && String(selectedItem.id) == feedId
    }

    func findSelectedIndexPath() -> IndexPath? {
        guard let selectedItem = self.selectedItem else { return nil }
        guard let section = viewDataStateModule.uiStore.indexData.childIndexMap[selectedItem.parentId],
              let labelIndexData = viewDataStateModule.uiStore.indexData.getChildIndexData(id: selectedItem.parentId),
              let row = labelIndexData.childIndexMap[selectedItem.id] else { return nil }
        return IndexPath(row: row, section: section)
    }
}
