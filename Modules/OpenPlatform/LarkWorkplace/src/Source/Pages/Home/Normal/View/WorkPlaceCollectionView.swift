//
//  WorkPlaceCollectionView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/8.
//

import UIKit

/// widget版工作台的表格视图
final class WorkPlaceCollectionView: UICollectionView {
    // MARK: propeties
    /// 异常情况返回的 CellID
    let unknownCellID: String = "AppCenterUnknownCell"
    /// gadget cell
    let gadgetCellID: String = "AppCenterGadgetCell"
    /// widget cell
    let widgetCellID: String = "AppCenterWidgetCell"
    /// 无常用应用时的空态提示Cell（添加应用）
    let addGadgetCellID: String = "addGadgetCell"
    /// 分割间距cell identifier
    let spaceCellReuseID = "spaceCellID"
    /// 填充cell的ID
    let fillCellReuseID = "fillCellReuseID"
    /// 骨架cell的ID
    let stateCellReuseID = "stateCellReuseID"
    /// gadget分组的租名header
    let gadgetGroupHeaderID: String = "gadgetGroupHeader"
    /// 全部应用分组的ID
    let allAppCategoryHeaderID: String = "AllAppCategoryHeaderID"
    /// 全部应用分组的ID
    let workplaceEmptyFooterID: String = "WorkplaceEmptyFooterID"
    /// 处理touch事件
    var handleTouchEvent: (() -> Void)?

    // MARK: initial
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        /// View配置：背景设置，不显示滚动条，contentInset不调整
        backgroundColor = UIColor.ud.bgBody
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        /// 注册常规cell
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: unknownCellID)
        register(WorkPlaceIconCell.self, forCellWithReuseIdentifier: gadgetCellID)
        register(WorkPlaceWidgetCell.self, forCellWithReuseIdentifier: widgetCellID)
        register(EmptyCommonGadgetCell.self, forCellWithReuseIdentifier: addGadgetCellID)
        register(EmptySpaceViewCell.self, forCellWithReuseIdentifier: spaceCellReuseID)
        register(FillEmptySpaceCell.self, forCellWithReuseIdentifier: fillCellReuseID)
        register(ItemStateCell.self, forCellWithReuseIdentifier: stateCellReuseID)

        /// 注册header
        register(
            GadgetGroupHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: gadgetGroupHeaderID
        )
        /// 注册所有应用的分组header
        register(
            AppCenterAllAppHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: allAppCategoryHeaderID
        )
        /// 注册全部应用的footer，主要是为了填充高度，避免从长列表切换到短列表的时候出现位置跳动
        register(
            EmptyFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: workplaceEmptyFooterID
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 处理苹果的bug
    override func cancelInteractiveMovement() {
        super.cancelInteractiveMovement()
        super.endInteractiveMovement() // ← will not perform the standard "end" animation
        // the moving cell was already reset by cancelInteractiveMovement
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        handleTouchEvent?()
        return super.hitTest(point, with: event)
    }
}
