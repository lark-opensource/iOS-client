//
//  UDEmpty.swift
//  Pods-UniverseDesignEmptyDev
//
//  Created by 王元洵 on 2020/9/23.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignFont

public final class UDEmpty: UIStackView {
    private enum UDEmptyLayoutStatus {
        case belowImage
        case belowTitle
        case belowDescription
    }

    ///布局情况
    private var spaceStatus: UDEmptyLayoutStatus = .belowImage

    ///标题
    private(set) lazy var titleLabel = UILabel()
    ///描述
    private(set) lazy var descriptionLabel = UILabel()
    ///图片视图
    private(set) var imageView = UIImageView()
    ///UI配置
    public private(set) var config: UDEmptyConfig
    ///按钮
    private(set) lazy var buttons: [UDButton] = []

    ///主要按钮配置
    public var primaryButtonConfig: UDButtonUIConifg? {
        didSet {
            self.update(config: self.config)
        }
    }

    ///次要按钮配置
    public var secondaryButtonConfig: UDButtonUIConifg? {
        didSet {
            self.update(config: self.config)
        }
    }

    ///初始化方法
    public init(config: UDEmptyConfig) {
        self.config = config
        super.init(frame: .zero)

        self.axis = .vertical
        self.alignment = .center
        setUI()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///设置最大左右边界
    private func setLeftRightBorderConstraints(view: UIView) {
        view.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(16)
        }
    }

    ///设置图片视图的约束
    private func setImageConstraints() {
        setLeftRightBorderConstraints(view: imageView)
        imageView.snp.makeConstraints { (make) in
            if let imageSize = config.imageSize {
                make.width.height.equalTo(imageSize)
            } else if case .initial = self.config.type {
                make.width.height.equalTo(245)
            } else {
                make.width.height.equalTo(100)
            }
        }
    }

    ///设置标题的约束
    private func setTitleConstraints() {
        setLeftRightBorderConstraints(view: titleLabel)
        setCustomSpacing(config.spaceBelowImage, after: imageView)

        spaceStatus = .belowTitle
    }

    ///设置描述文本的约束
    private func setDescriptionConstraints() {
        setLeftRightBorderConstraints(view: descriptionLabel)
        switch spaceStatus {
        case .belowImage:
            setCustomSpacing(config.spaceBelowImage, after: imageView)
        case .belowTitle:
            setCustomSpacing(config.spaceBelowTitle, after: titleLabel)
        default: break
        }

        spaceStatus = .belowDescription
    }

    ///设置按钮的约束
    private func setButtonsConstraints(buttons: [UDButton]) {
        for i in 0..<buttons.count {
            let button = buttons[i]
            setLeftRightBorderConstraints(view: button)

            if i == 0 {
                button.snp.makeConstraints { (make) in
                    make.height.greaterThanOrEqualTo(36)
                    switch spaceStatus {
                    case .belowImage:
                        setCustomSpacing(config.spaceBelowImage, after: imageView)
                    case .belowTitle:
                        setCustomSpacing(config.spaceBelowTitle, after: titleLabel)
                    case .belowDescription:
                        setCustomSpacing(config.spaceBelowDescription, after: descriptionLabel)
                    }
                }
            } else {
                button.snp.makeConstraints { (make) in
                    make.height.greaterThanOrEqualTo(36)
                }
                setCustomSpacing(config.spaceBetweenButtons, after: buttons[i - 1])
            }
        }
    }

    ///设置标题
    private func setTitle(_ title: UDEmptyConfig.Title) {
        addArrangedSubview(titleLabel)
        titleLabel.text = title.titleText
        titleLabel.textColor = UDEmptyColorTheme.emptyTitleColor
        titleLabel.font = title.font
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        setTitleConstraints()
    }

    ///设置描述
    private func setDescription(_ description: UDEmptyConfig.Description) {
        addArrangedSubview(descriptionLabel)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.attributedText = setDescriptionAttributedText(descriptionText: description.descriptionText,
                                                         range: description.operableRange)
        if let font = description.font {
            descriptionLabel.font = description.font
        }
        descriptionLabel.textAlignment = description.textAlignment

        setDescriptionConstraints()

        if config.labelHandler != nil,
           descriptionLabel.isUserInteractionEnabled == false {
            descriptionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                         action: #selector(onLabelClick)))
            descriptionLabel.isUserInteractionEnabled = true
        }
    }

    ///设置按钮
    private func setButton(_ config: UDEmptyConfig) {
        if let primaryButtonConfig = config.primaryButtonConfig {

            var primaryConfig: UDButtonUIConifg = UDButtonUIConifg(normalColor: .init(borderColor: UDEmptyColorTheme.primaryButtonBorderColor,
                                                                                      backgroundColor: UDEmptyColorTheme.primaryButtonBackgroundColor,
                                                                                      textColor: UDEmptyColorTheme.primaryButtonTextColor),
                                                                   type: .middle)
            if let primary = self.primaryButtonConfig {
                primaryConfig = primary
            }

            let primaryButton =
                getButton(config: primaryConfig,
                          title: primaryButtonConfig.0,
                          font: UDFont.body2(.fixed))
            primaryButton.addTarget(self, action: #selector(onPrimaryButtonClick), for: .touchUpInside)

            if let secondaryButtonConfig = config.secondaryButtonConfig {

                var secondaryConfig: UDButtonUIConifg = UDButtonUIConifg(normalColor:
                                                                            .init(borderColor: UDEmptyColorTheme.secondaryButtonBorderColor,
                                                                                  backgroundColor: UDEmptyColorTheme.secondaryButtonBackgroundColor,
                                                                                  textColor: UDEmptyColorTheme.secondaryButtonTextColor),
                                                                         type: .middle)
                if let secondary = self.secondaryButtonConfig {
                    secondaryConfig = secondary
                }

                let secondaryButton =
                    getButton(config: secondaryConfig,
                              title: secondaryButtonConfig.0,
                              font: UDFont.body2(.fixed))
                secondaryButton.addTarget(self, action: #selector(onSecondaryButtonClick), for: .touchUpInside)

                if let primaryTextCount = primaryButton.titleLabel?.text?.count,
                   let secondaryTextCount = secondaryButton.titleLabel?.text?.count {
                    if primaryTextCount > secondaryTextCount {
                        secondaryButton.snp.makeConstraints { make in
                            make.width.equalTo(primaryButton)
                        }
                    } else {
                        primaryButton.snp.makeConstraints { make in
                            make.width.equalTo(secondaryButton)
                        }
                    }
                }
            }

            setButtonsConstraints(buttons: self.buttons)
        }
    }

    ///设置整体UI
    private func setUI() {
        imageView.image = config.type.defaultImage()
        addArrangedSubview(imageView)
        setImageConstraints()

        if let title = config.title {
            setTitle(title)
        }

        if let description = config.description {
            setDescription(description)
        }

        setButton(config)
    }

    private func setDescriptionAttributedText(descriptionText: NSAttributedString,
                                              range: NSRange? = nil) -> NSMutableAttributedString {
        let descriptionString = NSMutableAttributedString(attributedString: descriptionText)
        descriptionString.addAttribute(.foregroundColor,
                                       value: UDEmptyColorTheme.emptyDescriptionColor,
                                       range: .init(location: 0, length: descriptionString.length))
        if let range = range {
            descriptionString.addAttribute(.foregroundColor,
                                           value: UDEmptyColorTheme.emptyNegtiveOperableColor,
                                           range: range)
        }

        return descriptionString
    }

    ///设置按钮
    private func getButton(config: UDButtonUIConifg,
                           title: String?,
                           font: UIFont) -> UDButton {
        let button = UDButton(config)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        addArrangedSubview(button)
        self.buttons.append(button)
        return button
    }

    ///更新当前空状态
    public func update(config: UDEmptyConfig) {
        self.subviews.forEach {
            $0.snp.removeConstraints()
            $0.removeFromSuperview()
        }
        self.buttons = []
        self.spaceStatus = .belowImage

        self.config = config
        setUI()
    }

    ///可操作文本点击事件
    @objc
    private func onLabelClick() {
        config.labelHandler?()
    }

    ///主要按钮点击事件
    @objc
    private func onPrimaryButtonClick(sender: UIButton) {
        config.primaryButtonConfig?.1(sender)
    }

    ///次要按钮点击事件
    @objc
    private func onSecondaryButtonClick(sender: UIButton) {
        config.secondaryButtonConfig?.1(sender)
    }
}
