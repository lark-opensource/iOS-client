//
//  CatagroyLabelHorizontalCollectionView.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/9/29.
//

import UIKit

/// 应用中心主页全部应用对应的Header里边的横向滑动按钮对应的表格视图 这个表格只要有cell 就必须有且只有一个cell是selected状态
final class CatagroyLabelHorizontalCollectionView: UICollectionView {
    static let cellID = "HorizontalLabelCell"
    static let tabCellID = "HorizontalTabCell"
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = UIColor.ud.bgBody
        register(HorizontalLabelCell.self, forCellWithReuseIdentifier: Self.cellID)
        register(HorizontalTabCell.self, forCellWithReuseIdentifier: Self.tabCellID)
        /// 不显示滚动条
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        clipsToBounds = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
