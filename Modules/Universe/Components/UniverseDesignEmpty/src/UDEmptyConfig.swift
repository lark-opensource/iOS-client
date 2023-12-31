//
//  UDEmptyConfig.swift
//  UniverseDesignEmpty
//
//  Created by 王元洵 on 2020/9/28.
//

import UIKit
import Foundation
import UniverseDesignButton
import UniverseDesignFont

///Empty页面UI配置
public struct UDEmptyConfig {
    ///标题结构
    public var title: Title?
    ///描述文本结构
    public var description: Description?
    ///图片尺寸
    public var imageSize: Int?
    ///图片下间距
    public var spaceBelowImage: CGFloat
    ///标题下间距
    public var spaceBelowTitle: CGFloat
    ///描述下间距
    public var spaceBelowDescription: CGFloat
    ///按钮间距
    public var spaceBetweenButtons: CGFloat
    ///主要按钮配置
    public var primaryButtonConfig: (String?, (UIButton) -> Void)?
    ///次要按钮配置
    public var secondaryButtonConfig: (String?, (UIButton) -> Void)?
    ///类型
    public var type: UDEmptyType
    ///可操作文本响应
    public var labelHandler: (() -> Void)?

    ///标题结构
    public struct Title {
        let titleText: String
        let font: UIFont

        ///初始化标题
        public init(titleText: String,
                    font: UIFont = UDFont.title3(.fixed)) {
            self.titleText = titleText
            self.font = font
        }
    }

    ///描述文本结构
    public struct Description {
        let descriptionText: NSAttributedString
        let font: UIFont?
        let textAlignment: NSTextAlignment
        let operableRange: NSRange?

        ///初始化描述
        public init(descriptionText: String,
                    font: UIFont = UDFont.body2(.fixed),
                    textAlignment: NSTextAlignment = .center,
                    operableRange: NSRange? = nil) {
            self.descriptionText = NSAttributedString(string: descriptionText)
            self.font = font
            self.textAlignment = textAlignment
            self.operableRange = operableRange
        }

        ///用自定义NSAttributedString初始化描述
        public init(descriptionText: NSAttributedString,
                    textAlignment: NSTextAlignment = .center,
                    operableRange: NSRange? = nil) {
            self.descriptionText = descriptionText
            self.font = nil
            self.textAlignment = textAlignment
            self.operableRange = operableRange
        }
    }

    ///初始化方法
    public init(title: Title? = nil,
                description: Description? = nil,
                imageSize: Int? = nil,
                spaceBelowImage: CGFloat = 12,
                spaceBelowTitle: CGFloat = 4,
                spaceBelowDescription: CGFloat = 16,
                spaceBetweenButtons: CGFloat = 12,
                type: UDEmptyType,
                labelHandler: (() -> Void)? = nil,
                primaryButtonConfig: (String?, (UIButton) -> Void)? = nil,
                secondaryButtonConfig: (String?, (UIButton) -> Void)? = nil) {
        self.title = title
        self.description = description
        self.imageSize = imageSize
        self.type = type
        self.labelHandler = labelHandler
        self.primaryButtonConfig = primaryButtonConfig
        self.secondaryButtonConfig = secondaryButtonConfig
        self.spaceBelowImage = spaceBelowImage
        self.spaceBelowTitle = spaceBelowTitle
        self.spaceBelowDescription = spaceBelowDescription
        self.spaceBetweenButtons = spaceBetweenButtons
    }

    ///初始化方法
    public init(titleText: String = "",
                font: UIFont = UDFont.title3(.fixed),
                description: Description? = nil,
                imageSize: Int? = nil,
                spaceBelowImage: CGFloat = 12,
                spaceBelowTitle: CGFloat = 4,
                spaceBelowDescription: CGFloat = 16,
                spaceBetweenButtons: CGFloat = 12,
                type: UDEmptyType,
                labelHandler: (() -> Void)? = nil,
                primaryButtonConfig: (String?, (UIButton) -> Void)? = nil,
                secondaryButtonConfig: (String?, (UIButton) -> Void)? = nil) {
        self.init(
            title: titleText.isEmpty ? nil : Title(titleText: titleText, font: font),
            description: description,
            imageSize: imageSize,
            spaceBelowImage: spaceBelowImage,
            spaceBelowTitle: spaceBelowTitle,
            spaceBelowDescription: spaceBelowDescription,
            spaceBetweenButtons: spaceBetweenButtons,
            type: type,
            labelHandler: labelHandler,
            primaryButtonConfig: primaryButtonConfig,
            secondaryButtonConfig: secondaryButtonConfig
        )
    }
}
