import Foundation
import LarkUIKit
import LarkLocalizations
import SnapKit
import LKCommonsLogging
import RxSwift
import UniverseDesignActionPanel
import UniverseDesignColor

/// 输入联系方式页面
class SetCredentialViewController: BaseViewController {

    private lazy var mobileCodeProvider: MobileCodeProvider = {
        let topCountryList = vm.topCountryList
        let allowRegionList = vm.setCredentialInfo.allowRegionList ?? []
        let blockRegionList = vm.setCredentialInfo.blockRegionList ?? []
        return MobileCodeProvider(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: topCountryList,
            allowCountryList: allowRegionList,
            blockCountryList: blockRegionList
        )
    }()

    lazy var inputTextField: V3FlatTextField = {
        return initTextField()
    }()

    lazy private var bottomLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        label.attributedText = vm.bottomTip
        label.numberOfLines = 0
        return label
    }()

    let vm: SetCredentialViewModel

    init(vm: SetCredentialViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("input credential for credential type:\(vm.credentialType)")

        configTopInfo(vm.title, detail: vm.subTitle)
        nextButton.setTitle(vm.btnTitle, for: .normal)

        centerInputView.addSubview(inputTextField)
        centerInputView.addSubview(bottomLabel)

        inputTextField.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(CL.fieldHeight)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
        }

        let tipTopSpace = 24.0
        bottomLabel.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextField.snp.bottom).offset(tipTopSpace)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.bottom.equalToSuperview()
        }

        if vm.credentialType == .phone {
            let mobileCode = getMobileCode()
            inputTextField.labelText = mobileCode.code
            inputTextField.format = mobileCode.format
        }

        nextButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self](_) in
                self?.nextStep()
            }).disposed(by: disposeBag)

        self.logger.info("n_page_new_credential_start")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextField.becomeFirstResponder()
    }

    func nextStep() {
        let contact = inputTextField.currentText ?? ""
        logger.info("next to verify contact length \(contact.count)")
        logger.info("n_action_new_credential_next")
        logger.info("n_action_new_credential_next_req")
        self.showLoading()
        vm.verifyCredential(contact)
            .subscribe(onNext: { [weak self](_) in
                self?.logger.info("n_action_new_credential_succ")
                self?.stopLoading()
            }, onError: { [weak self](error) in
                self?.logger.error("n_action_new_credential_fail", error: error)
                self?.handle(error)
            }).disposed(by: disposeBag)
    }

    func checkButtonDisable() {
        let currentLength = inputTextField.text?.count ?? 0
        nextButton.isEnabled = !(currentLength == 0 || currentLength < inputTextField.formatMaxLength())
    }

    func getMobileCode() -> MobileCode {
        var mobileCode: MobileCode
        let defaultCode: String
        if let code = vm.setCredentialInfo.countryCode, !code.isEmpty {
            defaultCode = code
        } else {
            defaultCode = viewModel.service.config.registerRegionCode(for: viewModel.service.store.configEnv)
        }

        if let code = mobileCodeProvider.searchCountry(searchCode: defaultCode) {
            mobileCode = code
        } else {
            // swiftlint:disable ForceUnwrapping
            mobileCode = mobileCodeProvider.getFirstTopMobileCode() ?? mobileCodeProvider.getMobileCodes().first!
            // swiftlint:enable ForceUnwrapping
        }
        return mobileCode
    }

    func switchAreaCode() {
        if !vm.enableChangeRegionCode {
            return
        }
        
        if !vm.ncCountryChangeable {
            let mobileVC = MobileCodeSelectViewController(
                mobileCodeLocale: LanguageManager.currentLanguage,
                topCountryList: vm.topCountryList,
                allowCountryList: vm.setCredentialInfo.allowRegionList ?? [],
                blockCountryList: vm.setCredentialInfo.blockRegionList ?? []
            ) { [weak self] (mobileCode) in
                    guard let self = self else { return }
                    self.inputTextField.labelText = mobileCode.code
                    self.inputTextField.format = mobileCode.format
                    self.viewModel.service.storeCountryCode(code: mobileCode.code)
                    self.checkButtonDisable()
            }
            self.present(mobileVC, animated: true, completion: nil)
            return
        }
        
        var dataSource: [MobileCode] = []
        let mobileCodes = mobileCodeProvider.getMobileCodes()
        vm.ncCountryList.forEach { (code) in
            dataSource.append(contentsOf: mobileCodes.filter({ $0.code == code }))
        }
        
        if dataSource.count < 6 {
            switchAreaCodeWithActionPanel(dataSource: dataSource)
        }else {
            switchAreaCodeWithDataSource(dataSource)
        }
    }
    
    func switchAreaCodeWithDataSource(_ dataSource: [MobileCode]) {
        let mobileVC = MobileCodeSelectViewController(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: vm.topCountryList,
            allowCountryList: vm.setCredentialInfo.allowRegionList ?? [],
            blockCountryList: vm.setCredentialInfo.blockRegionList ?? []
        ) { [weak self] (mobileCode) in
                guard let self = self else { return }
                self.inputTextField.labelText = mobileCode.code
                self.inputTextField.format = mobileCode.format
                self.viewModel.service.storeCountryCode(code: mobileCode.code)
                self.checkButtonDisable()
        }
        mobileVC.modalPresentationStyle = .fullScreen
        self.present(mobileVC, animated: true, completion: nil)
    }
    
    func switchAreaCodeWithActionPanel(dataSource: [MobileCode]) {
        if !vm.enableChangeRegionCode {
            return
        }
        
        let mobileVC = SetCredentialMobileCodeViewController(
            countryList: dataSource) { [weak self] (mobileCode) in
                guard let self = self else { return }
                self.inputTextField.labelText = mobileCode.code
                self.inputTextField.format = mobileCode.format
                self.viewModel.service.storeCountryCode(code: mobileCode.code)
                self.checkButtonDisable()
        }
       
        if Display.pad {
            mobileVC.modalPresentationStyle = .popover
            mobileVC.popoverPresentationController?.sourceView = inputTextField.label
            mobileVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(mobileVC, animated: true, completion: nil)
        }else{
            let originY = UIScreen.main.bounds.height - mobileVC.contentHeight(count: dataSource.count)
            let panelVC = UDActionPanel(customViewController: mobileVC, config: UDActionPanelUIConfig(originY:originY,canBeDragged: false))
            self.present(panelVC, animated: true, completion: nil)
        }
    }
}

extension SetCredentialViewController: V3FlatTextFieldDelegate {
    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        if nextButton.isEnabled {
            nextStep()
        }
        return textField.resignFirstResponder()
    }

    func textField(_ textField: V3FlatTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        switch vm.credentialType {
        case .email:
            nextButton.isEnabled = !vm.isNextBtnDisableForEmail(currentText: currentText, range: range, string: string)
        case .phone:
            nextButton.isEnabled = !vm.isNextBtnDisableForMobile(
                currentLength: currentText.count,
                formatLength: textField.formatMaxLength(),
                rangeLength: range.length,
                stringLength: string.count
            )
        default:
            logger.error("credential type unhandle \(vm.credentialType)")
        }
        return true
    }

    func textFieldShouldClear(_ textField: V3FlatTextField) -> Bool {
        DispatchQueue.main.async {
            self.checkButtonDisable()
        }
        return true
    }
}

// MARK: - 控件初始化
extension SetCredentialViewController {

    func initTextField() -> V3FlatTextField {
        let type: V3FlatTextField.TypeEnum = vm.credentialType == .phone ? .phoneNumber : .email
        let textfield = V3FlatTextField(type: type, labelChangable: vm.enableChangeRegionCode)
        if type == .phoneNumber {
            textfield.labelTapGesture.rx.event.subscribe(onNext: { [weak self] _ in
                self?.switchAreaCode()
            }).disposed(by: self.disposeBag)
            textfield.labelFont = UIFont.systemFont(ofSize: 17)
            textfield.labelTextColor = UIColor.ud.textTitle
            textfield.textFieldTextColor = UIColor.ud.textTitle
            textfield.splitLineColor = UIColor.ud.lineBorderCard
            textfield.attributedPlaceholder = NSAttributedString(
                string: vm.setCredentialInfo.inputPlaceHolder.placeholder ?? BundleI18n.suiteLogin.Lark_Login_TelePlaceholeder,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.ud.textPlaceholder
                ]
            )
        } else {
            textfield.disableLabel = true
            textfield.attributedPlaceholder = NSAttributedString(
                string: vm.setCredentialInfo.inputPlaceHolder.placeholder ?? BundleI18n.suiteLogin.Lark_Login_EmailPlaceholder,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.ud.textPlaceholder
                ]
            )
        }
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.delegate = self
        textfield.textFiled.returnKeyType = .done
        return textfield
    }
}
