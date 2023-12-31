//
//  ExternalInviteSendController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/11/4.
//

import UIKit
import Foundation
import RxSwift
import LarkActionSheet
import LarkModel
import UniverseDesignToast
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkRustClient

protocol ExternalInviteSendRouter {
    func presentCountryCodeSelectController(vc: UIViewController, selectCompletionHandler: @escaping (String) -> Void)
}

final class ExternalInviteSendController: UIViewController {
    static let thresholdOffset: CGFloat = 120
    static let cornerRadius: CGFloat = 20
    static let containerTopMargin: CGFloat = 64

    private let viewModel: ExternalInviteSendViewModel
    private let router: ExternalInviteSendRouter
    private let source: SourceScene
    private let transition = ActionSheetTransition()
    private let disposeBag = DisposeBag()
    private let sendCompletionHandler: () -> Void
    private var needBecomeFirstResponder: Bool = true
    private var contentHeight: CGFloat = 0
    private var originY: CGFloat {
        return view.frame.height - contentHeight
    }
    private lazy var updateLayoutOnce: Void = {
        calculateContentHeight()
        containerView.snp.updateConstraints { (make) in
            make.height.equalTo(contentHeight)
        }
    }()

    init(viewModel: ExternalInviteSendViewModel,
         router: ExternalInviteSendRouter,
         source: SourceScene,
         sendCompletionHandler: @escaping () -> Void) {
        self.viewModel = viewModel
        self.router = router
        self.source = source
        self.sendCompletionHandler = sendCompletionHandler
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        calculateContentHeight()
        layoutPageSubviews()
        addKeyboardObserver()
        addverificationStateObserve()
        fillInitialDataSource(type: viewModel.sendType)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if needBecomeFirstResponder {
            self.senderField.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _ = updateLayoutOnce
    }

    func sendInvite() {
        let isValid = viewModel.verify(senderField.text ?? "")
        if isValid {
            let sendInviteRequestHandle = {
                /// send invite request
                let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
                self.viewModel
                    .sendInviteMessage(contactContent: self.viewModel.getPureContactsContent(self.senderField.text ?? ""))
                    .timeout(.seconds(5), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (result: InvitationResult) in
                        guard let `self` = self else { return }
                        let presentView = self.presentingViewController?.view
                        var msg = ""
                        hud.remove()
                        if result.success {
                            self.dismiss(animated: true, completion: nil)
                            self.sendCompletionHandler()
                            msg = BundleI18n.LarkContact.Lark_UserGrowth_InviteTenantToastSent
                        } else {
                            msg = BundleI18n.LarkContact.Lark_UserGrowth_InviteTenantToastFailed
                        }
                        if let presentView = presentView {
                            UDToast.showTips(with: msg, on: presentView)
                        }
                        self.buzTrackWhenDidSend(isSuccess: true)
                    }, onError: { [weak self] (error) in
                        guard let `self` = self else { return }
                        hud.remove()
                        if let rcError = error.metaErrorStack.last as? RCError,
                            case let .businessFailure(buzErrorInfo) = rcError {
                            UDToast.showFailure(with: buzErrorInfo.displayMessage, on: self.view, error: error)
                            if buzErrorInfo.errorCode == 5011 {
                                self.senderField.fieldState = .invalid
                            }
                        }
                        self.buzTrackWhenDidSend(isSuccess: false)
                    })
                    .disposed(by: self.disposeBag)
            }
            if senderField.isFirstResponder {
                senderField.resignFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    sendInviteRequestHandle()
                }
            } else {
                sendInviteRequestHandle()
            }
        } else {
            buzTrackWhenDidSend(isSuccess: false)
        }
    }

    private lazy var containerView: UIControl = {
        let containerView = UIControl()
        containerView.backgroundColor = UIColor.ud.bgBody
        /// add top corner radius
        let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: contentHeight)
        let maskPath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight],
                                    cornerRadii: CGSize(width: ExternalInviteSendController.cornerRadius, height: ExternalInviteSendController.cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        containerView.layer.mask = maskLayer
        /// add pan gesture handle
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        containerView.addGestureRecognizer(pan)
        containerView.addTarget(self, action: #selector(clickToResign), for: .touchUpInside)
        return containerView
    }()

    private lazy var panGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 2.0
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var inviteSendIconView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.invite_send_icon
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickToSend))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var senderField: InviteSendField = {
        let field = InviteSendField(viewModel: viewModel, delegate: self)
        return field
    }()

    private lazy var inviteMsgLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    /// Phone handle views
    private lazy var phoneHandleView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var countryCodeSelectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.selectCountryCode()
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var downArrowView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.down_arrow
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCountryCode))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var splitLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    private lazy var phoneFieldLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    /// Email handle views
    private lazy var emailHandleView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var toLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_UserGrowth_SearchNoResultReceiver
        return label
    }()

    private lazy var toLabelLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    private lazy var subjectLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_UserGrowth_SearchNoResultSubject
        return label
    }()

    private lazy var subjectContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle()
        return label
    }()

    private lazy var subjectLabelLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()
}

extension ExternalInviteSendController: InviteSendFieldDelegate {
    func fieldContentDidChange(field: InviteSendField, content: String) {
        if content.isEmpty {
            viewModel.verificationStateSubject.accept(.empty)
        } else if viewModel.verificationStateSubject.value == .empty {
            viewModel.verificationStateSubject.accept(.waiting)
        }
    }

    func fieldStateDidChange(field: InviteSendField, state: InviteFieldState) {
        if state == .valid {
            viewModel.verificationStateSubject.accept(field.isFirstResponder ? .waiting : .valid)
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        viewModel.verificationStateSubject.accept((textField.text ?? "").isEmpty ? .empty : .waiting)
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        viewModel.verify(textField.text ?? "")
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendInvite()
        return true
    }
}

private extension ExternalInviteSendController {
    @objc
    func selectCountryCode() {
        /// select country code
        self.senderField.resignFirstResponder()
        self.needBecomeFirstResponder = false
        self.router.presentCountryCodeSelectController(vc: self) { [weak self] (countryCode) in
            guard let `self` = self else { return }
            self.viewModel.countryCode = countryCode
            self.countryCodeSelectButton.setTitle(countryCode, for: .normal)
            self.viewModel.verify(self.senderField.text ?? "")
        }
    }

    func addverificationStateObserve() {
        viewModel.verificationStateSubject.asDriver().drive(onNext: { [weak self] (state) in
            guard let `self` = self else { return }
            switch state {
            case .empty:
                self.inviteSendIconView.image = Resources.invite_send_icon_unable
            case .valid:
                self.inviteSendIconView.image = Resources.invite_send_icon
                self.senderField.fieldState = .valid
            case .invalid:
                self.inviteSendIconView.image = Resources.invite_send_icon_unable
                self.senderField.fieldState = .invalid
                let errorTip = self.viewModel.sendType == .phone ?
                    BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberInvalidPhone :
                    BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberInvalidEmail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UDToast.showTipsOnScreenCenter(with: errorTip, on: self.view)
                }
            case .waiting:
                self.inviteSendIconView.image = Resources.invite_send_icon
            }
        }).disposed(by: disposeBag)
    }

    func fillInitialDataSource(type: InviteSendType) {
        if viewModel.content.isEmpty {
            inviteSendIconView.image = Resources.invite_send_icon_unable
        }
        senderField.text = viewModel.content
        if type == .phone {
            countryCodeSelectButton.setTitle(viewModel.countryCode, for: .normal)
        } else if type == .email {

        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .left
        let attrs: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle,
                                                    .font: UIFont.systemFont(ofSize: 16),
                                                    .foregroundColor: UIColor.ud.N500]
        let attributedString = NSMutableAttributedString(string: viewModel.inviteMsg)
        attributedString.addAttributes(attrs, range: NSRange(location: 0, length: viewModel.inviteMsg.count))
        inviteMsgLabel.attributedText = attributedString
    }

    func addControl() {
        let control = UIControl()
        control.backgroundColor = .clear
        control.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        view.addSubview(control)
        control.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func calculateContentHeight() {
        var height = view.frame.height - ExternalInviteSendController.containerTopMargin
        if let safeAreaInsets = view.window?.safeAreaInsets {
            height -= safeAreaInsets.top
        }
        contentHeight = height
    }

    func layoutPageSubviews() {
        addControl()
        view.addSubview(containerView)
        containerView.addSubview(panGuideView)
        containerView.addSubview(inviteSendIconView)
        containerView.addSubview(inviteMsgLabel)

        containerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentHeight)
        }
        panGuideView.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        inviteSendIconView.snp.makeConstraints { (make) in
            make.width.equalTo(20.5)
            make.height.equalTo(22)
            make.right.equalToSuperview().offset(-17)
            if let safeAreaInsets = view.window?.safeAreaInsets {
                make.bottom.equalToSuperview().offset(-safeAreaInsets.bottom - 7.5)
            } else {
                make.bottom.equalToSuperview().offset(-7.5)
            }
        }
        setFormView(type: viewModel.sendType)
    }

    /// PAD屏幕旋转更新显示
    func padTransitionUpdateDisplay() {
        if !Display.pad {
            return
        }
        calculateContentHeight()
        containerView.snp.updateConstraints { (make) in
            make.height.equalTo(self.contentHeight)
        }
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: contentHeight)
        let maskPath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight],
                                    cornerRadii: CGSize(width: ExternalInviteSendController.cornerRadius, height: ExternalInviteSendController.cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        containerView.layer.mask = maskLayer
        containerView.superview?.layoutIfNeeded()
    }

    func setFormView(type: InviteSendType) {
        if type == .phone {
            containerView.addSubview(phoneHandleView)
            phoneHandleView.addSubview(countryCodeSelectButton)
            phoneHandleView.addSubview(downArrowView)
            phoneHandleView.addSubview(splitLine)
            phoneHandleView.addSubview(phoneFieldLine)
            phoneHandleView.addSubview(senderField)
            containerView.addSubview(inviteMsgLabel)

            phoneHandleView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(32)
                make.height.equalTo(54)
            }
            countryCodeSelectButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.width.equalTo(44)
                make.top.bottom.equalToSuperview()
            }
            downArrowView.snp.makeConstraints { (make) in
                make.left.equalTo(countryCodeSelectButton.snp.right).offset(4)
                make.width.height.equalTo(16)
                make.centerY.equalToSuperview()
            }
            splitLine.snp.makeConstraints { (make) in
                make.left.equalTo(downArrowView.snp.right).offset(12)
                make.width.equalTo(1)
                make.height.equalTo(22)
                make.centerY.equalToSuperview()
            }
            senderField.snp.makeConstraints { (make) in
                make.left.equalTo(splitLine.snp.right).offset(0)
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.top.equalToSuperview()
            }
            phoneFieldLine.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
            inviteMsgLabel.snp.makeConstraints { (make) in
                make.top.equalTo(phoneHandleView.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        } else if type == .email {
            containerView.addSubview(emailHandleView)
            emailHandleView.addSubview(toLabel)
            emailHandleView.addSubview(senderField)
            emailHandleView.addSubview(toLabelLine)
            emailHandleView.addSubview(subjectLabel)
            emailHandleView.addSubview(subjectContentLabel)
            emailHandleView.addSubview(subjectLabelLine)
            containerView.addSubview(inviteMsgLabel)

            emailHandleView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(32)
                make.height.equalTo(109)
            }
            toLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.top.equalToSuperview()
                make.height.equalTo(54)
            }
            senderField.snp.makeConstraints { (make) in
                make.left.equalTo(toLabel.snp.right).offset(0)
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview()
                make.height.equalTo(54)
            }
            toLabelLine.snp.makeConstraints { (make) in
                make.top.equalTo(senderField.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(0.5)
            }
            subjectLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.top.equalTo(toLabelLine.snp.bottom)
                make.height.equalTo(54)
            }
            subjectContentLabel.snp.makeConstraints { (make) in
                make.left.equalTo(subjectLabel.snp.right).offset(12)
                make.top.equalTo(toLabelLine.snp.bottom)
                make.height.equalTo(54)
            }
            subjectLabelLine.snp.makeConstraints { (make) in
                make.top.equalTo(subjectContentLabel.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(0.5)
            }
            inviteMsgLabel.snp.makeConstraints { (make) in
                make.top.equalTo(emailHandleView.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        }
    }

    func panEnded() {
        if (containerView.frame.minY - originY) > ExternalInviteSendController.thresholdOffset {
            dismiss(animated: true, completion: nil)
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.containerView.frame = CGRect(x: 0, y: self.originY, width: self.view.frame.width, height: self.contentHeight)
            })
        }
    }

    func updateContaineViewFrame(_ offsetY: CGFloat) {
        /// Update the upper boundary of the container based on the offset of the gesture point
        /// The maximum does not exceed the initial value(originY)
        let result = originY + offsetY
        let finalY = max(originY, result)
        containerView.frame = CGRect(x: 0, y: finalY, width: view.frame.width, height: contentHeight)
    }

    // MARK: - 屏幕旋转适配
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let `self` = self else { return }
            self.padTransitionUpdateDisplay()
        }, completion: nil)
    }

    func addKeyboardObserver() {
        if Display.pad {
            return
        }
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue, let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.containerView.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview().offset(-keyboardFrame.height)
                        make.height.equalTo(self.contentHeight - keyboardFrame.height)
                    })
                    self.containerView.superview?.layoutIfNeeded()
                    self.inviteSendIconView.snp.updateConstraints { (make) in
                        make.bottom.equalToSuperview().offset(-7.5)
                    }
                    self.inviteSendIconView.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.containerView.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview()
                        make.height.equalTo(self.contentHeight)
                    })
                    self.containerView.superview?.layoutIfNeeded()
                    self.inviteSendIconView.snp.updateConstraints { (make) in
                        if let safeAreaInsets = self.view.window?.safeAreaInsets {
                            make.bottom.equalToSuperview().offset(-safeAreaInsets.bottom - 7.5)
                        } else {
                            make.bottom.equalToSuperview().offset(-7.5)
                        }
                    }
                    self.inviteSendIconView.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)
    }

    @objc
    func clickToSend() {
        let state = viewModel.verificationStateSubject.value
        guard state == .valid || state == .waiting else { return }
        self.sendInvite()
    }

    @objc
    func clickToResign() {
        self.senderField.resignFirstResponder()
    }

    @objc
    func handlePan(pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: containerView)
        switch pan.state {
        case .began:
            view.endEditing(true)
        case .changed:
            updateContaineViewFrame(point.y)
        case .cancelled, .ended, .failed:
            panEnded()
        default:
            break
        }
    }

    @objc
    func dismiss(_ gesture: UIGestureRecognizer) {
        buzTrackWhenDismiss()
        senderField.text = ""
        dismiss(animated: true, completion: nil)
    }

    func buzTrackWhenDismiss() {
        /// Compatible with the modification of the email & phone number
        let hasChanged = "\(viewModel.initialCountryCode)\(viewModel.content)" == "\(viewModel.countryCode)\(senderField.text ?? "")"
        switch source {
        case .search:
            Tracer.trackInvitePeopleExternalSearchInviteCancel(changeTo: hasChanged ? 1 : 0)
        case .deviceContacts:
            Tracer.trackInvitePeopleExternalImportInviteCancel(changeTo: hasChanged ? 1 : 0)
        }
    }

    func buzTrackWhenDidSend(isSuccess: Bool) {
        /// Compatible with the modification of the email & phone number
        let hasChanged = "\(viewModel.initialCountryCode)\(viewModel.content)" == "\(viewModel.countryCode)\(senderField.text ?? "")"
        switch source {
        case .search:
            Tracer.trackInvitePeopleExternalSearchInviteSend(result: isSuccess ? "1" : "0", changeTo: hasChanged ? 1 : 0)
        case .deviceContacts:
            Tracer.trackInvitePeopleExternalImportInviteSend(result: isSuccess ? "1" : "0", changeTo: hasChanged ? 1 : 0)
        }
        switch viewModel.sendType {
        case .email:
            Tracer.trackInvitePeopleH5Share(
                method: .shareLink,
                channel: .inviteEmail,
                uniqueId: viewModel.uniqueId,
                type: .link
            )
        case .phone:
            Tracer.trackInvitePeopleH5Share(
                method: .shareLink,
                channel: .inviteMessage,
                uniqueId: viewModel.uniqueId,
                type: .link
            )
        }
    }
}
