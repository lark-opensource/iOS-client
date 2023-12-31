//
//  MenuPrivacyView.swift
//  OPSDK
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import SnapKit
import LarkUIKit

/// 权限视图，一个权限头像和一串描述文本
final class MenuPrivacyView: UIButton {
    /// 权限视图的数据模型
    private var model: MenuPrivacyViewModel

    /// 头像
    private var customImageView: UIImageView?

    /// 描述文本
    private var customTitleLabel: UILabel?

    /// 权限视图的布局样式
    private let style = MenuPrivacyViewStyle()

    /// 权限视图的事件代理
    weak var delegate: AppMenuPrivacyDelegate?

    /// 自己期望的显示大小
    private var hopeSize: CGSize = .zero

    /// 初始化权限视图
    /// - Parameter model: 权限视图的数据模型
    init(model: MenuPrivacyViewModel) {
        self.model = model

        super.init(frame: .zero)

        setupSubViews()
        setupStaticConstrain()

        updateModel(for: model)

        self.hopeSize = forecastSize() // 先设置为无约束时的期望大小
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubViews() {
        setupCurrentView()
        setupImageView()
        setupTitleView()
    }

    /// 初始化当前视图
    private func setupCurrentView() {
        self.addTarget(self, action: #selector(privacyAction), for: .touchUpInside)
    }

    /// 点击视图后触发的事件代理
    @objc
    private func privacyAction() {
        self.delegate?.action(for: self.model.type)
    }

    /// 初始化头像视图
    private func setupImageView() {
        if let imageView = self.customImageView {
            imageView.removeFromSuperview()
            self.customImageView = nil
        }

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = self.style.imageColor
        self.addSubview(imageView)
        self.customImageView = imageView
    }

    /// 初始化描述标签
    private func setupTitleView() {
        if let label = self.customTitleLabel {
            label.removeFromSuperview()
            self.customTitleLabel = nil
        }
        let label = UILabel()
        label.numberOfLines = 2 //支持双行显示
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        label.font = self.style.font
        label.textColor = self.style.labelColor

        self.addSubview(label)
        self.customTitleLabel = label
    }

    /// 初始化视图的静态约束
    private func setupStaticConstrain() {
        setupCurrentViewStaticConstrain()
        setupImageViewStaticConstrain()
        setupTitleViewStaticConstrain()
    }

    /// 初始化自身的静态约束
    private func setupCurrentViewStaticConstrain() {
        self.snp.makeConstraints{
            make in
            make.size.equalTo(self.hopeSize)
        }
    }

    /// 初始化头像的静态约束
    private func setupImageViewStaticConstrain() {
        guard let imageView = self.customImageView else {
            return
        }
        imageView.snp.makeConstraints{
            make in
            make.leading.equalToSuperview().offset(self.style.imageLeftSpacing)
            make.width.height.equalTo(self.style.imageWidthAndHeight)
            make.centerY.equalToSuperview()
        }
    }

    /// 初始化描述的静态约束
    private func setupTitleViewStaticConstrain() {
        guard let label = self.customTitleLabel, let imageView = self.customImageView else {
            return
        }
        label.snp.makeConstraints{
            make in
            make.leading.equalTo(imageView.snp.trailing).offset(self.style.titleLeftSpacing)
            make.trailing.equalToSuperview().offset(-self.style.titleRightSpacing)
            make.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    /// 更新数据模型
    /// - Parameter model: 新的数据模型
    private func updateModel(for model: MenuPrivacyViewModel) {
        self.model = model
        self.customImageView?.image = model.image.withRenderingMode(.alwaysTemplate)
        self.customTitleLabel?.text = model.name
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateCurrentViewConstrain()
    }

    /// 更新自身的大小
    private func updateCurrentViewConstrain() {
        self.snp.updateConstraints{
            make in
            make.size.equalTo(self.hopeSize)
        }
    }
}

extension MenuPrivacyView: MenuForecastSizeProtocol {
    /// 无约束情况下的期望大小
    /// - Returns: 期望大小
    func forecastSize() -> CGSize {
        var labelWidth: CGFloat = 0
        if let label = self.customTitleLabel {
            labelWidth = label.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        }
        let totalWidth = self.style.imageLeftSpacing + self.style.imageWidthAndHeight + self.style.titleLeftSpacing + labelWidth + self.style.titleRightSpacing
        return  CGSize(width: totalWidth, height: self.style.viewHeight(mutiLine: false))
    }

    /// 根据父视图传给它的建议大小来确定自己想显示的大小
    /// - Parameter suggestionSize: 父视图的建议大小
    /// - Returns: 自己根据父视图的大小调整后的大小
    func reallySize(for suggestionSize: CGSize) -> CGSize {
        var reallySize = forecastSize()
        if suggestionSize.width < reallySize.width {
            reallySize.width = suggestionSize.width
            reallySize.height = self.style.viewHeight(mutiLine: true)
        }
        hopeSize = reallySize
        return reallySize
    }
}
