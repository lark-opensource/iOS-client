//
//  WPTemplateCollectionView.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/11.
//

import UIKit

// MARK: cell ID
/// template cell
let unknownCellID: String = "unknownCell"
/// template header
let templateHeaderID: String = "templateHeaer"
/// 单卡片组件cell
let templateFeedCardID: String = "templateFeedCard"
/// FeedList 子项组件cell
let feedListItemID: String = "feedListItem"
/// 常用&推荐应用
let templateCommonAppID: String = "templateCommonApp"
/// 分组背景块ID
let groupBackgroundID: String = "groupBackground"
/// 加载示意组件ID
let stateTipCellID: String = "componentStateTip"
/// 常用推荐应用 Header
let templateCommonHeaderID: String = "templateCommonHeader"
/// 无常用应用时的空态提示Cell（添加应用）
let emptyCommonCellId: String = "emptyCommonCell"
/// 常用应用编辑态提示Cell
let commonAreaInEditTipsCellId: String = "commonAreaInEditTipsCell"
/// native 组件灰度下线兜底页面
let nativeComponentFallbackCell: String = "nativeComponentFallbackCell"

enum WPTmplCellID {
    static let block = "block"
}

final class WPTemplateCollectionView: UICollectionView {
    // MARK: initial
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        /// View配置：背景设置，不显示滚动条，contentInset不调整
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        /// 注册常规cell
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: unknownCellID)
        register(WPComponentStateTipCell.self, forCellWithReuseIdentifier: stateTipCellID)
        register(WorkPlaceIconCell.self, forCellWithReuseIdentifier: templateCommonAppID)
        register(EmptyCommonGadgetCell.self, forCellWithReuseIdentifier: emptyCommonCellId)
        register(WPCommonAreaTipCell.self, forCellWithReuseIdentifier: commonAreaInEditTipsCellId)
        register(WPTemplateFallbackCell.self, forCellWithReuseIdentifier: nativeComponentFallbackCell)
        register(
            WPCommonAppHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: templateCommonHeaderID
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
