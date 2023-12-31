//
//  UDTabsTitleCell.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

open class UDTabsTitleCell: UDTabsBaseCell {
    public let titleLabel = UILabel()
    public let maskTitleLabel = UILabel()
    public let titleMaskLayer = CALayer()
    public let maskTitleMaskLayer = CALayer()
    public var titleConfig = UDTabsTitleViewConfig()

    open override func commonInit() {
        super.commonInit()

        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)

        maskTitleLabel.textAlignment = .center
        maskTitleLabel.isHidden = true
        contentView.addSubview(maskTitleLabel)

        maskTitleLabel.layer.mask = maskTitleMaskLayer
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let labelSize = titleLabel.sizeThatFits(self.contentView.bounds.size)
        let labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
        titleLabel.bounds = labelBounds
        titleLabel.center = contentView.center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: -1),
            titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])

        maskTitleLabel.bounds = labelBounds
        maskTitleLabel.center = contentView.center
    }

    /// reloadData
    open override func reloadData(itemModel: UDTabsBaseItemModel,
                                  selectedType: UDTabsViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? UDTabsTitleItemModel else {
            return
        }

        titleLabel.numberOfLines = titleConfig.titleNumberOfLines
        maskTitleLabel.numberOfLines = titleConfig.titleNumberOfLines
        titleLabel.lineBreakMode = titleConfig.titleLineBreakMode
        maskTitleLabel.lineBreakMode = titleConfig.titleLineBreakMode

        if titleConfig.isTitleZoomEnabled {
            //先把font设置为缩放的最大值，再缩小到最小值，最后根据当前的titleCurrentZoomScale值，进行缩放更新。这样就能避免transform从小到大时字体模糊
            let maxScaleFont = UIFont(descriptor: titleConfig.titleNormalFont.fontDescriptor,
                                      size: titleConfig
                                        .titleNormalFont
                                        .pointSize * CGFloat(titleConfig.titleSelectedZoomScale))
            let baseScale = titleConfig.titleNormalFont.lineHeight / maxScaleFont.lineHeight

            if titleConfig.isSelectedAnimable,
               canStartSelectedAnimation(itemModel: itemModel,
                                         selectedType: selectedType) {
                //允许动画且当前是点击的
                let titleZoomClosure = preferredTitleZoomAnimateClosure(itemModel: myItemModel, baseScale: baseScale)
                appendSelectedAnimationClosure(closure: titleZoomClosure)
            } else {
                titleLabel.font = maxScaleFont
                maskTitleLabel.font = maxScaleFont
                let currentTransform = CGAffineTransform(
                    scaleX: baseScale * CGFloat(myItemModel.titleCurrentZoomScale),
                    y: baseScale * CGFloat(myItemModel.titleCurrentZoomScale))
                titleLabel.transform = currentTransform
                maskTitleLabel.transform = currentTransform
            }
        } else {
            if myItemModel.isSelected {
                titleLabel.font = titleConfig.titleSelectedFont
                maskTitleLabel.font = titleConfig.titleSelectedFont
            } else {
                titleLabel.font = titleConfig.titleNormalFont
                maskTitleLabel.font = titleConfig.titleNormalFont
            }
        }

        let title = myItemModel.title ?? ""
        let attriText = NSMutableAttributedString(string: title)
        if titleConfig.isTitleStrokeWidthEnabled {
            if titleConfig.isSelectedAnimable,
               canStartSelectedAnimation(itemModel: itemModel,
                                         selectedType: selectedType) {
                //允许动画且当前是点击的
                let titleStrokeWidthClosure = preferredTitleStrokeWidthAnimateClosure(
                    itemModel: myItemModel,
                    attriText: attriText)
                appendSelectedAnimationClosure(closure: titleStrokeWidthClosure)
            } else {
                attriText.addAttributes(
                    [NSAttributedString.Key.strokeWidth: myItemModel.titleCurrentStrokeWidth],
                    range: NSRange(location: 0, length: title.count))
                titleLabel.attributedText = attriText
                maskTitleLabel.attributedText = attriText
            }
        } else {
            titleLabel.attributedText = attriText
            maskTitleLabel.attributedText = attriText
        }

        if isMoreThanOneLine(lbl: titleLabel, text: title) {
            titleLabel.font = titleConfig.titleSmallerFont
            maskTitleLabel.font = titleConfig.titleSmallerFont
        }

        if titleConfig.isTitleMaskEnabled {
            //允许mask，maskTitleLabel在titleLabel上面，maskTitleLabel设置为titleSelectedColor。titleLabel设置为titleNormalColor
            //为了显示效果，使用了双遮罩。即titleMaskLayer遮罩titleLabel，maskTitleMaskLayer遮罩maskTitleLabel
            maskTitleLabel.isHidden = false
            titleLabel.textColor = titleConfig.titleNormalColor
            maskTitleLabel.textColor = titleConfig.titleSelectedColor
            let labelSize = maskTitleLabel.sizeThatFits(self.contentView.bounds.size)
            let labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
            maskTitleLabel.bounds = labelBounds

            var topMaskFrame = myItemModel.indicatorConvertToItemFrame
            topMaskFrame.origin.y = 0
            var bottomMaskFrame = topMaskFrame
            var maskStartX: CGFloat = 0
            if maskTitleLabel.bounds.size.width >= bounds.size.width {
                topMaskFrame.origin.x -= (maskTitleLabel.bounds.size.width - bounds.size.width) / 2
                bottomMaskFrame.size.width = maskTitleLabel.bounds.size.width
                maskStartX = -(maskTitleLabel.bounds.size.width - bounds.size.width) / 2
            } else {
                topMaskFrame.origin.x -= (bounds.size.width - maskTitleLabel.bounds.size.width) / 2
                bottomMaskFrame.size.width = bounds.size.width
                maskStartX = 0
            }
            bottomMaskFrame.origin.x = topMaskFrame.origin.x
            if topMaskFrame.origin.x > maskStartX {
                bottomMaskFrame.origin.x = topMaskFrame.origin.x - bottomMaskFrame.size.width
            } else {
                bottomMaskFrame.origin.x = topMaskFrame.maxX
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if topMaskFrame.size.width > 0 && topMaskFrame.intersects(maskTitleLabel.frame) {
                titleLabel.layer.mask = titleMaskLayer
                titleMaskLayer.frame = bottomMaskFrame
                maskTitleMaskLayer.frame = topMaskFrame
            } else {
                titleLabel.layer.mask = nil
                maskTitleMaskLayer.frame = topMaskFrame
            }
            CATransaction.commit()
        } else {
            maskTitleLabel.isHidden = true
            titleLabel.layer.mask = nil
            if titleConfig.isSelectedAnimable,
               canStartSelectedAnimation(itemModel: itemModel,
                                         selectedType: selectedType) {
                //允许动画且当前是点击的
                let titleColorClosure = preferredTitleColorAnimateClosure(itemModel: myItemModel)
                appendSelectedAnimationClosure(closure: titleColorClosure)
            } else {
                titleLabel.textColor = myItemModel.titleCurrentColor
            }
        }

        startSelectedAnimationIfNeeded(itemModel: itemModel, selectedType: selectedType)

        setNeedsLayout()
    }

    open func preferredTitleZoomAnimateClosure(itemModel: UDTabsTitleItemModel,
                                               baseScale: CGFloat) -> UDTabsCellSelectedAnimationClosure {
        return {[weak self] (percnet) in
            guard let self = `self` else {
                return
            }

            if itemModel.isSelected {
                //将要选中，scale从小到大插值渐变
                itemModel.titleCurrentZoomScale = UDTabsViewTool
                    .interpolate(from: self.titleConfig.titleNormalZoomScale,
                                 to: self.titleConfig.titleSelectedZoomScale,
                                 percent: percnet)
            } else {
                //将要取消选中，scale从大到小插值渐变
                itemModel.titleCurrentZoomScale = UDTabsViewTool
                    .interpolate(from: self.titleConfig.titleSelectedZoomScale,
                                 to: self.titleConfig.titleNormalZoomScale,
                                 percent: percnet)
            }
            let currentTransform = CGAffineTransform(scaleX: baseScale * itemModel.titleCurrentZoomScale,
                                                     y: baseScale * itemModel.titleCurrentZoomScale)
            self.titleLabel.transform = currentTransform
            self.maskTitleLabel.transform = currentTransform
        }
    }

    open func preferredTitleStrokeWidthAnimateClosure(
        itemModel: UDTabsTitleItemModel,
        attriText: NSMutableAttributedString) -> UDTabsCellSelectedAnimationClosure {
        return {[weak self] (percent) in
            guard let self = `self` else {
                return
            }
            if itemModel.isSelected {
                //将要选中，StrokeWidth从小到大插值渐变
                itemModel.titleCurrentStrokeWidth = UDTabsViewTool
                    .interpolate(from: self.titleConfig.titleNormalStrokeWidth,
                                 to: self.titleConfig.titleSelectedStrokeWidth,
                                 percent: percent)
            } else {
                //将要取消选中，StrokeWidth从大到小插值渐变
                itemModel.titleCurrentStrokeWidth = UDTabsViewTool
                    .interpolate(from: self.titleConfig.titleSelectedStrokeWidth,
                                 to: self.titleConfig.titleNormalStrokeWidth,
                                 percent: percent)
            }
            attriText.addAttributes([NSAttributedString.Key.strokeWidth: itemModel.titleCurrentStrokeWidth],
                                    range: NSRange(location: 0, length: attriText.string.count))
            self.titleLabel.attributedText = attriText
            self.maskTitleLabel.attributedText = attriText
        }
    }

    open func preferredTitleColorAnimateClosure(itemModel: UDTabsTitleItemModel) -> UDTabsCellSelectedAnimationClosure {
        return {[weak self] (percent) in
            guard let self = `self` else {
                return
            }
            if itemModel.isSelected {
                //将要选中，textColor从titleNormalColor到titleSelectedColor插值渐变
                itemModel.titleCurrentColor = UDTabsViewTool
                    .interpolateColor(from: self.titleConfig.titleNormalColor,
                                      to: self.titleConfig.titleSelectedColor,
                                      percent: percent)
            } else {
                //将要取消选中，textColor从titleSelectedColor到titleNormalColor插值渐变
                itemModel.titleCurrentColor = UDTabsViewTool
                    .interpolateColor(from: self.titleConfig.titleSelectedColor,
                                      to: self.titleConfig.titleNormalColor,
                                      percent: percent)
            }
            self.titleLabel.textColor = itemModel.titleCurrentColor
        }
    }

    //判断文本标签的内容是否被截断
        func isMoreThanOneLine (lbl : UILabel, text : String) ->(Bool) {
            let labelText = text
            var labelSize = lbl.sizeThatFits(self.contentView.bounds.size)
            labelSize.width = (titleConfig.itemMaxWidth < CGFloat.greatestFiniteMagnitude) ? titleConfig.itemMaxWidth : labelSize.width
            let labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
            //计算理论上显示所有文字需要的尺寸
            let rect = CGSize(width: labelBounds.width, height: CGFloat.greatestFiniteMagnitude)
            let labelTextSize = (labelText as NSString)
                .boundingRect(with: rect, options: .usesLineFragmentOrigin,
                              attributes: [NSAttributedString.Key.font: lbl.font], context: nil)

            //计算理论上需要的行数
            let labelTextLines = Int(ceil(CGFloat(labelTextSize.height) / lbl.font.lineHeight))

            //比较两个行数来判断是否需要截断
            return labelTextLines > 1
        }
}
