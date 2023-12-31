//
//  UDTabsBaseCell.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit
import UniverseDesignTheme

/// UDTabs CellSelected Animation Closure
public typealias UDTabsCellSelectedAnimationClosure = (CGFloat) -> Void

open class UDTabsBaseCell: UICollectionViewCell {
    open var itemModel: UDTabsBaseItemModel?
    open var animator: UDTabsAnimator?
    public var config = UDTabsViewConfig()
    private var selectedAnimationClosureArray = [UDTabsCellSelectedAnimationClosure]()

    deinit {
        animator?.stop()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()

        animator?.stop()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    open func commonInit() {

    }

    open func canStartSelectedAnimation(itemModel: UDTabsBaseItemModel,
                                        selectedType: UDTabsViewItemSelectedType) -> Bool {
        var isSelectedAnimatable = false
        if config.isSelectedAnimable {
            if selectedType == .scroll {
                //滚动选中且没有开启左右过渡，允许动画
                if !config.isItemTransitionEnabled {
                    isSelectedAnimatable = true
                }
            } else if selectedType == .click || selectedType == .code {
                //点击和代码选中，允许动画
                isSelectedAnimatable = true
            }
        }
        return isSelectedAnimatable
    }

    open func appendSelectedAnimationClosure(closure: @escaping UDTabsCellSelectedAnimationClosure) {
        selectedAnimationClosureArray.append(closure)
    }

    open func startSelectedAnimationIfNeeded(itemModel: UDTabsBaseItemModel,
                                             selectedType: UDTabsViewItemSelectedType) {
        if config.isSelectedAnimable && canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
            if #available(iOS 13.0, *) {
                let correctStyle = UDThemeManager.getRealUserInterfaceStyle()
                let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
                UITraitCollection.current = correctTraitCollection
            }
            //需要更新isTransitionAnimating，用于处理在过滤时，禁止响应点击，避免界面异常。
            itemModel.isTransitionAnimating = true
            animator?.progressClosure = {[weak self] (percent) in
                guard self != nil else {
                    return
                }
                for closure in self!.selectedAnimationClosureArray {
                    closure(percent)
                }
            }
            animator?.completedClosure = {[weak self] in
                itemModel.isTransitionAnimating = false
                self?.selectedAnimationClosureArray.removeAll()
            }
            animator?.start()
        }
    }

    open func reloadData(itemModel: UDTabsBaseItemModel, selectedType: UDTabsViewItemSelectedType) {
        self.itemModel = itemModel

        if config.isSelectedAnimable {
            selectedAnimationClosureArray.removeAll()
            if canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
                animator = UDTabsAnimator()
                animator?.duration = config.selectedAnimationDuration
            } else {
                animator?.stop()
            }
        }
    }
}
