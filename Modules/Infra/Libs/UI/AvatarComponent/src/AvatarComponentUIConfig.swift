//
//  AvatarComponentUIConfig.swift
//  AvatarComponent
//
//  Created by 姚启灏 on 2020/6/16.
//

import UIKit
import Foundation

/// AvatarComponent UI Config
public struct AvatarComponentUIConfig {
    public enum Style {
        case square, circle
    }

    /// Placeholder when the avatar is empty，二进制原因，不做不兼容的变更
    @available(*, deprecated, message: "无需设置，废弃属性")
    public var placeholder: UIImage?

    /// AvatarComponent BackgroundColor
    public var backgroundColor: UIColor?

    /// AvatarComponent View CornerRadius
    public var style: AvatarComponentUIConfig.Style = .circle

    /// A flag used to determine how a view lays out its content when its bounds change.
    public var contentMode: UIView.ContentMode = .scaleAspectFill

    public init(placeholder: UIImage? = nil,
                backgroundColor: UIColor? = nil,
                style: AvatarComponentUIConfig.Style = .circle,
                contentMode: UIView.ContentMode = .scaleAspectFill) {
        self.placeholder = placeholder
        self.backgroundColor = backgroundColor
        self.style = style
        self.contentMode = contentMode
    }
}
