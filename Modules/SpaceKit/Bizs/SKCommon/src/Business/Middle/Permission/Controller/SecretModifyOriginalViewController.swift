//
//  SecretModifyOriginalViewController.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/8/31.
//
//  swiftlint:disable file_length

import Foundation
import SKFoundation
import UniverseDesignColor
import RxSwift
import RxCocoa
import SKUIKit
import SKResource
import SnapKit
import UniverseDesignToast
import UniverseDesignIcon

private enum Layout {
    static var headerHeight: CGFloat { 48 }
    static var itemHeight: CGFloat { 48 }
    static var itemHorizontalSpacing: CGFloat { 13 }
    static var buttonHeight = 48
}

public protocol SecretModifyOriginalViewDelegate: AnyObject {
    ///密级修改成功
    func didUpdateLevel(_ view: UIViewController, viewModel: SecretModifyViewModel)
    /// 取消
    func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel)
    ///审批提交成功
    func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel)
}

// 密级修改理由
public final class SecretModifyOriginalViewController: SKTranslucentPanelController, UITextViewDelegate {
    public weak var delegate: SecretModifyOriginalViewDelegate?
    private let disposeBag = DisposeBag()
    private var permStatistic: PermissionStatistics? { viewModel.permStatistic }
    public private(set) var viewModel: SecretModifyViewModel
    var didSubmitApproval: ((UIViewController?, SecretModifyViewModel) -> Void)?
    weak var hostVC: UIViewController?

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifyTitle)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.text = viewModel.descriptionLabelText
        return label
    }()

    /// 放置审批人列表的stackView
    private lazy var reviewersView: ApprovalReviewersView = {
//        let view = ApprovalReviewersView(reviewers: viewModel.approvalDef?.reviewers ?? [])
        let view = ApprovalReviewersView()
        view.click = { [weak self] reviewer in
            guard let self = self else { return }
            HostAppBridge.shared.call(ShowUserProfileService(userId: reviewer.id, fromVC: self))
        }
        return view
    }()

    private lazy var originalInput: SKUDBaseTextView = setupTextView()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.CreationMobile_SecureLabel_Submit_Btn, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.iconDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.primaryContentDefault), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    private let keyboard = Keyboard()

    public init(viewModel: SecretModifyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.viewSizeChanged]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.reportPermissionSecurityDemotionView()
    }


    public override func setupUI() {
        super.setupUI()
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        containerView.addSubview(headerView)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(originalInput)
        containerView.addSubview(resetButton)
        containerView.addSubview(confirmButton)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        var originalInputTopView: UIView = descriptionLabel
        if viewModel.needApproval && viewModel.displayReviewers.count > 0 {
            containerView.addSubview(reviewersView)
            reviewersView.snp.makeConstraints { make in
                make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            reviewersView.width = Float(view.frame.width - 2 * 16)
            reviewersView.update(reviewers: viewModel.displayReviewers)
            originalInputTopView = reviewersView
        }

        originalInput.snp.makeConstraints { make in
            make.top.equalTo(originalInputTopView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(108)
        }

        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(originalInput.snp.bottom).offset(24)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
        confirmButton.isEnabled = false

        // 输入框文本改变
        _ = originalInput.rx.text.orEmpty
                .map({ !$0.isEmpty })
                .asDriver(onErrorJustReturn: false)
                .drive(confirmButton.rx.isEnabled)
                .disposed(by: disposeBag)

        setupKeyboardMonitor()
        
        UIView.animate(withDuration: 0.25) {
            self.originalInput.becomeFirstResponder()
        }
    }

    private func setupKeyboardMonitor() {
        keyboard.on(event: .willShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.resetButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.resetButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .willHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.resetButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.resetButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(24)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.start()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        originalInput.becomeFirstResponder()
        return false
    }

    @objc
    private func didClickConfirm() {
        guard let text = originalInput.text, text.count <= 1024 else {
            showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_MaxLength, type: .tips)
            return
        }
        viewModel.reason = text
        viewModel.reportPermissionSecurityDemotionClick(click: .apply, target: DocsTracker.EventType.noneTargetView.rawValue)

        if viewModel.needApproval {
            createApprovalInstance()
        } else {
            updateSecretLevel()
        }
    }

    private func updateSecretLevel() {
        showToast(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submitting_Mob, type: .loading)
        confirmButton.isEnabled = false
        viewModel.updateSecLabel()
            .subscribe { [self] in
                confirmButton.isEnabled = true
                DocsLogger.info("update secret level success")
                showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, type: .success)
                delegate?.didUpdateLevel(self, viewModel: viewModel)
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
                dismiss(animated: true)
            } onError: { [self] error in
                confirmButton.isEnabled = true
                DocsLogger.error("update secret level fail", error: error)
                showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, type: .failure)
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: false)
            }
            .disposed(by: disposeBag)
    }
    private func createApprovalInstance() {
        showToast(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submitting_Mob, type: .loading)
        confirmButton.isEnabled = false
        viewModel.createApprovalInstance()
            .subscribe { [self] in
                confirmButton.isEnabled = true
                DocsLogger.info("create approval instance success")
                UDToast.removeToast(on: self.view.window ?? self.view )
                dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didSubmitApproval(self, viewModel: self.viewModel)
                    self.didSubmitApproval?(self.hostVC, self.viewModel)
                }
            } onError: { [self] error in
                confirmButton.isEnabled = true
                DocsLogger.error("create approval instance fail", error: error)
                var text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevII_SubmitFailed_TryAgain_Toast
                if DocsNetworkError.error(error, equalTo: .forbidden) {
                    text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevII_SubmitFailed_NoPermission_Toast
                }
                showToast(text: text, type: .failure)
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: false)
            }
            .disposed(by: disposeBag)
    }

    @objc
    private func didClickReset() {
        delegate?.didClickCancel(self, viewModel: viewModel)
        viewModel.reportPermissionSecurityDemotionClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue)
        self.dismiss(animated: true)
    }

    @objc
    public override func didClickMask() {
        super.didClickMask()
        delegate?.didClickCancel(self, viewModel: viewModel)
    }

    private func setupTextView() -> SKUDBaseTextView {
        let textView = SKUDBaseTextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholder = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifyDesc
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
        if originalInput.isFirstResponder {
            originalInput.insertText("\n")
        }
    }

    @objc
    private func enterHandler(_ command: UIKeyCommand) {

    }
}

extension SecretModifyOriginalViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

public final class IpadSecretModifyOriginalViewController: BaseViewController, UITextViewDelegate {
    public weak var delegate: SecretModifyOriginalViewDelegate?
    private let disposeBag = DisposeBag()
    private var permStatistic: PermissionStatistics? {
        viewModel.permStatistic
    }
    public private(set) var viewModel: SecretModifyViewModel
    var didSubmitApproval: ((UIViewController?, SecretModifyViewModel) -> Void)?
    weak var hostVC: UIViewController?

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        var text = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifySubtitle
        label.text = viewModel.descriptionLabelText
        return label
    }()

    /// 放置审批人列表的stackView
    private lazy var reviewersView: ApprovalReviewersView = {
//        let view = ApprovalReviewersView(reviewers: viewModel.displayReviewers)
        let view = ApprovalReviewersView()
        view.click = { [weak self] reviewer in
            guard let self = self else { return }
            HostAppBridge.shared.call(ShowUserProfileService(userId: reviewer.id, fromVC: self))
        }
        return view
    }()

    private lazy var originalInput: SKUDBaseTextView = setupTextView()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.CreationMobile_SecureLabel_Submit_Btn, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.iconDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.primaryContentDefault), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    private let keyboard = Keyboard()

    public init(viewModel: SecretModifyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: false, completion: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboard.start()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboard.stop()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateReviewersView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaultValue()
        setupUI()
        viewModel.reportPermissionSecurityDemotionView()
    }

    func setupDefaultValue() {
        view.backgroundColor = UDColor.bgBase
        navigationBar.title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifyTitle
        let image = UDIcon.closeSmallOutlined
        let item = SKBarButtonItem(image: image,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        item.id = .back
        navigationBar.leadingBarButtonItem = item
    }


    override public var canShowBackItem: Bool {
        return false
    }

    override public func backBarButtonItemAction() {
        viewModel.reportPermissionSecurityDemotionClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue)
        self.dismiss(animated: true, completion: nil)
    }

    public  func setupUI() {
        originalInput.backgroundColor = UDColor.bgBody

        view.addSubview(descriptionLabel)
        view.addSubview(originalInput)
        view.addSubview(resetButton)
        view.addSubview(confirmButton)

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.lessThanOrEqualTo(40)
        }

        var originalInputTopView: UIView = descriptionLabel
        if viewModel.needApproval && viewModel.displayReviewers.count > 0 {
            view.addSubview(reviewersView)
            reviewersView.snp.makeConstraints { make in
                make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(16)
            }
//            reviewersView.width = Float(view.frame.width - 2 * 16)
//            reviewersView.update(reviewers: viewModel.displayReviewers)
            originalInputTopView = reviewersView
        }

        originalInput.snp.makeConstraints { make in
            make.top.equalTo(originalInputTopView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(originalInput.snp.bottom).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
        confirmButton.isEnabled = false

        // 输入框文本改变
        _ = originalInput.rx.text.orEmpty
                .map({ !$0.isEmpty })
                .asDriver(onErrorJustReturn: false)
                .drive(confirmButton.rx.isEnabled)
                .disposed(by: disposeBag)

        setupKeyboardMonitor()
    }

    private func updateReviewersView() {
        guard reviewersView.superview != nil else { return }
        reviewersView.width = Float(view.frame.width - 2 * 16)
        reviewersView.update(reviewers: viewModel.displayReviewers)
    }

    private func setupKeyboardMonitor() {
        keyboard.on(events: Keyboard.KeyboardEvent.allCases) { [weak self] (options) in
            guard let self = self else { return }
            guard let view = self.view else { return }
            let viewWindowBounds = view.convert(view.bounds, to: nil)

            var endFrame = options.endFrame.minY
            // 开启减弱动态效果/首选交叉淡出过渡效果,endFrame返回0.0,导致offset计算有问题
            if endFrame <= 0 {
                endFrame = viewWindowBounds.maxY
            }
            var offset = viewWindowBounds.maxY - endFrame - self.view.layoutMargins.bottom

            if self.isMyWindowRegularSizeInPad {
                var endFrameY = (options.endFrame.minY - self.view.frame.height) / 2
                endFrameY = endFrameY > 44 ? endFrameY : 44
                let moveOffest = self.view.convert(self.view.bounds, to: nil).minY - endFrameY
                offset -= moveOffest
            }
            self.resetButton.snp.updateConstraints({ (make) in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(min(-offset, -24))
            })

            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        originalInput.becomeFirstResponder()
        return false
    }

    @objc
    private func didClickConfirm() {
        guard let text = originalInput.text, text.count <= 1024 else {
            showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_MaxLength, type: .tips)
            return
        }
        viewModel.reason = text
        viewModel.reportPermissionSecurityDemotionClick(click: .apply, target: DocsTracker.EventType.noneTargetView.rawValue)

        if viewModel.needApproval {
            createApprovalInstance()
        } else {
            updateSecretLevel()
        }
    }

    private func updateSecretLevel() {
        showToast(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submitting_Mob, type: .loading)
        confirmButton.isEnabled = false
        viewModel.updateSecLabel()
            .subscribe { [self] in
                confirmButton.isEnabled = true
                DocsLogger.info("update secret level success")
                showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, type: .success)
                delegate?.didUpdateLevel(self, viewModel: viewModel)
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
                dismiss(animated: true)
            } onError: { [self] error in
                confirmButton.isEnabled = true
                DocsLogger.error("update secret level fail", error: error)
                showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, type: .failure)
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: false)
            }
            .disposed(by: disposeBag)
    }
    private func createApprovalInstance() {
        showToast(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submitting_Mob, type: .loading)
        confirmButton.isEnabled = false
        viewModel.createApprovalInstance()
            .subscribe { [self] in
                confirmButton.isEnabled = true
                DocsLogger.info("create approval instance success")
                UDToast.removeToast(on: self.view.window ?? self.view )
                dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didSubmitApproval(self, viewModel: self.viewModel)
                    self.didSubmitApproval?(self.hostVC, self.viewModel)
                }
            } onError: { [self] error in
                confirmButton.isEnabled = true
                DocsLogger.error("create approval instance fail", error: error)
                var text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevII_SubmitFailed_TryAgain_Toast
                if DocsNetworkError.error(error, equalTo: .forbidden) {
                    text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevII_SubmitFailed_NoPermission_Toast
                }
                self.viewModel.reportCcmPermissionSecurityDemotionResultView(success: false)
                showToast(text: text, type: .failure)
            }
            .disposed(by: disposeBag)
    }

    @objc
    private func didClickReset() {
        delegate?.didClickCancel(self, viewModel: viewModel)
        viewModel.reportPermissionSecurityDemotionClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue)
        self.dismiss(animated: true)
    }

    private func setupTextView() -> SKUDBaseTextView {
        let textView = SKUDBaseTextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholder = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifyDesc
        textView.delegate = self
        textView.bounces = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        textView.maxHeight = 108
        textView.textDragInteraction?.isEnabled = false
        textView.returnKeyType = .next
        textView.backgroundColor = UDColor.bgBody
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
        if originalInput.isFirstResponder {
            originalInput.insertText("\n")
        }
    }

    @objc
    private func enterHandler(_ command: UIKeyCommand) {

    }
}

extension IpadSecretModifyOriginalViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type, disableUserInteraction: true)
    }
}
