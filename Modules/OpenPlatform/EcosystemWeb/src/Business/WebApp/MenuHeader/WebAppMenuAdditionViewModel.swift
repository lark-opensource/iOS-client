//
//  WebAppMenuAdditionViewModel.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation

/// 网页应用菜单头部视图的数据模型
public struct WebAppMenuAdditionViewModel {
    /// 应用名称
    let name: String?

    /// 头像的key
    let iconKey: String?

    /// 初始化数据模型
    /// - Parameters:
    ///   - name: 应用名称
    ///   - iconKey: 头像的key
    public init(name: String?, iconKey: String?) {
        self.name = name
        self.iconKey = iconKey
    }

    /// 快速初始化数据模型
    public init() {
        self.name = nil
        self.iconKey = nil
    }
}
