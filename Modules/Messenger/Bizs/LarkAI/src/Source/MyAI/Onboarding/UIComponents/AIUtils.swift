//
//  AIUtils.swift
//  LarkAI
//
//  Created by Hayden on 2023/6/6.
//

import UIKit
import FigmaKit
import UniverseDesignColor
import UniverseDesignInput

enum AIUtils {

    /// 创建 AI 样式的极光渐变色 UIButton
    static func makeAIButton() -> FKGradientButton {
        let button = FKMultiLineGradientButton()
        button.colorStyle = .solidGradient(
            background: UDColor.AIPrimaryFillDefault,
            highlightedBackground: UDColor.AIPrimaryFillPressed,
            disabledBackground: UDColor.AIPrimaryFillLoading
        )
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.cornerRadius = 6
        button.setInsets(iconTitleSpacing: 0, contentInsets: UIEdgeInsets(edges: 12))
        return button
    }

    /// 创建 AI 名称输入框，已经定好样式和字数限制规则
    static func makeAINameTextField() -> UDTextField {
        let textField = UDTextField()
        textField.layer.cornerRadius = 6
        textField.placeholder = BundleI18n.LarkAI.MyAI_IM_Onboarding_ChooseName_Placeholder
        textField.config.isShowBorder = true
        textField.config.clearButtonMode = .whileEditing
        textField.config.borderColor = UIColor.ud.lineBorderComponent
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        // AI 名称字数限制
        textField.config.maximumTextLength = 16
        // 自定义计数规则
        textField.config.countingRule = { char in
            char.isASCII ? 0.5 : Float(char.unicodeScalars.count)
        }
        return textField
    }

    /// 创建极光背景视图，一般作为 UIViewController 的根 View
    static func makeAuroraBackgroundView() -> AuroraView {
        // swiftlint:disable init_color_with_token
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: UIColor(red: 156 / 255.0, green: 168 / 255.0, blue: 255 / 255.0, alpha: 0.5),
                            frame: CGRect(x: -21, y: 3, width: 250, height: 397),
                            opacity: 1),
            subBlob: .init(color: UIColor(red: 120 / 255.0, green: 255 / 255.0, blue: 239 / 255.0, alpha: 0.5),
                           frame: CGRect(x: 70, y: 445, width: 190, height: 450),
                           opacity: 1),
            reflectionBlob: .init(color: UIColor(red: 66 / 255.0, green: 153 / 255.0, blue: 255 / 255.0, alpha: 0.6),
                                  frame: CGRect(x: 170, y: 247, width: 202, height: 820),
                                  opacity: 1)
        ))
        // swiftlint:enable init_color_with_token
        auroraView.blobsBlurRadius = 100
        auroraView.blobsOpacity = 0.2
        auroraView.backgroundColor = UIColor.ud.bgBody
        return auroraView
    }
}

enum AICons {
    static var iPadModalSize: CGSize { CGSize(width: 420, height: 650) }
}
