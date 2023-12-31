//
//  SuiteAuthViewController.swift
//  Lark
//
//  Created by zc09v on 2017/5/5.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LarkLocalizations
import LarkContainer
import LarkAccountInterface
import LarkAlertController
import Homeric
import LarkButton
import UniverseDesignCheckBox
import LarkUIKit
import ECOProbeMeta

class SuiteAuthViewController: AuthorizationBaseViewController {

    @InjectedLazy private var dependency: AccountDependency // user:checked (global-resolve)

    private let authInfo: LoginAuthInfo
    private var showNotificationOption: Bool { authInfo.suiteAuthInfo?.subtitleOption ?? false }
    override func needBackImage() -> Bool { true }
    
    private lazy var confirmTipLabel: UILabel = {
        let confirmTipLabel = UILabel()
        confirmTipLabel.numberOfLines = 3
        confirmTipLabel.textAlignment = .center
        confirmTipLabel.font = Layout.confirmLabelFont
        return confirmTipLabel
    }()

    lazy var closeNofLabel: UILabel = {
        let closeNofLabel = UILabel()
        closeNofLabel.textAlignment = .left
        closeNofLabel.numberOfLines = 3
        closeNofLabel.font = UIFont.systemFont(ofSize: 13)
        closeNofLabel.textColor = UIColor.ud.textCaption
        closeNofLabel.setContentHuggingPriority(.required, for: .horizontal)
        return closeNofLabel
    }()
    
    lazy var confirmAllButton: NextButton = {
        let confirmButton = NextButton(title: "", style: .roundedRectBlue)
        confirmButton.addTarget(self, action: #selector(confirmAllButtonClick(_:)), for: .touchUpInside)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return confirmButton
    }()
    
    lazy var confirmSingleButton: NextButton = {
        let button = NextButton(title: "", style: .roundedRectWhiteWithGrayOutline)
        button.addTarget(self, action: #selector(confirmButtonClick), for: .touchUpInside)
        return button
    }()

    lazy var closeNofButton: UDCheckBox = {
        let closeNofButton = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(borderEnabledColor: UIColor.ud.textPlaceholder, style: .circle))
        closeNofButton.isSelected = false
        closeNofButton.isEnabled = true
        closeNofButton.tapCallBack = { [weak self] checkBox in
            self?.tapCheckBox()
        }
        return closeNofButton
    }()

    init(vm: SSOBaseViewModel, authInfo: LoginAuthInfo, resolver: UserResolver?) {
        self.authInfo = authInfo
        super.init(vm: vm, resolver: resolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Self.logger.info("n_page_suite_end", method: .local)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigation(hasTitle: false)
        setupViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("n_page_suite_start", body: "source: auth_qr", method: .local)
        PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.page_suite_enter, context: vm.context)
        SuiteLoginTracker.track(Homeric.SSO_PAGE_SHOW,
                                params: [AuthTrack.pageTypeKey: AuthTrack.suiteValue])

        confirmAllButton.isEnabled = true
        confirmSingleButton.isEnabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SuiteLoginTracker.track(Homeric.SSO_PAGE_DISMISS,
                                params: [AuthTrack.pageTypeKey: AuthTrack.suiteValue])
    }
    
    @objc
    private func tapCheckBox() {
        self.closeNofButton.isSelected = !self.closeNofButton.isSelected
    }

    private func setupViews() {
        let containerView = UIView()
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview().priority(.required)
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
            make.height.equalTo(0).priority(.low)
        }
        let loginConfirmIcon = UIImageView(image: BundleResources.LarkAccount.Common.auth_logo_frame)
        let logoIcon = UIImageView(image: BundleResources.AppResourceLogo.logo)
        loginConfirmIcon.addSubview(logoIcon)
        logoIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.logoTop)
            make.centerX.equalToSuperview()
            make.width.equalTo(Layout.logoSize)
            make.height.equalTo(Layout.logoSize)
        }
        containerView.addSubview(loginConfirmIcon)
        containerView.addSubview(confirmTipLabel)
        containerView.addSubview(confirmAllButton)
        containerView.addSubview(confirmSingleButton)

        let title = authInfo.suiteAuthInfo?.appName
        confirmTipLabel.text = title

        if showNotificationOption {
            let closeNofView = UIView()
            closeNofView.backgroundColor = .clear
            containerView.addSubview(closeNofView)
            closeNofView.snp.makeConstraints { (make) in
                make.top.equalTo(confirmTipLabel.snp.bottom).offset(16.0)
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualTo(16.0)
                make.right.lessThanOrEqualTo(16.0)
            }

            let subtitle = authInfo.suiteAuthInfo?.subtitle
            closeNofLabel.text = subtitle
            closeNofView.addSubview(closeNofLabel)
            closeNofView.addSubview(closeNofButton)
            closeNofLabel.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapCheckBox))
            closeNofLabel.addGestureRecognizer(tap)

            closeNofButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(20)
                make.width.height.equalTo(14)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-20)
            }

            closeNofLabel.snp.makeConstraints { (make) in
                make.top.equalTo(closeNofButton).offset(-1)
                make.left.equalTo(closeNofButton.snp.right).offset(4.0)
                make.right.equalToSuperview().offset(-Layout.largerItemSpace)
            }

            dependency.notifyDisableDriver
                .drive(onNext: { [weak self] (disable) in
                    self?.closeNofButton.isSelected = disable
                })
                .disposed(by: disposeBag)
        }

        var singleTitle: String? = nil
        let multiTitle: String?
        if let buttonList = authInfo.buttonList, buttonList.count > 1 {
            singleTitle = authInfo.buttonList?.first { $0.actionType == .qrSingle }?.text
            multiTitle = authInfo.buttonList?.first { $0.actionType == .qrMulti }?.text
        } else {
            multiTitle = authInfo.buttonList?.first { $0.actionType == .qrSingle }?.text
        }

        confirmSingleButton.setTitle(singleTitle, for: .normal)
        confirmSingleButton.isHidden = singleTitle?.isEmpty ?? true

        confirmAllButton.setTitle(multiTitle, for: .normal)
        confirmAllButton.isHidden = multiTitle?.isEmpty ?? true

        loginConfirmIcon.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalTo(Layout.imageWidth)
            make.height.equalTo(Layout.imageHeight)
            make.centerX.equalToSuperview()
        }

        confirmTipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(loginConfirmIcon.snp.bottom).offset(Layout.largerItemSpace)
            make.left.greaterThanOrEqualToSuperview().offset(Layout.largerItemSpace)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.largerItemSpace)
            make.centerX.equalToSuperview()
        }
        confirmAllButton.snp.makeConstraints { (make) in
            make.top.equalTo(confirmTipLabel.snp.bottom).offset(Layout.confirmButtonTopSpace)
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(Layout.confirmButtonHeight)
        }

        confirmSingleButton.snp.makeConstraints { (make) in
            make.top.equalTo(confirmAllButton.snp.bottom).offset(22)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(Layout.confirmButtonHeight)
        }
    }
    
//    @objc
//    private func tapCheckBox() {
//        self.closeNofButton.isSelected = !self.closeNofButton.isSelected
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        closeNofLabel.textColor = UIColor.ud.textCaption
    }

    @objc
    func confirmButtonClick() {
        SuiteLoginTracker.track(Homeric.SSO_CONFIRM_BTN_CLICK,
                                params: [AuthTrack.pageTypeKey: AuthTrack.suiteValue])
        confirmToken(scope: "", isMultiLogin: false, success: { [unowned self] in
            if self.showNotificationOption {
                self.dependency.updateNotificaitonStatus(notifyDisable: self.closeNofButton.isSelected, retry: 2)
            }
            self.confirmSingleButton.isEnabled = true
        }){ [unowned self] in
            self.confirmSingleButton.isEnabled = true
        }
    }

    @objc
    func confirmAllButtonClick(_ sender: NextButton) {
        SuiteLoginTracker.track(Homeric.SSO_CONFIRM_BTN_CLICK,
                                params: [AuthTrack.pageTypeKey: AuthTrack.suiteValue])
        let sender = sender
        sender.isEnabled = false
        confirmToken(scope: "", isMultiLogin: true, success: { [unowned self] in
            if self.showNotificationOption {
                self.dependency.updateNotificaitonStatus(notifyDisable: self.closeNofButton.isSelected, retry: 2)
            }
            sender.isEnabled = true
        }) {
            sender.isEnabled = true
        }
    }

    override func closeBtnClick() {
        Self.logger.info("n_action_suite_back")
        SuiteLoginTracker.track(Homeric.SSO_CLOSE_BTN_CLICK,
                                params: [AuthTrack.pageTypeKey: AuthTrack.suiteValue])
        super.closeBtnClick()
    }
}

extension SuiteAuthViewController {
    private enum Layout {
        static let navigationHeight: CGFloat = 44
        static let confirmLabelFont: UIFont = UIFont.systemFont(ofSize: 15)
        static let smallerItemSpace: CGFloat = 10
        static let itemSpace: CGFloat = 16
        static let largerItemSpace: CGFloat = 20
        static let imageWidth: CGFloat = 128
        static let imageHeight: CGFloat = 102
        static let closeButtonWidth: CGFloat = 14
        static let confirmButtonTopSpace: CGFloat = 94
        static let confirmButtonHeight: CGFloat = 48
        static let logoTop = 15
        static let logoSize = 36
    }
}
