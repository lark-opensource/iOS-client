//
//  UDTabsTitleView.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

open class UDTabsTitleView: UDTabsView {
    /// 如果将UDTabsView嵌套进UITableView的cell，
    /// 每次重用的时候，UDTabsView进行reloadData时，会重新计算所有的title宽度。
    /// 所以该应用场景，需要UITableView的cellModel缓存titles的文字宽度，再通过该闭包方法返回给UDTabsView。
    open var widthForTitleClosure: ((String) -> CGFloat)?

    /// title数组
    open var titles = [String]()

    override var config: UDTabsViewConfig {
        return titleConfig
    }

    private var titleConfig: UDTabsTitleViewConfig = UDTabsTitleViewConfig()

    deinit {
        widthForTitleClosure = nil
    }

    open func setConfig(config: UDTabsTitleViewConfig = UDTabsTitleViewConfig()) {
        self.titleConfig = config
        self.reloadData()
        setupAppearance()
    }

    open override func getConfig() -> UDTabsTitleViewConfig {
        return self.titleConfig
    }

    open override func preferredItemModelInstance() -> UDTabsBaseItemModel {
        return UDTabsTitleItemModel()
    }

    open override func reloadData(selectedIndex: Int) {
        super.reloadData(selectedIndex: selectedIndex)

        for index in titles.indices {
            let itemModel = preferredItemModelInstance()
            preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
            itemDataSource.append(itemModel)
        }
    }

    open override func preferredRefreshItemModel( _ itemModel: UDTabsBaseItemModel,
                                                  at index: Int,
                                                  selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let myItemModel = itemModel as? UDTabsTitleItemModel else {
            return
        }

        myItemModel.title = titles[index]
        myItemModel.textWidth = widthForItem(title: myItemModel.title ?? "")
        if index == selectedIndex {
            myItemModel.titleCurrentColor = titleConfig.titleSelectedColor
            myItemModel.titleCurrentZoomScale = titleConfig.titleSelectedZoomScale
            myItemModel.titleCurrentStrokeWidth = titleConfig.titleSelectedStrokeWidth
        } else {
            myItemModel.titleCurrentColor = titleConfig.titleNormalColor
            myItemModel.titleCurrentZoomScale = 1
            myItemModel.titleCurrentStrokeWidth = 0
        }
    }

    open func widthForItem(title: String) -> CGFloat {
        if widthForTitleClosure != nil {
            return widthForTitleClosure!(title)
        } else {
            let textWidth = NSString(string: title)
                .boundingRect(with: CGSize(width: CGFloat.infinity,
                                           height: CGFloat.infinity),
                              options: [.usesFontLeading,
                                        .usesLineFragmentOrigin],
                              attributes: [NSAttributedString.Key.font: titleConfig.titleNormalFont],
                              context: nil).size.width
            return CGFloat(ceilf(Float(textWidth)))
        }
    }

    /// 因为该方法会被频繁调用，
    /// 所以应该在
    /// `preferredRefreshItemModel( _ itemModel: UDTabsBaseItemModel, at index: Int, selectedIndex: Int)`
    /// 方法里面，根据数据源计算好文字宽度，然后缓存起来。该方法直接使用已经计算好的文字宽度即可。
    open override func preferredTabsView(widthForItemAt index: Int) -> CGFloat {
        guard !itemDataSource.isEmpty else {
            return 0
        }
        var itemWidth = super.preferredTabsView(widthForItemAt: index)
        switch titleConfig.layoutStyle {
        case .average:
            let averageWidth = self.bounds.width / CGFloat(self.itemDataSource.count)
            return min(itemWidth + averageWidth, config.itemMaxWidth)
        case .custom(let itemContentWidth):
            if itemContentWidth == UDTabsViewAutomaticDimension,
               let model = itemDataSource[index] as? UDTabsTitleItemModel {
                itemWidth += model.textWidth
            } else {
                itemWidth += itemContentWidth
            }
            return min(itemWidth, config.itemMaxWidth) + 1
        }
    }

    // MARK: - UDTabsViewDataSource
    open override func registerCellClass(in tabsView: UDTabsView) {
        tabsView.collectionView.register(UDTabsTitleCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        let cell = self.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        if let titleCell = cell as? UDTabsTitleCell {
            titleCell.titleConfig = self.titleConfig
            titleCell.config = self.config
        }
        return cell
    }

    open override func refreshItemModel(leftItemModel: UDTabsBaseItemModel,
                                        rightItemModel: UDTabsBaseItemModel,
                                        percent: CGFloat) {
        super.refreshItemModel(leftItemModel: leftItemModel, rightItemModel: rightItemModel, percent: percent)

        guard let leftModel = leftItemModel as? UDTabsTitleItemModel,
              let rightModel = rightItemModel as? UDTabsTitleItemModel else {
            return
        }

        if titleConfig.isTitleZoomEnabled && titleConfig.isItemTransitionEnabled {
            leftModel.titleCurrentZoomScale = UDTabsViewTool
                .interpolate(from: titleConfig.titleSelectedZoomScale,
                             to: titleConfig.titleNormalZoomScale,
                             percent: CGFloat(percent))
            rightModel.titleCurrentZoomScale = UDTabsViewTool
                .interpolate(from: titleConfig.titleNormalZoomScale,
                             to: titleConfig.titleSelectedZoomScale,
                             percent: CGFloat(percent))
        }

        if titleConfig.isTitleStrokeWidthEnabled && titleConfig.isItemTransitionEnabled {
            leftModel.titleCurrentStrokeWidth = UDTabsViewTool
                .interpolate(from: titleConfig.titleSelectedStrokeWidth,
                             to: titleConfig.titleNormalStrokeWidth,
                             percent: CGFloat(percent))
            rightModel.titleCurrentStrokeWidth = UDTabsViewTool
                .interpolate(from: titleConfig.titleNormalStrokeWidth,
                             to: titleConfig.titleSelectedStrokeWidth,
                             percent: CGFloat(percent))
        }

        if titleConfig.isTitleColorGradientEnabled && titleConfig.isItemTransitionEnabled {
            leftModel.titleCurrentColor = UDTabsViewTool
                .interpolateColor(from: titleConfig.titleSelectedColor,
                                  to: titleConfig.titleNormalColor,
                                  percent: percent)
            rightModel.titleCurrentColor = UDTabsViewTool
                .interpolateColor(from: titleConfig.titleNormalColor,
                                  to: titleConfig.titleSelectedColor,
                                  percent: percent)
        }
    }

    open override func refreshItemModel(currentSelectedItemModel: UDTabsBaseItemModel,
                                        willSelectedItemModel: UDTabsBaseItemModel,
                                        selectedType: UDTabsViewItemSelectedType) {
        super.refreshItemModel(currentSelectedItemModel: currentSelectedItemModel,
                               willSelectedItemModel: willSelectedItemModel,
                               selectedType: selectedType)

        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? UDTabsTitleItemModel,
              let myWillSelectedItemModel = willSelectedItemModel as? UDTabsTitleItemModel else {
            return
        }

        myCurrentSelectedItemModel.titleCurrentColor = titleConfig.titleNormalColor
        myCurrentSelectedItemModel.titleCurrentZoomScale = titleConfig.titleNormalZoomScale
        myCurrentSelectedItemModel.titleCurrentStrokeWidth = titleConfig.titleNormalStrokeWidth
        myCurrentSelectedItemModel.indicatorConvertToItemFrame = CGRect.zero

        myWillSelectedItemModel.titleCurrentColor = titleConfig.titleSelectedColor
        myWillSelectedItemModel.titleCurrentZoomScale = titleConfig.titleSelectedZoomScale
        myWillSelectedItemModel.titleCurrentStrokeWidth = titleConfig.titleSelectedStrokeWidth
    }
}
