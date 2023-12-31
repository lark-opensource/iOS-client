//
//  VerifyViewControllerProtocol.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/17.
//

import Foundation
import RxSwift
import Homeric
import SnapKit
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl
import LarkReleaseConfig

protocol VerifyViewControllerProtocol: AnyObject {

    // MARK: Switch UI
    func updateVerifyView()
    func beginEdit()
    func handleVerifyError()

    // MARK: context
    var currentVC: BaseViewController { get }
    var verifyState: VerifyStateProtocol { get }
    var verifyAPI: VerifyProtocol { get }
    var webAuthNAPI: WebauthNServiceProtocol { get }

    var currentVerifyControl: V3VerifyCodeControl? { get }
    var currentPwdTextField: ALPasswordTextField? { get }
}

// MARK: Switch UI

extension VerifyViewControllerProtocol {

    func updateView(animate: Bool = true, beginEdit: Bool = true) {
        if animate {
            UIView.animate(withDuration: 0.2, animations: {
                self.currentVC.moveBoddyView.alpha = 0
            }) { (_) in
                self.updateVerifyView()
                self.update(beginEdit: beginEdit)
                UIView.animate(withDuration: 0.2, animations: {
                    self.currentVC.moveBoddyView.alpha = 1
                })
            }
        } else {
            self.updateVerifyView()
            self.update(beginEdit: beginEdit)
        }
    }

    func updateVerifyCodeView(
        show: Bool,
        verifyControl: V3VerifyCodeControl,
        tipLabel: LinkClickableLabel,
        recoverAccountLabel: LinkClickableLabel? = nil,
        pageInfo: VerifyPageInfo? = nil,
        verifyCodeState: VerifyCodeState
    ) {
        let alpha: CGFloat = show ? 1 : 0
        verifyControl.view.alpha = alpha
        tipLabel.alpha = alpha
        // 在 iPad 场景下，点击键盘上的 tab key 会将 firstResponder 置为背后的 textField，通过这样的方式避免
        verifyControl.updateTextFieldUserInteraction(show)
        if show {
            currentVC.nextButton.alpha = 0
            updateVerifyTip(tipLabel: tipLabel, tip: verifyCodeState.verifyTip)
            if let recoverLabel = recoverAccountLabel,
                let pageInfo = pageInfo,
                let _ = pageInfo.retrieveButton,
                PassportSwitch.shared.value(.recoverAccount) {
                updateRecoverAccountTip(recoverAccountLabel: recoverLabel, tip: verifyCodeState.recoverAccountTip(pageInfo: pageInfo,linkTile: verifyState.retrieveLinkTitle))
            }
        }
        if show, !verifyCodeState.hasApplyCode {
            verifyCodeState.hasApplyCode = true
            applyCode()
        }
        
        updateVerifyCodeViewConstraints(verifyCodeControl: verifyControl, show: show)
    }

    func updateVerifyTip(tipLabel: LinkClickableLabel, tip: NSAttributedString) {
        tipLabel.attributedText = tip
    }

    func updateRecoverAccountTip(recoverAccountLabel: LinkClickableLabel, tip: NSAttributedString) {
        recoverAccountLabel.attributedText = tip
    }

    func update(beginEdit: Bool = true) {
        currentVC.configTopInfo(verifyState.title, detail: verifyState.subtitle)
        currentVC.updateSwitchBtnTitle(verifyState.switchBtnTitle)
        if beginEdit {
            self.beginEdit()
        }
    }

    func beginEdit() {
        if let control = currentVerifyControl {
            control.beginEdit()
        }
        if let textField = self.currentPwdTextField {
            textField.becomeFirstResponder()
        }
    }

}

// MARK: VerifyCode UI

extension VerifyViewControllerProtocol {

    func createVerifyControl(
        needCountDown: Bool = true,
        verifyCodeState: VerifyCodeState,
        tipLabel: LinkClickableLabel,
        source: V3VerifyCodeControl.Source
    ) -> V3VerifyCodeControl {
        return V3VerifyCodeControl(
            needCountDown: needCountDown,
            withResentBlock: { [weak self] in
                self?.currentVC.logger.info("resend code")
                self?.applyCode()
                switch source {
                case .login:
                    SuiteLoginTracker.track(Homeric.PASSPORT_CLICK_RESEND_VERIFY_CODE)
                    SuiteLoginTracker.track(Homeric.VERIFY_CODE_CLICK_RESEND)
                case .switchUser:
                    SuiteLoginTracker.track(Homeric.IDP_VERIFYCODE_RESEND)
                }
            }, textChangeBlock: { (newValue) in
                verifyCodeState.code = newValue
            }, verifyCodeBlock: { [weak self] (code) in
                self?.currentVC.logger.info("verify code start", method: .local)
                verifyCodeState.code = code
                self?.verify({})
            }, beginEdit: false,
               timeoutBlock: { [weak self] in
                verifyCodeState.timeout = true
                self?.updateVerifyTip(tipLabel: tipLabel, tip: verifyCodeState.verifyTip)
               },
               source: source)
    }

    func setupVerifyCodeView(
        verifyCodeControl: V3VerifyCodeControl,
        tipLabel: LinkClickableLabel,
        recoverAccountLabel: LinkClickableLabel? = nil
    ) {
        currentVC.centerInputView.addSubview(verifyCodeControl.view)
        updateVerifyCodeViewConstraints(verifyCodeControl: verifyCodeControl, show: false)
        
        currentVC.inputAdjustView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(currentVC.switchButtonContainer.snp.bottom).offset(CL.processTipTopSpace)
            make.left.equalTo(currentVC.moveBoddyView).inset(CL.itemSpace)
            make.right.lessThanOrEqualTo(currentVC.moveBoddyView).inset(CL.itemSpace)
            make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }

        if let recoverLabel = recoverAccountLabel {
            currentVC.inputAdjustView.addSubview(recoverLabel)
            recoverLabel.snp.makeConstraints { (make) in
                make.top.equalTo(currentVC.switchButtonContainer.snp.bottom).offset(CL.processTipTopSpace)
                make.left.equalTo(currentVC.moveBoddyView).inset(CL.itemSpace)
                make.right.lessThanOrEqualTo(currentVC.moveBoddyView).inset(CL.itemSpace)
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            }
        }
    }
    
    func updateVerifyCodeViewConstraints(verifyCodeControl: V3VerifyCodeControl, show: Bool) {
        guard verifyCodeControl.view.superview != nil else { return }
        
        verifyCodeControl.view.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(CL.itemSpace)
            make.right.equalToSuperview().inset(CL.itemSpace)
            if show {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalToSuperview().priority(.low)
            }
        }
    }

    func setupBindVerifyCode(verifyCodeState: VerifyCodeState, verifyControl: V3VerifyCodeControl) {
        verifyCodeState
            .expire
            .asObservable()
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak verifyControl] (count) in
                verifyControl?.updateCountDown(uint(count))
            }).disposed(by: currentVC.disposeBag)
    }

}

// MARK: VerifyPwd UI
extension VerifyViewControllerProtocol {
    func createPwdTextField(verifyPwdState: VerifyPwdState, placeholder: String) -> ALPasswordTextField {
        let textField = ALPasswordTextField(
            placeholder: placeholder,
            textChangeBlock: { [weak self] (value) in
                let newValue = value ?? ""
                verifyPwdState.password = newValue
                self?.currentVC.nextButton.isEnabled = !newValue.isEmpty
            },
            returnBtnClickedBlock: { [weak self] (_) in
                guard let self = self else { return }
                self.currentVC.logger.info("keyboard done button click")
                self.verify()
            },
            autoBecomeFirstResponder: false)
        textField.returnKeyType = .done
        return textField
    }

    func setupPwdView(textField: ALPasswordTextField, tipLabel: LinkClickableLabel) {
        currentVC.centerInputView.addSubview(textField)
        updatePasswordViewConstraints(textField: textField, show: false)
        
        currentVC.inputAdjustView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(currentVC.switchButtonContainer.snp.bottom).offset(CL.processTipTopSpace)
            make.left.equalTo(currentVC.moveBoddyView).inset(CL.itemSpace)
            make.right.lessThanOrEqualTo(currentVC.moveBoddyView).inset(CL.itemSpace)
            make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }
        currentVC.nextButton.setTitle(I18N.Lark_Login_V3_NextStep, for: .normal)
    }

    func setupBindPwd() {
        currentVC.nextButton.rx.tap.subscribe(onNext: { [weak self] () in
            self?.currentVC.logger.info("verify next button click")
            self?.verify()
        }).disposed(by: currentVC.disposeBag)
    }

    func updatePasswordView(
        show: Bool,
        textField: ALPasswordTextField,
        tipLabel: LinkClickableLabel,
        pageInfo: VerifyPageInfo?,
        verifyPwdState: VerifyPwdState
    ) {
        let alpha: CGFloat = show ? 1 : 0
        textField.alpha = alpha
        tipLabel.alpha = alpha
        // 在 iPad 场景下，点击键盘上的 tab key 会将 firstResponder 置为背后的 textField，通过这样的方式避免
        textField.isUserInteractionEnabled = show
        if show {
            currentVC.nextButton.alpha = 1
            updateVerifyTip(tipLabel: tipLabel, tip: verifyPwdState.resetPwdTip(pageInfo: pageInfo))
        }
        
        updatePasswordViewConstraints(textField: textField, show: show)
    }
    
    func updatePasswordViewConstraints(textField: ALPasswordTextField, show: Bool) {
        guard textField.superview != nil else { return }
        
        textField.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(CL.fieldHeight)
            make.right.left.equalToSuperview().inset(CL.itemSpace)
            if show {
                make.bottom.equalToSuperview().inset(CL.itemSpace)  // 调整文本框与下方的间距
            } else {
                make.bottom.equalToSuperview().priority(.low)
            }
        }
    }

}


// MARK: VeryfyMoItem UI

extension VerifyViewControllerProtocol{
    func createVerifyMoItemView(verifyMoState: VerifyMoState, verifyInfo: VerifyInfoProtocol) -> VerifyMoBoxView {
        let moVerifyView = VerifyMoBoxView()

        
        guard let verifyMoInfo = verifyInfo.verifyMo?.moTextList,
           let skipButtonInfo = verifyInfo.verifyMo?.nextButton else {
                self.currentVC.logger.error("n_page_verify_mo_present_fail")
                return moVerifyView
        }
        
         //如果返回的数据列表元素个数不为 2 就不展示
         guard verifyMoInfo.count == 2 else {
             self.currentVC.logger.error("n_page_verify_mo_present_fail")
             return moVerifyView
         }
        
        var constraintNext = moVerifyView.snp.top
        for i in 0..<verifyMoInfo.count {
             let moTextBox = verifyMoInfo[i]
             var itemSpace = CL.itemSpace
             if i <= 0 {
                 itemSpace = 0
             }
            let moTextItemView = VerifyMoItemView(title: moTextBox.title ?? "", content: moTextBox.content ?? "", buttonText: moTextBox.copyButton?.text ?? "",itemType: i)
            moVerifyView.addSubview(moTextItemView)
            if i == 0 {
                moVerifyView.recipientsView = moTextItemView
            } else {
                moVerifyView.mesContentView = moTextItemView
            }
            moTextItemView.snp.makeConstraints { make in
                 make.top.equalTo(constraintNext).offset(itemSpace)
                 make.left.right.equalToSuperview().inset(CL.safeAreaLeft)
                 make.height.equalTo(90)
             }
            constraintNext = moTextItemView.snp.bottom
         }

        return moVerifyView
    }

    func setupVerifyMoView(verifyMoView: UIView, skipToMessageButton: NextButton) {
        
        currentVC.moveBoddyView.addSubview(verifyMoView)

        //设置中心内容区域
        verifyMoView.snp.makeConstraints { make in
            make.top.equalTo(currentVC.detailLabel.snp.bottom).offset(24)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(currentVC.nextButton.snp.top).offset(-CL.itemSpace)
        }

        verifyMoView.addSubview(skipToMessageButton)

        //重新设置Layout
        //设置跳转到短信页的按钮
        skipToMessageButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(CL.safeAreaLeft)
            make.bottom.equalToSuperview()
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
                
    }
    
    
    func updateVerifyMoView(
        show: Bool,
        verifyMoView: VerifyMoBoxView,
        skipToMessageButton: NextButton,
        pageInfo: VerifyPageInfo? = nil,
        verifyMoState: VerifyMoState
    ) {
        let alpha: CGFloat = show ? 1 : 0
        verifyMoView.alpha = alpha
        // 在 iPad 场景下，点击键盘上的 tab key 会将 firstResponder 置为背后的 textField，通过这样的方式避免
        verifyMoView.isUserInteractionEnabled = show
        if show {
            currentVC.nextButton.alpha = 1
            currentVC.nextButton.update(style: .roundedRectWhiteWithGrayOutline)
            currentVC.nextButton.setTitle(pageInfo?.nextButton?.text, for: .normal)
            currentVC.nextButton.isEnabled = true
            
            skipToMessageButton.alpha = 1
            skipToMessageButton.setTitle(pageInfo?.sendMoButton?.text, for: .normal)
            
        }
        
    }
    
    func setupBindMessageView(
        pageInfo: VerifyPageInfo?,
        skipToMessageButton: NextButton,
        openMessageFunc: @escaping (URL?) -> (Void)
    ) {
        guard let pageInfo = pageInfo else {
            return
        }
        //读取收件人号码
        let recipient = pageInfo.moTextList?[0].content ?? ""
        //读取短信内容
        let content = pageInfo.moTextList?[1].content ?? ""
        skipToMessageButton.rx.tap.subscribe { _ in
            //复制短信内容并打开短信发送页面
            let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_context_jump_messager"))
            SCPasteboard.general(config).string = content
            let url = URL(string: "sms://\(recipient)")
            openMessageFunc(url)
        }.disposed(by: currentVC.disposeBag)
    }

    func setupBindCopyButton(
        pageInfo: VerifyPageInfo?,
        verifyBoxView: VerifyMoBoxView
    ) {
        if let recipientsView = verifyBoxView.recipientsView,
           let mesContentView = verifyBoxView.mesContentView {
            recipientsView.copyButton.rx.tap.subscribe { _ in
                let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_phoneNumber"))
                if let pasteboard = try? SCPasteboard.generalUnsafe(config) {
                    pasteboard.string = recipientsView.contentView.text
                    UDToast.showTips(with: I18N.Lark_Legacy_CopyReady,on: self.currentVC.view)
                } else {
                    UDToast.showTips(with: I18N.Lark_AdminUpdate_Toast_MobileFailedToCopy,on: self.currentVC.view)
                }
                SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                    "flow_type": pageInfo?.flowType,
                    "target": "none",
                    "click": "copy_number",
                ])
            }.disposed(by: recipientsView.disposeBag)

            mesContentView.copyButton.rx.tap.subscribe { _ in
                let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_context"))
                if let pasteboard = try? SCPasteboard.generalUnsafe(config) {
                    pasteboard.string = mesContentView.contentView.text
                    UDToast.showTips(with: I18N.Lark_Legacy_CopyReady,on: self.currentVC.view)
                } else {
                    UDToast.showTips(with: I18N.Lark_AdminUpdate_Toast_MobileFailedToCopy,on: self.currentVC.view)
                }
                SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                    "flow_type": pageInfo?.flowType,
                    "target": "none",
                    "click": "copy_msg",
                ])
            }.disposed(by: mesContentView.disposeBag)
        }

    }
    
}

// MARK: VerifyCode API

extension VerifyViewControllerProtocol {
    func applyCode() {
        currentVerifyControl?.startTime()
        verifyAPI.applyCode()
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (error) in
                self?.currentVC.handle(error)
            }).disposed(by: currentVC.disposeBag)
    }

    func verify(_ complete: @escaping () -> Void = {}) {
        if verifyState.isVerifying {
            return
        }
        verifyState.isVerifying = true
        /// showLoading 夹在中间c会触发 textfield代理, 导致重复调用 verify_code
        currentVC.showLoading()
        verifyAPI.verify()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                    guard let `self` = self else { return }
                    self.currentVC.stopLoading()
                    self.verifyState.isVerifying = false
                    complete()
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    self.currentVC.stopLoading()
                    self.verifyState.isVerifying = false
                    self.currentVC.handle(error)
                    self.handleVerifyError()
                    self.beginEdit() // showloading 会end edit
            }).disposed(by: currentVC.disposeBag)
    }

    func handleVerifyError() {
        if let control = currentVerifyControl {
            control.resetView()
        }
        if let textField = self.currentPwdTextField {
            textField.textFieldView.text = ""
            currentVC.nextButton.isEnabled = false
        }
    }

}

// MARK: VerifyFido2 UI & API

extension VerifyViewControllerProtocol {
    func createFidoVerifyView(verifyFidoState: VerifyFidoState) -> UIView {
        let fidoVeifyView = UIView()
        return fidoVeifyView
    }

    func setupVerifyFidoView(verifyFidoView: UIView, verifyButton: NextButton) {
        verifyFidoView.addSubview(verifyButton)
        currentVC.centerInputView.addSubview(verifyFidoView)
        verifyButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        verifyFidoView.snp.makeConstraints { make in
            make.top.equalTo(currentVC.detailLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(CL.safeAreaLeft)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
    }

    func updateVerifyFidoView(
        show: Bool,
        verifyFidoView: UIView,
        verifyButton: NextButton,
        pageInfo: VerifyPageInfo? = nil,
        verifyFidoState: VerifyFidoState
    ) {
        let alpha: CGFloat = show ? 1 : 0
        verifyFidoView.alpha = alpha
        // 在 iPad 场景下，点击键盘上的 tab key 会将 firstResponder 置为背后的 textField，通过这样的方式避免
        verifyFidoView.isUserInteractionEnabled = show
        if show {
            verifyButton.alpha = 1
            verifyButton.update(style: .roundedRectBlue)
            verifyButton.setTitle(pageInfo?.nextButton?.text, for: .normal)
            verifyButton.isEnabled = true

            currentVC.nextButton.alpha = 0
        }

    }

    func setupFidoVerifyButton(
        pageInfo: VerifyPageInfo?,
        usePackageDomain: Bool?,
        verifyFidoButton: NextButton,
        context: UniContextProtocol
    ) {
        verifyFidoButton.rx
            .tap
            .asDriver()
            .throttle(.seconds(5),latest: false)
            .drive(onNext:{
                let params = SuiteLoginTracker.makeCommonViewParams(flowType: pageInfo?.flowType ?? "", data: ["target": "none",
                                                                                                     "click": "use_fido"])
                SuiteLoginTracker.track(Homeric.PASSPORT_FIDO_VERIFY_CLICK, params: params)

                if self.webAuthNAPI.webAuthNService == nil {
                    if #available(iOS 16.0, *), PassportStore.shared.enableNativeWebauthnAuth, !ReleaseConfig.isKA {
                        self.webAuthNAPI.webAuthNService = PassportWebauthServiceNativeImpl(actionType: .auth,
                                                                             context: context,
                                                                             addtionalParams: ["flow_type": pageInfo?.flowType ?? ""],
                                                                             callback: {[weak self] _,_ in
                            self?.webAuthNAPI.webAuthNService = nil},
                                                                             usePackageDomain: usePackageDomain ?? false,
                                                                             errorHandler: {[weak self] error in
                            self?.currentVC.handle(error)
                        })
                        self.webAuthNAPI.webAuthNService?.start()
                    } else if #available(iOS 14.0, *){
                        self.webAuthNAPI.webAuthNService = PassportWebAuthServiceBrowserImpl(actionType: .auth,
                                                                                             context: context,
                                                                                             addtionalParams: ["flow_type": pageInfo?.flowType ?? ""],
                                                                                             callback: {[weak self] _,_ in self?.webAuthNAPI.webAuthNService = nil},
                                                                                             usePackageDomain: usePackageDomain ?? false,
                                                                                             errorHandler: {[weak self] error in
                                                                                                 self?.currentVC.handle(error)
                                                                                             })
                        self.webAuthNAPI.webAuthNService?.start()
                    } else {
                        let endReason = EndReason.systemNotSupport
                        V3ErrorHandler.showAlert(endReason.getMessage(type: .auth), vc: self.currentVC, confirm: {})
                    }
                }
            }).disposed(by: currentVC.disposeBag)
    }
}
