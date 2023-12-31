//
//  AppLockSettingPINCodeField.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/23.
//

import UIKit
import LarkUIKit
import UniverseDesignColor

typealias AppLockSettingPINCodeFieldCompletion = (_ text: String) -> Void

final class AppLockSettingPINCodeField: UITextField, UITextFieldDelegate {
    var inputCompletion: AppLockSettingPINCodeFieldCompletion?
    var numberOfDigits: Int = 4 { didSet { redraw() } }
    var spacing: Int = 12 { didSet { redraw() } }
    var borderColor: UIColor = .lightGray {
        didSet { redraw() }
    }

    var activeBorderColor: UIColor? {
        didSet { redraw() }
    }

    var filledBorderColor: UIColor? {
        didSet { redraw() }
    }

    var cornerRadius: CGFloat = 0 {
        didSet { redraw() }
    }

    private var labels: [AppLockSettingPINCodeLabel] {
        return stackView.arrangedSubviews.compactMap({ $0 as? AppLockSettingPINCodeLabel })
    }

    var isSecurePINCodeEntry: Bool = true {
        didSet { textChanged() }
    }

    private lazy var stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.isUserInteractionEnabled = false
        s.spacing = CGFloat(spacing)
        return s
    }()

    private var _textColor: UIColor?
    override var textColor: UIColor? {
        didSet {
            if _textColor == nil {
                _textColor = oldValue
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func reset() {
        text = nil
        redraw()
        becomeFirstResponder()
        updateFocus()
        _ = caretRect(for: UITextPosition())
    }

    private func setup() {
        textColor = .clear
        keyboardType = .numberPad
        returnKeyType = .done
        borderStyle = .none

        if #available(iOS 12.0, *) {
            textContentType = .oneTimeCode
        }

        delegate = self
        addTarget(self, action: #selector(textChanged), for: .editingChanged)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func redraw() {
        stackView.spacing = CGFloat(spacing)

        stackView.arrangedSubviews.forEach { (v) in
            stackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        for _ in 0 ..< self.numberOfDigits {
            let label = AppLockSettingPINCodeLabel()
            label.textColor = _textColor
            label.font = font
            label.isUserInteractionEnabled = false
            label.backgroundColor = backgroundColor
            label.activeBorderColor = activeBorderColor
            label.borderColor = borderColor
            label.cornerRadius = cornerRadius
            label.filledBorderColor = filledBorderColor

            self.stackView.addArrangedSubview(label)
        }
        layoutIfNeeded()
    }

    private func updateFocus() {
        let focusIndex = text?.count ?? 0
        labels.enumerated().forEach { (i, label) in
            label.active = i == focusIndex
        }
    }

    private func removeFocus() {
        let focusIndex = text?.count ?? 0
        guard focusIndex < numberOfDigits else {
            return
        }
        labels[focusIndex].active = false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard var text = self.text else {
            return false
        }
        if string.isEmpty, !text.isEmpty, range.location == text.count - 1 {
            labels[text.count - 1].text = nil
            text.removeLast()
            self.text = text
            updateFocus()
            return false
        }
        return text.count < numberOfDigits
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateFocus()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc
    private func textChanged() {
        self.text = text?.filter { return $0.isNumber }
        guard let text = text, text.count <= numberOfDigits else { return }

        labels.enumerated().forEach({ (i, label) in
            if i < text.count {
                let index = text.index(text.startIndex, offsetBy: i)
                let char = isSecurePINCodeEntry ? "●" : String(text[index])
                label.text = char
            }
        })
        updateFocus()
        if text.count == numberOfDigits {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) { [weak self] in
                self?.inputCompletion?(text)
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        removeFocus()
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        let index = self.text?.count ?? 0
        guard index < stackView.arrangedSubviews.count else {
            return .zero
        }

        let viewFrame = self.stackView.arrangedSubviews[index].frame
        let caretHeight = self.font?.pointSize ?? ceil(self.frame.height * 0.6)
        return CGRect(x: viewFrame.midX - 1, y: ceil((self.frame.height - caretHeight) / 2), width: 2, height: caretHeight)
    }
}

final class AppLockSettingPINCodeLabel: UIView {
    var text: String? {
        didSet { label.text = text }
    }

    var font: UIFont? {
        didSet { label.font = font }
    }

    var active = false {
        didSet { updateActive(oldValue: oldValue, newValue: active) }
    }

    var borderColor: UIColor? {
        didSet { redraw() }
    }

    var cornerRadius: CGFloat = 0 {
        didSet { redraw() }
    }

    var placeholder: String? {
        didSet { redraw() }
    }

    var placeholderColor: UIColor? {
        didSet { redraw() }
    }

    var textColor: UIColor? {
        didSet { self.label.textColor = textColor }
    }

    override var backgroundColor: UIColor? {
        get { return _backgroundColor }
        set {
            _backgroundColor = newValue
            guard let newValue = newValue else {
                return
            }
            // 使用udColor提供的接口设置颜色，防止使用cgColor导致UIColor丧失动态性
            self.layer.ud.setBackgroundColor(newValue)
        }
    }

    var activeBorderColor: UIColor?
    var filledBorderColor: UIColor?

    private var animator = UIViewPropertyAnimator()
    private let label: UILabel
    private var _backgroundColor: UIColor?

    private var hasText: Bool {
        return (self.text?.isEmpty).isFalse
    }

    override init(frame: CGRect) {
        self.label = UILabel(frame: frame)
        super.init(frame: frame)
        self.addSubview(label)
        label.alpha = 0
        self.label.textAlignment = .center
        self.clipsToBounds = false
        redraw()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateActive(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }

        if newValue {
            self.startAnimation()
        } else {
            self.stopAnimation()
        }
    }

    private func redraw() {
        self.layer.borderColor = self.borderColor?.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = self.cornerRadius
        if let placeholder = placeholder {
            self.label.textColor = placeholderColor
            self.label.text = placeholder
            self.label.alpha = 1
        }
    }

    private func startAnimation() {
        animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9, animations: {
            self.layer.borderColor = self.activeBorderColor?.cgColor ?? self.borderColor?.cgColor
            self.label.alpha = 0
        })
        animator.startAnimation()
    }

    private func stopAnimation() {
        animator.addAnimations {
            self.layer.borderColor = self.hasText ? (self.activeBorderColor?.cgColor ?? self.borderColor?.cgColor) : self.borderColor?.cgColor
            self.label.textColor = self.hasText ? self.textColor : self.placeholderColor
            self.label.text = self.text ?? self.placeholder
            self.label.alpha = 1
        }
        animator.startAnimation()
    }
}
