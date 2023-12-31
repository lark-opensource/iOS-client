//
//  AppMenuPrivacyDelegate.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import Foundation

@objc
/// 权限视图的事件代理
public protocol AppMenuPrivacyDelegate {
    func action(for type: BDPMorePanelPrivacyType)
}
