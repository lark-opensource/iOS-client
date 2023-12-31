//
//  UDDialog.swift
//  UniverseDesignDialog
//
//  Created by 姚启灏 on 2020/10/14.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignButton
import UniverseDesignTheme

public extension UDDialog {

    enum Layout {

        public static var dialogWidth: CGFloat {
            let baseWidths: (screenWidth: CGFloat, dialogWidth: CGFloat) = (414, 303)
            var currentBounds: CGRect
            if let window = UIApplication.shared.delegate?.window {
                currentBounds = window?.bounds ?? UIScreen.main.bounds
            } else {
                currentBounds = UIScreen.main.bounds
            }
            if currentBounds.width >= baseWidths.screenWidth {
                return baseWidths.dialogWidth
            } else {
                // app宽度不足414，弹窗左右边距固定为36
                return ceil(currentBounds.width - 72)
            }
        }
    }
}

open class UDDialog: UIViewController {
    @available(iOS 13.0, *)
    open override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        didSet {
            self.transitioning.dimmingView.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }
    }

    public let config: UDDialogUIConfig

    /// 是否支持自动旋转
    @available(*, deprecated, message: "Use overrideSupportedInterfaceOrientations to support More Orientation")
    public var isAutorotatable: Bool = false {
        didSet {
            if isAutorotatable {
                overrideSupportedInterfaceOrientations = .allButUpsideDown
            } else {
                overrideSupportedInterfaceOrientations = .portrait
            }
        }
    }

    /// 业务指定 UDDialog 支持的旋转方向，默认为 .portrait
    public var overrideSupportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait

    var titleLabel: UILabel?

    private var contentView: UIView?

    private var contentIsText = false

    private lazy var contentsContainer: UIView = UIView()

    lazy var buttonContainer: UIStackView = UIStackView()

    private var horizontalLine = UIView()

    private var transitioning: UDDialogTransitioningDelegate = UDDialogTransitioningDelegate()

    private lazy var dialog: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    var buttons: [UDDialogButton] = []

    private let buttonHeight = 50

    private var dialogWidth: CGFloat { Layout.dialogWidth }

    private let horizontalPadding: CGFloat = 20

    public init(config: UDDialogUIConfig = UDDialogUIConfig()) {
        self.config = config

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = transitioning
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return overrideSupportedInterfaceOrientations
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(dialog)

        horizontalLine.backgroundColor = config.splitLineColor
        dialog.addSubview(horizontalLine)
        dialog.addSubview(contentsContainer)

        if let titleLabel = titleLabel {
            contentsContainer.addSubview(titleLabel)
        }

        if let contentView = contentView {
            contentsContainer.addSubview(contentView)
        }

        layoutSubviews()
        setConfig()
        observeKeyboard()
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onKeyboardShowOrHide(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onKeyboardShowOrHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // 因为iphone上键盘切换时,键盘高度可能会发生改变,因此在手机上监听键盘尺寸变化,iPad上键盘不存在尺寸变化,所以不做监听
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onKeyboardFrameDidChanged(_:)),
                                                   name: UIResponder.keyboardDidChangeFrameNotification,
                                                   object: nil)
        }
    }

    private func setConfig() {
        if let titleLabel = titleLabel, let titleText = titleLabel.text {
            titleLabel.textColor = config.titleColor
            titleLabel.font = config.titleFont
            titleLabel.numberOfLines = config.titleNumberOfLines
            let baselineOffset = (config.titleFont.figmaHeight - config.titleFont.lineHeight) / 2.0 / 2.0
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = config.titleFont.figmaHeight
            paragraphStyle.maximumLineHeight = config.titleFont.figmaHeight
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = config.titleAlignment
            titleLabel.attributedText = NSAttributedString(
                string: titleText,
                attributes: [
                    .baselineOffset: baselineOffset,
                    .paragraphStyle: paragraphStyle,
                    .font: config.titleFont,
                    .foregroundColor: config.titleColor,
                ]
              )
        }

        self.dialog.backgroundColor = config.backgroundColor
        self.dialog.layer.cornerRadius = config.cornerRadius
    }

    private func layoutSubviews(willTransition: Bool = false) {

        if let titleLabel = titleLabel {
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            if contentView == nil {
                titleLabel.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview().offset(24)
                    make.bottom.equalToSuperview().offset(-24)
                    make.width.equalTo(dialogWidth - 2 * horizontalPadding)
                    make.centerX.equalToSuperview()
                }
            } else {
                titleLabel.snp.remakeConstraints { (make) in
                    if contentView != nil && !contentIsText {
                        make.top.equalToSuperview().offset(20)
                    } else {
                        make.top.equalToSuperview().offset(24)
                    }
                    make.width.equalToSuperview().offset(-2 * horizontalPadding)
                    make.centerX.equalToSuperview()
                }
            }
        }

        if let contentView = contentView {
            let top = titleLabel?.snp.bottom ?? contentsContainer.snp.top
            contentView.snp.remakeConstraints { (make) in
                make.top.equalTo(top)
                make.bottom.centerX.width.equalToSuperview()
            }
            if titleLabel == nil && contentIsText {
                let contentLabel = contentView.subviews.first?.subviews.first
                contentLabel?.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                        .inset(UIEdgeInsets(top: 24, left: horizontalPadding, bottom: 24, right: horizontalPadding))
                }
            }
        }

        contentsContainer.snp.remakeConstraints { (make) in
            make.leading.right.top.equalToSuperview()
            make.bottom.equalTo(horizontalLine.snp.top)
        }

        horizontalLine.snp.remakeConstraints { (make) in
            make.height.equalTo(1)
            make.top.equalTo(contentsContainer.snp.bottom)
            make.width.centerX.equalToSuperview()
        }

        if !willTransition {
            layoutButtons()
        }

        dialog.snp.remakeConstraints { (make) in
            make.centerY.centerX.equalToSuperview()
            make.width.equalTo(dialogWidth)
            make.top.greaterThanOrEqualToSuperview().offset(36)
            make.bottom.lessThanOrEqualToSuperview().offset(-36)
        }
    }

    private func layoutButtons() {
        buttonContainer.removeFromSuperview()
        buttonContainer = UIStackView()
        dialog.addSubview(buttonContainer)

        buttonContainer.alignment = .center
        buttonContainer.distribution = .fill

        var isOverWidth = false

        switch self.config.style {
        case .normal:
            if buttons.count > 2 {
                addVerticalButtons()
            } else {
                let buttonWidth = CGFloat((dialogWidth - CGFloat(buttons.count - 1)) / CGFloat(buttons.count))
                for button in buttons {
                    isOverWidth = button.isOverWidth(maxWidth: buttonWidth)
                    if isOverWidth {
                        break
                    }
                }

                if isOverWidth {
                    addVerticalButtons()
                } else {
                    addHorizontalButtons()
                }

            }
        case .horizontal:
            addHorizontalButtons()
        case .vertical:
            addVerticalButtons()
        }

        buttonContainer.snp.remakeConstraints { (make) in
            make.top.equalTo(horizontalLine.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func addHorizontalButtons() {
        buttonContainer.axis = .horizontal

//        let sorted = buttons.sorted { button1, button2 in
//            return button1.priority.rawValue > button2.priority.rawValue
//        }
//        buttons = sorted

        let buttonWidth = CGFloat((dialogWidth - CGFloat(buttons.count - 1)) / CGFloat(buttons.count))
        for i in 0..<buttons.count {
            buttonContainer.addArrangedSubview(buttons[i])
            buttons[i].snp.remakeConstraints { (make) in
                make.height.equalTo(buttonHeight)
                make.width.equalTo(buttonWidth)
            }
            if i != buttons.count - 1 {
                let verticalLine = UIView()
                verticalLine.backgroundColor = config.splitLineColor
                verticalLine.snp.remakeConstraints { (make) in
                    make.height.equalTo(buttonHeight)
                    make.width.equalTo(1)
                }
                buttonContainer.addArrangedSubview(verticalLine)
            }
        }
    }

    private func addVerticalButtons() {
        buttonContainer.axis = .vertical

//        let sorted = buttons.sorted { button1, button2 in
//            return button1.priority.rawValue < button2.priority.rawValue
//        }
//        buttons = sorted

        for i in 0..<buttons.count {
            buttonContainer.addArrangedSubview(buttons[i])
            buttons[i].snp.remakeConstraints { (make) in
                make.height.equalTo(buttonHeight)
                make.width.equalToSuperview()
            }
            if i != buttons.count - 1 {
                let verticalLine = UIView()
                verticalLine.backgroundColor = config.splitLineColor
                buttonContainer.addArrangedSubview(verticalLine)
                verticalLine.snp.remakeConstraints { (make) in
                    make.height.equalTo(1)
                    make.width.equalToSuperview()
                }
            }
        }
    }

    private func layoutContentView(view: UIView, contentMargin: UIEdgeInsets) {
        if contentView == nil {
            contentView = UIView()
            contentView?.backgroundColor = .clear
            contentView?.clipsToBounds = true
        }

        if let contentView = contentView {
            for subView in contentView.subviews {
                subView.removeFromSuperview()
            }
            let wrapperView = UIView()
            wrapperView.backgroundColor = .clear
            contentView.addSubview(wrapperView)
            wrapperView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.bottom.equalToSuperview().priority(750)
                make.width.lessThanOrEqualTo(UIScreen.main.bounds.width - 2 * horizontalPadding).priority(.required)
            }
            wrapperView.addSubview(view)
            view.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview().inset(contentMargin)
                make.centerX.equalToSuperview()
                make.height.lessThanOrEqualToSuperview().priority(1000)
            }
        }
    }

    @objc
    private func onKeyboardShowOrHide(_ notify: Notification) {
        guard let userinfo = notify.userInfo else { return }
        guard dialog.superview != nil else { return }
        if notify.name == UIResponder.keyboardWillShowNotification {
            self.onKeyboardShow(userinfo)
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            self.remakeDialogFitToCenter()
        }
    }

    @objc
    private func onKeyboardFrameDidChanged(_ notify: Notification) {
        guard let userinfo = notify.userInfo else { return }
        guard dialog.superview != nil else { return }
        if userinfo[UIResponder.keyboardFrameEndUserInfoKey] is CGRect {
            self.onKeyboardShow(userinfo)
        }
    }

    /// 键盘弹出时，对判断是否需要对Dialog进行上移操作
    private func onKeyboardShow(_ userinfo: [AnyHashable : Any]) {
        if let keyboardRect = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            guard let superview = dialog.superview else { return }
            let addedDifference = dialog.frame.midY - superview.frame.midY
            let difference = keyboardRect.minY - dialog.frame.maxY
            // dialog是否能移到中间
            // 满足 1. dialog当前不在中间 2. dialog移到中间后和键盘没有遮挡
            let dialogIsNotInCenter = addedDifference < 0
            let dialogCanFitToCenter = (superview.frame.midY + dialog.frame.height / 2) < keyboardRect.minY
            if difference <= 0 {
                self.remakeDialogFitToKeyBoard(-keyboardRect.height)
            } else if dialogIsNotInCenter && dialogCanFitToCenter {
                self.remakeDialogFitToCenter()
            }
        }
    }
    /// 键盘与 Dialog 不重叠或键盘不存在时，Dialog 居中
    private func remakeDialogFitToCenter() {
        UIView.animate(withDuration: 0.25) {
            self.dialog.snp.remakeConstraints { (make) in
                make.centerY.centerX.equalToSuperview()
                make.width.equalTo(self.dialogWidth)
                make.top.greaterThanOrEqualToSuperview().offset(36)
                make.bottom.lessThanOrEqualToSuperview().offset(-36)
            }
            self.view.layoutIfNeeded()
        }
    }

    /// 键盘与 Dialog 重合且处于横屏时，Dialog 顶部距离屏幕顶部最少 12 px
    private func remakeDialogFitToKeyBoard(_ height: CGFloat) {
        UIView.animate(withDuration: 0.25) {
            self.dialog.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(self.dialogWidth)
                if UDDialog.isLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                    make.top.greaterThanOrEqualToSuperview().offset(12)
                    make.bottom.lessThanOrEqualToSuperview().offset(-36)
                } else {
                    make.top.greaterThanOrEqualToSuperview().offset(36)
                    make.bottom.equalToSuperview().offset(height)
                }
            }
            self.view.layoutIfNeeded()
        }
    }

    open override func viewWillTransition(to size: CGSize,
                                          with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        layoutSubviews(willTransition: true)
    }

    // Enter 快捷键选中最后一个按钮
    open override var canBecomeFirstResponder: Bool {
        true
    }
    open override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: "\u{D}", modifierFlags: [], action: #selector(selectLastButton))]
    }
    @objc
    private func selectLastButton() {
        guard let alertButton = self.buttons.last else { return }
        alertButton.action()
    }

    private static var isLandscape: Bool {
        if let isLandscape = UDDialog.getCurrentInterfaceOrientation()?.isLandscape {
            return isLandscape
        }
        let screenSize = UDDialog.getCurrentScreen().bounds
        return screenSize.width > screenSize.height
    }

    private static func getCurrentInterfaceOrientation() -> UIInterfaceOrientation? {
        if #available(iOS 13, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: { return $0.session.role == .windowApplication }) as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        return UIApplication.shared.statusBarOrientation
    }

    private static func getCurrentScreen() -> UIScreen {
        if #available(iOS 13, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: { return $0.session.role == .windowApplication }) as? UIWindowScene {
            return windowScene.screen
        }
        return UIScreen.main
    }
}

public extension UDDialog {
    /// 添加标题
    ///
    /// - Parameters:
    ///   - text: 标题文本
    func setTitle(text: String) {
        if titleLabel == nil {
            titleLabel = UILabel()
        }

        titleLabel?.text = text
    }
}

public extension UDDialog {
    /// 设置自定义View内容，容器四边是标题下方，按钮横线，模态框左右两边。会自动检测是否有文字输入以移动弹窗
    ///
    /// - Parameters:
    ///   - view: 自定义view
    ///   - padding: 距离容器四边的padding [Default = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)]
    func setContent(view: UIView) {
        contentIsText = false
        layoutContentView(view: view, contentMargin: config.contentMargin)
    }

    /// 设置文字内容 默认居中灰字，效果类似系统Alert
    ///
    /// - Parameters:
    ///   - text: 内容文本
    ///   - color: 文本颜色 [Default = UIColor.lk.N900]
    ///   - font: 文本字体 [Default = UIFont.ud.body0， 16]
    ///   - alignment: 文本对齐方式 [Default = .center，当超过两行时显示为.left]
    ///   - lineSpacing: // 废弃，设置不生效
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    func setContent(
        text: String,
        color: UIColor = UIColor.ud.textTitle,
        font: UIFont = UIFont.ud.body0(.fixed),
        alignment: NSTextAlignment = .center,
        lineSpacing: CGFloat = 4,
        numberOfLines: Int = 0) {
            let labelWidth = dialogWidth - 2 * horizontalPadding
            let textSize = CGSize(width: labelWidth, height: CGFloat.infinity)
            let textHeight: CGFloat = getTextWidthAndHeight(text: text,
                                                            font: font,
                                                            textSize: textSize).height
            let textFontHeight = font.figmaHeight

            let baselineOffset = (font.figmaHeight - font.lineHeight) / 2.0 / 2.0
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = font.figmaHeight
            paragraphStyle.maximumLineHeight = font.figmaHeight
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = (textHeight > 2 * textFontHeight) ? .left : alignment
            let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: color,
                        .paragraphStyle: paragraphStyle,
                        .baselineOffset: baselineOffset
                    ]
            setContent(attributedText: NSAttributedString(string: text, attributes: attributes),
                       numberOfLines: numberOfLines)
    }

    /// 设置富文本内容
    ///
    /// - Parameters:
    ///   - attributedText: 内容富文本
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    func setContent(attributedText: NSAttributedString, numberOfLines: Int = 0) {
        let contentLabel = UILabel()
        contentLabel.attributedText = attributedText
        contentLabel.numberOfLines = numberOfLines
        contentIsText = true

        contentLabel.snp.remakeConstraints { (make) in
            make.width.lessThanOrEqualTo(dialogWidth - 2 * horizontalPadding)
        }

        layoutContentView(view: contentLabel,
                          contentMargin: UIEdgeInsets(top: 12, left: 20, bottom: 24, right: 20))
    }

    @discardableResult
    internal func addButton(
        text: String,
        color: UIColor = UIColor.ud.primaryContentDefault,
        font: UIFont = UIFont.ud.title4(.fixed),
        numberOfLines: Int = 1,
        priority: UDButtonPriority,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
            let button = UDDialogButton(text: text, textColor: color, priority: priority) { [weak self] in
                let shouldDismiss = dismissCheck()
                if shouldDismiss {
                    guard let self = self else { return }
                    if #available(iOS 13.0, *) {
                        self.dismiss(animated: true, completion: dismissCompletion)
                    } else {
                        if self.presentingViewController == nil {
                            dismissCompletion?()
                        } else {
                            self.dismiss(animated: true, completion: dismissCompletion)
                        }
                    }
                }
            }

            button.button.titleLabel?.font = font
            button.button.titleLabel?.numberOfLines = numberOfLines

            let baselineOffset = (font.figmaHeight - font.lineHeight) / 2.0 / 2.0
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = font.figmaHeight
            paragraphStyle.maximumLineHeight = font.figmaHeight
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = .center
            button.button.titleLabel?.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .baselineOffset: baselineOffset,
                    .paragraphStyle: paragraphStyle,
                    .font: font,
                    .foregroundColor: color
                ]
              )
            buttons.append(button)
            return button.button
    }
}

// 按钮部分接口实现
public extension UDDialog {
    /// 添加一个主要按钮 默认蓝字
    @available(*, deprecated, message: "Use addPrimaryButton, addSecondaryButton or addDestructiveButton instead. For more message，please consult Dong Wei")
    @discardableResult
    func addButton(
        text: String,
        color: UIColor = UIColor.ud.primaryContentDefault,
        font: UIFont = UIFont.ud.title4(.fixed),
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        return addButton(text: text,
                         color: color,
                         font: font,
                         numberOfLines: numberOfLines,
                         priority: .priority,
                         dismissCheck: dismissCheck,
                         dismissCompletion: dismissCompletion)
    }

    /// 添加一个主要按钮 默认蓝字
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - font: 文本字体 [Default = title4,  17]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @discardableResult
    func addPrimaryButton(
        text: String,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        return addButton(text: text,
                         color: UIColor.ud.primaryContentDefault,
                         numberOfLines: numberOfLines,
                         priority: .priority,
                         dismissCheck: dismissCheck,
                         dismissCompletion: dismissCompletion)
    }

    /// 添加一个灰字的次要操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @discardableResult
    func addSecondaryButton(
        text: String,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        return addButton(text: text,
                         color: UIColor.ud.textTitle,
                         numberOfLines: numberOfLines,
                         priority: .secondary,
                         dismissCheck: dismissCheck,
                         dismissCompletion: dismissCompletion)
    }

    /// 添加一个红字的警惕性操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    @discardableResult
    func addDestructiveButton(
        text: String,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        return addButton(text: text,
                         color: UIColor.ud.functionDangerContentDefault,
                         numberOfLines: numberOfLines,
                         priority: .destructive,
                         dismissCheck: dismissCheck,
                         dismissCompletion: dismissCompletion)
    }
}

private extension UDDialog {
    /// 获取文本的宽高
    private func getTextWidthAndHeight(text: String, font: UIFont, textSize: CGSize) -> CGRect {
        var size: CGRect
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        size = (text as NSString).boundingRect(with: textSize,
                                               options: [.usesLineFragmentOrigin],
                                               attributes: [
                                                    .font: font,
                                                    .baselineOffset : baselineOffset,
                                                    .paragraphStyle : mutableParagraphStyle
                                                    ],
                                               context: nil)
        return size
    }
}
