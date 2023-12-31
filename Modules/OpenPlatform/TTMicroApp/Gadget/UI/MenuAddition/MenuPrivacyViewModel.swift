//
//  MenuPrivacyViewModel.swift
//  OPSDK
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit

/// 权限视图的数据模型
struct MenuPrivacyViewModel {
    /// 头像
    var image: UIImage

    /// 应用描述
    var name: String

    /// 权限的类型
    var type: BDPMorePanelPrivacyType

    /// 初始化数据模型
    /// - Parameters:
    ///   - image: 头像
    ///   - name: 应用描述
    ///   - type: 权限的类型
    init(image: UIImage, name: String, type: BDPMorePanelPrivacyType) {
        self.image = image
        self.name = name
        self.type = type
    }
}
