//
//  JXSegmentedTitleView.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2018/12/26.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import Foundation
import UIKit

open class JXSegmentedTitleDataSource: JXSegmentedBaseDataSource{
    /// title数组
    public var titles = [String]()
    /// 如果将JXSegmentedView嵌套进UITableView的cell，每次重用的时候，JXSegmentedView进行reloadData时，会重新计算所有的title宽度。所以该应用场景，需要UITableView的cellModel缓存titles的文字宽度，再通过该闭包方法返回给JXSegmentedView。
    public var widthForTitleClosure: ((String)->(CGFloat))?
    /// label的numberOfLines
    public var titleNumberOfLines: Int = 1
    /// title普通状态的textColor
    public var titleNormalColor: UIColor = .black
    /// title选中状态的textColor
    public var titleSelectedColor: UIColor = .red
    /// title普通状态时的字体
    public var titleNormalFont: UIFont = UIFont.systemFont(ofSize: 15)
    /// title选中时的字体。如果不赋值，就默认与titleNormalFont一样
    public var titleSelectedFont: UIFont?
    /// title的颜色是否渐变过渡
    public var isTitleColorGradientEnabled: Bool = false
    /// title是否缩放。使用该效果时，务必保证titleNormalFont和titleSelectedFont值相同。
    public var isTitleZoomEnabled: Bool = false
    /// isTitleZoomEnabled为true才生效。是对字号的缩放，比如titleNormalFont的pointSize为10，放大之后字号就是10*1.2=12。
    public var titleSelectedZoomScale: CGFloat = 1.2
    /// title的线宽是否允许粗细。使用该效果时，务必保证titleNormalFont和titleSelectedFont值相同。
    public var isTitleStrokeWidthEnabled: Bool = false
    /// 用于控制字体的粗细（底层通过NSStrokeWidthAttributeName实现），负数越小字体越粗。
    public var titleSelectedStrokeWidth: CGFloat = -2
    /// title是否使用遮罩过渡
    public var isTitleMaskEnabled: Bool = false

    deinit {
        widthForTitleClosure = nil
    }

    public override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedTitleItemModel()
    }

    public override func reloadData(selectedIndex: Int) {
        super.reloadData(selectedIndex: selectedIndex)

        for (index, _) in titles.enumerated() {
            let itemModel = preferredItemModelInstance()
            preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
            dataSource.append(itemModel)
        }
    }

    public override func preferredRefreshItemModel( _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let myItemModel = itemModel as? JXSegmentedTitleItemModel else {
            return
        }

        myItemModel.title = titles[index]
        myItemModel.textWidth = widthForItem(title: myItemModel.title ?? "")
        myItemModel.titleNumberOfLines = titleNumberOfLines
        myItemModel.isSelectedAnimable = isSelectedAnimable
        myItemModel.titleNormalColor = titleNormalColor
        myItemModel.titleSelectedColor = titleSelectedColor
        myItemModel.titleNormalFont = titleNormalFont
        myItemModel.titleSelectedFont = titleSelectedFont != nil ? titleSelectedFont! : titleNormalFont
        myItemModel.isTitleZoomEnabled = isTitleZoomEnabled
        myItemModel.isTitleStrokeWidthEnabled = isTitleStrokeWidthEnabled
        myItemModel.isTitleMaskEnabled = isTitleMaskEnabled
        myItemModel.titleNormalZoomScale = 1
        myItemModel.titleSelectedZoomScale = titleSelectedZoomScale
        myItemModel.titleSelectedStrokeWidth = titleSelectedStrokeWidth
        myItemModel.titleNormalStrokeWidth = 0
        if index == selectedIndex {
            myItemModel.titleCurrentColor = titleSelectedColor
            myItemModel.titleCurrentZoomScale = titleSelectedZoomScale
            myItemModel.titleCurrentStrokeWidth = titleSelectedStrokeWidth
        }else {
            myItemModel.titleCurrentColor = titleNormalColor
            myItemModel.titleCurrentZoomScale = 1
            myItemModel.titleCurrentStrokeWidth = 0
        }
    }

    public func widthForItem(title: String) -> CGFloat {
        if widthForTitleClosure != nil {
            return widthForTitleClosure!(title)
        }else {
            let textWidth = NSString(string: title).boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
                                                                 options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                                 attributes: [NSAttributedString.Key.font : titleNormalFont],
                                                                 context: nil).size.width
            return CGFloat(ceilf(Float(textWidth)))
        }
    }

    /// 因为该方法会被频繁调用，所以应该在`preferredRefreshItemModel( _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int)`方法里面，根据数据源计算好文字宽度，然后缓存起来。该方法直接使用已经计算好的文字宽度即可。
    public override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        var itemWidth = super.preferredSegmentedView(segmentedView, widthForItemAt: index)
        if itemContentWidth == JXSegmentedViewAutomaticDimension {
            let model = dataSource[index] as? JXSegmentedTitleItemModel
            let width = model?.textWidth ?? 0
            itemWidth += width
        }else {
            itemWidth += itemContentWidth
        }
        return itemWidth
    }

    //MARK: - JXSegmentedViewDataSource
    public override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedTitleCell.self, forCellWithReuseIdentifier: "cell")
    }

    public override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }

    public override func refreshItemModel(_ segmentedView: JXSegmentedView,
                                        leftItemModel: JXSegmentedBaseItemModel,
                                        rightItemModel: JXSegmentedBaseItemModel,
                                        percent: CGFloat) {
        super.refreshItemModel(segmentedView, leftItemModel: leftItemModel, rightItemModel: rightItemModel, percent: percent)

        guard let leftModel = leftItemModel as? JXSegmentedTitleItemModel,
              let rightModel = rightItemModel as? JXSegmentedTitleItemModel else {
                  return
              }

        if isTitleZoomEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: leftModel.titleSelectedZoomScale,
                                                                              to: leftModel.titleNormalZoomScale,
                                                                              percent: CGFloat(percent))
            rightModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: rightModel.titleNormalZoomScale,
                                                                               to: rightModel.titleSelectedZoomScale,
                                                                               percent: CGFloat(percent))
        }

        if isTitleStrokeWidthEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: leftModel.titleSelectedStrokeWidth,
                                                                                to: leftModel.titleNormalStrokeWidth,
                                                                                percent: CGFloat(percent))
            rightModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: rightModel.titleNormalStrokeWidth,
                                                                                 to: rightModel.titleSelectedStrokeWidth,
                                                                                 percent: CGFloat(percent))
        }

        if isTitleColorGradientEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentColor = JXSegmentedViewTool.interpolateColor(from: leftModel.titleSelectedColor,
                                                                               to: leftModel.titleNormalColor,
                                                                               percent: percent)
            rightModel.titleCurrentColor = JXSegmentedViewTool.interpolateColor(from:rightModel.titleNormalColor ,
                                                                                to:rightModel.titleSelectedColor,
                                                                                percent: percent)
        }
    }

    public override func refreshItemModel(_ segmentedView: JXSegmentedView,
                                        currentSelectedItemModel: JXSegmentedBaseItemModel,
                                        willSelectedItemModel: JXSegmentedBaseItemModel,
                                        selectedType: JXSegmentedViewItemSelectedType) {
        super.refreshItemModel(segmentedView,
                               currentSelectedItemModel: currentSelectedItemModel,
                               willSelectedItemModel: willSelectedItemModel,
                               selectedType: selectedType)

        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? JXSegmentedTitleItemModel,
              let myWillSelectedItemModel = willSelectedItemModel as? JXSegmentedTitleItemModel else {
                  return
              }

        myCurrentSelectedItemModel.titleCurrentColor = myCurrentSelectedItemModel.titleNormalColor
        myCurrentSelectedItemModel.titleCurrentZoomScale = myCurrentSelectedItemModel.titleNormalZoomScale
        myCurrentSelectedItemModel.titleCurrentStrokeWidth = myCurrentSelectedItemModel.titleNormalStrokeWidth
        myCurrentSelectedItemModel.indicatorConvertToItemFrame = CGRect.zero

        myWillSelectedItemModel.titleCurrentColor = myWillSelectedItemModel.titleSelectedColor
        myWillSelectedItemModel.titleCurrentZoomScale = myWillSelectedItemModel.titleSelectedZoomScale
        myWillSelectedItemModel.titleCurrentStrokeWidth = myWillSelectedItemModel.titleSelectedStrokeWidth
    }
}
