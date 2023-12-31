//
//  LoginInputSegmentView.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/17.
//

import UIKit
import RxSwift
import LarkUIKit
import LarkLocalizations

protocol LoginInputSegmentViewDelegateProtocol: UIViewController {
    func mobileCodeSelectClick()
    func selectedMobileCode(_ mobileCode: MobileCode)
    func needUpdateButton(enable: Bool)
    func inputMethodChange(method: SuiteLoginMethod)
    func didTapReturnButton()
}

struct LoginInputViewConfig {
    let canChangeMethod: Bool
    let defaultMethod: SuiteLoginMethod
    let topCountryList: [String]
    let allowRegionList: [String]
    let blockRegionList: [String]
    let emailRegex: NSPredicate
    let credentialInputList: [V4CredentialInputInfo]
}

extension SuiteLoginMethod {
    fileprivate var tabName: String {
        switch self {
        case .email: return I18N.Lark_Login_V3_Tabbar_Email
        case .phoneNumber: return I18N.Lark_Login_V3_Tabbar_Phone
        }
    }
}

class LoginInputView: SegmentView, UITextFieldDelegate {

    weak var delegate: LoginInputSegmentViewDelegateProtocol?
    let config: LoginInputViewConfig
    let disposeBag = DisposeBag()

    // 外部传入，用于解决 iPad tab 切换问题
    weak var nameTextField: V3FlatTextField?
    private var isNameTextFieldResponding = false

    private lazy var loginMethodList: [SuiteLoginMethod] = {
        if !config.credentialInputList.isEmpty {
            return config.credentialInputList.map { $0.credentialType.method }
        }

        if config.defaultMethod == .email {
            return [.email, .phoneNumber]
        } else {
            return [.phoneNumber, .email]
        }
    }()

    private var isTextFieldFocus: Bool = false {
        didSet {
            if isTextFieldFocus {
                self.hadInteractive = true
            }
        }
    }

    private(set) var hadInteractive: Bool = false
    private let loginSegView: LoginSegment

    private var currentInputMethod: SuiteLoginMethod {
        didSet {
            self.delegate?.inputMethodChange(method: currentInputMethod)
        }
    }

    // MARK: mail input
    lazy var emailTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .email)
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 16)
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.clearButtonMode = .always
        textfield.delegate = self
        return textfield
    }()

    // MARK: mobile Input
    lazy var phoneTextField: V3FlatTextField = {
        let textField = V3FlatTextField(type: .phoneNumber, labelChangable: canChangeRegionCode)
        textField.labelTapGesture.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.mobileCodeSelectClick()

            let mobileVC = MobileCodeSelectViewController(
                mobileCodeLocale: LanguageManager.currentLanguage,
                topCountryList: self.config.topCountryList,
                allowCountryList: self.config.allowRegionList,
                blockCountryList: self.config.blockRegionList) { [weak self] (mobileCode) in
                    self?.delegate?.selectedMobileCode(mobileCode)
                    self?.updateMobileCode(mobileCode)
            }
//            if Display.pad {
//                mobileVC.modalPresentationStyle = .formSheet
//            }
            mobileVC.modalPresentationStyle = .fullScreen
            self.delegate?.present(mobileVC, animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
        textField.label.isEnabled = false
        textField.label.isUserInteractionEnabled = false
        textField.label.accessibilityIdentifier = "ll_country_select"
        textField.labelFont = UIFont.systemFont(ofSize: 16)
        textField.textFieldFont = UIFont.systemFont(ofSize: 16)
        textField.textFieldTextColor = UIColor.ud.textTitle
        textField.splitLineColor = UIColor.ud.lineBorderComponent
        textField.textFiled.returnKeyType = .done
        textField.textFiled.clearButtonMode = .always
        textField.textFiled.accessibilityIdentifier = "phone_number_edit"
        textField.delegate = self
        return textField
    }()

    private lazy var mobileCodeProvider: MobileCodeProvider = {
        return MobileCodeProvider(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: config.topCountryList,
            allowCountryList: config.allowRegionList,
            blockCountryList: config.blockRegionList
        )
    }()

    // 切语言需要动态更新不能lazy
    private var itemTitles: [String] {
        // TODO: 完备性判断
        if config.credentialInputList.isEmpty || config.credentialInputList.count != loginMethodList.count {
            return loginMethodList.map { $0.tabName }
        }
        return config.credentialInputList.map({ $0.tabName })
    }

    init(delegate: LoginInputSegmentViewDelegateProtocol, config: LoginInputViewConfig) {
        self.delegate = delegate
        self.config = config
        self.currentInputMethod = config.defaultMethod
        let seg = LoginSegment()
        self.loginSegView = seg
        super.init(segment: seg)
        backgroundColor = .clear

        if config.canChangeMethod && loginMethodList.count > 1 {

            let itemViews: [LoginSegContainer] = loginMethodList.map { (method) in
                switch method {
                case .email: return LoginSegContainer(content: emailTextField)
                case .phoneNumber: return LoginSegContainer(content: phoneTextField)
                }
            }

            assert(itemTitles.count == itemViews.count, "title count should same with view count")

            seg.isHidden = false
            var items: [(String, UIView)] = []
            for i in 0..<self.itemTitles.count {
                items.append((self.itemTitles[i], itemViews[i]))
            }
            self.set(views: items)
        } else {
            seg.isHidden = true
            let inputView: UIView
            switch config.defaultMethod {
            case .email:
                inputView = emailTextField
            case .phoneNumber:
                inputView = phoneTextField
            }
            addSubview(inputView)
            inputView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.height.equalTo(LoginSegLayout.inputViewHeight)
            }
        }

        seg.selectedIndexDidChangeBlock = { [weak self] _, to in
            guard let self = self else { return }
            if config.canChangeMethod {
                self.currentInputMethod = self.loginMethodOf(index: to)
            }
            self.checkTextFieldFocus()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var canChangeRegionCode: Bool {
        return config.allowRegionList.count != 1
    }

    // layout 结束后调用 不然 bottomView 位置不准确
    func setViewDefault() {
        if config.canChangeMethod {
            setCurrentView(index: indexOf(method: config.defaultMethod), animated: false)
        }
    }

    func updateViewLocale() {
        mobileCodeProvider = MobileCodeProvider(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: config.topCountryList,
            allowCountryList: config.allowRegionList,
            blockCountryList: config.blockRegionList
        )

        let emailPlaceholder = config.credentialInputList
            .first(where: { $0.credentialType == .email })?.credentialInput.placeholder ??
            BundleI18n.suiteLogin.Lark_Login_V3_InputEmailPlaceholder
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: emailPlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])

        let phonePlaceholder = config.credentialInputList
            .first(where: { $0.credentialType == .phoneNumber })?.credentialInput.placeholder ??
            BundleI18n.suiteLogin.Lark_Login_V3_InputPhonePlaceholder
        phoneTextField.attributedPlaceholder = NSAttributedString(
            string: phonePlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )

        if config.canChangeMethod {
            for i in 0..<itemTitles.count {
                segment.updateItem(title: itemTitles[i], index: i)
            }
        }

        // 更新语言后需要重设字体，来生效不同语言下不同字体
        self.phoneTextField.textFieldFont = UIFont.systemFont(ofSize: 16)
        self.phoneTextField.labelFont = UIFont.systemFont(ofSize: 16)
        self.emailTextField.textFieldFont = UIFont.systemFont(ofSize: 16)
    }

    func beginEdit() {
        switch currentInputMethod {
        case .phoneNumber:
            phoneTextField.textFiled.becomeFirstResponder()
        case .email:
            emailTextField.textFiled.becomeFirstResponder()
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === phoneTextField.label {
            return false
        }
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loginSegView.spacing = LoginSegLayout.segmentSpace
        loginSegView.height = LoginSegLayout.segmentHeight
    }
}

extension LoginInputView {
    func loginMethodOf(index: Int) -> SuiteLoginMethod {
        guard index < loginMethodList.count else {
            assertionFailure("should not run here")
            return config.defaultMethod
        }
        return loginMethodList[index]
    }

    func indexOf(method: SuiteLoginMethod) -> Int {
        guard let index = loginMethodList.firstIndex(of: method) else {
            assertionFailure("should not run here")
            return 0
        }
        return index
    }
}

extension LoginInputView {

    func updateMobileCode(_ mobileCode: MobileCode) {
        phoneTextField.labelText = mobileCode.code
        phoneTextField.format = mobileCode.format
    }

    func updateMobileRegion(regionCode: String) {
        var mobileCode: MobileCode
        if let code = mobileCodeProvider.searchCountry(searchCode: regionCode) {
            mobileCode = code
        } else {
            // swiftlint:disable ForceUnwrapping
            mobileCode = mobileCodeProvider.getFirstTopMobileCode() ?? mobileCodeProvider.getMobileCodes().first!
            // swiftlint:enable ForceUnwrapping
        }

        updateMobileCode(mobileCode)
    }

    func checkButtonDisable() -> Bool {
        switch currentInputMethod {
        case .email:
            let text = emailTextField.currentText ?? ""
            return config.emailRegex.evaluate(with: text)
        case .phoneNumber:
            let currentLength = phoneTextField.text?.count ?? 0
            return !(currentLength == 0 || currentLength < phoneTextField.formatMaxLength())
        }
    }

    func checkTextFieldFocus() {
        if isTextFieldFocus {
            beginEdit()
        }
    }
}

extension LoginInputView: V3FlatTextFieldDelegate {
    // 目前是为了修复 iPad 上点击键盘 tab 切换顺序的问题
    func textFieldShouldBeginEditing(_ textField: V3FlatTextField) -> Bool {
        // 登录 CP 输入页场景，点击 tab 不允许切换
        if config.canChangeMethod && nameTextField == nil {
            let currentTextField: V3FlatTextField
            switch currentInputMethod {
            case .email:
                currentTextField = emailTextField
            case .phoneNumber:
                currentTextField = phoneTextField
            }
            if textField === currentTextField {
                return true
            } else {
                return false
            }
        }

        // 填写个人信息页的场景
        if !config.canChangeMethod || nameTextField == nil {
            return true
        }
        if isNameTextFieldResponding {
            isNameTextFieldResponding = false
            return false
        }
        let currentTextField: V3FlatTextField
        switch currentInputMethod {
        case .email:
            currentTextField = emailTextField
        case .phoneNumber:
            currentTextField = phoneTextField
        }
        if textField === currentTextField {
            return true
        }
        nameTextField?.becomeFirstResponder()
        isNameTextFieldResponding = true
        return false
    }

    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        delegate?.didTapReturnButton()
        return true
    }

    func textFieldShouldClear(_ textField: V3FlatTextField) -> Bool {
        DispatchQueue.main.async {
            // dispatch checking work to queue end
            self.delegate?.needUpdateButton(enable: self.checkButtonDisable())
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: V3FlatTextField) {
        isTextFieldFocus = true
    }

    func textFieldDidEndEditing(_ textField: V3FlatTextField) {
        isTextFieldFocus = false
    }

    func textField(_ textField: V3FlatTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentLength = textField.text?.count ?? 0
        switch currentInputMethod {
        case .email:
            var text = textField.text ?? ""
            if let range = Range(range, in: text) {
                text.replaceSubrange(range, with: string)
                self.delegate?.needUpdateButton(enable: config.emailRegex.evaluate(with: text))
            }
        case .phoneNumber:
            self.delegate?.needUpdateButton(enable: !(currentLength + string.count - range.length < textField.formatMaxLength()))
        }
        return true
    }
}

class LoginSegContainer: UIView {
    init(content: UIView) {
        super.init(frame: .zero)
        backgroundColor = .clear

        addSubview(content)
        content.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(LoginSegLayout.segInputSpace)
            make.height.equalTo(LoginSegLayout.inputViewHeight)
            make.left.bottom.right.equalToSuperview().inset(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoginSegment: StandardSegment {

    override init() {
        super.init()
        self.backgroundColor = .clear
        self.titleNormalColor = UIColor.ud.textCaption
        self.titleSelectedColor = UIColor.ud.primaryContentDefault
        self.spacing = LoginSegLayout.segmentSpace
        self.height = LoginSegLayout.segmentHeight
        self.contentView.alignment = .leading
        self.contentView.distribution = .fill
        self.contentView.snp.remakeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.shadowColor = nil
        self.layer.shadowOpacity = 0.0
        self.layer.shadowOffset = .zero
        self.layer.shadowPath = nil
    }
}

enum LoginSegLayout {
    static let inputViewHeight: CGFloat = 48.0
    static let segInputSpace: CGFloat = 15.0
    static let segmentSpace: CGFloat = 34.0
    static let segmentHeight: CGFloat = 34.0
}
