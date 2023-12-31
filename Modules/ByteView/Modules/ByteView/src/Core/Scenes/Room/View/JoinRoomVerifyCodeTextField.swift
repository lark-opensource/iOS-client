//
//  JoinRoomVerifyCodeTextField.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewCommon

final class JoinRoomVerifyCodeTextField: UIView, UITextFieldDelegate {
    var codeHandler: ((String) -> Void)?
    var willBeginEditingHandler: ((UITextField) -> Void)?
    private var text: String = ""
    private var state: JoinRoomVerifyCodeState = .idle

    override init(frame: CGRect) {
        super.init(frame: frame)
        resetInputViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateVerifyCode(_ code: String, state: JoinRoomVerifyCodeState) {
        self.text = code
        if self.textFieldView.text != code {
            self.textFieldView.text = code
        }
        self.state = state
        updateVerifyState()
    }

    private lazy var textFieldView: NoActionTextField = {
        let tf = NoActionTextField()
        tf.tintColor = UIColor.clear
        tf.backgroundColor = UIColor.clear
        tf.textColor = UIColor.clear
        tf.delegate = self
        tf.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        tf.autocorrectionType = .no
        tf.keyboardType = .alphabet
        tf.autoresizingMask = .flexibleWidth
        tf.autocapitalizationType = .allCharacters
        tf.clearsOnBeginEditing = false
        return tf
    }()

    private let inputNum = 6
    var inputSize: CGSize = CGSize(width: 48, height: 48) {
        didSet {
            if oldValue != inputSize {
                resetInputViews()
                updateVerifyCode(text, state: state)
            }
        }
    }
    // inputViews contains cursor & label
    private var inputViews: [VerifyCodeInputView] = []

    private func resetInputViews() {
        self.subviews.forEach {
            $0.removeFromSuperview()
        }
        inputViews.removeAll()

        let contentView = UIView()
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(inputSize.height)
        }
        contentView.addSubview(textFieldView)
        textFieldView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        var prevLayoutGuide: UILayoutGuide?
        var firstLayoutGuide: UILayoutGuide?
        var currentInputNum = 0
        var prevInputView: UIView?
        while currentInputNum < inputNum {
            let inputView = VerifyCodeInputView()
            contentView.addSubview(inputView)
            inputViews.append(inputView)
            inputView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(inputSize.width).priority(.high) // 屏幕宽的时候 控制方格大小不要超过48 打破 space 的宽度的约束变化
                if let prevInputView = prevInputView {
                    make.width.equalTo(prevInputView)
                }
                if let prevLayoutGuide = prevLayoutGuide {
                    make.left.equalTo(prevLayoutGuide.snp.right)
                } else {
                    make.left.equalToSuperview()
                }
                if currentInputNum == inputNum - 1 {
                    make.right.equalToSuperview()
                }
            }
            prevInputView = inputView

            currentInputNum += 1
            if currentInputNum == inputNum {
                break
            }

            let guide = UILayoutGuide()
            contentView.addLayoutGuide(guide)
            guide.snp.makeConstraints { make in
                make.left.equalTo(inputView.snp.right)
                make.top.bottom.equalToSuperview()
                make.width.greaterThanOrEqualTo(2)
                if let firstLayoutGuide = firstLayoutGuide {
                    make.width.equalTo(firstLayoutGuide)
                }
            }
            prevLayoutGuide = guide
            if firstLayoutGuide == nil {
                firstLayoutGuide = guide
            }
        }
    }

    // MARK: - UITextFieldDelegate
    private func updateVerifyState() {
        updateInputViews()
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            guard let self = self, self.window != nil else { return }
            switch self.state {
            case .idle:
                if !self.textFieldView.isFirstResponder {
                    Logger.ui.info("becomeFirstResponder")
                    self.textFieldView.becomeFirstResponder()
                }
            case .success:
                if self.textFieldView.isFirstResponder {
                    Logger.ui.info("resignFirstResponder")
                    self.textFieldView.resignFirstResponder()
                }
            default:
                break
            }
        }
    }

    private func updateInputViews() {
        let text = self.text
        let isEditing = self.textFieldView.isFirstResponder
        inputViews.enumerated().forEach { index, inputView in
            if index < text.count {
                let content = text.vc.substring(from: index, length: 1)
                inputView.update(focusOn: false, state: state, content: content)
            } else if index == text.count {
                inputView.update(focusOn: isEditing, state: state, content: "")
            } else {
                inputView.update(focusOn: false, state: state, content: "")
            }
        }
    }

    private func callbackTextChange() {
        self.codeHandler?(text)
    }

    @objc private func textFieldEditingChanged(_ textView: UITextField) {
        guard var text = textView.text?.uppercased() else { return }
        if text.count > inputNum {
            text = text.vc.substring(to: inputNum)
        }
        self.text = text
        updateInputViews()
        callbackTextChange()
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.willBeginEditingHandler?(textField)
        return state == .idle || state == .error
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if state == .success || state == .loading { return false }
        if let text = textField.text, let range = Range(range, in: text) {
            let s = text.replacingCharacters(in: range, with: string)
            if s.count > inputNum {
                return false
            }
        }
        if string.rangeOfCharacter(from: .letters) != nil || (string == "" && range.length > 0) {
            return true
        }
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateInputViews()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateInputViews()
    }

    /// remove select / paste / copy .etc actions
    private class NoActionTextField: UITextField {
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            return false
        }
    }
}

private class VerifyCodeInputView: UIView {

    private let needBorder: Bool = true

    init() {
        super.init(frame: .zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 内容
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = VCFontConfig.body.font
        return label
    }()

    // 光标
    let cursor = VerifyCodeCursorView()

    func setupSubViews() {
        isUserInteractionEnabled = false
        addSubview(label)
        addSubview(cursor)
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.ud.setBorderColor(.ud.lineBorderComponent)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
        }
        cursor.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 2, height: 22))
        }
    }

    func update(focusOn: Bool, state: JoinRoomVerifyCodeState, content: String) {
        let isFocus = focusOn && (state == .idle || state == .error)
        cursor.update(show: isFocus, animated: true)
        label.text = content
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.35) {
            switch state {
            case .idle:
                if isFocus {
                    self.layer.ud.setBorderColor(.ud.primaryContentDefault)
                } else {
                    self.layer.ud.setBorderColor(.ud.lineBorderComponent)
                }
                self.backgroundColor = .clear
            case .loading:
                self.layer.ud.setBorderColor(.ud.lineBorderComponent)
                self.backgroundColor = .ud.udtokenInputBgDisabled
            case .success:
                self.layer.ud.setBorderColor(.ud.lineBorderComponent)
                self.backgroundColor = .clear
            case .error:
                self.layer.ud.setBorderColor(.ud.functionDangerContentDefault)
                self.backgroundColor = .clear
            }
        }
    }
}

private class VerifyCodeCursorView: UIView {
    var shapeLayer: CAShapeLayer? {
        return layer as? CAShapeLayer
    }

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    init() {
        super.init(frame: .zero)
        guard let shapeLayer = layer as? CAShapeLayer else {
            return
        }
        shapeLayer.contentsScale = self.vc.displayScale
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(show: Bool, animated: Bool) {
        if show {
            if let opacity = opacityAnimation() {
                layer.add(opacity, forKey: "kOpacityAnimation")
            }
        } else {
            layer.removeAnimation(forKey: "kOpacityAnimation")
        }
        func updateHighlight() {
            isHidden = !show
        }
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: {
                updateHighlight()
            })
        } else {
            updateHighlight()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawCursor()
    }

    func drawCursor() {
        let path = CGPath(rect: bounds, transform: nil)
        shapeLayer?.path = path
        shapeLayer?.ud.setFillColor(UIColor.ud.functionInfoContentDefault)
    }

    private func opacityAnimation() -> CABasicAnimation? {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1
        opacityAnimation.repeatCount = .greatestFiniteMagnitude
        opacityAnimation.isRemovedOnCompletion = true
        opacityAnimation.fillMode = .forwards
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        return opacityAnimation
    }
}
