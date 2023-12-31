//
//  ToolBarMoreButton.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/4/1.
//

import UIKit
import LarkBadge
import LKCommonsLogging

/// 日志
private let logger = Logger.log(ToolBarMoreButton.self, category: "TTMicroApp")

@objc
/// 小程序导航栏中的菜单按钮
public final class ToolBarMoreButton: UIButton {

    /// 容器的PathString
    /// - Note: 为何在这里存储字符串而不直接存储Path
    /// 因为在Xcode 12编译的时候，如果ToolBarMoreButton类中将LarkBadge.Path作为存储属性
    /// 这个属性即使没有暴露给OC，虽然能通过编译阶段，但是链接器进行链接的时候，就会报错，原因未知，因为自己写一个结构体作为存储属性
    /// 一样的条件，链接器可以正常链接，原因应该出在LarkBadge.Path这个结构体中。
    /// 要么就是链接器存在bug，要么就是LarkBadge.Path这个结构体触发了Xcode的某种异常
    /// 在这里采用绕开的方式，将生成Path的字符串作为存储属性放置在ToolBarMoreButton中，然后
    /// 需要Path的时候就计算生成一个Path，即可避免此问题
    /// 如果升级到XCode 13可以验证此bug是否消失
    private var containerMoreButtonPathString: String?

    /// 设置菜单按钮的BadgePath，让其可以监听红点信息
    /// - Parameter containerMoreButtonPathString: 菜单按钮的Path
    @objc
    public func setBadgeObserve(for containerMoreButtonPathString: String) {
        let path = Path().raw(containerMoreButtonPathString)
        self.containerMoreButtonPathString = containerMoreButtonPathString
        self.badge.observe(for: path)
    }


    /// 更新菜单按钮的Badge
    /// - Parameters:
    ///   - itemIdentifier: 来自于哪个菜单选项，选项的ID
    ///   - isDisplay: 是否应该显示红点
    @objc
    public func updateBadgeNumber(for itemIdentifier: String, isDisplay: Bool) {
        guard let containerMoreButtonPathString = self.containerMoreButtonPathString else {
            logger.error("ToolBarMoreButton haven't containerButtonPath")
            return
        }
        let path = Path().raw(containerMoreButtonPathString).raw(itemIdentifier)
        if isDisplay {
            BadgeManager.setBadge(path, type: .dot(.web), strategy: .weak)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
