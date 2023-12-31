//
//  PassportEnterpriseLoginSchemeService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/10/3.
//

import Foundation
import LarkLocalizations
import LarkAlertController
import RunloopTools
import LarkUIKit
import LKCommonsLogging
import RxRelay
import RxSwift
import Homeric
import LarkContainer
import EENavigator

class PassportEnterpriseLoginSchemeService {
    static let logger = Logger.plog(PassportEnterpriseLoginSchemeService.self, category: "SuiteLogin.PassportEnterpriseLoginSchemeService")

    private var loginVCAvailableSub: BehaviorRelay<Bool> { loginService.loginVCAvailableSub }

    private lazy var store = PassportStore.shared

    private var task: (() -> Void)?

    @Provider private var idpService: IDPServiceProtocol

    @Provider private var loginService: V3LoginService

    private var isLoggedIn: Bool { store.isLoggedIn }

    let disposeBag = DisposeBag()

    init() {}

    func handleSSOLogin(
        _ ssoDomain: String,
        tenantName: String,
        refreshUserListBlock: @escaping () -> Observable<Void>,
        switchUserBlock: @escaping (String, @escaping (Bool) -> Void) -> Void,
        context: UniContextProtocol
    ) {
        Self.logger.info("loginVCAvailableSub task added")
        self.task = { [weak self] in
            guard let self = self else { return }
            self.showLoading()
            self.internalHandleSSODomain(
                ssoDomain,
                tenantName: tenantName,
                refreshUserListBlock: refreshUserListBlock,
                switchUserBlock: switchUserBlock,
                context: context
            )
        }

        // 已登录
        RunloopDispatcher.shared.addTask {
            if self.isLoggedIn {
                Self.logger.info("RunloopDispatcher called when logined")
                self.excuteTask()
            }
        }.waitCPUFree()

        // 未登录
        self.loginVCAvailableSub
            .subscribe(onNext: { [weak self] inputCredentialVCAvailable in
                Self.logger.info("loginVCAvailableSub called: \(inputCredentialVCAvailable)")
                guard let self = self else { return }
                if inputCredentialVCAvailable {
                    self.excuteTask()
                }
            }).disposed(by: disposeBag)
    }

    private func excuteTask() {
        SuiteLoginUtil.runOnMain {
            Self.logger.info("loginVCAvailableSub task excuted")
            self.task?()
            self.task = nil
        }
    }

    private func internalHandleSSODomain(
        _ ssoDomain: String,
        tenantName: String,
        refreshUserListBlock: @escaping () -> Observable<Void>,
        switchUserBlock: @escaping (String, @escaping (Bool) -> Void) -> Void,
        firstAttempt: Bool = true,
        context: UniContextProtocol
    ) {
        Self.logger.info("internalHandleSSODomain called")
        if !isLoggedIn {
            Self.logger.info("internalHandleSSODomain not logged in, go to SSO login page")
            
            self.stopLoading()
            self.goToSSOLoginPage(ssoDomain, context: context)
            return
        }
        
        if let targetUserId = self.userIdForSSODomain(ssoDomain) {
            self.stopLoading()
            if targetUserId == self.store.foregroundUserID { // user:current
                Self.logger.info("internalHandleSSODomain skipped")
                return
            } else {
                Self.logger.info("internalHandleSSODomain switch to logged in user")
                self.alertSwitch(targetUserId, tenantName: tenantName, switchUserBlock: switchUserBlock)
            }
            
            return
        }
        
        if firstAttempt {
            Self.logger.info("internalHandleSSODomain update user list")
            
            // 当前账号没有domain对应租户，拉取userList重试
            refreshUserListBlock()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    Self.logger.info("succeed to refresh user list")
                }, onError: { error in
                    Self.logger.error("fail to refresh user list: \(error)")
                }, onCompleted: {
                    self.internalHandleSSODomain(
                        ssoDomain,
                        tenantName: tenantName,
                        refreshUserListBlock: refreshUserListBlock,
                        switchUserBlock: switchUserBlock,
                        firstAttempt: false,
                        context: context
                    )
                }).disposed(by: self.disposeBag)
        } else {
            Self.logger.info("internalHandleSSODomain go to SSO login page after attempt")
            
            self.stopLoading()
            // 重试之后当前账号没有domain对应租户，跳转到 SSO 登录页
            self.goToSSOLoginPage(ssoDomain, context: context)
        }
    }

    private func userIdForSSODomain(_ ssoDomain: String) -> String? {
        let user = self.store.getUserList()
            .sorted(by: { $0.latestActiveTime > $1.latestActiveTime })
            .first { userInfo in
                userInfo.user.tenant.fullDomain == ssoDomain
            }
        return user?.userID
    }

    private func alertSwitch(
        _ targetUserId: String,
        tenantName: String,
        switchUserBlock: @escaping (String, @escaping (Bool) -> Void) -> Void
    ) {
        let content = I18N.Lark_Login_SSOAppLinkConfirmPopUp2(tenantName)
        self.showAlert(title: I18N.Lark_Login_SSOAppLinkConfirmPopUpTitle, content: content, confirmBlock: {
            SuiteLoginTracker.track(Homeric.APPLINK_SSO_SWITCHTEAM, params: [
                "action_name": "confirm"
            ])
            switchUserBlock(targetUserId, { result in
                if result {
                    SuiteLoginTracker.track(Homeric.APPLINK_SSO_SWITCHTEAM_SUCC)
                }
            })
        }) {
            SuiteLoginTracker.track(Homeric.APPLINK_SSO_SWITCHTEAM, params: [
                "action_name": "cancel"
            ])
        }
    }

    private func showAlert(
        title: String,
        content: String,
        confirmBtnTitle: String = I18N.Lark_Login_V3_PolicyAlertAgree,
        cancelBtnTitle: String = I18N.Lark_Login_V3_PolicyAlertCancel,
        confirmBlock: (() -> Void)? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        SuiteLoginUtil.runOnMain {
            let controller = LarkAlertController()
            controller.setTitle(text: title)
            controller.setContent(text: content)
            controller.addSecondaryButton(
                text: cancelBtnTitle,
                dismissCompletion: {
                    cancelBlock?()
                })
            controller.addPrimaryButton(
                text: confirmBtnTitle,
                dismissCompletion: {
                    confirmBlock?()
                })
            PassportNavigator.topMostVC?.present(controller, animated: true, completion: nil)
        }
    }

    private func goToSSOLoginPage(
        _ ssoDomain: String,
        context: UniContextProtocol
    ) {
        SuiteLoginTracker.track(Homeric.APPLINK_SSO_LOGIN)
        // 取消一键登录、匿名会议等presented页面
        self.dismissAllVC {
            let body = SSOUrlReqBody(idpName: ssoDomain, context: context)
            self.idpService
                .fetchConfigForIDP(body)
                .post(false, context: context)
                .subscribe(onNext: {
                    Self.logger.info("succeed to open sso login page")
                    SuiteLoginTracker.track(Homeric.APPLINK_SSO_LOGIN_SUCC)
                }, onError: { (err) in
                    Self.logger.info("fail to open sso login page: \(err)")
                }).disposed(by: self.disposeBag)
        }
    }

    private func dismissAllVC(completion: @escaping (() -> Void)) {
        if let vc = PassportNavigator.topMostVC {
            if vc.isModal {
                vc.dismiss(animated: true) {
                    completion()
                }
            } else {
                completion()
            }
        } else {
            Self.logger.info("should not happen")
            completion()
        }
    }

    func showLoading() {
        var currentTopView: UIView? = PassportNavigator.keyWindow
        if let topMost = PassportNavigator.topMostVC {
            currentTopView = topMost.view
            if let navi = topMost.nearestNavigation {
                currentTopView = navi.view
            }
        }
        guard let topView = currentTopView else {
            Self.logger.errorWithAssertion("no main scene for showLoading")
            return
        }
        PassportLoadingService.shared.showLoading(on: topView)
    }

    func stopLoading() {
        PassportLoadingService.shared.stopLoading()
    }
}
