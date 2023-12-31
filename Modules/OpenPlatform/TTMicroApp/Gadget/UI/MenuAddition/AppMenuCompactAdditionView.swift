//
//  AppMenuCompactAdditionView.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import LarkUIKit

@objc
/// 小程序菜单头部的附加视图，紧凑的样式，现在用于iPad
public final class AppMenuCompactAdditionView: UIView {

    /// 附加视图的高度
    private let viewHeight: CGFloat = 54
    /// 视图的左边距
    private let leftSpacing: CGFloat = 16
    /// 视图的右边距
    private let rightSpacing: CGFloat = 16

    /// 附着视图
    private var appAdditionView: AppMenuAdditionView?

    /// 动画器的事件代理
    @objc public weak var delegate: AlternateAnimatorDelegate? {
        didSet {
            self.appAdditionView?.delegate = delegate
        }
    }

    /// 动画视图的事件代理
    @objc public weak var privacyActionDelegate: AppMenuPrivacyDelegate? {
        didSet {
            self.appAdditionView?.privacyActionDelegate = privacyActionDelegate
        }
    }

    /// 初始化紧凑视图
    @objc
    public init() {
        super.init(frame: .zero)

        let appAddition = AppMenuAdditionView()
        self.appAdditionView = appAddition
        self.addSubview(appAddition)

        setupAppAdditionStaticConstrain()
    }

    /// 初始化附着视图的约束
    private func setupAppAdditionStaticConstrain() {
        guard let appAdditionView = self.appAdditionView else {
            return
        }
        appAdditionView.snp.makeConstraints{
            make in
            make.leading.equalToSuperview().offset(self.leftSpacing)
            make.trailing.equalToSuperview().offset(-self.rightSpacing)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    /// 开始监听权限事件变化
    @objc
    public func startNotifier() {
        self.appAdditionView?.startNotifier()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AppMenuCompactAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        let privacyWidth = self.appAdditionView?.forecastSize().width ?? 0
        let totalWidth = privacyWidth + leftSpacing + rightSpacing
        return CGSize(width: totalWidth, height: self.viewHeight)
    }

    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        var newSuggestionSize = suggestionSize
        newSuggestionSize.width = max((newSuggestionSize.width - leftSpacing - rightSpacing), 0)
        let privacyWidth = self.appAdditionView?.reallySize(for: newSuggestionSize).width ?? 0
        let totalWidth = privacyWidth + leftSpacing + rightSpacing
        return CGSize(width: totalWidth, height: self.viewHeight)
    }
}
