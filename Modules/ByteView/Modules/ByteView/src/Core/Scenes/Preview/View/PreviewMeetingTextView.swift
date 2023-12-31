//
//  PreviewMeetingTextView.swift
//  ByteView
//
//  Created by ford on 2019/5/22.
//

import UIKit
import RxSwift
import SnapKit

protocol PreviewTextFieldDelegte: AnyObject {
    func textFieldWillBeginEditing(_ textField: UITextField)
}

class PreviewTextField: UITextField {
    let placeHolderLabel = UILabel()
    var underlineColor: UIColor?
    var trackClosure: (() -> Void)?

    var rectInset: UIEdgeInsets = .zero {
        didSet {
            placeHolderLabel.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview().inset(rectInset)
            }
        }
    }

    weak var previewDelegate: PreviewTextFieldDelegte?

    override var placeholder: String? {
        get { placeHolderLabel.text }
        set { placeHolderLabel.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return rectInset != .zero ? bounds.insetBy(dx: rectInset.left, dy: rectInset.top) : bounds
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return rectInset != .zero ? bounds.insetBy(dx: rectInset.left, dy: rectInset.top) : bounds
    }

    private func setupViews() {
        textColor = .ud.textTitle
        font = UIFont.boldSystemFont(ofSize: 24)
        textAlignment = .center
        borderStyle = .none
        returnKeyType = UIReturnKeyType.done

        placeHolderLabel.textColor = UIColor.ud.textPlaceholder
        placeHolderLabel.font = UIFont.boldSystemFont(ofSize: 24)
        placeHolderLabel.textAlignment = .center
        self.addSubview(placeHolderLabel)

        placeHolderLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.rx.text.orEmpty.subscribe(onNext: { [weak self] (str) in
            self?.placeHolderLabel.isHidden = !str.isEmpty
        }).disposed(by: rx.disposeBag)
    }

    func setLineBreakMode(_ lineBreakMode: NSLineBreakMode) {
        placeHolderLabel.lineBreakMode = lineBreakMode
    }
}

class PreviewMeetingTextView: UIView {

    static let maxCount = 50

    lazy var textField = UnderlineTextField()
    var firstBeginEditingAction: (() -> Void)?
    var textDidChangedClosure: ((UITextField) -> Void)?
    var isFirstEdit: Bool = true

    var text: String? {
        return Self.trimToMaxTextCount(text: textField.text)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    private func setupViews() {
        self.backgroundColor = UIColor.clear
        textField.clearsOnBeginEditing = false
        textField.clearButtonMode = .never
        textField.returnKeyType = UIReturnKeyType.done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        self.addSubview(textField)
        // setup constraints
        textField.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    static func trimToMaxTextCount(text: String?) -> String? {
        if let text = text, text.count > maxCount {
            let endIndex = text.index(text.startIndex, offsetBy: maxCount)
            return String(text[..<endIndex])
        } else {
            return text
        }
    }
}

extension PreviewMeetingTextView: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.textField.previewDelegate?.textFieldWillBeginEditing(textField)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textField.trackClosure?()
        guard isFirstEdit else { return }
        isFirstEdit = false
        firstBeginEditingAction?()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
    }
}

extension PreviewMeetingTextView {
    @objc private func textFieldDidChanged(_ textField: UITextField) {
        // 有高亮的临时字符则直接跳过不处理
        if textField.markedTextRange !== nil {
            return
        }
        textField.text = Self.trimToMaxTextCount(text: textField.text)
        self.textDidChangedClosure?(textField)
    }
}
