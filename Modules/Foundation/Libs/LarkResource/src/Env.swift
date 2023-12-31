//
//  Env.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/6.
//

import UIKit
import Foundation

/// 环境参数
public struct Env: Hashable {

    public static var defaultTheme: Atomic<String> = Atomic<String>("light")

    public static var defaultLanguage: Atomic<String> = Atomic<String>("en")

    /// 当前模块名
    public var moduleName: String

    /// 皮肤
    public var theme: String

    /// 设备
    public var device: UIUserInterfaceIdiom

    /// 语言
    public var language: String

    /// 分辨率
    public var multiply: CGFloat

    public init(
        moduleName: String = "",
        theme: String = Env.defaultTheme.value,
        device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        language: String = Env.defaultLanguage.value,
        multiply: CGFloat = UIScreen.main.scale
    ) {
        self.moduleName = moduleName
        self.theme = theme
        self.device = device
        self.language = language
        self.multiply = multiply
    }
}
