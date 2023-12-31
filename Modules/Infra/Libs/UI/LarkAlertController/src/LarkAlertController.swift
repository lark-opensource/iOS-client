//
//  LarkAlertController.swift
//  LarkAlertController
//
//  Created by PGB on 2019/7/14.
//

/*

import Foundation
import SnapKit

// 标题部分接口实现
extension LarkAlertController: LarkAlertControllerInterface {
    /// 添加标题 默认粗体黑字
    ///
    /// - Parameters:
    ///   - text: 标题文本
    ///   - color: 文本颜色 [Default = UIColor.ud.N900]
    ///   - font: 文本字体 [Default = UIFont.boldSystemFont(ofSize: 17)]
    ///   - alignment: 文本对齐方式 [Default = .center]
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    public func setTitle(
        text: String,
        color: UIColor = UIColor.ud.textTitle,
        font: UIFont = UIFont.boldSystemFont(ofSize: 17),
        alignment: NSTextAlignment = .center,
        numberOfLines: Int = 0) {
        if titleLabel == nil {
            titleLabel = UILabel()
        }

        titleLabel?.text = text
        titleLabel?.textColor = color
        titleLabel?.font = font
        titleLabel?.textAlignment = alignment
        titleLabel?.numberOfLines = numberOfLines
    }
}

// 内容部分接口实现
extension LarkAlertController {
    /// 设置文字内容 默认居中灰字，效果类似系统Alert
    ///
    /// - Parameters:
    ///   - text: 内容文本
    ///   - color: 文本颜色 [Default = UIColor.ud.N900]
    ///   - font: 文本字体 [Default = UIFont.systemFont(ofSize: 16)]
    ///   - alignment: 文本对齐方式 [Default = .center]
    ///   - lineSpacing: 行间距 [Default = 4]
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    public func setContent(
        text: String,
        color: UIColor = UIColor.ud.textTitle,
        font: UIFont = UIFont.systemFont(ofSize: 16),
        alignment: NSTextAlignment = .center,
        lineSpacing: CGFloat = 4,
        numberOfLines: Int = 0) {
        let paragraphStyle = NSMutableParagraphStyle()
        let textWidth = text.size(withAttributes: [NSAttributedString.Key.font: font]).width
        let labelWidth = alertWidth - 2 * horizontalPadding
        paragraphStyle.lineSpacing = textWidth > labelWidth ? lineSpacing : 0
        paragraphStyle.alignment = alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color
        ]

        setContent(attributedText: NSAttributedString(string: text, attributes: attributes),
                   numberOfLines: numberOfLines)
    }

    /// 设置富文本内容
    ///
    /// - Parameters:
    ///   - attributedText: 内容富文本
    ///   - numberOfLines: 最多展示行数 [Default = 0(无限制)]
    public func setContent(attributedText: NSAttributedString, numberOfLines: Int = 0) {
        let contentLabel = UILabel()
        contentLabel.attributedText = attributedText
        contentLabel.numberOfLines = numberOfLines
        contentIsText = true

        contentLabel.snp.makeConstraints { (make) in
            make.width.equalTo(alertWidth - 2 * horizontalPadding)
        }

        layoutContentView(view: contentLabel, padding: UIEdgeInsets(top: 10, left: 20, bottom: 24, right: 20))
    }

    /// 设置自定义View内容，容器四边是标题下方，按钮横线，模态框左右两边。会自动检测是否有文字输入以移动弹窗
    ///
    /// - Parameters:
    ///   - view: 自定义view
    ///   - padding: 距离容器四边的padding [Default = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)]
    public func setContent(
        view: UIView,
        padding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)) {
        contentIsText = false
        layoutContentView(view: view, padding: padding)
    }
}

// 按钮部分接口实现
extension LarkAlertController {
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
    public func addButton(
        text: String,
        color: UIColor = UIColor.ud.primaryContentDefault,
        font: UIFont = UIFont.systemFont(ofSize: 17),
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        guard weight > 0 else {
            assertionFailure("weight cannot be zero")
            return UIButton()
        }

        if newLine || buttons.isEmpty {
            buttons.append([])
        }

        let button = AlertButton(text: text, textColor: color, weight: weight) { [weak self] in
            let shouldDismiss = dismissCheck()
            if shouldDismiss {
                self?.dismiss(animated: true, completion: dismissCompletion)
            }
        }

        button.button.titleLabel?.font = font
        button.button.titleLabel?.numberOfLines = numberOfLines

        buttons[buttons.count - 1].append(button)
        return button.button
    }

    /// 添加一个灰字的次要操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    public func addSecondaryButton(
        text: String,
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addButton(text: text, color: UIColor.ud.textTitle, newLine: newLine, weight: weight, numberOfLines: numberOfLines,
                  dismissCheck: dismissCheck, dismissCompletion: dismissCompletion)
    }

    /// 添加一个灰字，文本为[Lark_Legacy_Cancel]的次要操作按钮
    ///
    /// - Parameters:
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    public func addCancelButton(
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addSecondaryButton(text: BundleI18n.LarkAlertController.Lark_Legacy_Cancel,
                           newLine: newLine, weight: weight, numberOfLines: numberOfLines,
                           dismissCheck: dismissCheck, dismissCompletion: dismissCompletion)
    }

    /// 添加一个红字的警惕性操作按钮
    ///
    /// - Parameters:
    ///   - text: 按钮文本
    ///   - newLine: 按钮是否新起一行 [Default = false]
    ///   - weight: 按钮在一行占宽度的权重，最终宽度是按钮权重除以该行按钮总权重 [Default = 1]
    ///   - numberOfLines: 按钮文本最多展示行数 [Default = 1]
    ///   - dismissCheck: 模态框dismiss之前执行的闭包，返回值代表是否可以dismiss [Default = { true }]
    ///   - dismissCompletion: 模态框dismiss之后执行的闭包，如果dismissCheck返回false则不会执行此闭包 [Default = nil]
    public func addDestructiveButton(
        text: String,
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addButton(text: text, color: UIColor.ud.functionDangerContentDefault, newLine: newLine, weight: weight, numberOfLines: numberOfLines,
                  dismissCheck: dismissCheck, dismissCompletion: dismissCompletion)
    }
}

extension LarkAlertController {
    /// 注册一个 View，在 viewDidLoad 时成为第一响应者
    ///
    /// - Parameters:
    ///   - view: 准备被注册的视图
    public func registerFirstResponder(for view: UIView) {
        firstResponder = view
    }
}

// 内部实现
/// Lark模态弹窗
/// - 组件文档：https://bytedance.feishu.cn/space/doc/doccn1ILOvxc38Kt78zuUe7c6He
open class LarkAlertController: UIViewController {

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override var keyCommands: [UIKeyCommand]? {
        let selectKeyCommand: UIKeyCommand
        if #available(iOS 13.0, *) {
            selectKeyCommand = UIKeyCommand(action: #selector(selected), input: "\u{D}")
        } else {
            selectKeyCommand = UIKeyCommand(input: "\u{D}", modifierFlags: [], action: #selector(selected), discoverabilityTitle: "")
        }
        return [selectKeyCommand]
    }

    @objc
    func selected() {
        guard let alertButton = self.buttons.last?.last else {
            return
        }
        alertButton.action()
    }

    private var titleLabel: UILabel?

    private var contentView: UIView?

    private weak var firstResponder: UIView?

    private var contentIsText = false

    private lazy var contentsContainer: UIView = {
        return UIView()
    }()

    private lazy var buttonContainer: UIView = {
        return UIView()
    }()

    private lazy var dialog: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()

    private var buttons: [[AlertButton]] = []
    private let buttonHeight = 50
    private func assembleButtons() {
        var lastButton: AlertButton?
        for buttonsLine in buttons {
            let totalWeight = buttonsLine.reduce(0) { (sum, button) in
                return sum + button.weight
            }

            let firstButton = buttonsLine[0]
            buttonContainer.addSubview(firstButton)
            firstButton.snp.makeConstraints { (make) in
                if let button = lastButton {
                    make.top.equalTo(button.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
                make.width.equalToSuperview().multipliedBy(firstButton.weight / totalWeight)
                make.height.equalTo(buttonHeight)
                make.left.equalToSuperview()
            }
            for i in 1..<buttonsLine.count {
                buttonContainer.addSubview(buttonsLine[i])
                buttonsLine[i].snp.makeConstraints { (make) in
                    make.width.equalToSuperview().multipliedBy(buttonsLine[i].weight / totalWeight)
                    make.centerY.height.equalTo(firstButton)
                    make.leading.equalTo(buttonsLine[i - 1].snp.trailing)
                }
                let verticalLine = Line()
                buttonContainer.addSubview(verticalLine)
                verticalLine.snp.makeConstraints { (make) in
                    make.height.centerY.equalTo(firstButton)
                    make.width.equalTo(1.0)
                    make.leading.equalTo(buttonsLine[i - 1].snp.trailing)
                }
            }
            lastButton = buttonsLine.last
            let horizontalLine = Line()
            buttonContainer.addSubview(horizontalLine)
            horizontalLine.snp.makeConstraints { (make) in
                make.top.equalTo(firstButton)
                make.height.equalTo(1.0)
                make.width.centerX.equalToSuperview()
            }
        }
    }

    private func layoutContentView(view: UIView, padding: UIEdgeInsets) {
        if contentView == nil {
            contentView = UIView()
            contentView?.backgroundColor = .clear
        }

        if let contentView = contentView {
            let wrapperView = UIView()
            wrapperView.backgroundColor = .clear
            contentView.addSubview(wrapperView)
            wrapperView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.width.lessThanOrEqualTo(UIScreen.main.bounds.width - 2 * horizontalPadding).priority(.required)
            }
            wrapperView.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(padding)
            }

            handleKeyboardEvent = hasTextInput(view: view)
        }
    }

    private var alertWidth: CGFloat {
        let baseWidths: (screenWidth: CGFloat, alertWidth: CGFloat) = (414, 300)
        return UIScreen.main.bounds.width > baseWidths.screenWidth ? baseWidths.alertWidth :
            UIScreen.main.bounds.width / baseWidths.screenWidth * baseWidths.alertWidth
    }
    private let horizontalPadding: CGFloat = 20

    private func layoutSubviews() {
        view.addSubview(dialog)
        dialog.backgroundColor = UIColor.ud.bgFloat

        dialog.addSubview(contentsContainer)
        dialog.addSubview(buttonContainer)

        if let titleLabel = titleLabel {
            contentsContainer.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                if contentView != nil && !contentIsText {
                    make.top.equalToSuperview().offset(20)
                } else {
                    make.top.equalToSuperview().offset(24)
                }
                make.width.equalToSuperview().offset(-2 * horizontalPadding)
                make.centerX.equalToSuperview()
            }
            if contentView == nil {
                titleLabel.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview().offset(-24)
                    make.width.equalTo(alertWidth - 2 * horizontalPadding)
                }
            }
        }

        if let contentView = contentView {
            contentsContainer.addSubview(contentView)
            let top = titleLabel?.snp.bottom ?? contentsContainer.snp.top
            contentView.snp.makeConstraints { (make) in
                make.top.equalTo(top)
                make.bottom.centerX.width.equalToSuperview()
            }
            if titleLabel == nil && contentIsText {
                let contentLabel = contentView.subviews.first?.subviews.first
                contentLabel?.snp.updateConstraints { (make) in
                    make.edges.equalToSuperview()
                        .inset(UIEdgeInsets(top: 24, left: horizontalPadding, bottom: 24, right: horizontalPadding))
                }
            }
        }

        contentsContainer.snp.makeConstraints { (make) in
            make.width.centerX.top.equalToSuperview()
            make.bottom.equalTo(buttonContainer.snp.top)
        }

        assembleButtons()

        buttonContainer.snp.makeConstraints { (make) in
            make.bottom.width.centerX.equalToSuperview()
            make.height.equalTo(buttons.count * 50)
        }

        dialog.snp.makeConstraints { (make) in
            make.centerY.centerX.equalToSuperview()
        }

        view.insertSubview(keyboardGestureView, belowSubview: dialog)
        keyboardGestureView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        layoutSubviews()

        let closeKeyboardRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapBeyondTextInput(ges:))
        )
        keyboardGestureView.addGestureRecognizer(closeKeyboardRecognizer)

    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let firstResponder = self.firstResponder {
            firstResponder.becomeFirstResponder()
        } else {
            self.becomeFirstResponder()
        }
    }

    lazy var keyboardGestureView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    @objc
    private func onTapBeyondTextInput(ges: UIGestureRecognizer) {
        guard handleKeyboardEvent else { return }
        self.view.endEditing(true)
        if !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }

    @objc
    private func onKeyboardShowOrHide(_ notify: Notification) {
        guard let userinfo = notify.userInfo else { return }
        guard dialog.superview != nil else { return }
        if notify.name == UIResponder.keyboardWillShowNotification {
            if let keyboardRect = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                guard let superview = dialog.superview else { return }
                let addedDifference = dialog.frame.midY - superview.frame.midY
                let difference = keyboardRect.minY - dialog.frame.maxY + addedDifference
                if difference < 0 {
                    UIView.animate(withDuration: 0.25) {
                        self.dialog.snp.updateConstraints { (make) in
                            make.centerY.equalToSuperview().offset(difference)
                        }
                        self.view.layoutIfNeeded()
                    }
                } else if difference >= 0 && addedDifference < 0 {
                    UIView.animate(withDuration: 0.25) {
                        self.dialog.snp.updateConstraints { (make) in
                            make.centerY.equalToSuperview()
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            UIView.animate(withDuration: 0.25) {
                self.dialog.snp.updateConstraints { (make) in
                    make.centerY.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    private var handleKeyboardEvent: Bool = false {
        didSet {
            if handleKeyboardEvent == oldValue {
                return
            }
            if handleKeyboardEvent {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(onKeyboardShowOrHide(_:)),
                                                       name: UIResponder.keyboardWillShowNotification,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(onKeyboardShowOrHide(_:)),
                                                       name: UIResponder.keyboardWillHideNotification,
                                                       object: nil)
            } else {
                NotificationCenter.default.removeObserver(self)
            }
        }
    }

    private func hasTextInput(view: UIView) -> Bool {
        if view is UITextField || view is UITextView {
            return true
        }
        for subview in view.subviews {
            if hasTextInput(view: subview) {
                return true
            }
        }
        return false
    }
}

 */
import UIKit
