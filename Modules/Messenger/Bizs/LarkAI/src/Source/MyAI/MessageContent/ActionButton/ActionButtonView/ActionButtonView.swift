//
//  ActionButtonView.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/5/15.
//

import Foundation
import UIKit
import LarkAIInfra
import LarkMessengerInterface
import LarkRichTextCore
import UniverseDesignColor

public protocol ActionButtonViewDelegate: AnyObject {
    /// 点击了某个按钮
    func actionButtonClick(button: MyAIChatModeConfig.ActionButton, buttonView: ActionButtonView)
}

final public class ActionButtonView: UIView {
    private static let buttonBeginTag: Int = 10_000
    /// 文档内容padding
    public static let contentPadding: UIEdgeInsets = UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16)
    /// 横向间距
    public static let horizontalSpacing: CGFloat = 8
    /// 纵向间距
    public static let verticalSpacing: CGFloat = 8
    /// 点击回调
    public weak var delegate: ActionButtonViewDelegate?
    /// 持有一下按钮，回调时使用
    public var actionButtons: [MyAIChatModeConfig.ActionButton] = []

    /// 设置内容，内部不持有ActionButtonLayout，做到单项数据流
    public func setup(layout: ActionButtonLayout) {
        self.actionButtons = layout.actionButtons.map({ $0.0 })
        // 获取到所有的子视图，方便复用
        var buttons: [UIButton] = []
        self.subviews.forEach({ if let ud = $0 as? UIButton { buttons.append(ud) }; $0.removeFromSuperview() })

        var buttonTag: Int = ActionButtonView.buttonBeginTag
        layout.actionButtons.forEach { (button, frame) in
            // 为啥不用UDButton：因为UDButton内部会设置约束，而我们这个场景frame已经算出来了，不需要增加计算复杂度
            let currButton: UIButton = buttons.isEmpty ? UIButton(type: .custom) : buttons.removeFirst()
            currButton.frame = frame
            // 边框、背景色
            currButton.layer.borderWidth = 1
            currButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            currButton.layer.cornerRadius = 6
            currButton.backgroundColor = UIColor.ud.bgFloat
            // 内容
            currButton.setTitle(button.title, for: .normal)
            currButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            currButton.titleLabel?.numberOfLines = 1
            currButton.titleLabel?.font = UIFont.ud.body0
            // 点击事件
            currButton.tag = buttonTag; buttonTag += 1
            currButton.addTarget(self, action: #selector(self.actionButtonClick(button:)), for: .touchUpInside)
            self.addSubview(currButton)
        }
    }

    @objc
    private func actionButtonClick(button: UIButton) {
        let typeIndex = button.tag - ActionButtonView.buttonBeginTag
        guard typeIndex < self.actionButtons.count else { return }

        self.delegate?.actionButtonClick(button: self.actionButtons[typeIndex], buttonView: self)
    }
}
