//
//  BTURLEditBoardItemView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/18.
//  


import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UIKit


struct BTURLEditBoardItemViewModel {
    var title: String
    var content: String
    var placeholder: String 
}

final class BTURLEditBoardItemView: UIView, UITextFieldDelegate {
    
    var pasteOperation: (() -> Void)? {
        didSet {
            contentTextField.pasteOperation = pasteOperation
        }
    }
    
    var content: String {
        get {
            return contentTextField.text ?? ""
        }
        set {
            contentTextField.text = newValue
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var contentTextField: URLEditBoardTextField = {
        let textField = URLEditBoardTextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = UDColor.textTitle
        textField.tintColor = UDColor.functionInfoContentDefault
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.baseContext = baseContext
        return textField
    }()
    
    private let baseContext: BaseContext?

    init(frame: CGRect, baseContext: BaseContext?) {
        self.baseContext = baseContext
        super.init(frame: frame)
        setupViews()
        setupLaytous()
        setTextFieldHighlight(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        contentTextField.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    func updateData(_ data: BTURLEditBoardItemViewModel) {
        self.titleLabel.text = data.title
        self.contentTextField.attributedText = NSAttributedString(string: data.content,
                                                        attributes: [NSAttributedString.Key.foregroundColor: UDColor.textTitle])
        self.contentTextField.attributedPlaceholder = NSAttributedString(string: data.placeholder,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UDColor.textPlaceholder])
    }
    
    func setTextFieldLongPressEnable(_ isEnabled: Bool) {
        contentTextField.setLongPressGREnabled(isEnabled)
    }

    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setTextFieldHighlight(true)
        contentTextField.setLongPressGREnabled(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setTextFieldHighlight(false)
        contentTextField.setLongPressGREnabled(false)
    }
    
    private func setTextFieldHighlight(_ isHighlight: Bool) {
        contentContainerView.layer.borderColor = isHighlight ?  UDColor.primaryContentDefault.cgColor : UDColor.lineBorderCard.cgColor
    }

    // MARK: setup Methods
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(contentContainerView)
        contentContainerView.addSubview(contentTextField)
    }

    private func setupLaytous() {
        titleLabel.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
        }
        contentContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(40)
        }
        
        contentTextField.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(12)
        }
    }
}



final class URLEditBoardTextField: BTConditionalTextField {

    var pasteOperation: (() -> Void)?

    override func paste(_ sender: Any?) {
        pasteOperation?()
        super.paste(sender)
    }

    /// 为了解决 iOS 15 以后，长按出现的异常
    /// https://meego.feishu.cn/larksuite/issue/detail/4936009?parentUrl=%2Flarksuite%2FissueView%2FSBg67fTcn
    func setLongPressGREnabled(_ isEnabled: Bool) {
        self.gestureRecognizers?.forEach {
            if $0 is UILongPressGestureRecognizer {
                $0.isEnabled = isEnabled
            }
        }
    }
}
