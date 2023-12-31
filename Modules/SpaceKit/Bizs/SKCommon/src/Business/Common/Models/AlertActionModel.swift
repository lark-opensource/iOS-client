//
//  AlertActionModel.swift
//  SKCommon
//
//  Created by huayufan on 2023/1/30.
//  

// 5.32迁移其他地方代码

import UIKit

/// 兼容 UI 和 Lark AlertController 的模型
public struct AlertActionModel {
    public let title: String
    public let handler: (() -> Void)?

    public private(set) var isDefault = false
    public var style: UIAlertAction.Style = .default
    public var isEnable = true
    public var needCheckDisableColor = false
    public var needRedPoint = false
    public var isCancel = false
    //是否默认置灰
    public var isSettingDisable = false

    public init(title: String, handler: (() -> Void)?) {
        self.title = title
        self.handler = handler
    }

    static func `default`() -> AlertActionModel {
        var model = AlertActionModel(title: "", handler: nil)
        model.isDefault = true
        return model
    }

    public func convert2UIAlertACtion() -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style) { (_) in
            self.handler?()
        }
        action.isEnabled = isEnable
        let color = UIColor.ud.N900
        if isEnable {
            action.setValue(color, forKey: "_titleTextColor")
        } else {
            action.setValue(color.withAlphaComponent(0.3), forKey: "_titleTextColor")
        }
        return action
    }
}
