//
//  BioAuthViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/28.
//

import Foundation
import Homeric
import LKCommonsLogging
import UniverseDesignToast
import LarkAlertController
import LarkLocalizations
import LarkContainer

class BioAuthViewController: BaseViewController {
    private let vm: BioAuthViewModel
    static let logger = Logger.log(BioAuthViewController.self)

    private var interactiveGestureState: UIGestureRecognizer.State?

    override var needSkipWhilePop: Bool { true }

    lazy var imageView: UIImageView = {
        let result = UIImageView(image: BundleResources.LarkIllustrationResources.specializedAdminCertification)
        return result
    }()

    lazy var mainMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.text = vm.title
        lbl.font = .systemFont(ofSize: 16, weight: .regular)
        lbl.textColor = UIColor.ud.textTitle
        lbl.textAlignment = .center
        return lbl
    }()

    lazy var detailMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = UIColor.ud.textPlaceholder
        lbl.lineBreakMode = .byWordWrapping
        lbl.textAlignment = .center
        lbl.attributedText = V3ViewModel.attributedString(for: vm.subTitle)
        lbl.sizeToFit()
        return lbl
    }()

    lazy var verifyFaceButton: NextButton = {
        let btn = NextButton(title: vm.buttonTitle)
        return btn
    }()

    lazy var bottomLabel: UITextView = {
        let detailLabel = LinkClickableLabel.default(with: self)
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textContainerInset = .zero
        detailLabel.textContainer.lineFragmentPadding = 0
        detailLabel.attributedText = self.vm.bottomTitle
        detailLabel.textAlignment = .center
        return detailLabel
    }()

    lazy var policyCheckbox: V3Checkbox = {
        let checkbox = V3Checkbox(iconSize: CGSize(width: 16, height: 16))
        checkbox.hitTestEdgeInsets = CL.checkBoxInsets
        checkbox.rx.controlEvent(UIControl.Event.valueChanged).subscribe { _ in
        }.disposed(by: disposeBag)
        return checkbox
    }()

    lazy var policyLabel: LinkClickableLabel = {
        let label = LinkClickableLabel.default(with: self)
        label.textContainerInset = .zero
        return label
    }()

    init(vm: BioAuthViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextButton.isHidden = true

        moveBoddyView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(130)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(150)
        }

        moveBoddyView.addSubview(mainMsgLabel)
        mainMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
        }

        moveBoddyView.addSubview(detailMsgLabel)
        detailMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(mainMsgLabel.snp.bottom).offset(Common.Layout.itemSpace)
            make.width.lessThanOrEqualToSuperview().offset(-Common.Layout.itemSpace * 2.0)
        }

        moveBoddyView.addSubview(self.verifyFaceButton)
        verifyFaceButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalTo(detailMsgLabel.snp.bottom).offset(Layout.verifyFaceButtonTop)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
        self.verifyFaceButton.rx.tap.subscribe { [unowned self] (_) in
            SuiteLoginTracker.track(
                Homeric.PASSPORT_FACE_VERIFY_CLICK,
                params: [
                    "click" : "face_verify"
                ])

            if self.vm.policyShouldShow, !policyCheckbox.isSelected {
                self.showPolicyAlert(delegate: self) { confirmed in
                    if confirmed {
                        self.policyCheckbox.isSelected = true
                        self.goNext()
                    }
                }
            } else {
                self.goNext()
            }
        }.disposed(by: disposeBag)

        if let str = self.vm.switchButtonTitle {
            switchButton.setAttributedTitle(str, for: .normal)
            moveBoddyView.addSubview(switchButton)
            switchButton.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
                make.centerX.equalToSuperview()
            }
        } else {
            moveBoddyView.addSubview(self.bottomLabel)
            bottomLabel.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
                make.centerX.equalToSuperview()
            }
        }

        if let policyTitle = self.vm.policyAttributedString(forAlertOrNot: false) {
            moveBoddyView.addSubview(policyCheckbox)
            policyLabel.attributedText = policyTitle
            moveBoddyView.addSubview(policyLabel)
            policyCheckbox.snp.makeConstraints { make in
                make.left.equalTo(verifyFaceButton)
                make.top.equalTo(verifyFaceButton.snp.bottom).offset(17)
            }
            policyLabel.snp.makeConstraints { make in
                make.left.equalTo(policyCheckbox.snp.right)
                make.right.lessThanOrEqualTo(verifyFaceButton)
                make.top.equalTo(policyCheckbox)
            }
        }
    }

    private func goNext() {
        if let window = currentWindow() {
            UDToast.showDefaultLoading(on: window)
        }

        vm.onVerifyFaceButtonClicked(completion: { [weak self] error in
            if let window = self?.currentWindow() {
                UDToast.removeToast(on: window)
                if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: window)
                }
            }
        })
        .subscribe()
        .disposed(by: disposeBag)
    }

    @objc
    override func switchAction(sender: UIButton) {
        SuiteLoginTracker.track(
            Homeric.PASSPORT_FACE_VERIFY_CLICK,
            params: [
                "click" : "change_verify_method"
            ])
        guard let stepData = self.vm.bioAuthInfo.switchButton?.next else {
            Self.logger.info("no switch button stepData in bioAuthInfo.")
            return
        }
        self.vm.post(
            event: stepData.stepName ?? "",
            stepInfo: stepData.stepInfo,
            additionalInfo: self.vm.additionalInfo,
            success: {},
            error: { [weak self] err in
                self?.handle(err)
            })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SuiteLoginTracker.track(Homeric.PASSPORT_FACE_VERIFY_VIEW)
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.identityURL:
            let urlStr: String?
            let defaultDomain = RustDynamicDomainProvider().getDomain(.privacy).value ?? ""
            let domain = vm.policyDomain ?? defaultDomain
            let language = LanguageManager.currentLanguage.languageIdentifier
            let suffix = "/identity"
            if domain.hasSuffix("/") {
                urlStr = CommonConst.prefixHTTPS + domain + language + suffix
            } else {
                urlStr = CommonConst.prefixHTTPS + domain + "/" + language + suffix
            }
            if let url = Foundation.URL(string: urlStr ?? "") {
                BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
            }
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }

    override func clickBackOrClose(isBack: Bool) {
        cancelRealNameQRCodeVerificationIfNeeded()

        super.clickBackOrClose(isBack: isBack)
    }

    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            interactiveGestureState = navigationController?.interactivePopGestureRecognizer?.state
        }

        super.willMove(toParent: parent)
    }

    override func didMove(toParent parent: UIViewController?) {
        if parent == nil, let state = interactiveGestureState, (state == .began || state == .changed || state == .ended) {
            cancelRealNameQRCodeVerificationIfNeeded()
        }

        super.didMove(toParent: parent)
    }

    private func cancelRealNameQRCodeVerificationIfNeeded() {
        vm.cancelRealNameQRCodeVerificationIfNeeded()
    }
}

extension BioAuthViewController {
    struct Layout {
        static let verifyFaceButtonTop: CGFloat = 32.0
        static let lineHight: CGFloat = 0.5
    }
}

// MARK: alert
extension BioAuthViewController: PassportPrivacyServicePolicyProtocol {
    var currentPolicyPresentVC: UIViewController { self }

    func showPolicyAlert(delegate: UITextViewDelegate, completion:@escaping ((Bool) -> Void)) {
        let controller = LarkAlertController()
        controller.setTitle(text: I18N.Lark_IdentityVerification_NoticeForAgreement)
        let label = LinkClickableLabel.default(with: delegate)
        label.attributedText = vm.policyAttributedString(forAlertOrNot: true)
        label.textAlignment = .center
        controller.setFixedWidthContent(view: label)
        controller.addSecondaryButton(
            text: I18N.Lark_Login_V3_PolicyAlertCancel,
            dismissCompletion: {
                completion(false)
            })
        controller.addPrimaryButton(
            text: I18N.Lark_IdentityVerification_ReadAgreeTheTerm_Agree_Button,
            dismissCompletion: {
                completion(true)
            })
        self.currentPolicyPresentVC.present(controller, animated: true, completion: nil)
    }
}
