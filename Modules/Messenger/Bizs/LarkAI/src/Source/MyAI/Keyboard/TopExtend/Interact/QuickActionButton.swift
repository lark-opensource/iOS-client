//
//  QuickActionButton.swift
//  LarkAI
//
//  Created by Hayden on 10/7/2023.
//

import UIKit
import FigmaKit
import ServerPB
import LarkAIInfra
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignToast
import LarkMessengerInterface

class QuickActionButton: UIButton {

    let quickAction: AIQuickAction

    init(with quickAction: AIQuickAction) {
        self.quickAction = quickAction
        super.init(frame: .zero)
        layer.masksToBounds = true
        layer.cornerRadius = Cons.buttonCornerRadius
        // layer.borderWidth = 1
        layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        titleLabel?.font = UIFont.ud.body2
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentEdgeInsets = UIEdgeInsets(horizontal: Cons.quickActionButtonHInset, vertical: 0)

        setTitle(quickAction.displayName, for: .normal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        // UX：快捷指令按钮最大宽度不超过 600px
        self.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Cons.quickActionButtonMaxWidth)
        }
        /* 需求改来改去，代码不删了，这里是为了让 Button 宽度适配屏幕宽度
        var maxWidth: CGFloat = Cons.quickActionButtonMaxWidth
        if #available(iOS 13.0, *),
            let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first {
            maxWidth = window.bounds.width - Cons.buttonHeight - Cons.hMargin * 2 - Cons.buttonSpacing
        } else if let window = UIApplication.shared.keyWindow {
            maxWidth = window.bounds.width - Cons.buttonHeight - Cons.hMargin * 2 - Cons.buttonSpacing
        }
        maxWidth = max(Cons.quickActionButtonMinWidth, min(Cons.quickActionButtonMaxWidth, maxWidth))
        self.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(maxWidth)
        }
         */
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
            updateAuroraColors()
        }
    }

    override var bounds: CGRect {
        didSet {
            guard bounds != oldValue else { return }
            updateAuroraColors()
        }
    }

    private func updateAuroraColors() {
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.bgBody, size: .square(1), scale: 1), for: .normal)
        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
            // 设置 Press 态的文字颜色
            let textColor = UIColor.ud.AIPrimaryContentPressed.toColor(withSize: bounds.size)
            setTitleColor(textColor, for: .highlighted)
            // 设置 Press 态的背景颜色
            let backgroundLayer = FKGradientLayer.fromPattern(UIColor.ud.AIPrimaryFillTransparent02)
            let backgroundImage = UIImage.fromGradient(backgroundLayer, frame: bounds)
            setBackgroundImage(backgroundImage, for: .highlighted)
        } else {
            // 设置 Press 态的文字颜色
            let textColor = UIColor.ud.AIPrimaryFillDefault.toColor(withSize: bounds.size)
            setTitleColor(textColor, for: .highlighted)
            // 设置 Press 态的背景颜色
            let backgroundLayer = FKGradientLayer.fromPattern(UIColor.ud.AIPrimaryFillTransparent02)
            let backgroundImage = UIImage.fromGradient(backgroundLayer, frame: bounds)
            setBackgroundImage(backgroundImage, for: .highlighted)
        }
    }
}

private typealias Cons = MyAIInteractView.Cons
