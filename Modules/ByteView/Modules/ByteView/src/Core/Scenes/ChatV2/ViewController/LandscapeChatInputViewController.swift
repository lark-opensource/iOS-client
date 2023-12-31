//
//  LandscapeChatInputViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/5/30.
//

import UIKit
import SnapKit
import ByteViewTracker
import UniverseDesignIcon

/// iPhone 横屏模式下输入框是单行横向滚动的，textView 只能竖向滚动，因此必须使用 textField
class LandscapeChatInputViewController: BaseViewController, UITextFieldDelegate {
    weak var delegate: ChatInputViewControllerDelegate?

    private enum Layout {
        static let fontSize: CGFloat = 16
        static let lineHeight: CGFloat = 22
        static let textViewVerticalPadding: CGFloat = Display.iPhoneXSeries ? 78 : 16
        static let textViewHorizontalPadding: CGFloat = 8
        static let inputViewHeight: CGFloat = 40
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private(set) lazy var textField: UITextField = {
        let view = InsetTextField()
        view.delegate = self
        view.backgroundColor = UIColor.ud.bgFloat
        view.textColor = UIColor.ud.textTitle
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10

        view.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        view.enablesReturnKeyAutomatically = true
        view.keyboardAppearance = .default
        view.keyboardType = .default
        view.returnKeyType = .send
        view.textAlignment = .left
        view.inset = UIEdgeInsets(top: 9, left: 13.5, bottom: 9, right: 13.5)

        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = Layout.lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = .byClipping
        let font = UIFont.systemFont(ofSize: Layout.fontSize, weight: .regular)
        let offset = (lineHeight - font.lineHeight) / 4.0
        view.typingAttributes = [.paragraphStyle: style, .baselineOffset: offset, .font: font, .foregroundColor: UIColor.ud.textTitle]

        return view
    }()

    var allowInput: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    // MARK: - Public

    func clearText() {
        setText("")
    }

    func setText(_ text: String) {
        guard text != textField.text else { return }
        textField.text = text
        textField.invalidateIntrinsicContentSize()
        handleTextChange()
    }

    func endEditing() {
        textField.resignFirstResponder()
    }

    func setPlaceholder(_ placeholder: String, color: UIColor? = nil) {
        if let color = color {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, config: .body, textColor: color)
        } else {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, config: .body, textColor: UIColor.ud.textPlaceholder)
        }
    }

    // 疑似 iOS 系统问题，锁定重力感应，冷启动 app，入会点击旋转屏幕按钮，然后唤起横屏 toolbar，在聊天输入框中长按出来的 menu 反向不对
    // 下面方法可以强行让系统纠正 menuController 的方向。加在 performWithoutAnimation block 中是为了防止影响其他动画
    func fixMenuOrientation() {
        UIView.performWithoutAnimation {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    // MARK: - Private

    private func setupSubviews() {
        view.backgroundColor = .clear

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.textViewVerticalPadding)
            make.top.bottom.equalToSuperview().inset(Layout.textViewHorizontalPadding)
            make.height.equalTo(Layout.inputViewHeight)
        }
    }

    // MARK: - Actions

    @objc
    private func handleTextChange() {
        if let text = textField.text {
            delegate?.chatInputViewTextDidChange(to: text)
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return allowInput
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n", let text = textField.text {
            delegate?.chatInputViewDidPressReturnKey(text: text)
            return false
        }
        return true
    }
}

private class InsetTextField: UITextField {
    var inset: UIEdgeInsets = .zero

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let result = CGRect(x: bounds.minX + inset.left,
               y: bounds.minY + inset.top,
               width: bounds.maxX - inset.left - inset.right,
               height: bounds.maxY - inset.top - inset.bottom)
        return result
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let result = CGRect(x: bounds.minX + inset.left,
               y: bounds.minY + inset.top,
               width: bounds.maxX - inset.left - inset.right,
               height: bounds.maxY - inset.top - inset.bottom)
        return result
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let result = CGRect(x: bounds.minX + inset.left,
               y: bounds.minY + inset.top,
               width: bounds.maxX - inset.left - inset.right,
               height: bounds.maxY - inset.top - inset.bottom)
        return result
    }
}
