//
//  WebAppMenuAdditionView.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/2/24.
//

import ByteWebImage
import FigmaKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignTheme
import LarkOPInterface
import WebBrowser

/// 网页应用菜单头部视图，带头像和标题
public final class WebAppMenuAdditionView: UIView {

    /// 头部高度
    private let additionViewHeight: CGFloat = 48
    /// 图片宽度和长度
    private let iconWidthAndHeight: CGFloat = 24
    /// 图片圆角
    private let iconImageCornerRadius: CGFloat = 6
    /// 应用名称字体大小
    private let titleFont = UIFont.systemFont(ofSize: 16)
    /// 应用名称标签高度
    private let titleHeight: CGFloat = 22
    /// 标签的左边距
    private let titleLeftSpacing: CGFloat = 8
    /// 头部视图的左边距
    private let additionViewLeftSpacing: CGFloat = 16
    /// 头部视图的右边距
    private let additionViewRightSpacing: CGFloat = 16

    /// 默认的应用头像
    private let defaultImage = BundleResources.WebBrowser.web_app_header_icon
    /// 默认的应用名称
    private let defaultName = BundleI18n.EcosystemWeb.OpenPlatform_AppActions_LoadingDesc

    /// 头像视图
    private var iconImageView: UIImageView?

    /// 标签视图
    private var titleView: UILabel?


    /// 头部视图的数据模型
    private var model: WebAppMenuAdditionViewModel

    /// 初始化头部视图
    /// - Parameter model: 数据模型
    public init(model: WebAppMenuAdditionViewModel) {
        self.model = model
        super.init(frame: .zero)

        setupSubviews()
        setupSubviewsStaticConstrain()

        updateModel(for: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新头部视图
    /// - Parameter model: 新的数据模型
    public func updateModel(for model: WebAppMenuAdditionViewModel) {
        self.model = model
        updateIcon(for: model.iconKey)
        updateName(for: model.name)
    }

    /// 更新标签
    /// - Parameter name: 新的应用名称
    private func updateName(for name: String?) {
        guard let label = self.titleView else {
            return
        }
        label.text = name ?? self.defaultName
    }

    /// 更新头像
    /// - Parameter key: 新的头像
    private func updateIcon(for key: String?) {
        guard let icon = self.iconImageView else {
            return
        }
        guard let key = key else {
            icon.image = self.defaultImage
            return
        }
        icon.bt.setLarkImage(with: .avatar(key: key, entityID: "", params: .init(sizeType: .size(self.iconWidthAndHeight))))
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupIconImageView()
        setupTitleView()
    }

    /// 初始化子视图静态约束
    private func setupSubviewsStaticConstrain() {
        setupCurrentViewStaticConstrain()
        setupIconImageViewStaticConstrain()
        setupTitleViewStaticConstrain()
    }

    /// 初始化头像
    private func setupIconImageView() {
        if let iconImageView = self.iconImageView {
            iconImageView.removeFromSuperview()
            self.iconImageView = nil
        }

        let newIcon = UIImageView()
        newIcon.contentMode = .scaleAspectFit
        newIcon.layer.masksToBounds = true
        newIcon.layer.ux.setSmoothCorner(radius: iconImageCornerRadius)
        self.addSubview(newIcon)
        self.iconImageView = newIcon
    }

    /// 初始化标签视图
    private func setupTitleView() {
        if let titleView = self.titleView {
            titleView.removeFromSuperview()
            self.titleView = nil
        }
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = self.titleFont
        self.addSubview(label)
        self.titleView = label
    }

    /// 初始化自身的约束
    private func setupCurrentViewStaticConstrain() {
        self.snp.makeConstraints{
            make in
            make.height.equalTo(self.additionViewHeight)
        }
    }

    /// 初始化头像的约束
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

    /// 初始化标签的约束
    private func setupTitleViewStaticConstrain() {
        guard let label = self.titleView, let icon = self.iconImageView else {
            return
        }
        label.snp.makeConstraints{
            make in
            make.leading.equalTo(icon.snp.trailing).offset(self.titleLeftSpacing)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-self.additionViewRightSpacing)
            make.height.equalTo(self.titleHeight)
        }
    }

}

extension WebAppMenuAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        var labelWidth: CGFloat = 0
        if let label = self.titleView {
            labelWidth = label.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        }
        let totalWidth = self.additionViewLeftSpacing + self.iconWidthAndHeight + self.titleLeftSpacing + labelWidth + self.additionViewRightSpacing
        return CGSize(width: totalWidth, height: self.additionViewHeight)
    }
    
    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        forecastSize()
    }
}

extension WebAppMenuAdditionView: WebAppMenuAddtionProtocol {
    public func updateReviewInfo(for appReviewInfo: AppReviewInfo?) {
        
    }
}
