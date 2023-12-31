//
//  PrivacyAlternateAnimatorDataSource.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit

@objc
/// 权限视图的数据代理
public protocol PrivacyAlternateAnimatorDataSource: AnyObject {
    /// 根据现在的权限获取相应的视图，此视图将用于动画
    /// - Parameters:
    ///   - animator: 权限视图动画器
    ///   - status: 当前的权限状态
    /// - Returns: 将用于动画的视图
    func privacyAlternateAnimator(_ animator: PrivacyAlternateAnimator, for status: BDPPrivacyAccessStatus) -> [UIView]
}
