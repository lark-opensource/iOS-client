//
//  AppCenterHomeCategroyCollectionView.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/17.
//

import UIKit

/// 应用中心主页侧边栏应用中心对应的表格视图
final class AppCenterHomeCategroyCollectionView: UICollectionView {

    let appCenterHomeCategroyCollectionCellID = "AppCenterHomeCategroyCollectionViewCell"
    let categoryLabelHeaderViewCellID = "CategoryLabelHeaderView"

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = UIColor.ud.bgBody
        showsVerticalScrollIndicator = false
        register(
            AppCenterHomeCategroyCollectionViewCell.self,
            forCellWithReuseIdentifier: appCenterHomeCategroyCollectionCellID
        )
        register(
            CategoryLabelHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: categoryLabelHeaderViewCellID
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
