//
//  AppCenterHomeCategroyLayout.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/17.
//

import UIKit

final class AppCenterHomeCategroyLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        itemSize = CGSize(width: 128, height: 36)
        // 最小行间距
        minimumLineSpacing = 16
        // 最小列间距
        minimumInteritemSpacing = 16
        // Header吸顶
        sectionHeadersPinToVisibleBounds = false
        // 设置间距
        sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
