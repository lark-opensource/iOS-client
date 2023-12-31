//
//  PrivacyAlternateAnimator.swift
//  OPSDK
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import LarkUIKit

@objc
/// 进行权限动画的动画器
public final class PrivacyAlternateAnimator: NSObject {
    /// 轮换动画器
    private var alternateAnimator: AlternateAnimator

    @objc
    /// 动画器的事件代理
    public weak var delegate: AlternateAnimatorDelegate? {
        didSet {
            self.alternateAnimator.delegate = delegate
        }
    }

    @objc
    /// 权限动画器的数据代理
    public weak var dataSource: PrivacyAlternateAnimatorDataSource?

    /// 当前权限动画器展示的权限类型，默认为空
    private var lastPrivacyStatus: BDPPrivacyAccessStatus = []

    @objc
    /// 当前权限动画器展示的视图，默认为空
    public var currentAnimateViews: [UIView] {
        self.alternateAnimator.currentAnimateViews
    }

    /// 一次轮换动画的时长
    private let animationDuration = 1.6

    /// 初始化权限动画器
    /// - Parameter targetView: 作用于动画的视图
    @objc
    public init(targetView: UIView) {
        self.alternateAnimator = AlternateAnimator(targetView: targetView, animationDuration: self.animationDuration)
        super.init()
    }

    /// 开始监听权限变化
    @objc
    public func startNotifier() {
        self.privacyAccessNotifier(BDPPrivacyAccessNotifier.shared(), didChange: BDPPrivacyAccessNotifier.shared()?.currentStatus ?? [])
        BDPPrivacyAccessNotifier.shared()?.add(self)
    }
}

extension PrivacyAlternateAnimator: BDPPrivacyAccessNotifyDelegate {
    public func privacyAccessNotifier(_ notifier: BDPPrivacyAccessNotifier!, didChange status: BDPPrivacyAccessStatus) {
        // 结束动画
        if status == [] && lastPrivacyStatus != status {
            lastPrivacyStatus = []
            self.alternateAnimator.endAnimate()
            return
        }
        //开始动画
        if status != [] && lastPrivacyStatus == [] {
            lastPrivacyStatus = status
            let uiViews = self.dataSource?.privacyAlternateAnimator(self, for: status) ?? []
            self.alternateAnimator.setAnimateLists(for: uiViews)
            self.alternateAnimator.startAnimate()
            return
        }
        // 更新动画
        if status != lastPrivacyStatus {
            lastPrivacyStatus = status
            let uiViews = self.dataSource?.privacyAlternateAnimator(self, for: status) ?? []
            self.alternateAnimator.setAnimateLists(for: uiViews)
        }
    }
}
