//
//  QRCodeLoginViewController.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/18.
//

import Foundation
import LarkLocalizations
import RxSwift
import SnapKit
import UniverseDesignButton

class QRCodeLoginViewController: BaseViewController {

    private lazy var scanTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = I18N.Lark_Login_TitleOfQRPage
        lb.textAlignment = .center
        lb.textColor = UIColor.ud.textTitle
        lb.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return lb
    }()

    private lazy var scanSubtitleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.ud.textCaption
        lb.text = I18N.Lark_Login_DescOfQRCode_iPad(LanguageManager.bundleDisplayName)
        lb.textAlignment = .center
        lb.font = UIFont.systemFont(ofSize: 14.0)
        return lb
    }()

    private lazy var successTitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = I18N.Lark_Login_SuccessTipsOfTitle
        lb.textColor = UIColor.ud.textTitle
        lb.textAlignment = .center
        lb.alpha = 0
        lb.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return lb
    }()

    private lazy var successSubtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = I18N.Lark_Login_SuccessTipsOfSubtitle_V2(LanguageManager.bundleDisplayName)
        lb.textColor = UIColor.ud.textCaption
        lb.textAlignment = .center
        lb.alpha = 0
        lb.font = UIFont.systemFont(ofSize: 14.0)
        return lb
    }()

    private lazy var qrCodeView: QRCodeLoginImageView = {
        let view = QRCodeLoginImageView(content: self.vm.qrCodeString) { [weak self] in
            guard let self = self else { return }
            self.showLoading()
            // 将之前的 start 点位消费
            self.monitorQRCodeLoginResult(isSucceeded: false, error: nil)
            self.vm.refreshCode { [weak self] in
                guard let self = self else { return }
                self.qrCodeView.revalid()
                self.startPolling()
                self.stopLoading()
            } onError: { [weak self](error) in
                self?.handle(error)
            }
        }
        return view
    }()

    private lazy var processTipLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        let attributedString = NSMutableAttributedString.tip(str: I18N.Lark_Passport_Newlogin_HomePageSwitchSignUpButton, color: UIColor.ud.textPlaceholder)
        let suffixLink = NSAttributedString.link(
            str: I18N.Lark_Login_V3_notregtoreg,
            url: Link.registerURL,
            font: UIFont.systemFont(ofSize: 14.0)
        )
        attributedString.append(suffixLink)
        lbl.attributedText = attributedString
        return lbl
    }()
    
    private lazy var commonLoginButton: UDButton = {
        var config = UDButtonUIConifg.secondaryGray
        config.type = .big
        config.radiusStyle = .circle
        let button = UDButton(config)
        return button
    }()

    private lazy var needKeepLoginView: AgreementView = {
        let view = AgreementView(
            needCheckBox: true,
            plainString: I18N.Lark_Login_PeriodOfValidity,
            links: []
        ) { (checked) in
            PassportStore.shared.keepLogin = checked
        } clickAction: { (_, _, _) in
        }
        return view
    }()

    let vm: QRLoginViewModel

    init(vm: QRLoginViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
        PassportMonitor.flush(PassportMonitorMetaLogin.qrcodeLoginEnter,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: nil,
                              context: vm.context)

        processTipLabel.isHidden = !vm.registEnable

        vm.needUpdateImage.asDriver().skip(1).drive { [weak self](type) in
            self?.updateView(qrImageType: type)
        }.disposed(by: disposeBag)

        vm.needRefreshQRCode.asDriver().skip(1).drive { [weak self](_) in
            guard let self = self  else { return }
            self.updateView(qrImageType: .scan(content: self.vm.qrCodeString, needRefresh: true))
        }.disposed(by: disposeBag)

        startPolling()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 轮询接口 qrlogin/polling 可能会在页面关闭后还未返回，导致后续的 flowkey 被污染
        vm.cancelPollingRequest()
    }

    func setUpView() {
        moveBoddyView.addSubview(qrCodeView)
        moveBoddyView.addSubview(scanTitleLabel)
        moveBoddyView.addSubview(scanSubtitleLabel)
        moveBoddyView.addSubview(processTipLabel)
        moveBoddyView.addSubview(commonLoginButton)

        qrCodeView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(
                CGSize(width: QRCodeLoginImageView.Layout.size, height: QRCodeLoginImageView.Layout.size)
            )
        }

        scanSubtitleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(qrCodeView.snp.top).offset(-CL.itemSpace * 2)
            make.centerX.equalToSuperview()
        }

        scanTitleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(scanSubtitleLabel.snp.top).offset(-Layout.titleSpace)
            make.centerX.equalToSuperview()
        }

        processTipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(qrCodeView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        if vm.needKeepLoginTip {
            moveBoddyView.addSubview(needKeepLoginView)
            needKeepLoginView.snp.makeConstraints { (make) in
                make.top.equalTo(processTipLabel.snp.bottom).offset(Layout.keepLoginSpace)
                make.centerX.equalToSuperview()
            }
        }
        
        commonLoginButton.setTitle(I18N.Lark_Passport_iPadLogin_UsePhoneOrEmailLoginButton, for: .normal)
        commonLoginButton.rx
            .tap
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] _ in
                self.clickBackOrClose(isBack: false)
            }
            .disposed(by: self.disposeBag)
        commonLoginButton.snp.makeConstraints { make in
            var offset: CGFloat
            switch (vm.registEnable, vm.needKeepLoginTip) {
            case (true, true):
                offset = 94
            case (true, false), (false, true):
                offset = 60
            case (false, false):
                offset = 32
            }
            make.top.equalTo(qrCodeView.snp.bottom).offset(offset)
            make.centerX.equalToSuperview()
        }

        moveBoddyView.addSubview(successTitleLabel)
        moveBoddyView.addSubview(successSubtitleLabel)
        successTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(qrCodeView.snp.bottom).offset(CL.itemSpace * 2)
            make.centerX.equalToSuperview()
        }

        successSubtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(successTitleLabel.snp.bottom).offset(Layout.titleSpace)
            make.centerX.equalToSuperview()
        }
    }

    func updateView(qrImageType: QRImageType) {
        switch qrImageType {
        case .scan(let content, let needRefresh):
            if needRefresh {
                self.qrCodeView.invalid()
            }
            self.qrCodeView.update(content: content, avatarUrl: nil)
            UIView.animate(withDuration: 0.4) {
                self.qrCodeView.snp.updateConstraints { (make) in
                    make.centerY.equalToSuperview().offset(0)
                }
                self.processTipLabel.alpha = 1
                self.needKeepLoginView.alpha = 1
                self.scanTitleLabel.alpha = 1
                self.scanSubtitleLabel.alpha = 1
                self.successTitleLabel.alpha = 0
                self.successSubtitleLabel.alpha = 0
                self.commonLoginButton.alpha = 1
                self.view.layoutIfNeeded()
            }
        case .confirm(let content, let url):
            self.qrCodeView.update(content: content, avatarUrl: url)

            UIView.animate(withDuration: 0.4) {
                self.qrCodeView.snp.updateConstraints { (make) in
                    make.centerY.equalToSuperview().offset(-Layout.successImageMove)
                }
                self.processTipLabel.alpha = 0
                self.needKeepLoginView.alpha = 0
                self.scanTitleLabel.alpha = 0
                self.scanSubtitleLabel.alpha = 0
                self.successTitleLabel.alpha = 1
                self.successSubtitleLabel.alpha = 1
                self.commonLoginButton.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }

    func startPolling() {
        PassportMonitor.monitor(PassportMonitorMetaLogin.startQrcodeLoginVerify,
                                eventName: ProbeConst.monitorEventName,
                                categoryValueMap: nil,
                                context: UniContextCreator.create(.authorization)).flush()
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginQRCodeVerifyFlow)

        vm.verifyPolling(startEnterApp: { [weak self] in
            self?.showLoading()
        })
        .subscribe(onError: { [weak self] error in
            guard let self = self else { return }
            self.monitorQRCodeLoginResult(isSucceeded: false, error: error)
            self.handle(error)
        }, onCompleted: { [weak self] in
            guard let self = self else { return }
            self.stopLoading()
            self.logger.info("qrlogin success")
            self.monitorQRCodeLoginResult(isSucceeded: true)
        })
        .disposed(by: disposeBag)
    }

    override func onlyNavUI() -> Bool {
        true
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        if URL == Link.registerURL {
            self.showLoading()
            self.vm.fetchPrepareTenantInfo().subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.stopLoading()
            }, onError: { [weak self] (err) in
                guard let self = self else { return }
                self.handle(err)
            }).disposed(by: self.disposeBag)
        }
    }

    override func clickBackOrClose(isBack: Bool) {
        monitorQRCodeLoginResult(isSucceeded: false, error: nil)
        super.clickBackOrClose(isBack: isBack)
    }

    private func monitorQRCodeLoginResult(isSucceeded: Bool, error: Error? = nil) {
        var errorMsg: String = ""
        var errorCode: String = ""
        if !isSucceeded {
            if let e = error {
                errorMsg = e.localizedDescription
                errorCode = PassportProbeHelper.getErrorCode(e)
            } else {
                switch vm.state {
                case .cancelled:
                    errorMsg = "qrcode_login_error: user cancelled"
                    errorCode = ProbeConst.commonUserActionErrorCode
                case .failed:
                    errorMsg = "qrcode_login_error: login failed"
                    errorCode = ProbeConst.commonUserActionErrorCode
                case .tokenExpired:
                    errorMsg = "qrcode_login_error: token expired"
                    errorCode = ProbeConst.commonUserActionErrorCode
                default:
                    // 用户手动关闭，作为一次 start 消费
                    errorMsg = "qrcode_login_error: in \(vm.state)"
                    errorCode = ProbeConst.commonUserActionErrorCode
                }
            }
        }
        let map: [String: Any] = [ProbeConst.duration: ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginQRCodeVerifyFlow),
                                  ProbeConst.qrloginState: "\(vm.state)"]
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogin.qrcodeLoginVerifyResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: map,
                                              context: vm.context)
        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
        }
    }
}

extension QRCodeLoginViewController {
    enum Layout {
        static let titleSpace: CGFloat = 16
        static let keepLoginSpace: CGFloat = 12
        static let successImageMove: CGFloat = 50
    }
}
