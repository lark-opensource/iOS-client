//
//  V3JoinTenantCodeViewController.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import LKCommonsLogging
import RxSwift
import Homeric
import UniverseDesignToast

class V3JoinTenantCodeViewController: BaseViewController {

    static let logger = Logger.log(V3JoinTenantCodeViewController.self, category: "JoinTenantCodeView")

    private let vm: V4JoinTenantCodeViewModel

    init(vm: V4JoinTenantCodeViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var codeTextField: V3TeamCodeTextField = {
        let textfield = V3TeamCodeTextField()
        textfield.textFieldView.returnKeyType = .done
        textfield.textFieldView.placeholder = I18N.Lark_Login_V3_Input_Tenant_Code_Placeholder
        textfield.returnBtnClicked = { [weak self] _ in
            guard let self = self else { return }
            if self.isInputValid() {
                guard let code = self.codeTextField.currentText, !code.isEmpty else {
                    return
                }
                self.vm.joinTenant(tenantCode: code).subscribe( onError: { [weak self] (err) in
                    guard let self = self else { return }
                    self.stopLoading()
                    self.handle(err)
                }, onCompleted: { [weak self] in
                    self?.stopLoading()
                }).disposed(by: self.disposeBag)
            }
        }
        return textfield
    }()

    lazy var subtitleSwitchScanLabel: UITextView = {
        let label = LinkClickableLabel.default(with: self)
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapSwitchLabel(recognizer:)))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        label.addGestureRecognizer(tapRecognizer)
        return label
    }()
    
    @objc
    private func onTapSwitchLabel(recognizer: UITapGestureRecognizer) {
        if let stepData = self.vm.joinTenantCodeInfo.switchButton?.next {
            self.vm.post(event: stepData.stepName ?? PassportStep.joinTenantScan.rawValue, serverInfo: stepData.nextServerInfo(), additionalInfo: self.vm.additionalInfo) {
                Self.logger.info("switch to join tenant scan page success.")
            } error: { (error) in
                Self.logger.error("switch to join tenant scan page error: \(error)")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.setTitle(I18N.Lark_Login_V3_Input_Tenant_Code_Next, for: .normal)
        configTopInfo(vm.title, detail: vm.subtitle)
        subtitleSwitchScanLabel.attributedText = vm.subtitleSwitchScanText

        centerInputView.addSubview(codeTextField)
        codeTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView)
            make.bottom.equalToSuperview()
        }

        inputAdjustView.addSubview(subtitleSwitchScanLabel)
        inputAdjustView.bringSubviewToFront(bottomView)
        subtitleSwitchScanLabel.snp.makeConstraints { (make) in
            make.top.equalTo(switchButtonContainer.snp.bottom)
            make.left.equalTo(moveBoddyView).inset(CL.itemSpace)
            make.right.lessThanOrEqualTo(moveBoddyView).inset(CL.itemSpace)
            make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }

        _ = nextButton.rx.tap.subscribe { [weak self] (_) in
            guard let self = self else { return }
            self.logger.info("n_action_click_scan_qrcode")
            SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_CLICK_NEXT)
            PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantTeamcodeStart,
                    eventName: ProbeConst.monitorEventName,
                    categoryValueMap: [ProbeConst.flowType: self.vm.joinTenantCodeInfo.flowType],
                    context: self.vm.context)
            let startTime = Date()
            self.showLoading()
            self.updateFieldValueToVM()
            guard let code = self.codeTextField.currentText, !code.isEmpty else {
                return
            }
            self.vm.joinTenant(tenantCode: code).subscribe( onError: { [weak self] (err) in
                guard let self = self else { return }
                self.logger.error("n_action_join_team_by_code_error", error: err)
                PassportMonitor.monitor(PassportMonitorMetaJoin
                    .joinTenantTeamcodeResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.joinTenantCodeInfo.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: err)
                .flush()
                self.stopLoading()
                self.handle(err)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                PassportMonitor.monitor(PassportMonitorMetaJoin.joinTenantTeamcodeResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.joinTenantCodeInfo.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
                self.stopLoading()
            }).disposed(by: self.disposeBag)
        }

        NotificationCenter.default
            .rx.notification(UITextField.textDidChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.checkBtnDisable()
            }).disposed(by: disposeBag)

        PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantTeamcodeEnter,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.joinTenantCodeInfo.flowType],
                context: vm.context)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isPad {
            view.backgroundColor = UIColor.ud.bgBody
            self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        } else {
            view.backgroundColor = UIColor.ud.bgLogin
        }
    }

//    func confirmCode() {
//        logger.info("click join tenant code")
//        SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_CLICK_NEXT)
//        showLoading()
//        updateFieldValueToVM()
//        vm.teamCodeConfirm()
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] teamCodeInfo in
//                guard let self = self else { return }
//                self.stopLoading()
//                self.vm.alertConfirm(
//                    title: teamCodeInfo.title,
//                    content: teamCodeInfo.content,
//                    confirm: { [weak self] in
//                        self?.handleNext()
//                    },
//                    cancel: {},
//                    vc: self,
//                    scene: .joinTenantCode)
//            }, onError: { [weak self] error in
//                guard let self = self else { return }
//                self.stopLoading()
//                self.handle(error)
//            }).disposed(by: self.disposeBag)
//    }
//    func handleNext() {
//       showLoading()
//       vm.teamCodeJoin()
//        .subscribe(onError: { [weak self] (err) in
//            guard let self = self else { return }
//            self.stopLoading()
//            self.handle(err)
//       }, onCompleted: { [weak self] in
//            self?.stopLoading()
//       }).disposed(by: self.disposeBag)
//    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.info("n_page_input_team_code")
        _ = codeTextField.becomeFirstResponder()
        if let pn = pageName() {
            SuiteLoginTracker.track(pn, params: [TrackConst.path: vm.trackPath])
        }
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.joinTenantCodeInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_CODE_INPUT_VIEW, params: params)
        
        if let toastMessage =  vm.joinTenantCodeInfo.toast, !toastMessage.isEmpty {
            let config = UDToastConfig(toastType: .info, text: toastMessage, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
    }

    override func pageName() -> String? {
        return Homeric.ENTER_JOIN_TENANT_CODE
    }

    func checkBtnDisable() {
        nextButton.isEnabled = isInputValid()
    }

    func isInputValid() -> Bool {
        guard let code = codeTextField.currentText,
            !code.isEmpty else {
            return false
        }
        return code.count == codeTextField.inputNum
    }

    func updateFieldValueToVM() {
        if let code = codeTextField.currentText {
            vm.code = code
        }
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        if textView == detailLabel {
            SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_CLICK_HOW_GET_TEAM_CODE)
        } else if textView == subtitleSwitchScanLabel {
            SuiteLoginTracker.track(Homeric.JOIN_TENANT_CODE_CLICK_SCAN_QRCODE)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.joinTenantCodeInfo.flowType ?? "", click: "switch_qr_code", target: TrackConst.passportTeamQRCodeScanView)
            SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_CODE_INPUT_CLICK, params: params)
        }
        super.handleClickLink(URL, textView: textView)
    }

    public func handleBiz(_ error: Error) -> Bool {
        if let err = error as? V3LoginError,
            case let .badServerCode(info) = err,
            case .normalAlertError = info.type {
            stopLoading()
            V3ErrorHandler.showAlert(info.message, vc: self) {
                self.afterHandlerError()
            }
            return true
        }
        return false
    }

    override func handle(_ error: Error) {
        if !handleBiz(error) {
            super.handle(error)
            afterHandlerError()
        }
    }

    func afterHandlerError() {
        _ = codeTextField.becomeFirstResponder()
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantTeamcodeCancel,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.joinTenantCodeInfo.flowType],
                context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }

}
