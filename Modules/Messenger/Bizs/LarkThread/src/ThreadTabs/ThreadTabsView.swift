//
//  ThreadTabsView.swift
//  ThreadTabsView
//
//  Created by 袁平 on 2021/9/13.
//

import Foundation
import LarkCore
import UniverseDesignTabs
import UIKit

final class ThreadTabsView: UDTabsTitleView {
    private var tabModels: [TabItemBaseModel]

    init(tabModels: [TabItemBaseModel]) {
        self.tabModels = tabModels
        super.init(frame: .zero)
        let config = getConfig()
        config.titleNormalFont = SegmentLayout.unselectedFont
        config.titleSelectedFont = SegmentLayout.selectedFont
        config.itemSpacing = SegmentLayout.itemSpacing
        config.contentEdgeInsetLeft = SegmentLayout.tabsInset
        config.contentEdgeInsetRight = SegmentLayout.tabsInset
        config.isItemSpacingAverageEnabled = false
        config.isShowGradientMaskLayer = true
        config.maskColor = UIColor.ud.bgBody
        config.maskWidth = 10
        self.setConfig(config: config)
        self.backgroundColor = UIColor.ud.bgBody
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        self.indicators = [indicator]

        self.titles = tabModels.map({ $0.title })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(tabModels: [TabItemBaseModel]) {
        self.tabModels = tabModels
        self.titles = tabModels.map({ $0.title })
        reloadData()
    }

    override func registerCellClass(in tabsView: UDTabsView) {
        self.tabModels.forEach { model in
            tabsView.collectionView.register(model.cellType, forCellWithReuseIdentifier: model.itemType.rawValue)
        }
    }

    override func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        guard index < tabModels.count else { return super.tabsView(cellForItemAt: index) }
        let model = tabModels[index]
        let cell = self.dequeueReusableCell(withReuseIdentifier: model.itemType.rawValue, at: index)
        if let tabCell = cell as? TabItemBaseCell {
            tabCell.config(model: model)
            let config = self.getConfig()
            tabCell.titleConfig = config
            tabCell.config = config
        }
        return cell
    }
}
