//
//  MemberInviteViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LarkMessengerInterface
import LarkAlertController
import LKCommonsLogging
import LarkContainer
import LarkTraitCollection
import LarkEnv
import LarkAccountInterface

/// 团队成员定向邀请页
final class MemberInviteViewController: BaseUIViewController, UserResolverWrapper {
    var rightButtonTitle: String?
    var rightButtonClickHandler: (() -> Void)?
    let viewModel: MemberInviteViewModel
    var currentContainer: UIView = .init()
    private var isPresented: Bool = false
    var userResolver: LarkContainer.UserResolver
    private let passportService: PassportService
    @ScopedInjectedLazy private var inviteStorageService: InviteStorageService?
    static let logger = Logger.log(MemberInviteViewController.self, category: "LarkContact.MemberInviteViewController")

    private lazy var needDisablePopSource: Bool = {
        return (viewModel.sourceScenes == .newGuide
                    || (viewModel.sourceScenes == .upgrade && passportService.isOversea)
                    || viewModel.sourceScenes == .feedBanner)
            && !viewModel.isFromInviteSplitPage
    }()
    private lazy var showSkipNavItem: Bool = {
        return (viewModel.sourceScenes == .newGuide
                    || viewModel.sourceScenes == .upgrade
                    || viewModel.sourceScenes == .feedBanner)
            && !viewModel.isFromInviteSplitPage
    }()

    private lazy var segmentView: SegmentView = {
        let segment = StandardSegment(withHeight: 40)
        segment.lineStyle = .adjust
        segment.selectedIndexWillChangeBlock = { [unowned self] (_, newIndex) in
            let type = FieldListType(rawValue: newIndex)
            switch type {
            case .email:
                Tracer.trackAddMemberSwitchToEmailClick(source: self.viewModel.sourceScenes)
            case .phone:
                Tracer.trackAddMemberSwitchToPhoneClick(source: self.viewModel.sourceScenes)
            default: break
            }
        }
        segment.selectedIndexDidChangeBlock = { [unowned self] (_, newIndex) in
            self.viewModel.resignCurrentResponder()
            self.viewModel.currentType = FieldListType(rawValue: newIndex) ?? self.viewModel.currentType
        }
        return SegmentView(segment: segment)
    }()
    private lazy var emailContainer = { [unowned self] () -> EmailInviteContainer in
        let container = EmailInviteContainer(viewModel: viewModel)
        return container
    }()
    private lazy var phoneContainer = { [unowned self] () -> PhoneInviteContainer in
        let container = PhoneInviteContainer(viewModel: viewModel)
        return container
    }()

    // MARK: - lifeCycle
    init(viewModel: MemberInviteViewModel, resolver: UserResolver) throws {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.passportService = try resolver.resolve(assert: PassportService.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isPresented = !hasBackPage && presentingViewController != nil
        layoutPageSubviews()
        registerKeyboardNotification()
        Tracer.trackAddMemberSendShow(source: viewModel.sourceScenes)
        // override traitCollection observe
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.setSpecialNavBarIfOnOnboardingProcess()
            }).disposed(by: viewModel.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSpecialNavBarIfOnOnboardingProcess()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBase), for: .default)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isPresented || (self.needDisablePopSource && !viewModel.isFromInviteSplitPage) {
            /// 不使用 asyncAfter，会禁用侧滑无效
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            }
        }
        self.pushGroupNameSettingPageIfSimpleB()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isPresented || (self.needDisablePopSource && !viewModel.isFromInviteSplitPage) {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    func quit() {
        Tracer.trackAddMemberGoBackClick(source: viewModel.sourceScenes)
        if isPresented {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc
    func skipStep() {
        Tracer.trackAddMemberSkip(source: viewModel.sourceScenes)
        if let handler = rightButtonClickHandler {
            handler()
        } else {
            if isPresented {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    override internal func closeBtnTapped() { quit() }
    override internal func backItemTapped() { quit() }
}

private extension MemberInviteViewController {
    func setSpecialNavBarIfOnOnboardingProcess() {
        if needDisablePopSource {
            // clear left back button
            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
        if showSkipNavItem {
            // add right skip button
            let skipItem = LKBarButtonItem(image: nil, title: rightButtonTitle ?? BundleI18n.LarkContact.Lark_Guide_VideoSkip)
            skipItem.button.setTitleColor(UIColor.ud.N900, for: .normal)
            skipItem.button.addTarget(self, action: #selector(skipStep), for: .touchUpInside)
            navigationItem.rightBarButtonItem = skipItem
        }
    }

    func pushGroupNameSettingPageIfSimpleB() {
        if viewModel.currentTenantIsSimpleB {
            MemberInviteViewController.logger.info("current tenant is simple B")
            Tracer.trackGuideUpdateDialogShow()
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogTitle)
            alertController.setContent(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogContent())
            alertController.addCancelButton(dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                Tracer.trackGuideUpdateDialogSkip()
                if self.isPresented {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamYes, dismissCompletion: {
                Tracer.trackGuideUpdateDialogClick()
                self.viewModel.router.pushToGroupNameSettingController(self) { [weak self] (isSuccess) in
                    guard let `self` = self else { return }
                    if isSuccess {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        if self.isPresented {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.popSelf(dismissPresented: false)
                        }
                    }
                }
            })
            present(alertController, animated: true)
        } else {
            MemberInviteViewController.logger.info("current tenant is not simple B")
        }
    }

    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBase
        guard let inviteStorageService = self.inviteStorageService else { return }
        title = inviteStorageService.getInviteInfo(key: InviteStorage.isAdministratorKey) ?
            BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleThree_AddMembersDirectly_EnterPhone :
            BundleI18n.LarkContact.Lark_Invitation_AddMembersTitle
        if viewModel.shouldShowEmailInvitation && viewModel.shouldShowPhoneInvitation {
            view.addSubview(segmentView)
            segmentView.set(views: [(title: BundleI18n.LarkContact.Lark_Invitation_AddMembersViaEmail, view: emailContainer),
                                         (title: BundleI18n.LarkContact.Lark_Invitation_AddMembersViaPhone, view: phoneContainer)])
            currentContainer = segmentView
            Tracer.trackAddMemberInputEmail(source: viewModel.sourceScenes)
        } else if viewModel.shouldShowEmailInvitation {
            view.addSubview(emailContainer)
            currentContainer = emailContainer
            Tracer.trackAddMemberInputEmail(source: viewModel.sourceScenes)
            title = BundleI18n.LarkContact.Lark_Guide_TeamCreate2MobileEmail
        } else {
            view.addSubview(phoneContainer)
            currentContainer = phoneContainer
            Tracer.trackAddMemberInputPhone(source: viewModel.sourceScenes)
            title = BundleI18n.LarkContact.Lark_Invitation_AddMembersViaPhone
        }

        currentContainer.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(Display.iPhoneXSeries ? -49 : 0)
        }
    }

    func registerKeyboardNotification() {
        if Display.pad {
            return
        }
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue, let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.currentContainer.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview().offset(-keyboardFrame.height)
                    })
                    self.currentContainer.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: viewModel.disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.currentContainer.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview().offset(Display.iPhoneXSeries ? -49 : 0)
                    })
                    self.currentContainer.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: viewModel.disposeBag)
    }
}
