//
//  FreshnessReportViewController.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/7.
//  

import SKFoundation
import UniverseDesignColor
import RxSwift
import RxCocoa
import SKUIKit
import SKResource
import SnapKit
import UniverseDesignToast

final class FreshnessReportViewController: FreshnessBaseViewController, UITextViewDelegate, PermissionTopTipViewDelegate {

    let docsInfo: DocsInfo
    weak var hostVC: UIViewController?

    private lazy var inputTextView: SKUDBaseTextView = setupTextView()
    private let keyboard = Keyboard()

    private lazy var tipView: PermissionTopTipView = {
        var textView = PermissionTopTipView()
        textView.backgroundColor = .clear
        textView.titleLabelFont = UIFont.docs.pfsc(16)
        textView.setIconHidden(true)

        let displayUsername = docsInfo.displayName
        var commString = BundleI18n.SKResource.LarkCCM_CM_Verify_SendFeedback_Description(" \(displayUsername) ")

        let attrContent = NSAttributedString(string: commString)
        let mutableStr = NSMutableAttributedString(attributedString: attrContent)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        mutableStr.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle],
                                 range: NSRange(location: 0, length: mutableStr.string.count))

        if let range = mutableStr.string.range(of: displayUsername) {
            var nsRange = mutableStr.string.toNSRange(range)
            nsRange = NSRange(location: nsRange.location, length: nsRange.length)
            textView.addTapRange(nsRange)
            mutableStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ud.colorfulBlue, range: nsRange)
        }

        textView.paragraphStyle = paragraphStyle
        textView.attributeTitle = mutableStr
        textView.linkCheckEnable = true
        textView.delegate = self
        return textView
    }()

    init(docsInfo: DocsInfo) {
        self.docsInfo = docsInfo
        super.init()
        dismissalStrategy = [.viewSizeChanged]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        headerView.setTitle(BundleI18n.SKResource.LarkCCM_CM_Verify_AskOwner_Menu)
        // 反馈
        confirmButton.setTitle(BundleI18n.SKResource.LarkCCM_CM_Verify_SendFeedback_Button, for: .normal)
        confirmButton.addTarget(self, action: #selector(reportDocOutdate), for: .touchUpInside)

        containerView.addSubview(headerView)
        containerView.addSubview(tipView)
        containerView.addSubview(inputTextView)
        containerView.addSubview(confirmButton)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }

        tipView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
        }

        inputTextView.snp.makeConstraints { make in
            make.top.equalTo(tipView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(108)
        }

        confirmButton.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview().inset(16)
            make.top.equalTo(inputTextView.snp.bottom).offset(24)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight_48)
        }

        setupKeyboardMonitor()
    }

    private func setupKeyboardMonitor() {
        keyboard.on(event: .willShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.confirmButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.confirmButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .willHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.confirmButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.confirmButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.start()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        inputTextView.becomeFirstResponder()
        return false
    }

    private func setupTextView() -> SKUDBaseTextView {
        let textView = SKUDBaseTextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholder = BundleI18n.SKResource.LarkCCM_CM_Verify_SendFeedback_LeaveNote_Placeholder
        textView.delegate = self
        textView.bounces = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        textView.maxHeight = 108
        textView.textDragInteraction?.isEnabled = false
        textView.returnKeyType = .next
        textView.backgroundColor = UDColor.bgBodyOverlay
        textView.layer.cornerRadius = 6
        if SKDisplay.pad {
            let enterKey = UIKeyCommand(input: "\u{D}", modifierFlags: [], action: #selector(enterHandler(_:)))
            let shiftEnterKey = UIKeyCommand(input: "\u{D}", modifierFlags: .shift, action: #selector(shiftEnterHandler(_:)))
            textView.customKeyCommands.append(shiftEnterKey)
            textView.customKeyCommands.append(enterKey)
        }
        return textView
    }

    @objc
    private func shiftEnterHandler(_ command: UIKeyCommand) {
        if inputTextView.isFirstResponder {
            inputTextView.insertText("\n")
        }
    }

    @objc
    private func enterHandler(_ command: UIKeyCommand) {

    }

    @objc
    func reportDocOutdate() {
        guard let hostVC else { return }
        let viewForHUD: UIView = hostVC.view.window ?? hostVC.view
        FreshnessService.feedbackExpired(objToken: docsInfo.objToken,
                                         objType: docsInfo.type,
                                         feedbackNote: inputTextView.text)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] in
                UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_CM_Verify_Reminded_Toast, on: viewForHUD)
                self?.dismiss(animated: true)
            } onError: { [weak self] error in
                if let docsError = error as? DocsNetworkError, docsError.code == .reachMetionNotifyLimit {
                    UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_CM_Verify_Reminded_Toast, on: viewForHUD)
                } else {
                    DocsLogger.error("docFresh: feedback Doc Expired Faild \(error.localizedDescription)")
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_Verify_RemindFail_Toast, on: viewForHUD)
                }
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // PermissionTopTipViewDelegate
    func handleTitleLabelClicked(_ tipView: PermissionTopTipView, index: Int, range: NSRange) {
        guard let ownerID = docsInfo.ownerID else {
            DocsLogger.warning("docFresh: no ownerId")
            return
        }
        //跳转到用户profile
        let params = ["type": docsInfo.type.rawValue]
        HostAppBridge.shared.call(ShowUserProfileService(userId: ownerID, fileName: docsInfo.name, fromVC: self, params: params))
    }
}
