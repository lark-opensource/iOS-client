//
//  InvitationViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/10.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import RxSwift
import UniverseDesignToast
import EENavigator
import LarkNavigator
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import LarkContainer

final class InvitationViewController: BaseUIViewController, UserResolverWrapper {
    private lazy var segmentView: SegmentView = {
        let segment = StandardSegment(withHeight: 40)
        segment.lineStyle = .adjust
        return SegmentView(segment: segment)
    }()
    /// 电话邀请
    private lazy var phoneInvitationView = InvitationView(invitationType: .mobile, delegate: self)
    /// 邮件邀请
    private lazy var emailInvitationView = InvitationView(invitationType: .email, delegate: self)

    private var invitationUser: UserProfile?
    var userResolver: LarkContainer.UserResolver
    private let viewModel: InvitationViewModel
    private let disposeBag = DisposeBag()

    static let phoneRegex: String = "^\\d{1,20}$"
    static let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

    init(viewModel: InvitationViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_Legacy_InvitePartners
        /// 飞书用户禁用邮件邀请
        if !self.viewModel.isOversea {
            self.view.addSubview(phoneInvitationView)
            phoneInvitationView.snp.makeConstraints { $0.edges.equalToSuperview() }
            if InvitationViewController.phonePredicate.evaluate(with: viewModel.content) {
                phoneInvitationView.setContent(content: viewModel.content)
            }
        } else {
            self.view.addSubview(segmentView)
            segmentView.snp.makeConstraints { $0.edges.equalToSuperview() }
            segmentView.set(views: [(title: BundleI18n.LarkContact.Lark_Legacy_Phone, view: phoneInvitationView),
                                    (title: BundleI18n.LarkContact.Lark_Legacy_InviteViaEmail, view: emailInvitationView)])
            if InvitationViewController.phonePredicate.evaluate(with: viewModel.content) {
                phoneInvitationView.setContent(content: viewModel.content)
            } else if !viewModel.content.isEmpty {
                emailInvitationView.setContent(content: viewModel.content)
            }
        }
        viewModel.loadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InvitationViewController: InvitationViewDelegate {

    func invite(type: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, content: String) {
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        self.viewModel.invite(type: type, content: content)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                hud.remove()
                guard let `self` = self else { return }
                if result.success {
                    switch type {
                    case .email:
                        self.emailInvitationView.setResult(isSuccess: result.success)
                    case .mobile:
                        self.phoneInvitationView.setResult(isSuccess: result.success)
                    case .unknown:
                        break
                    @unknown default:
                        assert(false, "new value")
                        break
                    }
                } else {
                    guard let userInfo = result.user else { return }
                    self.invitationUser = userInfo
                    let displayName = userInfo.alias.isEmpty ? userInfo.localizedName : userInfo.alias
                    switch type {
                    case .email:
                        self.emailInvitationView.setResult(
                            isSuccess: result.success,
                            entityId: userInfo.userId,
                            avatarKey: userInfo.avatarKey,
                            displayName: displayName,
                            tenantName: userInfo.company.tenantName
                        )
                    case .mobile:
                        self.phoneInvitationView.setResult(
                            isSuccess: result.success,
                            entityId: userInfo.userId,
                            avatarKey: userInfo.avatarKey,
                            displayName: displayName,
                            tenantName: userInfo.company.tenantName
                        )
                    case .unknown:
                        break
                    @unknown default:
                        assert(false, "new value")
                        break
                    }
                }
            }, onError: { [weak self] (error) in
                guard let window = self?.view.window else { return }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .mobileFormatIncorrect:
                        hud.showFailure(
                            with: BundleI18n.LarkContact.Lark_Legacy_InvitePhoneRemind,
                            on: window,
                            error: error
                        )
                    case .emailFormatIncorrect:
                        hud.showFailure(
                            with: BundleI18n.LarkContact.Lark_Legacy_EnterValidEmail,
                            on: window,
                            error: error
                        )
                    default:
                        hud.showFailure(
                            with: BundleI18n.LarkContact.Lark_Legacy_FriendRequestSendFailedRetry,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    hud.showFailure(
                        with: BundleI18n.LarkContact.Lark_Legacy_FriendRequestSendFailedRetry,
                        on: window,
                        error: error
                    )
                }
            }).disposed(by: self.disposeBag)
    }

    func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }

    func pushPersonCard() {
        if let userProfile = self.invitationUser {
            let body = ProfileCardBody(userProfile: userProfile, fromWhere: .invitation)
            navigator.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: self,
                                           prepareForPresent: { (vc) in
               vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func pushSelectVC() {
        /// 飞书用户 && fg关：不能邀请国外用户
        if !self.viewModel.isOversea && !self.viewModel.inviteAbroadphone { return }

        let body = SelectCountryNumberBody(hotDatasource: self.viewModel.hotDatasource,
                                           allDatasource: self.viewModel.hotDatasource
        ) { [weak self] (number) in
            guard let `self` = self else { return }
            self.phoneInvitationView.setCountry(number: number)
        }

        navigator.present(body: body, from: self)
    }
}
