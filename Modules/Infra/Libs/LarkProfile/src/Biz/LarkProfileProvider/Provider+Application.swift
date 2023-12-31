//
//  Provider+Application.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/27.
//

import Foundation
import RustPB
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast
import LarkFeatureGating
import RxSwift
import UniverseDesignDialog
import LarkUIKit

extension LarkProfileDataProvider {
    public func changeRelationship(_ relationship: ProfileRelationship) {

        switch relationship {
        case .accept:
            self.acceptChatApplicationRequest()
        case .apply:
            self.pushAddContactRelationVC()
        case .accepted, .none, .applying:
            break
        }

    }

    /// 同意好友申请
    private func acceptChatApplicationRequest() {
        guard let userInfo = self.userProfile?.userInfoProtocol, let fromVC = self.profileVC else {
            return
        }

        let hasVerification = userInfo.hasTenantCertification_p
        && !userInfo.tenantName.getString().isEmpty ? "true" : "false"
        let isVerified = userInfo.hasTenantCertification_p
        && userInfo.isTenantCertification ? "true" : "false"

        self.tracker?.trackMainClick("contact_agree", extra: ["verification": hasVerification,
                                                            "is_verified": isVerified,
                                                            "target": "profile_main_view"])
        // 同意好友申请，需要服务端去同步协作权限
        var hud: UDToast = UDToast.showLoading(with: "", on: fromVC.view, disableUserInteraction: false)

        self.acceptChatApplicationWith(authSync: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak hud] in
                self?.actionForUserAcceptResponse(success: true, hud: hud)
            }, onError: { [weak self, weak hud] (error) in
                self?.actionForUserAcceptResponse(success: false, hud: hud, error: error)
            }).disposed(by: self.disposeBag)
    }

    private func actionForUserAcceptResponse(success: Bool, hud: UDToast?, error: Error? = nil) {
        guard let userInfo = self.userProfile?.userInfoProtocol, let fromVC = self.profileVC else {
            return
        }
        if let loadingView = hud {
            loadingView.remove()
        }

        if success {
            self.reloadData()
            let notificationName = Notification.Name(rawValue: LKFriendStatusChangeNotification)
            NotificationCenter.default.post(name: notificationName, object: ["userID": userInfo.userID, "isFriend": true])
            if let window = fromVC.view.window {
                UDToast.showTips(with: BundleI18n.LarkProfile.Lark_NewContacts_AcceptedContactRequestToast(), on: window)
            }
            return
        }

        guard let window = fromVC.view.window,
              let error = error else {
            fromVC.dismissSelf()
            return
        }
        UDToast.showFailure(
            with: BundleI18n.LarkProfile.Lark_Legacy_ActionFailedTryAgainLater,
            on: window,
            error: error
        )
    }

    /// 跳转新的添加好友的界面
    func pushAddContactRelationVC() {
        guard let userInfo = userProfile?.userInfoProtocol, let fromVC = self.profileVC else {
            return
        }

        let hasVerification = userInfo.hasTenantCertification_p
        && !userInfo.tenantName.getString().isEmpty ? "true" : "false"
        let isVerified = userInfo.hasTenantCertification_p
        && userInfo.isTenantCertification ? "true" : "false"

        self.tracker?.trackMainClick("contact_add", extra: ["verification": hasVerification,
                                                            "is_verified": isVerified,
                                                            "target": "profile_contact_request_view"])

        var source = Source()
        source.sender = data.sender
        source.sourceType = data.source
        source.sourceName = data.sourceName
        source.senderID = data.senderID
        source.sourceID = data.sourceID
        source.subSourceType = data.subSourceType

        let body = AddContactRelationBody(userId: userInfo.userID,
                                          chatId: data.chatId,
                                          token: data.contactToken,
                                          source: source,
                                          addContactBlock: { [weak self] (_) in
                                            guard let self = self else {
                                                return
                                            }
                                            self.reloadData()
                                          },
                                          userName: userInfo.userName,
                                          isAuth: userInfo.hasTenantCertification_p
                                          && userInfo.isTenantCertification,
                                          hasAuth: userInfo.hasTenantCertification_p
                                          && !userInfo.tenantName.getString().isEmpty,
                                          businessType: .profileAdd)
        self.userResolver.navigator.push(body: body, from: fromVC)
    }

    /// 接收添加好友请求
    func acceptChatApplicationWith(authSync: Bool) -> Observable<Void> {
        guard let userInfo = userProfile?.userInfoProtocol,
              let api = self.chatApplicationAPI else {
            return .just(())
        }

        return api.processChatApplication(id: String(userInfo.contactApplicationID),
                                    result: .agreed,
                                    authSync: authSync)
    }
}

extension LarkProfileDataProvider {
    public func changeCommunicationPermission(_ permission: ProfileCommunicationPermission) {
        guard let userInfo = userProfile?.userInfoProtocol else { return }
        let oppositeApplyStatus: ProfileCommunicationPermission = userInfo.applyCommunication.oppositeApplyStatus.getApplyCommunicationStatus()
        LarkProfileDataProvider.logger.info("change communication permission oppositeApplyStatus: \(oppositeApplyStatus)")
        switch oppositeApplyStatus {
        case .applying, .applied:
            //对方已经申请，前置toast拦截
            showToastOppositeAlreadyApply()
        case .unown, .agreed, .apply, .inelligible:
            processApplyCommunication(permission)
        }
    }

    func processApplyCommunication(_ permission: ProfileCommunicationPermission) {
        LarkProfileDataProvider.logger.info("process apply communication permission: \(permission)")
        switch permission {
        case .apply:
            //首次申请
            pushApplyCommunicationPermissionVC()
        case .applied:
            //再次申请需二次确认弹窗
            showAlertDuplicateApply()
        case .unown, .agreed, .applying, .inelligible:
            break
        }
    }
    /// 跳转的填写申请沟通理由的界面
    func pushApplyCommunicationPermissionVC() {
        guard let userInfo = userProfile?.userInfoProtocol, let fromVC = self.profileVC else {
            return
        }
        LarkProfileDataProvider.logger.info("push apply communication permission vc")
        let body = ApplyCommunicationPermissionBody(userId: userInfo.userID, type: .profile) { [weak self] (success) in
            guard let self = self else { return }
            if success {
                self.fetchUserProfileInformation()
            }
        }
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    // 对方已申请提示
    private func showToastOppositeAlreadyApply() {
        guard let window = self.profileVC?.view.window else {
            return
        }
        LarkProfileDataProvider.logger.info("show toast ppposite already apply")
        UDToast.showTips(with: BundleI18n.LarkProfile.Lark_IM_UserSentRequestAlreadyPleaseApprove_Toast, on: window)
    }

    // 重复申请弹窗
    private func showAlertDuplicateApply() {
        guard let from = self.profileVC else { return }
        LarkProfileDataProvider.logger.info("show alert duplicate apply")
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkProfile.Lark_IM_MessageRequest_AlreadySent_Title)
        alert.addCancelButton()
        alert.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_IM_MessageRequest_AlreadySent_Resend_Button, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.pushApplyCommunicationPermissionVC()
        })
        self.userResolver.navigator.present(alert, from: from)
    }
}
