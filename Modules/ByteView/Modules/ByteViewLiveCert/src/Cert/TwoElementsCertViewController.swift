//
//  TwoElementsCertViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RichLabel
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import UniverseDesignToast

final class TwoElementsCertViewController: CertBaseViewController {
    var vm: TwoElementsCertViewModel

    init(viewModel: TwoElementsCertViewModel) {
        self.vm = viewModel
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var nameTextField: FlatTextField = {
        let textField = FlatTextField()
        textField.textFieldFont = UIFont.systemFont(ofSize: 17)
        textField.returnKeyType = .done
        textField.textFieldView.keyboardType = .default
        textField.placeHolder = I18n.View_G_EnterRealName
        return textField
    }()

    private lazy var codeTextField: FlatTextField = {
        let textField = FlatTextField()
        textField.textFieldFont = UIFont.systemFont(ofSize: 17)
        textField.returnKeyType = .done
        textField.placeHolder = I18n.View_G_EnterIdNumber
        return textField
    }()

    private lazy var legalLabel: LKLabel = {
        let label = LKLabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var checkbox: Checkbox = {
        let cb = Checkbox(iconSize: Layout.checkBoxSize)
        cb.hitTestEdgeInsets = Layout.checkBoxInsets
        return cb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configTopInfo(vm.title, detail: vm.detail)
        nextButton.setTitle(I18n.View_G_NextStep, for: .normal)
        inputTapGesture.delegate = self

        centerInputView.addSubview(nameTextField)
        centerInputView.addSubview(codeTextField)
        centerInputView.addSubview(checkbox)
        centerInputView.addSubview(legalLabel)

        nameTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
            make.height.equalTo(Layout.fieldHeight)
            make.top.equalTo(centerInputView.snp.top)
            make.bottom.equalTo(codeTextField.snp.top).offset(-Layout.itemSpace)
        }

        codeTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
            make.height.equalTo(Layout.fieldHeight)
            make.top.equalTo(nameTextField.snp.bottom).offset(Layout.itemSpace)
            make.bottom.equalToSuperview().offset(-Layout.fieldBottom)
        }

        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.itemSpace)
            make.size.equalTo(Layout.checkBoxSize)
            make.centerY.equalTo(legalLabel.snp.top).offset(legalLabel.font.lineHeight / 2.0)
        }

        legalLabel.snp.makeConstraints { (make) in
            make.top.equalTo(codeTextField.snp.bottom).offset(Layout.policyTopSpace)
            make.left.equalTo(checkbox.snp.right).offset(Layout.checkBoxRightPadding)
            make.right.equalToSuperview().offset(-Layout.itemSpace)
        }

        nextButton.addTarget(self, action: #selector(didClickNext), for: .touchUpInside)

        NotificationCenter.default.addObserver(self, selector: #selector(didChangeText), name: UITextField.textDidChangeNotification, object: nil)
        bindViewModel()
        LiveCertTracks.trackTwoElementsPage(nextStep: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        legalLabel.preferredMaxLayoutWidth = legalLabel.frame.size.width
        legalLabel.attributedText = legalLabel.attributedText
        if legalLabel.isMutipleLines {
            checkbox.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(BaseLayout.itemSpace)
                make.size.equalTo(Layout.checkBoxSize)
                make.centerY.equalTo(legalLabel.snp.top).offset(legalLabel.font.lineHeight / 2.0)
            }
        } else {
            checkbox.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(BaseLayout.itemSpace)
                make.size.equalTo(Layout.checkBoxSize)
                make.centerY.equalTo(legalLabel)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in }, completion: { [weak self] _ in
            self?.legalLabel.preferredMaxLayoutWidth = self?.legalLabel.frame.size.width ?? 0
            self?.legalLabel.attributedText = self?.legalLabel.attributedText
        })
    }

    func bindViewModel() {
        vm.setDelegate(self)
        vm.fetchPolicy(type: .checkbox) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, case .success(let (links, attributedText)) = result else { return }
                for link in links {
                    self.legalLabel.addLKTextLink(link: link)
                }
                self.legalLabel.attributedText = attributedText
            }
        }
    }

    func checkBtnDisable() {
        nextButton.isEnabled = isInputValid()
    }

    func handleNextEvent() {
        self.showLoading()
        self.updateFieldValueToVM()
        self.vm.doCert { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.openLivenessPage()
                case .failure(let error):
                    self?.stopLoading()
                    self?.handle(error)
                }
            }
        }
    }

    private func openLivenessPage() {
        let nav = self.navigationController
        let vm = self.vm.createLivenessCertViewModel()
        let vc = LivenessCertViewController(viewModel: vm)
        nav?.pushViewController(vc, animated: true)
        if let coordinator = nav?.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.stopLoading()
            }
        } else {
            self.stopLoading()
        }
    }

    override func pageName() -> String? {
        return vm.pageName
    }

    override func handle(_ error: Error) {
        if case let CertError.unknown(_, msg) = error {
            ByteViewDialog.Builder()
                .title(I18n.View_VM_NotificationDefault)
                .message(msg)
                .rightTitle(I18n.View_G_OkButton)
                .show()
        }
    }

    func isInputValid() -> Bool {
        guard let name = nameTextField.currentText,
            let code = codeTextField.currentText,
            !name.isEmpty, vm.isCodeValid(code) else {
                return false
        }
        return true
    }

    func updateFieldValueToVM() {
        if let name = nameTextField.currentText {
            vm.name = name
        }
        if let code = codeTextField.currentText {
            vm.code = code
        }
    }

    override func clickBack() {
        LiveCertTracks.trackTwoElementsPage(nextStep: false)
    }

    func quit() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func didClickNext() {
        self.certLogger.info("click cert next")
        if self.checkbox.isSelected {
            self.handleNextEvent()
            LiveCertTracks.trackTwoElementsPage(nextStep: true)
        } else {
            self.alertPolicyCheckNeeded()
        }
    }

    @objc private func didChangeText() {
        self.checkBtnDisable()
    }

    private struct Layout {
        static let itemSpace: CGFloat = BaseLayout.itemSpace
        static let fieldHeight: CGFloat = 50
        static let fieldBottom: CGFloat = 40
        static let checkBoxSize: CGSize = CGSize(width: 12, height: 12)
        static let checkBoxInsets: UIEdgeInsets = UIEdgeInsets(top: -30, left: -50, bottom: -30, right: -30)
        static let checkBoxRightPadding: CGFloat = 7
        static let policyTopSpace: CGFloat = 20
    }
}

extension TwoElementsCertViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 处理手势冲突
        if let view = touch.view,
            view is LKLabel {
            return false
        }
        return true
    }
}

extension TwoElementsCertViewController {
    func alertPolicyCheckNeeded() {
        Logger.cert.debug("will show join live cert alert")
        vm.fetchLiveCertPolicy(for: .popup) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let linkText):
                    ByteViewDialog.Builder()
                        .title(I18n.View_VM_NotificationDefault)
                        .linkText(linkText, alignment: .center, handler: { [weak self] _, component in
                            guard let self = self, let url = component.url else { return }
                            self.vm.open(url: url, from: self)
                        })
                        .adaptsLandscapeLayout(false)
                        .leftTitle(I18n.View_G_CancelButton)
                        .leftHandler({ _ in
                            Logger.cert.debug("refuse live policy cert alert")
                        })
                        .rightTitle(I18n.View_G_ConfirmButton)
                        .rightHandler({ [weak self] _ in
                            Logger.cert.debug("agree live policy cert alert")
                            self?.checkbox.isSelected = true
                        })
                        .show()
                case .failure:
                    UDToast.showTips(with: I18n.View_G_SomethingWentWrong, on: self.view)
                }
            }
        }
    }
}

extension TwoElementsCertViewController: NetworkErrorHandler {
    private enum CertAlertType {
        case ok
        case two
        case over
    }

    private func transferToAlertType(_ errCode: Int) -> CertAlertType {
        switch errCode {
        case 238202:
            return .ok
        case 238203:
            return .two
        case 238204:
            return .over
        default:
            return .ok
        }
    }

    func handleBizError(httpClient: HttpClient, error: RustBizError) -> Bool {
        guard let msgInfo = error.msgInfo, msgInfo.type == .popup else { return false }
        let type = transferToAlertType(error.code)
        let reason = TwoEleFailReason.reason(from: msgInfo)
        let content = error.content
        switch type {
        case .ok:
            ByteViewDialog.Builder()
                .id(.liveCert)
                .title(I18n.View_VM_NotificationDefault)
                .message(content)
                .leftHandler({ _ in
                    LiveCertTracks.trackTwoElementsFailedAlert(reason: reason, isFinished: false)
                })
                .rightTitle(I18n.View_G_OkButton)
                .rightHandler({ _ in
                    LiveCertTracks.trackTwoElementsFailedAlert(reason: reason, isFinished: true)
                })
                .show()
        case .two:
            ByteViewDialog.Builder()
                .id(.liveCert)
                .colorTheme(.redLight)
                .title(I18n.View_VM_NotificationDefault)
                .message(content)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    LiveCertTracks.trackTwoElementsFailedAlert(reason: reason, isFinished: false)
                })
                .rightTitle(I18n.View_G_OkButton)
                .rightHandler({ [weak self] _ in
                    LiveCertTracks.trackTwoElementsFailedAlert(reason: reason, isFinished: true)
                    self?.quit()
                })
                .show()
        case .over:
            ByteViewDialog.Builder()
                .id(.liveCert)
                .colorTheme(.redLight)
                .title(I18n.View_VM_NotificationDefault)
                .message(content)
                .rightTitle(I18n.View_G_Quit)
                .rightHandler({ [weak self] _ in
                    self?.quit()
                })
                .show { _ in
                    if reason == .timesOut {
                        LiveCertTracks.trackTimeout()
                    }
                }
        }
        return true
    }
}

extension LKLabel {
    var isMutipleLines: Bool {
        let maxSize = CGSize(width: self.frame.size.width, height: CGFloat(MAXFLOAT))
        let textHeight = self.sizeThatFits(maxSize).height
        return textHeight >= 2 * self.font.pointSize
    }
}
