//
//  BTFilterValueInputController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/27.
//  


import SKUIKit
import UniverseDesignColor
import SKResource
import UIKit
import UniverseDesignToast


final class BTFilterValueInputController: BTFilterValueBaseController {
    
    
    var didBeginEdit: (() -> Void)?
    
    enum InputType {
        case text(String?)
        case number(String?)
        case phone(String?)
    }
    
    private var inputType: InputType
    
    private lazy var borderContainerView = UIView().construct { it in
        it.layer.cornerRadius = 6
        it.layer.borderWidth = 1
        it.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        it.backgroundColor = .clear
        it.clipsToBounds = true
    }
    
    private lazy var contentTextView: BTConditionalPlacehoderTextView = {
        let textView = BTConditionalPlacehoderTextView()
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 12
        let font = UIFont.systemFont(ofSize: 16)
        var attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
        attrs[.foregroundColor] = UDColor.textTitle
        textView.typingAttributes = attrs
        textView.placeholderFont = font
        textView.placeholderColor = UDColor.textPlaceholder
        textView.placeholder = BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer
        textView.baseContext = self.baseContext
        return textView
    }()
    
    let baseContext: BaseContext
    
    init(title: String, type: InputType, baseContext: BaseContext) {
        self.inputType = type
        self.baseContext = baseContext
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        initViewHeight = maxViewHeight
        super.setupUI()
        setupContentView()
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(containerViewDidPress))
        containerView.addGestureRecognizer(tapGR)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentTextView.becomeFirstResponder()
    }
    
    override func getValuesWhenFinish() -> [AnyHashable] {
        let value = (self.contentTextView.text ?? "")
        if value.isEmpty {
            return []
        }
        return [value]
    }
    
    override func isValueChange() -> Bool {
        switch inputType {
        case .number(let text), .text(let text), .phone(let text):
            let value = (self.contentTextView.text ?? "")
            return value != (text ?? "")
        }
    }
    
    override func didClickDoneButton() {
        switch inputType {
        case .number:
            let content = self.contentTextView.text?.trim() ?? ""
            let result = vertifyNumberRule(content: content)
            if result.isOK {
                super.didClickDoneButton()
            } else {
                UDToast.showFailure(with: result.errorMsg, on: self.view.window ?? self.view)
            }
        case .phone, .text:
            super.didClickDoneButton()
        }
    }
    
    @objc
    private func containerViewDidPress() {
        contentTextView.resignFirstResponder()
    }
    
    func update(_ inputText: String) {
        contentTextView.text = inputText
    }
    
    private func setupContentView() {
        contentView.addSubview(borderContainerView)
        borderContainerView.addSubview(contentTextView)
        let borderContainerViewHeight: CGFloat
        switch inputType {
        case let .text(text):
            contentTextView.text = text
            contentTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            borderContainerViewHeight = 108
        case let .number(number):
            contentTextView.text = number
            contentTextView.textContainerInset = UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0)
            borderContainerViewHeight = 48
            contentTextView.inputView = BTNumberKeyboardView(target: contentTextView)
        case let .phone(phone):
            contentTextView.text = phone
            contentTextView.textContainerInset = UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0)
            borderContainerViewHeight = 48
            contentTextView.keyboardType = .phonePad
        }
        borderContainerView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(borderContainerViewHeight)
        }
        contentTextView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func updateBorder(_ isEditing: Bool) {
        if isEditing {
            borderContainerView.layer.ud.setBorderColor(UDColor.primaryContentDefault)
        } else {
            borderContainerView.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        }
    }
    
    private func vertifyNumberRule(content: String) -> (isOK: Bool, errorMsg: String) {
        let okResult = (true, "")
        
        let dotCount = content.map { return String($0) }.filter { $0 == "." }.count
        if dotCount > 1 {
            return (false, BundleI18n.SKResource.Doc_Block_NotSupportMultiplePoints)
        }
        
        if content.isEmpty {
            return okResult
        }
        
        if let _ = Double(content), content.isDoubleFormat {
            return okResult
        } else {
            return (false, BundleI18n.SKResource.Doc_Block_OnlySupportNumber)
        }
    }
}

extension BTFilterValueInputController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.updateBorder(true)
        self.didBeginEdit?()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.updateBorder(false)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.valueSelected(textView.text ?? "", selected: true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch inputType {
        case .number:
            if text == "\n" {
                self.didClickDoneButton()
                return false
            }
        default: break
        }
        return true
    }
}

extension BTFilterValueInputController: ClipboardProtectProtocol {
    func getDocumentToken() -> String? {
        return self.baseContext.permissionObj.objToken
    }
}
