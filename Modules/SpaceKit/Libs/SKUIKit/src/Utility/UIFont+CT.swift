//
//  UIFont+CT.swift
//  SpaceKit
//
//  Created by 邱沛 on 2018/12/4.
//

import UIKit
import SKFoundation

public enum FontName: String {
    case `default`
    case defaultMedium
    case defaultRegular
}

extension UIFont: CTExtensionCompatible {}

extension CTExtension where BaseType == UIFont {
    // 默认16号字体
    public static let btDefault16Font = system(ofSize: 16)
    // displayView默认14号字体
    public static let btDisplayViewDefaultFont = system(ofSize: 14)
    // textView默认18号字体
    public static let btTextViewDefaultFont = system(ofSize: 18)
    // 单选和多选14号字体（用于displayView）
    public static let btOption14Font = systemMedium(ofSize: 14)
    // 单选和多选16号字体（用于editorCard）
    public static let btOption16Font = systemMedium(ofSize: 16)
    
    public static func system(ofSize size: CGFloat) -> UIFont {
        return loadFont(.default, size: size)
    }
    public static func systemMedium(ofSize size: CGFloat) -> UIFont {
        return loadFont(.defaultMedium, size: size)
    }
    public static func systemRegular(ofSize size: CGFloat) -> UIFont {
        return loadFont(.defaultRegular, size: size)
    }
}

extension CTExtension where BaseType == UIFont {
    public static func loadFont(_ fontName: FontName, size: CGFloat) -> UIFont {
        switch fontName {
        case .default:
            return UIFont.systemFont(ofSize: size)
        case .defaultMedium:
            return UIFont.systemFont(ofSize: size, weight: .medium)
        case .defaultRegular:
            return UIFont.systemFont(ofSize: size, weight: .regular)
        }
    }
}
