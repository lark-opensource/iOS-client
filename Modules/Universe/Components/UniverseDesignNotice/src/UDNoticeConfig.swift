//
//  UDNoticeConfig.swift
//  UniverseDesignNotice
//
//  Created by 龙伟伟 on 2020/10/12.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignColor

/// 提供通用样式配置
public enum UDNoticeType {
    case info
    case success
    case warning
    case error
}

public enum UDNoticeAlignment{
    case left
    case center
}

public enum ScrollDirectionType{
    case left
    case right
}

public struct UDNoticeUIConfig: Equatable {

    ///是否可轮播
    public var autoScrollable: Bool = false
    ///轮播速度
    public var speed: CGFloat = 50
    ///渐变长度
    public var fadeLength: CGFloat = 10
    ///向左/向右
    public var direction: ScrollDirectionType = .left
    /// 背景色 （必选）
    public var backgroundColor: UIColor

    /// Notice文本内容 （必选）
    public var attributedText: NSAttributedString

    /// 左侧文字按钮文案（可选，默认为空）
    public var leadingButtonText: String?

    /// 左侧图标（可选，默认为空）
    public var leadingIcon: UIImage?

    /// 右侧按钮图标（可选，默认为空）
    public var trailingButtonIcon: UIImage?

    /// notice 内容对齐方式
    public var alignment: UDNoticeAlignment = .left
    
    /// link 颜色定制
    public var linkTextColor: UIColor?

    /// Notice 文本截断，设置后，仅可显示一行
    public var lineBreakMode: NSLineBreakMode?

    public init(backgroundColor: UIColor, attributedText: NSAttributedString) {
        self.backgroundColor = backgroundColor
        self.attributedText = attributedText
    }

    /// 提供的默认样式的构造方法，包含了背景色和左侧图标
    public init(type: UDNoticeType, attributedText: NSAttributedString) {
        self.attributedText = attributedText
        switch type {
        case .info:
            backgroundColor = UDNoticeColorTheme.noticeInfoBgColor
            leadingIcon = UDIcon.getIconByKey(.infoColorful)
        case .success:
            backgroundColor = UDNoticeColorTheme.noticeSuccessBgColor
            leadingIcon = UDIcon.getIconByKey(.succeedColorful)
        case .warning:
            backgroundColor = UDNoticeColorTheme.noticeWarningBgColor
            leadingIcon = UDIcon.getIconByKey(.warningColorful)
        case .error:
            backgroundColor = UDNoticeColorTheme.noticeErrorBgColor
            leadingIcon = UDIcon.getIconByKey(.errorColorful)
        }
    }
}
