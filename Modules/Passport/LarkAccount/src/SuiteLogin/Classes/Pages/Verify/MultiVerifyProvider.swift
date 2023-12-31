//
//  MultiVerifyProvider.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/8/21.
//

import Foundation
import RxSwift
import RxRelay
import SnapKit
import Homeric
import LarkEMM
import LarkContainer
import LKCommonsLogging
import LarkReleaseConfig
import LarkSensitivityControl

protocol VerifyProvider {

    var needNextButton: Bool { get }

    var enableNext: BehaviorRelay<Bool> { get }

    var verifyStatus: PublishSubject<VerifyStatus> { get }

    var needSkipWhilePop: Bool { get }

    func layoutMaker(make: SnapKit.ConstraintMaker) -> Void

    func getVerifyPageInfo() -> VerifyTypeInfo

    func getRetrieveText() -> NSAttributedString?

    func getVerifyContentView() -> UIView

    func doVerify(_ complete: @escaping () -> Void)

    func doRetrieve(_ complete: @escaping () -> Void)

    func verifyDidAppear()

    func setupBottom(nextButton: NextButton, bottomView: UIView)

}

class VerifyCommonProvider: VerifyProvider {

    private let logger = Logger.plog(VerifyCommonProvider.self, category: "VerifyCommonProvider")

    private var _verifyPageInfo: VerifyTypeInfo

    @Provider var verifyAPI: VerifyAPI // user:checked (global-resolve)

    var needSkipWhilePop: Bool

    var context: UniContextProtocol

    var verifyStatus: RxSwift.PublishSubject<VerifyStatus>

    var isVerifying: Bool = false

    let disposeBag = DisposeBag()

    var needNextButton: Bool

    var enableNext: RxRelay.BehaviorRelay<Bool>

    func getRetrieveText() -> NSAttributedString? {
        return nil
    }

    func layoutMaker(make: SnapKit.ConstraintMaker) -> Void {
        make.top.equalToSuperview()
        make.bottom.equalToSuperview()
        make.left.right.equalToSuperview().inset(CL.itemSpace)
    }

    func getVerifyPageInfo() -> VerifyTypeInfo {
        return _verifyPageInfo
    }

    func getVerifyContentView() -> UIView {
        UIView()
    }

    func doVerify(_ complete: @escaping () -> Void = {}) {
        if isVerifying {
            return
        }
        isVerifying = true
        verifyStatus.onNext(.start)
        /// showLoading 夹在中间c会触发 textfield代理, 导致重复调用 verify_code
        verifyInternal()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.isVerifying = false
                    self.verifyStatus.onNext(.succ)
                    complete()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.verifyStatus.onNext(.fail(error))
                    self.isVerifying = false
                    self.resetVerify()
            }).disposed(by: disposeBag)
    }

    func doRetrieve(_ complete: @escaping () -> Void) {
        self.verifyStatus.onNext(.start)
        if let nextStep = getVerifyPageInfo().retrieveButton?.next,
           let stepInfo = nextStep.stepInfo,
           let action = stepInfo["action"] as? Int {
            verifyAPI
                .retrieveGuideWay(serverInfo: getVerifyPageInfo(), action: action, context: context)
                .post(context: context)
                .subscribe { [weak self] _ in
                    self?.logger.info("n_action_doRetrieve")
                    self?.verifyStatus.onNext(.succ)
                } onError: { [weak self] error in
                    self?.verifyStatus.onNext(.commonError(error))
                }.disposed(by: disposeBag)

        } else {
            self.verifyStatus.onNext(.fail(V3LoginError.toastError(I18N.Lark_Passport_BadServerData)))
        }
    }

    func verifyInternal() -> Observable<Void> {
        assertionFailure("please implement in subclass")
        return Observable.create { ob in
            // 空实现
            ob.onCompleted()
            return Disposables.create()
        }
    }

    /// 展示该验证方式时执行，父类提供空实现
    func verifyDidAppear() {
        logger.info("n_action_verify_appear")
    }

    /// 验证失败时重置，父类提供空实现
    func resetVerify() { assertionFailure("please implement in subclass") }

    func setupBottom(nextButton: NextButton, bottomView: UIView) {
        if let nextButtonInfo = getVerifyPageInfo().nextButton {
            nextButton.title = nextButtonInfo.text
            self.enableNext.bind { isEnable in
                nextButton.isEnabled = isEnable
            }.disposed(by: self.disposeBag)
        }
        nextButton.isHidden = !needNextButton
    }

    init(pageInfo: VerifyTypeInfo, context: UniContextProtocol) {
        self._verifyPageInfo = pageInfo
        self.context = context
        self.verifyStatus = PublishSubject<VerifyStatus>()
        self.needNextButton = false
        self.enableNext = BehaviorRelay<Bool>(value: false)
        self.needSkipWhilePop = true
    }
}

class VerifyCodeProvider: VerifyCommonProvider {

    let logger = Logger.plog(VerifyCodeProvider.self, category: "VerifyCodeProvider")

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyCodePageInfo }

    private var verifyCodePageInfo: VerifyCodeInfo

    var statusPublisher = PublishSubject<VerifyStatus>()

    var code: String = ""

    var hasApplyCode: Bool = false

    let expire: BehaviorRelay<uint> = BehaviorRelay(value: 60)

    lazy var verifyCodeControl: V3VerifyCodeControl = {
        let verifyControl = V3VerifyCodeControl(
            needCountDown: true,
            withResentBlock: { [weak self] in
                self?.logger.info("n_action_verify_code_resend")
                self?.applyCode()
                // TODO: 业务埋点
            }, textChangeBlock: { (newValue) in
                self.code = newValue
            }, verifyCodeBlock: { [weak self] (code) in
                self?.code = code
                self?.doVerify({})
            }, beginEdit: false,
               timeoutBlock: nil,
               source: .login)
        verifyControl.countdownButton.contentEdgeInsets = .init(edges: CGFLOAT_MIN)
        return verifyControl
    }()

    override func getVerifyContentView() -> UIView {
        return verifyCodeControl.view
    }

    init(pageInfo: VerifyCodeInfo, context: UniContextProtocol) {
        self.verifyCodePageInfo = pageInfo
        super.init(pageInfo: pageInfo, context: context)
        self.needNextButton = false
        self.enableNext = BehaviorRelay<Bool>(value: false)
    }

    func applyCode() {
        self.logger.info("n_action_verify_code_apply")
        verifyCodeControl.startTime()
        PassportMonitor.monitor(PassportMonitorMetaStep.startCodeApply,
                                eventName: ProbeConst.monitorEventName,
                                context: context).flush()
        let durationKey = verifyCodePageInfo.flowType ?? "verifyCode" + "Apply"
        ProbeDurationHelper.startDuration(durationKey)
        verifyAPI
            .applyCode(serverInfo: verifyCodePageInfo, context: context)
            .post(context: context)
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else { return }
                let duration = ProbeDurationHelper.stopDuration(durationKey)
                PassportMonitor.monitor(PassportMonitorMetaStep.codeApplyResult,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration],
                                        context: self.context)
                .setResultTypeSuccess()
                .flush()
            }, onError: {[weak self] error in
                guard let self = self else { return }
                if let err = error as? V3LoginError, case .badServerCode(let info) = err {
                    self.logger.error("n_action_verify_code_apply_fail", error: error)
                    if info.type == .applyCodeTooOften, let exp = info.detail[V3.Const.expire] as? uint {
                        self.verifyCodeControl.updateCountDown(exp)
                    } else if info.type == .needTuringVerify {
                        // 命中风控，倒计时清零
                        self.verifyCodeControl.updateCountDown(0)
                    }
                    let duration = ProbeDurationHelper.stopDuration(durationKey)
                    PassportMonitor.monitor(PassportMonitorMetaStep.codeApplyResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration],
                                            context: self.context)
                    .setResultTypeFail()
                    .setPassportErrorParams(error: error)
                    .flush()
                }
                self.verifyStatus.onNext(.commonError(error))
            }).disposed(by: disposeBag)
        hasApplyCode = true
    }

    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_code_start")
        return verifyAPI
            .verifyCode(
                serverInfo: verifyCodePageInfo,
                code: code,
                context: context
            )
            .post(context: context)
            .do(onNext: { [weak self] (_) in
                self?.logger.info("n_action_verify_code_succ")
            }, onError: {[weak self] error in
                self?.logger.error("n_action_verify_code_fail", error: error)
            })
    }

    override func getRetrieveText() -> NSAttributedString? {
        if let retrieveBtn = getVerifyPageInfo().retrieveButton {
            let attributedString = NSMutableAttributedString.tip(str: retrieveBtn.text + " ", color: UIColor.ud.textPlaceholder)
            let suffixLink = NSAttributedString.link(
                str: I18N.Lark_Login_RecoverAccountTextLink,
                url: Link.retrieveAction,
                font: UIFont.systemFont(ofSize: 14.0)
            )
            attributedString.append(suffixLink)
            return attributedString
        } else {
            return nil
        }
    }

    override func resetVerify() {
        self.verifyCodeControl.resetView()
        self.verifyCodeControl.beginEdit()
    }

    override func verifyDidAppear() {
        if !hasApplyCode {
            applyCode()
        }
        self.verifyCodeControl.beginEdit()
    }
}


class VerifyPwdProvider: VerifyCommonProvider {

    let logger = Logger.plog(VerifyPwdProvider.self, category: "verifyPwdProvider")

    override func getVerifyContentView() -> UIView {
        return passwordField
    }

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyPwdPageInfo }

    override func verifyDidAppear() {
        self.passwordField.becomeFirstResponder()
    }

    init(pageInfo: VerifyPwdInfo, context: UniContextProtocol) {
        self.verifyPwdPageInfo = pageInfo
        super.init(pageInfo: pageInfo, context: context)
        self.needNextButton = true
        self.enableNext = BehaviorRelay<Bool>(value: false)
    }

    private var verifyPwdPageInfo: VerifyPwdInfo

    lazy var passwordField: ALPasswordTextField = {
        let textField = ALPasswordTextField(
            placeholder: verifyPwdPageInfo.inputBox?.placeholder ?? I18N.Lark_Login_V3_InputPasswordPlaceholder,
            textChangeBlock: { [weak self] (value) in
                let newValue = value ?? ""
                self?.password = newValue
                self?.enableNext.accept(!newValue.isEmpty)
            },
            returnBtnClickedBlock: { [weak self] (_) in
                guard let self = self else { return }
                self.logger.info("keyboard done button click")
                self.doVerify({})
            },
            autoBecomeFirstResponder: false)
        textField.returnKeyType = .done
        return textField
    }()

    var password: String = ""

    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_pwd_start")
        let rsaInfo = verifyPwdPageInfo.rsaInfo
        return verifyAPI
            .verifyPwd(serverInfo: verifyPwdPageInfo, password: password, rsaInfo: rsaInfo, context: context)
            .post(context: context)
            .do(onNext: { [weak self] (_) in
                self?.logger.info("n_action_verify_pwd_succ")
            }, onError: { [weak self] error in
                self?.logger.error("n_action_verify_pwd_fail", error: error)
            })
    }

    override func layoutMaker(make: SnapKit.ConstraintMaker) -> Void {
        make.top.equalToSuperview()
        make.height.equalTo(CL.fieldHeight)
        make.right.left.equalToSuperview().inset(VerifyPageLayout.itemRightSpace)
        make.bottom.equalToSuperview() // 调整文本框与下方的间距
    }

    override func resetVerify() {
        enableNext.accept(false)
        passwordField.textFieldView.text = ""
        passwordField.becomeFirstResponder()
    }

    override func getRetrieveText() -> NSAttributedString? {
        if let retrieveBtn = getVerifyPageInfo().retrieveButton {
            let attributedString = NSMutableAttributedString.tip(str: retrieveBtn.text + " ", color: UIColor.ud.textPlaceholder)
            let suffixLink = NSAttributedString.link(
                str: I18N.Lark_Login_V3_ResetPwd,
                url: Link.retrieveAction,
                font: UIFont.systemFont(ofSize: 14.0)
            )
            attributedString.append(suffixLink)
            return attributedString
        } else {
            return nil
        }
    }

}

class verifyMoProvider: VerifyCommonProvider {

    let logger = Logger.plog(verifyMoProvider.self, category: "verifyMoProvider")

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyMoPageInfo }

    private var verifyMoPageInfo: VerifyMoInfo

    lazy var verifyMoListView: VerifyMoBoxView = {
        let moVerifyView = VerifyMoBoxView()

        guard let recipientsInfo = verifyMoPageInfo.moTextList?[0],
              let mesContentInfo = verifyMoPageInfo.moTextList?[1] else {
            self.logger.error("n_page_verify_mo_present_fail")
            return moVerifyView
        }

        let recipientsView = VerifyMoItemView(title: recipientsInfo.title ?? "", content: recipientsInfo.content ?? "", buttonText: recipientsInfo.copyButton?.text ?? "",itemType: 0)

        moVerifyView.addSubview(recipientsView)
        moVerifyView.recipientsView = recipientsView

        recipientsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CL.itemSpace)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
        }

        let mesContentView = VerifyMoItemView(title: mesContentInfo.title ?? "", content: mesContentInfo.content ?? "", buttonText: mesContentInfo.copyButton?.text ?? "",itemType: 1)

        moVerifyView.addSubview(mesContentView)
        moVerifyView.mesContentView = mesContentView

        mesContentView.snp.makeConstraints { make in
            make.top.equalTo(recipientsView.snp.bottom).offset(CL.itemSpace)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
            make.bottom.equalToSuperview()
        }

        bindCopyButtonAction(on: moVerifyView)

        return moVerifyView
    }()

    private lazy var skipToMessageButton: NextButton = {
        let button = NextButton(title: verifyMoPageInfo.sendMoButton?.text ?? "", style: .roundedRectBlue)
        bindSkipMessageAction(on: button)
        return button
    }()

    override func getVerifyContentView() -> UIView {
        return verifyMoListView
    }

    func bindCopyButtonAction(on verifyMoListView: VerifyMoBoxView) {
        if let recipientsView = verifyMoListView.recipientsView,
           let mesContentView = verifyMoListView.mesContentView {
            recipientsView.copyButton.rx.tap.subscribe {[weak self] _ in
                let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_phoneNumber"))
                if let pasteboard = try? SCPasteboard.generalUnsafe(config) {
                    pasteboard.string = recipientsView.contentView.text
                    self?.verifyStatus.onNext(.showTips(I18N.Lark_Legacy_CopyReady))
                } else {
                    self?.verifyStatus.onNext(.showTips(I18N.Lark_AdminUpdate_Toast_MobileFailedToCopy))
                    self?.logger.error("n_page_verify_mo_copy_fail")
                }
            }.disposed(by: disposeBag)

            mesContentView.copyButton.rx.tap.subscribe {[weak self] _ in
                let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_context"))
                if let pasteboard = try? SCPasteboard.generalUnsafe(config) {
                    pasteboard.string = mesContentView.contentView.text
                    self?.verifyStatus.onNext(.showTips(I18N.Lark_Legacy_CopyReady))
                } else {
                    self?.verifyStatus.onNext(.showTips(I18N.Lark_AdminUpdate_Toast_MobileFailedToCopy))
                    self?.logger.error("n_page_verify_mo_copy_fail")
                }
            }.disposed(by: disposeBag)
        }
    }

    func bindSkipMessageAction(on skipButton: NextButton) {
        //读取收件人号码
        let recipient = verifyMoPageInfo.moTextList?[0].content ?? ""
        //读取短信内容
        let content = verifyMoPageInfo.moTextList?[1].content ?? ""
        skipButton.rx.tap.subscribe {[weak self] _ in
            //复制短信内容并打开短信发送页面
            let config = PasteboardConfig(token: Token("LARK-PSDA-login_verify_mobile_original_context_jump_messager"))
            SCPasteboard.general(config).string = content
            let url = URL(string: "sms://\(recipient)")
            self?.openMessagePage(url: url)
        }.disposed(by: disposeBag)
    }

    func openMessagePage(url: URL?) {
        if let url = url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                "flow_type": self.verifyMoPageInfo.flowType ?? "",
                "target": "none",
                "click": "open_msg_app"
            ])
        } else {
            logger.error("n_page_verify_mo_skipToMessager_fail")
            self.verifyStatus.onNext(.showTips(I18N.Lark_Passport_SendTextToVerify_ManualCopyPaste_Toast))
        }
    }

    override func setupBottom(nextButton: NextButton, bottomView: UIView) {
        super.setupBottom(nextButton: nextButton, bottomView: bottomView)
        nextButton.update(style: .roundedRectWhiteWithGrayOutline)

        bottomView.addSubview(skipToMessageButton)
        //重新设置Layout
        //设置跳转到短信页的按钮
        skipToMessageButton.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(VerifyPageLayout.itemRightSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            make.top.equalToSuperview()
        }

        if nextButton.superview == bottomView {
            nextButton.snp.remakeConstraints { (make) in
                make.top.equalTo(skipToMessageButton.snp.bottom).offset(VerifyPageLayout.itemRightSpace)
                make.left.right.bottom.equalToSuperview().inset(CL.itemSpace)
                make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            }
        }

    }

    init(pageInfo: VerifyMoInfo, context: UniContextProtocol) {
        self.verifyMoPageInfo = pageInfo

        super.init(pageInfo: pageInfo, context: context)

        self.needNextButton = true
        self.enableNext = BehaviorRelay<Bool>(value: true)
    }


    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_mo_start")
        return verifyAPI.verifyMo(
            serverInfo: verifyMoPageInfo,
            context: context)
        .post(context: context)
        .do(onNext: {[weak self] (_) in
            guard let self = self else { return }
            self.logger.info("n_action_verify_mo_succ")
        }, onError: { _ in
            self.logger.error("n_action_verify_mo_fail")
        })
    }
}

class VerifyOTPProvider: VerifyCommonProvider {

    let logger = Logger.plog(VerifyOTPProvider.self, category: "VerifyOTPProvider")

    var code: String = ""

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyOtpPageInfo }

    private var verifyOtpPageInfo: VerifyCodeInfo

    lazy var verifyCodeControl: V3VerifyCodeControl = {
        V3VerifyCodeControl(
            needCountDown: false,
            textChangeBlock: { (newValue) in
                self.code = newValue
            },
            verifyCodeBlock: { [weak self] (code) in
                self?.code = code
                self?.doVerify({})
            },
            beginEdit: false,
            timeoutBlock: nil,
            source: .login)
    }()

    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_otp_start")
        return verifyAPI.verifyOtp(
            serverInfo: getVerifyPageInfo(),
            code: code,
            context: context
        )
        .post(context: context)
        .do(onNext: {[weak self] (_) in
            guard let self = self else { return }
            self.logger.info("n_action_verify_otp_succ")
        }, onError: { _ in
            self.logger.error("n_action_verify_otp_fail")
        })
    }

    override func getVerifyContentView() -> UIView {
        return verifyCodeControl.view
    }

    override func getRetrieveText() -> NSAttributedString? {
        if let retrieveBtn = getVerifyPageInfo().retrieveButton {
            let attributedString = NSMutableAttributedString.tip(str: retrieveBtn.text + " ", color: UIColor.ud.textPlaceholder)
            let suffixLink = NSAttributedString.link(
                str: I18N.Lark_Passport_OTPVerify_ResetOTP,
                url: Link.retrieveAction,
                font: UIFont.systemFont(ofSize: 14.0)
            )
            attributedString.append(suffixLink)
            return attributedString
        } else {
            return nil
        }
    }

    override func resetVerify() {
        self.verifyCodeControl.resetView()
        self.verifyCodeControl.beginEdit()
    }

    override func verifyDidAppear() {
        self.verifyCodeControl.beginEdit()
    }

    init(pageInfo: VerifyCodeInfo, context: UniContextProtocol) {
        self.verifyOtpPageInfo = pageInfo
        super.init(pageInfo: pageInfo, context: context)
        self.needNextButton = false
        self.enableNext = BehaviorRelay<Bool>(value: false)
    }
}

class VerifyFIDOProvider: VerifyCommonProvider {

    let logger = Logger.plog(VerifyFIDOProvider.self, category: "VerifyFIDOProvider")

    var verifyFIDOPageInfo: VerifyCommonInfo

    var webAuthNService: PassportWebAuthService?

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyFIDOPageInfo }

    override func getVerifyContentView() -> UIView {
        self.verifyButton
    }

    lazy var verifyButton: NextButton = {
        let btn = NextButton(title: verifyFIDOPageInfo.nextButton?.text ?? "")
        btn.rx
            .tap
            .asDriver()
            .throttle(.seconds(5),latest: false)
            .drive(onNext:{ [weak self] in
                guard let self = self else { return }
                self.doVerify()
            }).disposed(by: disposeBag)
        return btn
    }()

    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_fido_start")
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }
            let pageInfo = self.verifyFIDOPageInfo
            let usePackageDomain = self.verifyFIDOPageInfo.usePackageDomain
            if self.webAuthNService == nil {
                if #available(iOS 16.0, *), PassportStore.shared.enableNativeWebauthnAuth, !ReleaseConfig.isKA {
                    self.webAuthNService =
                    PassportWebauthServiceNativeImpl(actionType: .auth,
                                                     context: self.context,
                                                     addtionalParams: ["flow_type": pageInfo.flowType ?? ""],
                                                     callback: {[weak self] isSucc,_ in
                                                        if isSucc {
                                                            ob.onNext(())
                                                            self?.logger.info("n_action_verify_fido_succ")
                                                        }
                                                        self?.webAuthNService = nil},
                                                     usePackageDomain: usePackageDomain ?? false,
                                                     errorHandler: {[weak self] error in
                                                        ob.onError(error)
                                                        self?.logger.error("n_action_verify_fido_fail", error: error)
                                                     })
                    self.webAuthNService?.start()
                } else if #available(iOS 14.0, *) {
                    self.webAuthNService =
                    PassportWebAuthServiceBrowserImpl(actionType: .auth,
                                                      context: self.context,
                                                      addtionalParams: ["flow_type": pageInfo.flowType ?? ""],
                                                      callback: {[weak self] isSucc,_ in
                                                        if isSucc {
                                                            ob.onNext(())
                                                            self?.logger.info("n_action_verify_fido_succ")
                                                        }
                                                        self?.webAuthNService = nil},
                                                      usePackageDomain: usePackageDomain ?? false,
                                                      errorHandler: {[weak self] error in
                                                        ob.onError(error)
                                                        self?.logger.error("n_action_verify_fido_fail", error: error)
                                                      })
                    self.webAuthNService?.start()
                } else {
                    let endReason = EndReason.systemNotSupport
                    let error = V3LoginError.alertError(endReason.getMessage(type: .auth))
                    ob.onError(error)
                }
            }
            return Disposables.create()
        })
    }

    override func layoutMaker(make: SnapKit.ConstraintMaker) -> Void {
        make.top.equalToSuperview()
        make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        make.right.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
        make.bottom.equalToSuperview()  // 调整文本框与下方的间距
    }

    init(pageInfo: VerifyCommonInfo, context: UniContextProtocol) {
        self.verifyFIDOPageInfo = pageInfo

        super.init(pageInfo: pageInfo, context: context)

        self.needNextButton = false
        self.enableNext = BehaviorRelay<Bool>(value: false)
    }


}

class VerifyIDPProvider: VerifyCommonProvider {

    let logger = Logger.plog(VerifyIDPProvider.self, category: "VerifyIDPProvider")

    var verifyIDPPageInfo: VerifyCommonInfo

    var passportEventBus: PassportEventBusProtocol { LoginPassportEventBus.shared }

    override func getVerifyPageInfo() -> VerifyTypeInfo { verifyIDPPageInfo }

    override func getVerifyContentView() -> UIView {
        self.verifyButton
    }

    lazy var verifyButton: NextButton = {
        let btn = NextButton(title: verifyIDPPageInfo.nextButton?.text ?? "")
        let pageInfo = verifyIDPPageInfo
        let usePackageDomain = verifyIDPPageInfo.usePackageDomain
        btn.rx
            .tap
            .asDriver()
            .throttle(.seconds(5),latest: false)
            .drive(onNext:{ [weak self] in
                guard let self = self else { return }
                self.doVerify()
            }).disposed(by: disposeBag)
        return btn
    }()

    override func verifyInternal() -> Observable<Void> {
        self.logger.info("n_action_verify_idp_start")
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }
            if let nextStep = self.verifyIDPPageInfo.nextButton?.next,
               let stepName = nextStep.stepName,
               let stepInfo = nextStep.stepInfo {
                self.passportEventBus.post(
                    event: stepName,
                    context: V3RawLoginContext(stepInfo: stepInfo, additionalInfo: nil, context: self.context),
                    success: {[weak self] in
                        ob.onNext(())
                        self?.logger.info("n_action_verify_idp_succ")
                    },
                    error: {[weak self] error in
                        ob.onError(error)
                        self?.logger.error("n_action_verify_idp_fail", error: error)
                    }
                )
            } else {
                //服务端未正确下发
                let error = V3LoginError.badResponse(I18N.Lark_Passport_BadServerData)
                self.logger.error("n_action_verify_idp_bad_server_data", error: error)
                ob.onError(error)
            }

            return Disposables.create()
        })

    }

    override func layoutMaker(make: SnapKit.ConstraintMaker) -> Void {
        make.top.equalToSuperview()
        make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        make.right.left.equalToSuperview().inset(VerifyPageLayout.itemLeftSpace)
        make.bottom.equalToSuperview() // 调整文本框与下方的间距
    }

    init(pageInfo: VerifyCommonInfo, context: UniContextProtocol) {
        self.verifyIDPPageInfo = pageInfo

        super.init(pageInfo: pageInfo, context: context)

        self.needNextButton = false
        self.enableNext = BehaviorRelay<Bool>(value: false)
        // IDP验证会从webview返回，防止直接退回选择身份页
        self.needSkipWhilePop = false
    }

}
