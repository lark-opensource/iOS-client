//
//  FilterTabsView.swift
//  LarkFeed
//
//  Created by 姚启灏 on 2020/12/21.
//

import UIKit
import UniverseDesignTabs
import Foundation

protocol FilterTabsViewDelegate: UDTabsViewDelegate {
    func didEnterSetting(_ tabsView: UDTabsView, index: Int)
}

final class FilterTabsView: UDTabsTitleView {
    var longPressCallBack: ((Int) -> Void)?

    override func registerCellClass(in tabsView: UDTabsView) {
        // 如果要 override 下面的 cellForItemAt 方法的话，reuseIdentifier 必须是 "cell"
        // 组件内部限制了
        tabsView.collectionView.register(FilterTabCell.self, forCellWithReuseIdentifier: "cell")
    }

    override func tabsView(cellForItemAt index: Int) -> UniverseDesignTabs.UDTabsBaseCell {
        let cell = super.tabsView(cellForItemAt: index)
        if var filterCell = cell as? FilterTabCell {
            filterCell.longPressCallBack = { [weak self] in
                self?.longPressCallBack?(index)
            }
        }
        return cell
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        FeedTeaTrack.trackFilterTabSlide()
    }
}
