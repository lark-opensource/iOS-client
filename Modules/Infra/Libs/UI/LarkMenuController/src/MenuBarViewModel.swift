//
//  MenuBarViewModel.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation

/// MenuActionImage
public protocol MenuActionImage {
    /// set action
    func setActionImage(imageView: UIImageView, enable: Bool)
}

public struct MenuActionAsyncImage: MenuActionImage {

    public let imageBlock: (UIImageView) -> Void
    public init(imageBlock: @escaping (UIImageView) -> Void) {
        self.imageBlock = imageBlock
    }

    public func setActionImage(imageView: UIImageView, enable: Bool) {
        imageBlock(imageView)
    }
}

/// MenuActionItem
public struct MenuActionItem {
    /// name
    public var name: String
    /// image
    public var image: MenuActionImage
    /// params
    public var params: [String: Any]

    /// action
    public var action: (MenuActionItem) -> Void
    /// disable状态下的操作
    public var disableAction: ((MenuActionItem) -> Void)?

    /// UI上Item的使能端，当为true时表示功能开启，为false时表示功能关闭
    public var enable: Bool = true
    /// 是否展示红点
    public var isShowDot: Bool = false

    /// init
    public init(
        name: String,
        image: MenuActionImage,
        params: [String: Any] = [:],
        enable: Bool,
        action: @escaping (MenuActionItem) -> Void,
        disableAction: ((MenuActionItem) -> Void)? = nil) {
        self.name = name
        self.image = image
        self.action = action
        self.disableAction = disableAction
        self.enable = enable
        self.params = params
    }

    /// init
    public init(
        name: String,
        image: MenuActionImage,
        params: [String: Any] = [:],
        enable: Bool,
        isShowDot: Bool = false,
        action: @escaping (MenuActionItem) -> Void,
        disableAction: ((MenuActionItem) -> Void)? = nil) {
        self.name = name
        self.image = image
        self.action = action
        self.disableAction = disableAction
        self.enable = enable
        self.params = params
        self.isShowDot = isShowDot
    }
}

extension UIImage: MenuActionImage {
    public func setActionImage(imageView: UIImageView, enable: Bool) {
        // copy frm 新菜单icon设置规则
        imageView.image = self
        imageView.alpha = enable ? 1 : 0.3
    }
}
