//
//  UDFontAppearance.swift
//  UniverseDesignFont
//
//  Created by 白镜吾 on 2023/3/21.
//

import UIKit

public enum UDFontAppearance {
    /// 自定义字体信息
    public static var customFontInfo: CustomFontInfo?
    /// 是否使用了自定义字体
    public static var isCustomFont: Bool { return UDFontAppearance.customFontInfo != nil }
    /// 是否启用了粗体文本能力
    public static var isBoldTextEnabled: Bool = UIAccessibility.isBoldTextEnabled
}

public struct CustomFontInfo {

    // 资源所在 bundle
    public var bundle: Bundle

    // 字体名称
    public var customFontName: String

    // Regualr  字体文件路径
    public var regularFilePath: String

    // Meduim   字体文件路径
    public var mediumFilePath: String

    // SemiBold 字体文件路径
    public var semiBoldFilePath: String

    // Bold 字体文件路径
    public var boldFilePath: String

    public init(bundle: Bundle, customFontName: String, regularFilePath: String, mediumFilePath: String, semiBoldFilePath: String, boldFilePath: String) {
        self.bundle = bundle
        self.customFontName = customFontName
        self.regularFilePath = regularFilePath
        self.mediumFilePath = mediumFilePath
        self.semiBoldFilePath = semiBoldFilePath
        self.boldFilePath = boldFilePath
    }
}
