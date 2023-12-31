//
//  V3EnterpriseLoginViewController.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/10.
//

import Foundation
import RxSwift
import Homeric
import LarkPerf
import LarkAlertController
import LarkReleaseConfig
import LKCommonsLogging
import ECOProbeMeta
import LarkFontAssembly

class V3EnterpriseLoginViewController: BaseViewController {
    let plog = Logger.plog(V3EnterpriseLoginViewController.self, category: "EnterpriseLogin.V3EnterpriseLoginViewController")

    let vm: V3EnterpriseLoginViewModel

    init(vm: V3EnterpriseLoginViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var enterpriseAliasTextField: EnterpriseAliasTextField = {
        let textfield = EnterpriseAliasTextField()
        textfield.textFieldFont = ReleaseConfig.isLark ? .systemFont(ofSize: 16) : .boldSystemFont(ofSize: 17)
        textfield.returnKeyType = .done
        textfield.placeHolder = I18N.Lark_Login_IdP_placeholder
        textfield.returnBtnClicked = { [weak self] _ in
            guard let self = self else { return }
            if self.isInputValid() {
                self.confirmDomain()
            }
        }
        return textfield
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configTopInfo(vm.title, detail: vm.subtitle)
        nextButton.setTitle(I18N.Lark_Login_IdP_nextstep, for: .normal)
        switchButton.setTitle(I18N.Lark_Login_Idp_tip, for: .normal)
        enterpriseAliasTextField.delegate = self
        centerInputView.addSubview(enterpriseAliasTextField)
        enterpriseAliasTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView.snp.top)
            make.bottom.equalToSuperview().offset(-CL.itemSpace)
        }
        updateSelectionOption()
        nextButton.rx.tap.subscribe { [weak self] (_) in
            self?.confirmDomain()
        }.disposed(by: disposeBag)

        NotificationCenter.default
            .rx.notification(UITextField.textDidChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.checkBtnDisable()
            }).disposed(by: disposeBag)
        checkBtnDisable()
        setupLocaleNotification()
        setupFontNotification()

        PassportMonitor.flush(PassportMonitorMetaLogin.idpLoginEnter,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise],
                              context: vm.context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        plog.info("n_page_idp_login_start")
        
        _ = enterpriseAliasTextField.becomeFirstResponder()
        if let pn = pageName() {
            SuiteLoginTracker.track(pn)
        }
        SuiteLoginTracker.track(Homeric.PASSPORT_SSO_LOGIN_VIEW)
    }

    func setupLocaleNotification() {
        NotificationCenter.default.rx.notification(.preferLanguageChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
            })
            .disposed(by: disposeBag)
    }

    func setupFontNotification() {
        // 监听字体可能的变化（语言 或者 粗体），重新调用字体设置才能生效
        NotificationCenter.default.rx.notification(LarkFont.systemFontDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(LarkFont.boldTextStatusDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
            }).disposed(by: disposeBag)
    }

    func updateViewLocale() {
        // 重设文案以及字体以响应切换语言或者其他事件
        nextButton.setTitle(I18N.Lark_Login_IdP_nextstep, for: .normal)
        nextButton.resetFont()

        switchButton.setTitle(I18N.Lark_Login_Idp_tip, for: .normal)
        switchButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)

        enterpriseAliasTextField.placeHolder = I18N.Lark_Login_IdP_placeholder
        enterpriseAliasTextField.textFieldFont = ReleaseConfig.isLark ? .systemFont(ofSize: 16) : .boldSystemFont(ofSize: 17)

        configTopInfo(vm.title, detail: vm.subtitle)
        resetTitleFont()
    }

    func checkSSODomainSuffix() -> Bool {
        if let prefix = enterpriseAliasTextField.prefixText,
           !prefix.isEmpty,
           let suffix = enterpriseAliasTextField.suffixText,
           !suffix.isEmpty {
            let suffixWithDot: String
            if suffix.hasPrefix(".") {
                suffixWithDot = suffix
            } else {
                suffixWithDot = ".\(suffix)"
            }
            if vm.ssoDomains.map({ ".\($0)" }).contains(suffixWithDot) {
                // no dot suffix add dot after validate
                if !suffix.hasPrefix(".") {
                    self.enterpriseAliasTextField.suffixTextField.text = ".\(suffix)"
                }
                // valid domain suffix
                return true
            } else {
                // invalid domain suffix, suggest default domain
                showDomainInvalidAlert(prefix, suffix: ".\(vm.defaultDomain)")
                return false
            }
        } else {
            return false
        }
    }

    func showDomainInvalidAlert(_ prefix: String, suffix: String) {
        let adjustSSODomain = "\(prefix)\(suffix)"
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.suiteLogin.Lark_Login_SSO_ChangeDomainSuffix_title)
        alertController.setContent(text: BundleI18n.suiteLogin.Lark_Login_SSO_ChangeDomainSuffix_content(adjustSSODomain), alignment: .center)
        alertController.addSecondaryButton(text: BundleI18n.suiteLogin.Lark_Login_Cancel)
        alertController.addPrimaryButton(
            text: BundleI18n.suiteLogin.Lark_Login_ComfirmToRestPasword,
            dismissCompletion: {
                self.enterpriseAliasTextField.textFieldView.text = prefix
                self.enterpriseAliasTextField.suffixTextField.text = suffix
                self.confirmDomain()
            })
        present(alertController, animated: false)
    }

    func confirmDomain() {
        plog.info("n_action_idp_login_next")
        SuiteLoginTracker.track(Homeric.PASSPORT_SSO_LOGIN_CLICK, params: [
            "click" : "next",
        ])
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_company_login_next_click, context: vm.context)
        
        guard checkSSODomainSuffix() else {
            return
        }
        self.showLoading()
        self.updateFieldValueToVM()
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterContact.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "company_login",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        
        plog.info("n_action_idp_login_req")
        self.vm.idp(sceneInfo: sceneInfo).subscribe(onError: { [weak self] err in
            guard let self = self else { return }
            self.stopLoading()
            self.handle(err)
            
            self.plog.error("n_action_idp_login_req_fail", error: err)
        }, onCompleted: { [weak self] in
            guard let self = self else { return }
            self.stopLoading()
            self.plog.info("n_action_idp_login_req_suc")
        }).disposed(by: self.disposeBag)
    }

    func updateSelectionOption() {
        if let prefix = vm.service.store.ssoPrefix,
           !prefix.isEmpty,
           let suffix = vm.service.store.ssoSuffix,
           !suffix.isEmpty {
            // saved
            enterpriseAliasTextField.textFieldView.text = prefix
            enterpriseAliasTextField.selectOption = suffix
        } else {
            // default
            enterpriseAliasTextField.selectOption = ".\(vm.defaultDomain)"
        }
        enterpriseAliasTextField.layoutIfNeeded()
    }

    func checkBtnDisable() {
        nextButton.isEnabled = isInputValid()
    }

    override func pageName() -> String? {
        return vm.pageName
    }

    func isInputValid() -> Bool {
        guard let alias = enterpriseAliasTextField.prefixText,
            !alias.isEmpty,
            let domain = enterpriseAliasTextField.suffixText,
            !domain.isEmpty else {
                return false
        }
        return true
    }

    func updateFieldValueToVM() {
        if let alias = enterpriseAliasTextField.currentText {
            vm.enterpiseSSODomain = alias
        }
        if let prefix = enterpriseAliasTextField.prefixText {
            vm.prefixAlias = prefix
        }
        if let suffix = enterpriseAliasTextField.suffixText {
            vm.suffixDomain = suffix
        }
    }

    override func needSwitchButton() -> Bool {
        return vm.needTipButton
    }

    override func switchAction(sender: UIButton) {
        SuiteLoginTracker.track(Homeric.PASSPORT_SSO_LOGIN_CLICK, params: [
            "click" : "domain_help",
        ])
        
        guard let url = vm.helpUrl else {
            logger.error("invalid sso help url: \(String(describing: vm.ssoHelpUrl))")
            return
        }
        vm.post(
            event: V3NativeStep.simpleWeb.rawValue,
            serverInfo: nil,
            additionalInfo: V3SimpleWebInfo(url: url),
            success: {},
            error: { [weak self] err in
                self?.handle(err)
            })
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaLogin.idpLoginCancel,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise],
                              context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }
    
    func showSuffixPicker() {
        let suffixRaw = vm.supportedSSODomains
        let textFieldSuffixString = enterpriseAliasTextField.suffixText
        let suffixData: [SegPickerItem] = suffixRaw.map { SegPickerItem(content: $0, isSelected: $0 == textFieldSuffixString) }
        
        let dataSource: [(String, [SegPickerItem])] = [(I18N.Lark_PassportTenantGeoSetting_SSOLoginPage_SelectDomain_Title, suffixData)]
        let height: CGFloat = suffixData.isEmpty ? 0 : CGFloat(suffixData.count) * 51.5 + 50 + view.safeAreaInsets.bottom
        let picker = SegmentPickerViewController(
            segStyle: .default,
            headerStyle: .standard,
            presentationStyle: isPad ? .full : .fixedHeight(height: height),
            dataSource: dataSource,
            didSelect: { [weak self] indexes in
                guard let self = self else { return }
                guard indexes.count == 1 else {
                    self.logger.error("n_action_enterprise_login_suffix_indexes_count \(indexes.count)")
                    return
                }
                
                let index = indexes[0]
                if index < suffixRaw.count {
                    let suffixString = suffixRaw[index]
                    self.enterpriseAliasTextField.suffixTextField.text = suffixString
                } else {
                    self.logger.error("n_action_enterprise_login_suffix_index_out_of_range")
                }
            }, didDisappear: { [weak self] in
                guard let self = self else { return }
                self.enterpriseAliasTextField.updateSuffixSelectButton(false)
            }
        )
        if isPad {
            picker.modalPresentationStyle = .formSheet
        }
        
        self.present(picker, animated: true, completion: nil)
    }
}

extension V3EnterpriseLoginViewController: EnterpriseAliasTextFieldDelegate {
    func enterpriseAliasTextField(_ textField: EnterpriseAliasTextField, didTap suffixSelectButton: UIButton) {
        showSuffixPicker()
    }
}
