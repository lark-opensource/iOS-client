//
//  QuickActionListItemView.swift
//  LarkAI
//
//  Created by Hayden on 23/8/2023.
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

class QuickActionListItemView: UIButton {

    let quickAction: AIQuickActionModel

    init(with quickAction: AIQuickActionModel) {
        self.quickAction = quickAction
        super.init(frame: .zero)
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        layer.cornerRadius = 8.auto()
        titleLabel?.font = UIFont.ud.body0
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentEdgeInsets = UIEdgeInsets(horizontal: Cons.quickActionButtonHInset, vertical: 0)

        setTitle(quickAction.displayName, for: .normal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        isMultipleTouchEnabled = false
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
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.udtokenBtnSeBgNeutralPressed, size: .square(1), scale: 1), for: .highlighted)
        /* 彩色按钮
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
         */
    }
}

extension QuickActionListItemView {

    enum Cons {
        static var buttonHeight: CGFloat { UIFont.ud.body0.figmaHeight + 8 * 2 }
        static var quickActionButtonHInset: CGFloat { 16 }
        static var quickActionButtonMinWidth: CGFloat { 200 }
        static var quickActionButtonMaxWidth: CGFloat { 580 }
    }
}

class QuickActionListButton: UIView {

    var quickAction: AIQuickActionModel

    var onTapped: ((AIQuickActionModel) -> Void)?

    var isHighlighted: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = Cons.font
        label.lineBreakMode = Cons.lineBreakMode
        if #available(iOS 14.0, *) {
            label.lineBreakStrategy = Cons.lineBreakStrategy
        }
        return label
    }()

    init(with quickAction: AIQuickActionModel) {
        self.quickAction = quickAction
        super.init(frame: .zero)
        setupSubview()
        setupGesture()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubview() {
        layer.masksToBounds = true
        layer.borderWidth = Cons.borderWidth
        layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        layer.cornerRadius = Cons.cornerRadius
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Cons.buttonHInset)
            make.right.equalToSuperview().offset(-Cons.buttonHInset)
            make.top.equalToSuperview().offset(Cons.buttonVInset)
            make.bottom.equalToSuperview().offset(-Cons.buttonVInset)
        }
        label.text = quickAction.displayName
        label.numberOfLines = Cons.maxLinesOfText
    }

    private func setupGesture() {
        isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPressGesture)
    }

    private func updateAppearance() {
        backgroundColor = isHighlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.clear
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        isHighlighted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isHighlighted = false
        }
        // 处理点击事件的逻辑
        onTapped?(quickAction)
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            isHighlighted = true
        } else if gesture.state == .ended || gesture.state == .cancelled {
            isHighlighted = false
        }
    }

    enum Cons {
        static var font: UIFont { UIFont.ud.body0 }
        static var borderWidth: CGFloat { 1 }
        static var cornerRadius: CGFloat { 8 }
        static var buttonHInset: CGFloat { 12 }
        static var buttonVInset: CGFloat { 8 }
        static var buttonHeight: CGFloat { font.figmaHeight + buttonVInset * 2 }
        static var maxLinesOfText: Int { 0 }
        static func buttonHeight(withContent content: String, constraintWidth: CGFloat) -> CGFloat {
            let labelWidth = constraintWidth - buttonHInset * 2
            let contentHeight = heightForString(content, constrainedWidth: labelWidth)
            // 最大行数限制
            if maxLinesOfText != 0 {
                let twoLinesText = Array(repeating: " ", count: maxLinesOfText).joined(separator: "\n")
                let twoLinesHeight = twoLinesText.getHeight(font: font)
                let labelHeight = min(contentHeight, twoLinesHeight)
                return labelHeight + buttonVInset * 2
            } else {
                return contentHeight + buttonVInset * 2
            }
        }
        /// 精确计算文本高度，考虑到 `lineBreakMode` 和 `lineBreakStrategy`
        static func heightForString(_ string: String,
                                    constrainedWidth: CGFloat) -> CGFloat {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            if #available(iOS 14.0, *) {
                paragraphStyle.lineBreakStrategy = lineBreakStrategy
            }
            let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle]
            let constraintRect = CGSize(width: constrainedWidth, height: .greatestFiniteMagnitude)
            let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            return ceil(boundingBox.height)
        }
        @available(iOS 14.0, *)
        static var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy { .hangulWordPriority }
        static var lineBreakMode: NSLineBreakMode { .byWordWrapping }
    }
}
