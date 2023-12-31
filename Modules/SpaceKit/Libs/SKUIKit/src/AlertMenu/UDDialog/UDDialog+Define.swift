//
//  UDDialog+Define.swift
//  SKUIKit
//
//  Created by guoqp on 2021/7/6.
//

import Foundation
import UniverseDesignDialog

extension UDDialog {
    public struct TextStyle {
        public var color: UIColor = UIColor.ud.textTitle
        public var font: UIFont = UIFont.systemFont(ofSize: 16)
        public var alignment: NSTextAlignment = .center
        public var numberOfLines: Int = 0
        public var lineSpacing: CGFloat = 4

        public static func title() -> TextStyle {
            return TextStyle(font: UIFont.systemFont(ofSize: 17).medium)
        }
        public static func content() -> TextStyle {
            return TextStyle(font: UIFont.systemFont(ofSize: 16),
                             alignment: .center,
                             lineSpacing: 4)
        }
        public static var defaultContentStyle: TextStyle {
            return TextStyle(font: UIFont.systemFont(ofSize: 16),
                             alignment: .center,
                             lineSpacing: 4)
        }
    }

    public enum Mode {
        // 默认的样式
        case `default`
        // 带输入框的样式
        case input
        // 一个确认按钮的样式
        case checkButton
    }

    internal(set) public var customMode: Mode {
        get {
            guard let mode = objc_getAssociatedObject(self, &UDDialog._kCustomModeKey) as? Mode else {
                let m = UDDialog.Mode.default
                self.customMode = m
                return m
            }
            return mode
        }
        set { objc_setAssociatedObject(self, &UDDialog._kCustomModeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var _kCustomModeKey: UInt8 = 0

}
