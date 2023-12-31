//
//  FeedsTabsView.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/22.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import UniverseDesignTabs
import Foundation

protocol FeedsTabsViewDelegate: UDTabsViewDelegate {
    /// 双击对应Index的Cell
    /// - Parameters:
    ///   - tabsView: FeedsTabsView
    ///   - index: 双击选中的index
    func tabsView(_ tabsView: UDTabsView, doubleClick index: Int)
}

class FeedsTabsView: UDTabsTitleView {
    override func registerCellClass(in tabsView: UDTabsView) {
        tabsView.collectionView.register(FeedsTabsCell.self, forCellWithReuseIdentifier: "feedcell")
    }

    open override func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        let cell = self.dequeueReusableCell(withReuseIdentifier: "feedcell", at: index)

        if let feedCell = cell as? FeedsTabsCell {
            feedCell.tapCallBack = { [weak self] in
                guard let `self` = self,
                      let delegate = self.delegate as? FeedsTabsViewDelegate else {
                    return
                }

                guard self.delegate?.tabsView(self, canClickItemAt: index) != false else {
                    return
                }
                delegate.tabsView(self, doubleClick: index)
                self.selectItemAt(index: index, selectedType: .scroll)
            }
        }
        return cell
    }
}

