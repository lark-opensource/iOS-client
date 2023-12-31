//
//  PasswordTextFiled.swift
//  LarkLogin
//
//  Created by sniperj on 2019/1/9.
//

/// AutoLayout 版 PasswordTextField
class ALPasswordTextField: UIView {

    var password: String?

    var placeholder: String? = BundleI18n.suiteLogin.Lark_Login_PsdPlaceholder

    var isClosePreview = true

    var textChangeBlock: ((String?) -> Void)?

    var returnBtnClicked: ((ALPasswordTextField) -> Void)?
    
    var endEditingBlock: ((ALPasswordTextField) -> Void)?

    var returnKeyType: UIReturnKeyType {
        get { textFieldView.returnKeyType }
        set { textFieldView.returnKeyType = newValue }
    }
    
    let maxPasswordLength = 128

    lazy var pwdPreviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(pwdPreviewClick), for: .touchUpInside)
        return button
    }()

    lazy var pwdPreviewImageView: UIImageView = {
        let img = Resource.pwd_ClosePreview.ud.withTintColor(UIColor.ud.iconN3)
        let imgView = UIImageView(image: img)
        return imgView
    }()

    let borderView: V3BorderView

    lazy var textFieldView: CustomTextField = {
        let tf = CustomTextField()
        tf.font = UIFont.systemFont(ofSize: 17)
        tf.tintColor = UIColor.ud.primaryContentDefault
        tf.backgroundColor = UIColor.clear
        tf.textAlignment = .left
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )
        tf.textColor = UIColor.ud.textTitle
        tf.delegate = self
        tf.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        tf.isSecureTextEntry = true
        tf.keyboardType = .asciiCapable
        tf.clearButtonMode = .whileEditing
        tf.accessibilityIdentifier = "input_pass_word_edit_text"
        return tf
    }()

    /// 是否自动开始编辑（弹出键盘）
    let autoBecomeFirstResponder: Bool

    public init(
        enableSecureText: Bool = true,
        borderStyle: V3BorderView.BorderStyle = .roundedBorder,
        placeholder: String? = nil,
        textChangeBlock textChangeblock: ((String?) -> Void)? = nil,
        returnBtnClickedBlock: ((ALPasswordTextField) -> Void)? = nil,
        autoBecomeFirstResponder: Bool = true
    ) {
        self.autoBecomeFirstResponder = autoBecomeFirstResponder
        self.borderView = V3BorderView(borderStyle: borderStyle)
        super.init(frame: .zero)
        if placeholder != nil {
            self.placeholder = placeholder
        }
        self.textChangeBlock = textChangeblock
        self.returnBtnClicked = returnBtnClickedBlock
        self.setupSubviews(enableSecureText: enableSecureText)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews(enableSecureText: Bool) {
        addSubview(borderView)
        addSubview(textFieldView)

        borderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let horizonSpace = borderView.borderStyle == .roundedBorder ? 16.0 : 0

        textFieldView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(horizonSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            if !enableSecureText {
                make.right.equalToSuperview().inset(horizonSpace)
            }
        }

        if enableSecureText {
            addSubview(pwdPreviewImageView)
            addSubview(pwdPreviewButton)

            pwdPreviewButton.snp.makeConstraints { (make) in
                make.left.equalTo(textFieldView.snp.right)
                make.size.equalTo(CGSize(width: 25, height: 35))
                make.right.equalToSuperview().inset(horizonSpace)
                make.centerY.equalTo(textFieldView)
            }

            pwdPreviewImageView.snp.makeConstraints { (make) in
                make.right.equalTo(pwdPreviewButton)
                make.size.equalTo(CGSize(width: 16, height: 16))
                make.centerY.equalTo(textFieldView)
            }
        } else {
            textFieldView.isSecureTextEntry = false
            textFieldView.keyboardType = .`default`
            textFieldView.placeholder = BundleI18n.suiteLogin.Lark_Login_PlaceholderOfNamePage
        }

        if autoBecomeFirstResponder {
            becomeFirstResponder()
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textFieldView.becomeFirstResponder() && super.becomeFirstResponder()
    }

    @objc
    func pwdPreviewClick() {
        isClosePreview = !isClosePreview
        if isClosePreview {
            pwdPreviewImageView.image = Resource.pwd_ClosePreview.ud.withTintColor(UIColor.ud.iconN3)
            textFieldView.isSecureTextEntry = true
        } else {
            pwdPreviewImageView.image = Resource.pwd_Preview.ud.withTintColor(UIColor.ud.iconN3)
            textFieldView.isSecureTextEntry = false
        }
    }

    @objc
    func textFieldEditingChanged(textField: UITextField) {
        password = textField.text
        self.textChangeBlock?(password)
    }

}

extension ALPasswordTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        borderView.update(highlight: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        borderView.update(highlight: false)
        endEditingBlock?(self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnBtnClicked?(self)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= maxPasswordLength
    }
}
