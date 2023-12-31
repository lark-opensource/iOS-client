//
//  ActionButtonLayout.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/5/15.
//

import Foundation
import AsyncComponent
import LKRichView
import LarkAIInfra
import LarkRichTextCore
import LarkMessengerInterface

final public class ActionButtonLayout {
    /// 布局总大小
    public var size: CGSize = .zero
    /// 每个按钮的类型、大小
    public var actionButtons: [(button: MyAIChatModeConfig.ActionButton, frame: CGRect)] = []

    /// 展示所有按钮，直接平铺、换行即可
    public static func layoutForAll(props: ActionButtonViewProps, size: CGSize) -> ActionButtonLayout {
        // 组装结果
        let layout = ActionButtonLayout()

        // 每一行最大的宽度
        var maxLineWidth: CGFloat = 0
        // 当前行已经占用的宽度，最后一个按钮的Y值
        var currLineWidth: CGFloat = 0; var lastButtonY: CGFloat = 0
        props.actionButtons.forEach { button in
            // 计算当前按钮
            let title = NSMutableAttributedString(string: button.title)
            title.addAttribute(.font, value: UIFont.ud.body0, range: NSRange(location: 0, length: title.length))
            let titleSize = title.componentTextSize(for: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 1)
            var buttonSize = CGSize(width: titleSize.width + ActionButtonView.contentPadding.left + ActionButtonView.contentPadding.right, height: 32)
            // 按钮最多只展示一行
            buttonSize.width = min(buttonSize.width, size.width)
            // 如果当前行能展示下，则直接展示
            if ((currLineWidth == 0) ? 0 : (currLineWidth + ActionButtonView.horizontalSpacing) + buttonSize.width) <= size.width {
                let buttonFrame = CGRect(origin: CGPoint(x: (currLineWidth == 0) ? 0 : (currLineWidth + ActionButtonView.horizontalSpacing), y: lastButtonY),
                                         size: CGSize(width: buttonSize.width, height: 32))
                layout.actionButtons.append((button, buttonFrame))
                currLineWidth = buttonFrame.maxX
            } else {
                // 如果当前行展示不下，则直接换行
                lastButtonY += 32; lastButtonY += ActionButtonView.verticalSpacing
                let buttonFrame = CGRect(origin: CGPoint(x: 0, y: lastButtonY), size: CGSize(width: buttonSize.width, height: 32))
                layout.actionButtons.append((button, buttonFrame))
                currLineWidth = buttonFrame.maxX
            }

            // 更新行最大宽度
            maxLineWidth = max(maxLineWidth, currLineWidth)
        }

        layout.size = CGSize(width: maxLineWidth, height: lastButtonY + 32)
        return layout
    }
}
