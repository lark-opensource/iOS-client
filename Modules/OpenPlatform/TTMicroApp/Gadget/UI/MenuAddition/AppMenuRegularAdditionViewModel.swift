//
//  AppMenuRegularAdditionViewModel.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import Foundation

@objc
/// 正常的样式的小程序菜单头部的附加视图的数据模型
public final class AppMenuRegularAdditionViewModel: NSObject {
    /// 应用名称
    let name: String?

    /// 头像url
    let iconURL: String?

    /// 初始化数据模型
    /// - Parameters:
    ///   - name: 应用名称
    ///   - iconURL: 应用头像URL
    @objc
    public init(name: String?, iconURL: String?) {
        self.name = name
        self.iconURL = iconURL
        super.init()
    }

    /// 初始化默认的数据模型
    @objc
    public override init() {
        self.name = nil
        self.iconURL = nil
        super.init()
    }
}



