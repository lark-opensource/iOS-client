//
//  MailTabBarController+MailClientOauth.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/11/14.
//

import Foundation
import EENavigator
import RxSwift
import LarkAlertController

//protocol MailTabMailClientOauth {
//    func updateOauthStatus(viewType: OAuthViewType)
//    func showOauthPlaceholderPage(viewType: OAuthViewType, accountInfos: [MailAccountInfo]?)
//    func hideOauthPlaceholderPage()
//}

//extension MailTabBarController: MailTabMailClientOauth {
//
//    // MARK: auth page
//    func showOauthPlaceholderPage(viewType: OAuthViewType, accountInfos: [MailAccountInfo]? = nil) {
//        MailLogger.info("show oauth placeholder page \(viewType)")
//        if let page = oauthPlaceholderPage {
//            hideContentController(page)
//        }
//        if viewType == .typeNoOAuthView {
//            hideOauthPlaceholderPage()
//            return
//        }
//        shouldShowOauthPage = true
//        oauthPageViewType = viewType
//
//        createOauthPageIfNeeded()
//        oauthPlaceholderPage?.view.frame = content.view.frame
//        oauthPlaceholderPage?.setupViewType(viewType: viewType)
//        oauthPlaceholderPage?.delegate = self
//
//        if let infos = accountInfos, infos.count > 1 {
//            let badge = Store.settingData.getOtherAccountUnreadBadge()
//            var address = infos.first { $0.isSelected }?.address ?? ""
//            if address.isEmpty {
//                address = BundleI18n.MailSDK.Mail_Mailbox_BusinessEmailDidntLink
//            }
//            self.oauthPlaceholderPage?.showMultiAccount(address: address, showBadge: badge)
//        } else {
//            self.oauthPlaceholderPage?.hideMultiAccount()
//        }
//
//        view.addSubview(oauthPlaceholderPage!.view)
//
//        if viewType == .typeNewUserOnboard {
//            checkIfShowNewUserPopupAlert()
//        }
//    }
//
//    func updateOauthStatus(viewType: OAuthViewType) {
//        asyncRunInMainThread {
//            if viewType == .typeLoading || viewType == .typeLoadingFailed {
//                self.showOauthPlaceholderPage(viewType: viewType)
//                MailLogger.info("mail tab update oauth loading \(viewType)")
//            } else {
//                self.getAccountListDisposed = DisposeBag()
//                /// 这里跟当前账号状态相关
//                Store.settingData.getAccountList()
//                .subscribe(onNext: { [weak self](resp) in
//                    guard let `self` = self else { return }
//                    if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType != .larkServer {
//                        var viewType: OAuthViewType = .typeNoOAuthView
//                        if let status = setting.emailClientConfigs.first?.configStatus {
//                            switch status {
//                            case .deleted:
//                                viewType = .typeOauthDeleted
//                            case .expired:
//                                viewType = .typeOauthExpired
//                            case .notApplicable:
//                                viewType = .typeNewUserOnboard
//                            default:
//                                self.hideOauthPlaceholderPage()
//                                return
//                            }
//                        } else if setting.userType == .newUser {
//                            viewType = .typeNewUserOnboard
//                        } else if setting.userType == .exchangeClientNewUser {
//                            viewType = .typeExchangeOnboard
//                        } else if (setting.userType == .gmailApiClient || setting.userType == .exchangeApiClient) {
//                            if setting.showApiOnboardingPage {
//                                viewType = .typeApiOnboard
//                            } else {
//                                MailLogger.info("api onboard mode, onboarding is false")
//                                self.hideOauthPlaceholderPage()
//                                return
//                            }
//                        } else if setting.userType == .noPrimaryAddressUser {
//                            viewType = .typeOauthDeleted
//                        }
//
//                        MailLogger.info("mail tab update oauth status: \(viewType)")
//                        let accountInfos = Store.settingData.getAccountInfos()
//                        self.showOauthPlaceholderPage(viewType: viewType, accountInfos: accountInfos)
//                    } else {
//                        MailLogger.info("mail tab update oauth hide")
//                        self.hideOauthPlaceholderPage()
//                    }
//                }).disposed(by: self.getAccountListDisposed)
//            }
//        }
//    }
//
//    func hideOauthPlaceholderPage() {
//        shouldShowOauthPage = false
//        oauthPageViewType = .typeNoOAuthView
//        guard let page = oauthPlaceholderPage else {
//            return
//        }
//        hideContentController(page)
//    }
//
//    // MARK: Internal Method
//    func createOauthPageIfNeeded() {
//        if oauthPlaceholderPage == nil {
//            oauthPlaceholderPage = MailClientImportViewController()
//            oauthPlaceholderPage?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        }
//    }
//
//    func checkIfShowNewUserPopupAlert() {
//        guard isViewLoaded else { return }
//        self.content.checkIfShowNewUserPopupAlert()
//    }
//}

//extension MailTabBarController: MailClientImportViewControllerDelegate {
//    func didClickMultiAccount() {
//        self.content.didClickMultiAccount()
//    }
//}
