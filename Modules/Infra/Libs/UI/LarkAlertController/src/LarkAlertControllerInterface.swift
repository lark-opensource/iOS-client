//
//  LarkAlertControllerInterface.swift
//  LarkAlertController
//
//  Created by PGB on 2019/7/18.
//

import UIKit
import Foundation
import SnapKit

/*
/// Lark模态弹窗对外接口
/// - 组件文档：https://bytedance.feishu.cn/space/doc/doccn1ILOvxc38Kt78zuUe7c6He
protocol LarkAlertControllerInterface {
    /// 添加标题 默认粗体黑字
    ///
    /// - Parameters:
    ///   - text: 标题文本
    ///   - color: 文本颜色 [Default = UIColor.ud.N900]
    ///   - font: 文本字体 [Default = UIFont.boldSystemFont(ofSize: 17)]
    ///   - alignment: 文本对齐方式 [Default = .center]
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    func setTitle(
        text: String,
        color: UIColor,
        font: UIFont,
        alignment: NSTextAlignment,
        numberOfLines: Int)

    /// 设置文字内容 默认居中灰字，效果类似系统Alert
    ///
    /// - Parameters:
    ///   - text: 内容文本
    ///   - color: 文本颜色 [Default = UIColor.ud.N900]
    ///   - font: 文本字体 [Default = UIFont.systemFont(ofSize: 16)]
    ///   - alignment: 文本对齐方式 [Default = .center]
    ///   - lineSpacing: 行间距 [Default = 4]
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    func setContent(
        text: String,
        color: UIColor,
        font: UIFont,
        alignment: NSTextAlignment,
        lineSpacing: CGFloat,
        numberOfLines: Int)

    /// 设置富文本内容
    ///
    /// - Parameters:
    ///   - attributedText: 内容富文本
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    func setContent(attributedText: NSAttributedString, numberOfLines: Int)

    /// 设置自定义View内容
    ///
    /// - Parameters:
    ///   - view: 自定义view
    ///   - padding: 距离容器四边的padding [Default = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)]
    func setContent(view: UIView, padding: UIEdgeInsets)

    /// 添加一个按钮 默认蓝字
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - color: 文本颜色 [Default = UIColor.ud.colorfulBlue]
    ///   - font: 文本字体 [Default = UIFont.systemFont(ofSize: 17)]
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @discardableResult
    func addButton(
        text: String,
        color: UIColor,
        font: UIFont,
        newLine: Bool,
        weight: Int,
        numberOfLines: Int,
        dismissCheck: @escaping () -> Bool,
        dismissCompletion: (() -> Void)?) -> UIButton

    /// 添加一个灰字的次要操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    func addSecondaryButton(
        text: String,
        newLine: Bool,
        weight: Int,
        numberOfLines: Int,
        dismissCheck: @escaping () -> Bool,
        dismissCompletion: (() -> Void)?)

    /// 添加一个灰字，文本为[Lark_Legacy_Cancel]的次要操作按钮
    ///
    /// - Parameters:
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    func addCancelButton(
        newLine: Bool,
        weight: Int,
        numberOfLines: Int,
        dismissCheck: @escaping () -> Bool,
        dismissCompletion: (() -> Void)?)

    /// 添加一个红字的警惕性操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    func addDestructiveButton(
        text: String,
        newLine: Bool,
        weight: Int,
        numberOfLines: Int,
        dismissCheck: @escaping () -> Bool,
        dismissCompletion: (() -> Void)?)

    /// 注册一个 View，在 viewDidLoad 时成为第一响应者
    ///
    /// - Parameters:
    ///   - view: 准备被注册的视图
    func registerFirstResponder(for view: UIView)
}
*/
