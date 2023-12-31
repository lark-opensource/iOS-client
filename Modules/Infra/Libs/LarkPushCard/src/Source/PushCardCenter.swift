//
//  PushCardCenter.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import UIKit
import Foundation

/// 卡片推送中心
public final class PushCardCenter: PushCardCenterService {

    /// 卡片单例
    public static var shared: PushCardCenter = PushCardCenter()

    /// 卡片 WIndow
    public var window: UIWindow? {
        return PushCardManager.shared.window?.superWindow
    }

    /// Push 卡片当前展示的卡片组
    public var showCards: [Cardable] {
        return PushCardManager.shared.window?.pushCardController.cardModels ?? []
    }

    /// 推送卡片
    ///
    /// - parameter model: 卡片数据
    public func post(_ model: Cardable) {
        PushCardManager.shared.post(model)
    }

    /// 推送卡片
    ///
    /// - parameter model: 卡片数据组
    public func post(_ models: [Cardable]) {
        PushCardManager.shared.post(models)
    }

    /// 移除卡片
    ///
    /// - parameter with: 卡片标识符
    /// - parameter changeToStack: 卡片被移除后，是否进入折叠状态
    public func remove(with id: String, changeToStack: Bool = false) {
        PushCardManager.shared.remove(with: id, changeToStack: changeToStack)
    }

    /// 更新卡片
    ///
    /// - parameter with: 卡片标识符
    public func update(with id: String) {
        PushCardManager.shared.update(with: id)
    }
}
