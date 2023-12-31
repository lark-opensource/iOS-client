//
//  ChatPinUpdateTitleViewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignToast

final class ChatPinUpdateTitleViewController: BaseUIViewController {

    private var finishedButton: UIButton?
    static let textMaxLength = 60
    private lazy var titleInputView = ChatPinUpdateTitleInputView(textMaxLength: Self.textMaxLength)
    private let editTitle: String
    private let saveHandler: (String, UIView, @escaping () -> Void) -> Void

    init(editTitle: String, saveHandler: @escaping (String, UIView, @escaping () -> Void) -> Void) {
        self.editTitle = editTitle
        self.saveHandler = saveHandler
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkChat.Lark_IM_NewPin_EditName_Title
        addNavigationBarRightItem()
        self.view.addSubview(titleInputView)
        titleInputView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(15)
        }
        titleInputView.textFieldDidChangeHandler = { [weak self] (textField) in
            guard let self = self else { return }
            let text = textField.text ?? ""
            let textCount = text.count
            let color = (textCount > Self.textMaxLength || textCount == 0 || text.trimmingCharacters(in: .whitespaces).isEmpty) ? UIColor.ud.N400 : UIColor.ud.primaryPri500
            self.finishedButton?.setTitleColor(color, for: .normal)
        }
        titleInputView.text = self.editTitle

        self.backCallback = { [weak self] in
            self?.endEditting()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.titleInputView.textField.becomeFirstResponder()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditting()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_EditNameSave_Button, fontStyle: .medium)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        rightItem.button.addTarget(self, action: #selector(rightItemTapped), for: .touchUpInside)
        self.finishedButton = rightItem.button
        self.navigationItem.rightBarButtonItem = rightItem
    }

    @objc
    fileprivate func rightItemTapped() {
        let newTitle = self.titleInputView.text ?? ""
        let textCount = newTitle.count
        guard textCount > 0, !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        guard textCount <= Self.textMaxLength else {
            return
        }
        self.saveHandler(
            newTitle,
            self.view, { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        )
    }

    private func endEditting() {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }
}

private final class ChatPinUpdateTitleInputView: UIView, UITextFieldDelegate {
    private static let textCountNormalColor: UIColor = UIColor.ud.N500
    private let textMaxLength: Int
    let textField = BaseTextField(frame: .zero)
    var textFieldDidChangeHandler: ((UITextField) -> Void)?
    var text: String? {
        get { return self.textField.text }
        set {
            self.textField.text = newValue
            inputViewTextFieldDidChange(self.textField)
        }
    }
    let textCountLabel: UILabel = UILabel(frame: .zero)

    init(textMaxLength: Int) {
        self.textMaxLength = textMaxLength
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = 10.0
        textField.placeholder = BundleI18n.LarkChat.Lark_IM_NewPin_AddPinEnterDisplayedName_Placeholder
        textField.delegate = self
        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.borderStyle = .none

        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
        let clearButton = UIButton(frame: CGRect(x: 16, y: 18, width: 16, height: 16))
        clearButton.setImage(UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconDisabled), for: .normal)
        wrapperView.addSubview(clearButton)
        clearButton.addTarget(self, action: #selector(clearButtonClicked), for: .touchUpInside)
        textField.rightView = wrapperView
        textField.rightViewMode = .whileEditing
        textField.rightView?.systemLayoutSizeFitting(CGSize(width: 44, height: 52))
        textField.textColor = UIColor.ud.N900
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(inputViewTextFieldDidChange(_:)), for: .editingChanged)
        self.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-7)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }

        textCountLabel.font = .systemFont(ofSize: 12)
        self.addSubview(textCountLabel)
        textCountLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-8)
        }
        let attr = NSAttributedString(string: "\(0)/\(textMaxLength)",
                                      attributes: [.foregroundColor: Self.textCountNormalColor])
        textCountLabel.attributedText = attr
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func inputViewTextFieldDidChange(_ textField: UITextField) {
        let count = textField.text?.count ?? 0
        if count > textMaxLength {
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.R500])
            attr.append(NSAttributedString(string: "/\(textMaxLength)",
                                           attributes: [.foregroundColor: Self.textCountNormalColor]))
            textCountLabel.attributedText = attr
        } else {
            let attr = NSAttributedString(string: "\(count)/\(textMaxLength)",
                                          attributes: [.foregroundColor: Self.textCountNormalColor])
            textCountLabel.attributedText = attr
        }
        if let handler = self.textFieldDidChangeHandler {
            handler(textField)
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        let attr = NSAttributedString(string: "0/\(textMaxLength)",
                                      attributes: [.foregroundColor: Self.textCountNormalColor])
        textCountLabel.attributedText = attr
        return true
    }

    @objc
    private func clearButtonClicked() {
        self.text = ""
        _ = self.textFieldShouldClear(textField)
    }
}
