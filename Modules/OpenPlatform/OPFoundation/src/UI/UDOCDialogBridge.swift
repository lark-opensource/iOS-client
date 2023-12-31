//
//  UDOCDialogBridge.swift
//  TTMicroApp
//
//  Created by laisanpin on 2021/7/21.
//  该类是为了让OC使用主端提供的UDDialog而创建的转接类, UDDialog的其他方法也可以在这边进行桥接

import Foundation
import UniverseDesignDialog
import UniverseDesignTheme

@objc
open class UDOCDialogBridge: NSObject {
    @objc static public func createDialog() -> UDDialog {
        return UDDialog()
    }

    @objc static public func setTitle(dialog: UDDialog, text: String) {
        dialog.setTitle(text: text)
    }

    /// 设置自定义View内容，容器四边是标题下方，按钮横线，模态框左右两边。会自动检测是否有文字输入以移动弹窗
    ///
    /// - Parameters:
    ///   - view: 自定义view
    ///   - padding: 距离容器四边的padding [Default = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)]
    @objc static public func setContent(dialog: UDDialog, view: UIView) {
        dialog.setContent(view: view)
    }

    /// 设置文字内容 默认居中灰字，效果类似系统Alert
    ///
    /// - Parameters:
    ///   - text: 内容文本
    ///   - color: 文本颜色 [Default = UIColor.ud.N900]
    ///   - font: 文本字体 [Default = UIFont.systemFont(ofSize: 16)]
    ///   - alignment: 文本对齐方式 [Default = .center]
    ///   - lineSpacing: 行间距 [Default = 4]
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    @objc static public func setContent(dialog: UDDialog, text: String) {
        dialog.setContent(text: text)
    }

    /// 设置富文本内容
    ///
    /// - Parameters:
    ///   - attributedText: 内容富文本
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    @objc static public func setContent(dialog: UDDialog, attributedText: NSAttributedString) {
        dialog.setContent(attributedText: attributedText)
    }


    /// 添加一个按钮 默认蓝字
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - color: 文本颜色 [Default = UIColor.ud.colorfulBlue]
    ///   - font: 文本字体 [Default = UIFont.systemFont(ofSize: 17)]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @objc static public func addButton(dialog: UDDialog, text: String, dismissCompletion: (() -> Void)? = nil) {
        dialog.addPrimaryButton(text: text, dismissCompletion: dismissCompletion)
    }

    /// 添加一个灰字的次要操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @objc static public func addSecondaryButton(dialog: UDDialog, text: String, dismissCompletion: (() -> Void)? = nil) {
        dialog.addSecondaryButton(text: text, dismissCompletion: dismissCompletion)
    }

    /// 添加一个红字的警惕性操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @objc static public func addDestructiveButton(dialog: UDDialog, text: String, dismissCompletion: (() -> Void)? = nil) {
        dialog.addDestructiveButton(text: text, dismissCompletion: dismissCompletion)
    }
    
    /// 设置dialog是否支持横竖屏自动旋转
    ///
    /// - Parameters:
    ///   - enable: 支持横竖屏自动旋转
    @objc static public func setAutorotatable(dialog: UDDialog, enable: Bool) {
        dialog.isAutorotatable = enable
    }
}

@objc
open class UDOCLayerBridge: NSObject {
    @objc static public func setBoderColor(layer: CALayer, color: UIColor) {
        layer.ud.setBorderColor(color)
    }

    @objc static public func setShadowColor(layer: CALayer, color: UIColor) {
        layer.ud.setShadowColor(color)
    }

    @objc static public func setBackgroundColor(layer: CALayer, color: UIColor) {
        layer.ud.setBackgroundColor(color)
    }
}
