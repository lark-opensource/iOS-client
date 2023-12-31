//
//  AppMenuRegularAdditionView.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import LarkUIKit
import UniverseDesignColor
import OPFoundation
import FigmaKit

@objc
/// 小程序菜单头部的附加视图，正常的样式，现在用于iPhone
final class AppMenuRegularAdditionView: UIView {

    /// 附加视图的高度
    private let additionViewHeight: CGFloat = 48
    /// 头像的大小
    private let iconWidthAndHeight: CGFloat = 24
    /// 头像边框的宽度
    private let iconImageBorderWidht: CGFloat = 0
    /// 头像边框颜色
    private let iconImageBorderColor = UIColor.ud.N900.withAlphaComponent(0.1)
    /// 头像圆角
    private let iconImageCornerRadius: CGFloat = 6
    /// 应用名称字号
    private let titleFont = UIFont.systemFont(ofSize: 16)
    /// 应用名称高度
    private let titleHeight: CGFloat = 22
    /// 应用名称左边距
    private let titleLeftSpacing: CGFloat = 8
    /// 应用名称最小宽度
    private let minTitleWidth: CGFloat = 44
    /// 附加视图左边距
    private let additionViewLeftSpacing: CGFloat = 16
    /// 附加视图右边距
    private let additionViewRightSpacing: CGFloat = 16
    /// 应用名称颜色
    private let titleColor = UIColor.ud.textTitle

    /// 当有权限视图时应用名称的右边距
    private let titleRightSpacingWhenDisplayPrivacyView: CGFloat = 16

    /// 默认的应用头像
    private let defaultImage = UIImage.bdp_imageNamed("app_header_icon_default")
    /// 默认的应用名称
    private let defaultName = BDPI18n.openPlatform_AppActions_LoadingDesc

    /// 头像
    private var iconImageView: UIImageView?

    /// 名称
    private var titleView: UILabel?

    /// 权限附着视图
    private var appAdditionView: AppMenuAdditionView?
    /// 是否显示权限视图
    private var isShowAppAdditionView = false

    /// 附加视图的数据模型
    private var model: AppMenuRegularAdditionViewModel

    /// 权限视图的事件代理
    @objc public weak var privacyActionDelegate: AppMenuPrivacyDelegate? {
        didSet {
            self.appAdditionView?.privacyActionDelegate = privacyActionDelegate
        }
    }

    /// 初始化附加视图
    /// - Parameter model: 视图的数据模型
    @objc
    public init(model: AppMenuRegularAdditionViewModel) {
        self.model = model
        super.init(frame: .zero)

        setupSubviews()
        setupSubviewsStaticConstrain()

        updateModel(for: model)

        startNotifier()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateAppAdditionViewDynamicComstrain()
        iconImageView?.layer.ux.setSmoothCorner(radius: iconImageCornerRadius)
    }

    /// 更新数据模型
    /// - Parameter model: 新的数据模型
    @objc
    public func updateModel(for model: AppMenuRegularAdditionViewModel) {
        self.model = model
        updateIcon(for: model.iconURL)
        updateName(for: model.name)
    }

    /// 更新名称
    /// - Parameter name: 新的名称
    private func updateName(for name: String?) {
        guard let label = self.titleView else {
            return
        }
        label.text = name ?? self.defaultName
    }

    /// 更新头像
    /// - Parameter url: 头像的url
    private func updateIcon(for url: String?) {
        guard let icon = self.iconImageView else {
            return
        }
        guard let urlString = url, let url = URL(string: urlString) else {
            icon.image = self.defaultImage
            return
        }
        // 建议不要直接使用BDWebImage
        BDPNetworking.setImageView(icon, url: url, placeholder: self.defaultImage)
    }

    /// 开始监听权限变化
    private func startNotifier() {
        self.appAdditionView?.startNotifier()
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupIconImageView()
        setupTitleView()
        setupAppAdditionView()
    }

    /// 初始化子视图的约束
    private func setupSubviewsStaticConstrain() {
        setupCurrentViewStaticConstrain()
        setupIconImageViewStaticConstrain()
        updateTitleViewDynamicConstrain()
    }

    /// 初始化头像
    private func setupIconImageView() {
        if let iconImageView = self.iconImageView {
            iconImageView.removeFromSuperview()
            self.iconImageView = nil
        }

        let newIcon = OPThemeImageView()
        newIcon.contentMode = .scaleAspectFit
        newIcon.layer.borderWidth = self.iconImageBorderWidht
        newIcon.layer.borderColor = self.iconImageBorderColor.cgColor
        newIcon.layer.masksToBounds = true
        newIcon.layer.ux.setSmoothCorner(radius: iconImageCornerRadius)
        self.addSubview(newIcon)
        self.iconImageView = newIcon
    }

    /// 初始化应用名称标签
    private func setupTitleView() {
        if let titleView = self.titleView {
            titleView.removeFromSuperview()
            self.titleView = nil
        }
        let label = UILabel()
        label.textColor = self.titleColor
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = self.titleFont
        self.addSubview(label)
        self.titleView = label
    }

    /// 初始化权限视图
    private func setupAppAdditionView() {
        let privacyView = AppMenuAdditionView()
        privacyView.delegate = self
        self.appAdditionView = privacyView
    }

    /// 初始化当前自身的约束
    private func setupCurrentViewStaticConstrain() {
        self.snp.makeConstraints{
            make in
            make.height.equalTo(self.additionViewHeight)
        }
    }

    /// 初始化头像约束
    private func setupIconImageViewStaticConstrain() {
        guard let icon = self.iconImageView else {
            return
        }
        icon.snp.makeConstraints{
            make in
            make.leading.equalToSuperview().offset(self.additionViewLeftSpacing)
            make.width.height.equalTo(self.iconWidthAndHeight)
            make.centerY.equalToSuperview()
        }
    }

    /// 更新标签约束
    private func updateTitleViewDynamicConstrain() {
        guard let label = self.titleView, let icon = self.iconImageView else {
            return
        }
        label.snp.remakeConstraints{
            make in
            make.leading.equalTo(icon.snp.trailing).offset(self.titleLeftSpacing)
            make.centerY.equalToSuperview()
            if !self.isShowAppAdditionView {
                make.trailing.equalToSuperview().offset(-self.additionViewRightSpacing)
            }
            make.height.equalTo(self.titleHeight)
        }
    }

    /// 更新权限视图约束
    private func updateAppAdditionViewDynamicComstrain() {
        guard let label = self.titleView, let appAddition = self.appAdditionView, appAddition.superview != nil else {
            return
        }
        // 计算权限视图的长度，并设置最大长度，且让小程序名称有至少44px的显示宽度
        let allowMaxWidth = self.frame.width - (self.additionViewLeftSpacing + self.iconWidthAndHeight + self.titleLeftSpacing + self.minTitleWidth + titleRightSpacingWhenDisplayPrivacyView + self.additionViewRightSpacing)
        var reallySize = appAddition.forecastSize()
        var reallyWidth = min(max(0, allowMaxWidth), reallySize.width)
        var reallyHeight = reallySize.height
        reallySize = appAddition.reallySize(for: CGSize(width: reallyWidth, height: reallyHeight))
        reallyWidth = min(max(0, allowMaxWidth), reallySize.width)
        reallyHeight = reallySize.height
        appAddition.snp.remakeConstraints{
            make in
            make.leading.equalTo(label.snp.trailing).offset(self.titleRightSpacingWhenDisplayPrivacyView)
            make.trailing.equalToSuperview().offset(-self.additionViewRightSpacing)
            make.centerY.equalToSuperview()
            make.width.equalTo(reallyWidth)
            make.height.equalTo(reallyHeight)
        }
    }
}

extension AppMenuRegularAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        var labelWidth: CGFloat = 0
        if let label = self.titleView {
            labelWidth = label.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        }
        var totalWidth = self.additionViewLeftSpacing + self.iconWidthAndHeight + self.titleLeftSpacing + labelWidth + self.additionViewRightSpacing
        if self.isShowAppAdditionView {
            let privacyWidth = self.appAdditionView?.forecastSize().width ?? 0
            totalWidth += (privacyWidth + titleRightSpacingWhenDisplayPrivacyView)
        }
        return CGSize(width: totalWidth, height: additionViewHeight)
    }
    
    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        forecastSize()
    }
}

extension AppMenuRegularAdditionView: AlternateAnimatorDelegate {

    public func animationWillStart(for view: UIView) {
        //动画开始，将动画附着视图添加到自己的子视图中，并更新约束
        self.isShowAppAdditionView = true
        self.addSubview(view)
        updateTitleViewDynamicConstrain()
        updateAppAdditionViewDynamicComstrain()
    }

    public func animationDidEnd(for view: UIView) {
        //动画开始，将动画附着视图从子视图移除，并更新约束
        self.isShowAppAdditionView = false
        view.removeFromSuperview()
        updateTitleViewDynamicConstrain()
    }

    public func animationDidAddSubView(for targetView: UIView, subview: UIView) {
        // 当有新的动画视图添加到附着视图中时，可以设置子视图的布局方式
        // 右对齐
        subview.snp.makeConstraints{
            make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
        }
        // 需要强制刷新布局
        setNeedsLayout()
        layoutIfNeeded()
    }

    public func animationDidRemoveSubView(for targetView: UIView, subview: UIView) {
        // 需要强制刷新布局，才能使布局正确
        setNeedsLayout()
        layoutIfNeeded()
    }
}

