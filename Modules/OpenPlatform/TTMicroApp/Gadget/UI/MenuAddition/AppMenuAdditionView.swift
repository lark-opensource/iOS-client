//
//  AppMenuAdditionView.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import LarkUIKit

/// 显示到菜单附加视图中的权限动画，动画作用于的视图，我们称为附着视图
final class AppMenuAdditionView: UIView {
    /// 权限动画器
    private var privacyAnimator: PrivacyAlternateAnimator?

    /// 麦克风权限视图
    private lazy var microPrivacyView: MenuPrivacyView = {
        // OC方法返回类型不可信
        let model = MenuPrivacyViewModel(image: UIImage.bdp_imageNamed("tma_navi_privacy_mic") ?? UIImage(), name: BDPI18n.openPlatform_AppActions_UseMicDesc ?? "", type: .microphone)
        return MenuPrivacyView(model: model)
    }()

    /// 地理位置权限视图
    private lazy var locationPrivacyView: MenuPrivacyView = {
        // OC方法返回类型不可信
        let model = MenuPrivacyViewModel(image: UIImage.bdp_imageNamed("tma_navi_privacy_location") ?? UIImage(), name: BDPI18n.openPlatform_AppActions_UseLocationDesc ?? "", type: .location)
        return MenuPrivacyView(model: model)
    }()

    /// 动画器的事件代理
    weak var delegate: AlternateAnimatorDelegate? {
        didSet {
            self.privacyAnimator?.delegate = delegate
        }
    }

    /// 权限视图的事件代理
    weak var privacyActionDelegate: AppMenuPrivacyDelegate? {
        didSet {
            microPrivacyView.delegate = privacyActionDelegate
            locationPrivacyView.delegate = privacyActionDelegate
        }
    }

    /// 初始化附着视图
    init() {
        super.init(frame: .zero)
        self.privacyAnimator = PrivacyAlternateAnimator(targetView: self)
        self.privacyAnimator?.dataSource = self // 设置好数据代理
    }

    /// 开始监听权限变化
    func startNotifier() {
        self.privacyAnimator?.startNotifier()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AppMenuAdditionView: MenuForecastSizeProtocol {
    func forecastSize() -> CGSize {
        let currentDisplayPrivacyViews = self.privacyAnimator?.currentAnimateViews.compactMap{
            $0 as? MenuPrivacyView
        }
        guard let currentPrivacyVeiws = currentDisplayPrivacyViews else {
            return .zero
        }
        //获取所有视图的最大宽度和高度
        let maxWidth = currentPrivacyVeiws.map{
            $0.forecastSize().width
        }.max() ?? 0
        let maxHeight = currentPrivacyVeiws.map{
            $0.forecastSize().height
        }.max() ?? 0
        return CGSize(width: maxWidth, height: maxHeight)
    }

    func reallySize(for suggestionSize: CGSize) -> CGSize {
        let currentDisplayPrivacyViews = self.privacyAnimator?.currentAnimateViews.compactMap{
            $0 as? MenuPrivacyView
        }
        guard let currentPrivacyVeiws = currentDisplayPrivacyViews else {
            return .zero
        }
        let suggestionSizes = currentPrivacyVeiws.map{
            $0.reallySize(for: suggestionSize)
        }
        //获取所有视图的最大宽度和高度
        let maxWidth = suggestionSizes.map{
            $0.width
        }.max() ?? 0
        let maxHeight = suggestionSizes.map{
            $0.height
        }.max() ?? 0
        return CGSize(width: maxWidth, height: maxHeight)
    }
}

extension AppMenuAdditionView: PrivacyAlternateAnimatorDataSource {
    func privacyAlternateAnimator(_ animator: PrivacyAlternateAnimator, for status: BDPPrivacyAccessStatus) -> [UIView] {
        var result: [UIView] = []
        if status.contains(.location) {
            result.append(self.locationPrivacyView)
        }
        if status.contains(.microphone) {
            result.append(self.microPrivacyView)
        }
        return result
    }
}
