//
//  AppMenuAppRatingAdditionViewModel.swift
//  TTMicroApp
//
//  Created by xingjinhao on 2021/12/23.
//

import Foundation
import OPSDK

@objc
/// 正常的样式的小程序菜单头部的附加视图的数据模型
public final class AppMenuAppRatingAdditionViewModel: NSObject {
    
    /// 应用名称
    let name: String?

    /// 头像url
    let iconURL: String?
    
    /// 初始化数据模型
    /// - Parameters:
    ///   - name: 应用名称
    ///   - iconURL: 应用头像URL
    @objc
    public init(model: BDPModel) {
        self.name = model.name
        self.iconURL = model.icon
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
