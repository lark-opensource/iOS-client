//
//  ContactRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/8/30.
//

import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import LarkContainer
import EENavigator
import Swinject
import UniverseDesignToast
import Contacts
import LarkAlertController
import LarkNavigator
import LarkSDKInterface
import LarkLocalizations
import LarkAppConfig
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigation
import LarkAccountInterface
import LarkFeatureGating
import LKMetric
import AnimatedTabBar
import LarkAddressBookSelector
import LarkQRCode
import LarkTab
import RustPB
import UIKit
import LarkPrivacySetting
import LarkSensitivityControl

final class ContactRouter: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let passportUserService: PassportUserService
    let passportService: PassportService
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var myAIService: MyAIService?

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.passportService = try resolver.resolve(assert: PassportService.self)
    }

    private func _pushPersonalCardVC(_ vc: UIViewController, chatterId: String, source: Basic_V1_ContactSource?) {
        var body: PersonCardBody
        if let source = source {
            body = PersonCardBody(chatterId: chatterId, source: source)
        } else {
            body = PersonCardBody(chatterId: chatterId)
        }
        navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: vc,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
    }

    private func chat(with chatter: Chatter, _ vc: UIViewController, chatId: String? = nil) {
        chat(with: chatter.id, type: chatter.type, vc, chatId: chatId)
    }

    private func chat(with chatterID: String, type: Chatter.TypeEnum, _ vc: UIViewController, chatId: String? = nil) {
        switch type {
        case .user:
            // 发送request
            let body = PersonCardBody(chatterId: chatterID)
            navigator.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: vc,
                                           prepareForPresent: { (vc) in
              vc.modalPresentationStyle = .formSheet
            })
        case .bot:
            let feedId = chatId ?? ""
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: feedId, selectionType: .skipSame)
            ]
            let body = ChatControllerByChatterIdBody(
                chatterId: chatterID,
                fromWhere: .profile,
                isCrypto: false
            )
            navigator.showAfterSwitchIfNeeded(
                tab: Tab.feed.url,
                body: body,
                context: context,
                wrap: LkNavigationController.self,
                from: vc
            ) { [weak vc] (err) in
                guard let window = vc?.view.window else {
                    assertionFailure("缺少Window")
                    return
                }
                if err != nil {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ProfileDetailCreateSingleChatFailed, on: window)
                    ContactTopStructureHandler.logger.error("创建单聊失败", additionalData: ["botId": chatterID], error: err)
                }
            }
        case .ai:
            guard let aiService = myAIService else { return }
            if !aiService.canOpenOthersAIProfile, chatterID != aiService.info.value.id { return }
            aiService.openMyAIProfile(from: vc)
        case .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }
}

extension ContactRouter: ContactApplicationViewControllerRouter {
    func pushPersonalCardVC(_ vc: ContactApplicationViewController, chatterId: String) {
        _pushPersonalCardVC(vc, chatterId: chatterId, source: .newContact)
    }

    func pushAddFriendFromContact(_ vc: ContactApplicationViewController,
                                  _ inviteInfo: InviteAggregationInfo,
                                  _ source: ExternalInviteSourceEntrance) {
        AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: true, source: .addExternal)
        let r = self.userResolver
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        guard let chatApplicationAPI = try? r.resolve(assert: ChatApplicationAPI.self) else { return }
        guard let router = try? r.resolve(assert: ExternalContactImportRouter.self) else { return }
        let linkInviteData = inviteInfo.externalExtraInfo?.linkInviteData
        let importPresenter = ContactImportPresenter(isOversea: isOversea,
                                                     applicationAPI: chatApplicationAPI,
                                                     router: router,
                                                     inviteMsg: linkInviteData?.inviteMsg ?? "",
                                                     uniqueId: linkInviteData?.uniqueID ?? "",
                                                     source: source,
                                                     resolver: userResolver)
        let block = { [weak self] in
            guard let `self` = self, let userPushCenter = try? self.userResolver.userPushCenter else { return }
            Tracer.trackAddressbookEnter()
            let dest = AddrBookContactListController(addContactScene: .newContact,
                                                     resolver: self.userResolver,
                                                     importPresenter: importPresenter,
                                                     pushCenter: userPushCenter)
            AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()
            self.navigator.push(dest, from: vc)
        }
        requestSystemContactAuthorization(token: "LARK-PSDA-push_add_friend_from_contact", rootVc: vc, userOperationHandler: { (granted) in
            if granted { block() }
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(vc)
        }
    }

    func pushExternalInviteFromContactApplicationPage(_ vc: ContactApplicationViewController) {
        let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .contactNew)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }
}

extension ContactRouter: NewExternalContactsViewControllerRouter {
    func pushPersonalCardVC(_ vc: NewExternalContactsViewController, chatterId: String) {
        _pushPersonalCardVC(vc, chatterId: chatterId, source: .externalContact)
    }

    func pushExternalInvitePage(_ vc: NewExternalContactsViewController) {
        let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .contactExternal)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }
}

extension ContactRouter: GroupedExternalContactsViewControllerRouter {
    func pushPersonalCardVC(_ vc: GroupedExternalContactsViewController, chatterId: String) {
        _pushPersonalCardVC(vc, chatterId: chatterId, source: .externalContact)
    }

    func pushExternalInvitePage(_ vc: GroupedExternalContactsViewController) {
        let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .contactExternal)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }
}

extension ContactRouter: ContactAddListRouter {
    func presentContactAddressBookList(_ vc: ContactAddListController,
                                       inviteInfo: InviteAggregationInfo,
                                       showSkipButton: Bool,
                                       source: ExternalInviteSourceEntrance,
                                       skipCallback: ContactSkipCallback?) {
        AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: true, source: .addMember)
        let r = self.userResolver
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        guard let chatApplicationAPI = try? r.resolve(assert: ChatApplicationAPI.self) else { return }
        guard let router = try? r.resolve(assert: ExternalContactImportRouter.self) else { return }
        guard let userPushCenter = try? self.userResolver.userPushCenter else { return }
        let linkInviteData = inviteInfo.externalExtraInfo?.linkInviteData
        let importPresenter = ContactImportPresenter(isOversea: isOversea,
                                                     applicationAPI: chatApplicationAPI,
                                                     router: router,
                                                     inviteMsg: linkInviteData?.inviteMsg ?? "",
                                                     uniqueId: linkInviteData?.uniqueID ?? "",
                                                     source: source,
                                                     resolver: userResolver)
        let dest = AddrBookContactListController(addContactScene: .onBoarding,
                                                 resolver: r,
                                                 importPresenter: importPresenter,
                                               pushCenter: userPushCenter,
                                               showSkipButton: showSkipButton,
                                               skipCallback: skipCallback)
        AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()
        navigator.present(dest,
                                 wrap: LkNavigationController.self,
                                 from: vc,
                                 prepare: { $0.modalPresentationStyle = .fullScreen })
    }

    func pushAddContactRelation(addContactRelationBody: AddContactRelationBody, vc: ContactAddListController) {
        navigator.push(body: addContactRelationBody, from: vc)
    }
}

extension ContactRouter: AddContactViewControllerRouter {
    func pushScanQRCodeViewController(vc: AddContactViewController) {
        navigator.presentOrPush(
            body: QRCodeControllerBody(),
            from: vc,
            prepareForPresent: { (viewController) in
                viewController.modalPresentationStyle = .fullScreen
            })
    }

    func pushInviteContactsViewController(vc: AddContactViewController, didClickInviteOtherWith content: String) {
        let body = InvitationBody(content: content)
        navigator.push(body: body, from: vc)
    }

    func pushMyQRCodeViewController(vc: AddContactViewController) {
        let body = ExternalContactsInvitationControllerBody(scenes: .myQRCode, fromEntrance: .contact)
        navigator.push(body: body, from: vc)
    }

    func pushPersonalCardVC(_ vc: AddContactViewController, userProfile: UserProfile) {
        let body = ProfileCardBody(userProfile: userProfile, fromWhere: .search)
        navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: vc,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
    }
}

extension ContactRouter: OnCallViewControllerRouter {
    func onCallViewController(_ vc: OnCallViewController, chatModel: Chat) {
        let body = ChatControllerByChatBody(
            chat: chatModel,
            fromWhere: .profile
        )
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: chatModel.id, selectionType: .skipSame)
        ]
        navigator.showAfterSwitchIfNeeded(
            tab: Tab.feed.url,
            body: body,
            context: context,
            wrap: LkNavigationController.self,
            from: vc)
    }
}

extension ContactRouter: RobotViewControllerRouter {
    func robotViewController(_ vc: RobotViewController, chatter: Chatter, chatId: String?) {
        self.chat(with: chatter, vc, chatId: chatId)
    }
}

extension ContactRouter: GroupsViewControllerRouter {
    func didSelectBotWithGroup(_ vc: GroupsViewController, chat: Chat, fromWhere: ChatFromWhere = .profile) {
        let body = ChatControllerByChatBody(
            chat: chat,
            fromWhere: fromWhere
        )
        // iPad 先 dismiss 掉模态框再 push
        if Display.pad, vc.presentingViewController != nil {
            let from = WindowTopMostFrom(vc: vc)
            vc.dismiss(animated: true) { [weak self] in
                guard let `self` = self else { return }
                self.navigator.showDetail(body: body, wrap: LkNavigationController.self, from: from)
            }
        } else {
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            navigator.showAfterSwitchIfNeeded(
                tab: Tab.feed.url,
                body: body,
                context: context,
                wrap: LkNavigationController.self,
                from: vc)
        }
    }
}

extension ContactRouter: ContactSearchViewControllerRouter {
    func didSelectWithChat(_ vc: ContactSearchViewController, chatId: String) {
        let body = ChatControllerByIdBody(chatId: chatId)
        navigator.push(body: body, from: vc)
    }

    func didSelectWithChatter(_ vc: ContactSearchViewController, chatterId: String, type: Chatter.TypeEnum) {
        chat(with: chatterId, type: type, vc)
    }
}

extension ContactRouter: DepartmentViewControllerRouter {
    func didSelectWithChatter(_ vc: DepartmentViewController, chatter: Chatter) {
        self.chat(with: chatter, vc)
    }

    func pushDepartmentViewController(_ vc: DepartmentViewController, department: Department, departmentPath: [Department], departmentsAdministratorStatus: DepartmentsAdministratorStatus) {
        let body = DepartmentBody(department: department,
                                  departmentPath: departmentPath,
                                  showNameStyle: .nameAndAlias,
                                  showContactsTeamGroup: vc.showContactsTeamGroup,
                                  departmentsAdministratorStatus: departmentsAdministratorStatus)
        var params = NaviParams()
        params.forcePush = true
        params.openType = .push
        navigator.push(body: body, naviParams: params, from: vc)
    }

    func pushMemberInvitePage(_ vc: DepartmentViewController) {
        guard let service = try? userResolver.resolve(assert: UnifiedInvitationService.self) else { return }
        _ = service.dynamicMemberInvitePageResource(baseView: vc.view,
                                                    sourceScenes: .department,
                                                    departments: [])
            .subscribe(onNext: { [weak self] (resource) in
                guard let `self` = self else { return }
                switch resource {
                case .memberFeishuSplit(let body):
                    if Display.pad {
                        self.navigator.present(
                            body: body,
                            wrap: LkNavigationController.self,
                            from: vc,
                            prepare: { $0.modalPresentationStyle = .formSheet }
                        )
                    } else {
                        self.navigator.push(body: body, from: vc)
                    }
                case .memberLarkSplit(let body):
                    if Display.pad {
                        self.navigator.present(
                            body: body,
                            wrap: LkNavigationController.self,
                            from: vc,
                            prepare: { $0.modalPresentationStyle = .formSheet }
                        )
                    } else {
                        self.navigator.push(body: body, from: vc)
                    }
                case .memberDirected(let body):
                    if Display.pad {
                        self.navigator.present(
                            body: body,
                            wrap: LkNavigationController.self,
                            from: vc,
                            prepare: { $0.modalPresentationStyle = .formSheet }
                        )
                    } else {
                        self.navigator.push(body: body, from: vc)
                    }
                }
            })
    }
}

extension ContactRouter: CollaborationDepartmentViewControllerRouter {
    func didSelectWithChatter(_ vc: CollaborationDepartmentViewController, chatter: Chatter) {
        self.chat(with: chatter, vc)
    }

    func pushCollaborationDepartmentViewController(_ vc: CollaborationDepartmentViewController,
                                                   tenantId: String?,
                                                   department: Department,
                                                   departmentPath: [Department],
                                                   associationContactType: AssociationContactType?) {
        let body = CollaborationDepartmentBody(
                                  tenantId: tenantId,
                                  department: department,
                                  departmentPath: departmentPath,
                                  showNameStyle: .nameAndAlias,
                                  showContactsTeamGroup: vc.showContactsTeamGroup,
                                  associationContactType: associationContactType)
        var params = NaviParams()
        params.forcePush = true
        params.openType = .push
        navigator.push(body: body, naviParams: params, from: vc)
    }

    func pushCollaborationTenantInviteSelectPage(_ vc: CollaborationDepartmentViewController, contactType: AssociationContactType) {
        let body = AssociationInviteBody(source: .contact, contactType: contactType)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }

    func pushCollaborationTenantInviteQRPage(contactType: AssociationContactType, _ vc: AssociationInviteSelectViewController) {
        let body = AssociationInviteQRPageBody(source: .contact, contactType: contactType)
        navigator.push(body: body, from: vc)
    }

    func pushAssociationInviteHelpURL(url: URL, from vc: NavigatorFrom) {
        navigator.push(url, from: vc)
    }

}

extension ContactRouter: CollaborationSearchViewControllerRouter {
    func collaborationSearchViewController(_ vc: CollaborationSearchViewController, didSelect chatter: LarkModel.Chatter) {
        chat(with: chatter, vc)
    }
}

extension ContactRouter: MemberInviteRouter {
    var invalidCountryCodeErrorMessage: String {
        if passportService.isFeishuBrand {
            return BundleI18n.LarkContact.Lark_Contacts_ImportMember_SelectNot86BlockTip
        } else {
            return BundleI18n.LarkContact.Lark_Contacts_ImportMember_SelectUnsupportedNumberBlockTip
        }
    }
    // nolint: duplicated_code 跳转代码有差异
    func pushToContactsImportViewController(controller: BaseUIViewController,
                                            source: MemberInviteSourceScenes,
                                            presenter: ContactBatchInvitePresenter,
                                            contactType: ContactContentType? = nil,
                                            contactImportHandler: @escaping (AddressBookContact) -> Void) {
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        let block = { [weak self] in
            guard let `self` = self else { return }
            UDToast.showLoading(on: controller.view)
            self.passportService.getPhoneNumberRegionList { [weak self] allowRegionList, blockRegionList, _ in
                UDToast.removeToast(on: controller.view)

                AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: false, source: .addMember)
                let validCountryCodeProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                                                  topCountryList: [],
                                                                  allowCountryList: allowRegionList ?? [],
                                                                  blockCountryList: blockRegionList ?? [])
                let dest = SelectContactListController(
                    contactContentType: contactType ?? (isOversea ? .email : .phone),
                    contactTableSelectType: .multiple,
                    naviBarTitle: BundleI18n.LarkContact.Lark_Invitation_MembersBatchEntry,
                    contactNumberLimit: 50,
                    validCountryCodeProvider: validCountryCodeProvider,
                    invalidCountryCodeErrorMessage: self?.invalidCountryCodeErrorMessage)
                dest.rightItemTitle = BundleI18n.LarkContact.Lark_Invitation_MembersBatchContactsSendButton
                dest.delegate = presenter
                self?.navigator.push(dest, from: controller)
            }
        }
        requestSystemContactAuthorization(token: "LARK-PSDA-push_to_contacts_import", rootVc: controller, userOperationHandler: { (granted) in
            if granted { block() }
            Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                  access: granted ? "approve" : "deny")
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(controller, cancelCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "deny")
            }, goSettingCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "goto setting")
            })
        }
    }
    // enable-lint: duplicated_code

    func presentCountryCodeViewController(_ controller: BaseUIViewController,
                                          selectCompletionHandler: @escaping (String) -> Void) {
        self.showCountryCodeSelectController(vc: controller, selectCompletionHandler: selectCompletionHandler)
    }

    func pushToGroupNameSettingController(_ controller: BaseUIViewController,
                                          nextHandler: @escaping (Bool) -> Void) {
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else { return }
        dependency.jumpToGroupNameSettingPage(baseVc: controller, nextHandler: nextHandler)
    }

    func pushToNonDirectionalInviteController(_ controller: BaseUIViewController,
                                              sourceScenes: MemberInviteSourceScenes,
                                              departments: [String],
                                              priority: MemberNoDirectionalDisplayPriority) {
        let body = MemberNoDirectionalBody(displayPriority: priority,
                                           sourceScenes: sourceScenes,
                                           departments: departments)
        navigator.push(body: body, from: controller)
    }

    func pushToTeamCodeInviteController(_ controller: BaseUIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String]) {
        let body = TeamCodeInviteBody(sourceScenes: sourceScenes, departments: departments)
        navigator.push(body: body, from: controller)
    }
}

extension ContactRouter: MemberInviteSplitPageRouter {
    func pushToDirectedInviteController(baseVc: UIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String],
                                        rightButtonClickHandler: (() -> Void)?) {
        var body = MemberDirectedInviteBody(sourceScenes: sourceScenes,
                                            isFromInviteSplitPage: true,
                                            departments: departments)
        body.rightButtonClickHandler = rightButtonClickHandler
        navigator.push(body: body, from: baseVc)
    }

    func pushToNonDirectedInviteController(baseVc: UIViewController,
                                           priority: MemberNoDirectionalDisplayPriority,
                                           sourceScenes: MemberInviteSourceScenes,
                                           departments: [String]) {
        let body = MemberNoDirectionalBody(displayPriority: priority,
                                           sourceScenes: sourceScenes,
                                           departments: departments)
        navigator.push(body: body, from: baseVc)
    }

    func pushToGroupNameSettingController(baseVc: UIViewController,
                                          nextHandler: @escaping (Bool) -> Void) {
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else { return }
        dependency.jumpToGroupNameSettingPage(baseVc: baseVc, nextHandler: nextHandler)
    }

    func pushToTeamCodeInviteController(baseVc: UIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String]) {
        let body = TeamCodeInviteBody(sourceScenes: sourceScenes, departments: departments)
        navigator.push(body: body, from: baseVc)
    }
    // nolint: duplicated_code 跳转代码有差异
    func pushToAddressBookImportController(baseVc: UIViewController,
                                           sourceScenes: MemberInviteSourceScenes,
                                           presenter: ContactBatchInvitePresenter) {
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        let block = { [weak self] in
            guard let `self` = self else { return }
            UDToast.showLoading(on: baseVc.view)
            self.passportService.getPhoneNumberRegionList { [weak self] allowRegionList, blockRegionList, _ in
                UDToast.removeToast(on: baseVc.view)

                AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: false, source: .addMember)

                let validCountryCodeProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                                                  topCountryList: [],
                                                                  allowCountryList: allowRegionList ?? [],
                                                                  blockCountryList: blockRegionList ?? [])

                let dest = SelectContactListController(
                    contactContentType: isOversea ? .email : .phone,
                    contactTableSelectType: .multiple,
                    naviBarTitle: BundleI18n.LarkContact.Lark_Invitation_MembersBatchEntry,
                    contactNumberLimit: 50,
                    validCountryCodeProvider: validCountryCodeProvider,
                    invalidCountryCodeErrorMessage: self?.invalidCountryCodeErrorMessage)
                AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()
                dest.rightItemTitle = BundleI18n.LarkContact.Lark_Invitation_MembersBatchContactsSendButton
                dest.delegate = presenter
                self?.navigator.push(dest, from: baseVc)
            }
        }
        requestSystemContactAuthorization(token: "LARK-PSDA-push_to_address_book_import", rootVc: baseVc, userOperationHandler: { (granted) in
            if granted { block() }
            Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                  access: granted ? "approve" : "deny")
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(baseVc, cancelCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "deny")
            }, goSettingCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "goto setting")
            })
        }
    }
    // enable-lint: duplicated_code

    func pushToHelpCenterInternal(baseVc: UIViewController) {
        guard let userGeneralSettings = self.userGeneralSettings else { return }
        let helpCenterHost = userGeneralSettings.helpDeskBizDomainConfig.helpCenterHost
        let host = helpCenterHost.isEmpty ? "www.feishu.cn" : helpCenterHost
        let lang = LanguageManager.currentLanguage.languageIdentifier
        if let url = URL(string: "https://\(host)/hc/\(lang)/articles/360049067837") {
            navigator.push(url, from: baseVc)
        }
    }
}

extension ContactRouter: MemberInviteNoDirectionalControllerRouter {
    /// 外部邀请帮助中心
    func pushMemberInvitationHelpCenterViewController(vc: BaseUIViewController) {
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else { return }
        let urlString = dependency.unifiedInvitationHelpCenterURL()
        if let url = URL(string: urlString ?? "") {
            navigator.push(url, from: vc)
        }
    }
}

extension ContactRouter: TeamCodeInviteControllerRouter {
    /// 成员邀请团队码帮助中心
    func pushMemberInvitationTeamCodeHelpViewController(vc: BaseUIViewController) {
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else { return }
        let urlString = dependency.teamCodeUsageHelpCenterURL()
        if let url = URL(string: urlString ?? "") {
            navigator.push(url, from: vc)
        }
    }
}

extension ContactRouter: UnifiedPartnerInvitationRouter {
    /// 邀请团队成员
    func pushTeamMembersInvitationViewController(vc: BaseUIViewController) {
        guard let service = try? userResolver.resolve(assert: UnifiedInvitationService.self) else { return }
        _ = service.dynamicMemberInvitePageResource(baseView: vc.view,
                                                    sourceScenes: .invitePeopleUnion,
                                                    departments: [])
            .subscribe(onNext: { [weak self] (resource) in
                guard let `self` = self else { return }
                switch resource {
                case .memberFeishuSplit(let body):
                    self.navigator.push(body: body, from: vc)
                case .memberLarkSplit(let body):
                    self.navigator.push(body: body, from: vc)
                case .memberDirected(let body):
                    self.navigator.push(body: body, from: vc)
                }
            })
    }

    /// 邀请外部联系人
    func pushExternalContactsInvitationViewController(vc: BaseUIViewController) {
        let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .contact)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }

    /// 入口跳转帮助中心的url
    func pushInvitationHelpCenterViewController(vc: BaseUIViewController) {
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else { return }
        let urlString = dependency.unifiedInvitationHelpCenterURL()
        if let url = URL(string: urlString ?? "") {
            navigator.push(url, from: vc)
        }
    }
}

extension ContactRouter: ExternalContactsInvitationRouter {

    fileprivate func pushSelectContactListVC(
        from: BaseUIViewController,
        presenter: ContactImportPresenter,
        fromEntrance: ExternalInviteSourceEntrance
    ) {
        guard let passportService = try? userResolver.resolve(assert: PassportService.self) else { return }
        let dataSourceType: ContactContentType = (passportService.isOversea) ? .email : .phone
        AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: false, source: .addExternal)
        AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()
        Tracer.trackInvitePeopleExternalImport(
            access: "approve",
            source: fromEntrance.rawValue
        )
        let addressBookDest = SelectContactListController(
            contactContentType: dataSourceType,
            contactTableSelectType: .single,
            naviBarTitle: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsTitle
        )
        addressBookDest.delegate = presenter
        navigator.push(addressBookDest, from: from)
    }

    fileprivate func pushAddrBookContactListVC(
        from: BaseUIViewController,
        presenter: ContactImportPresenter,
        fromEntrance: ExternalInviteSourceEntrance
    ) {
        guard let userPushCenter = try? self.userResolver.userPushCenter else { return }
        AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: true, source: .addExternal)
        AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()
        Tracer.trackInvitePeopleExternalImport(
            access: "approve",
            source: fromEntrance.rawValue
        )
        let dest = AddrBookContactListController(addContactScene: .importFromContact,
                                                 resolver: userResolver,
                                                 importPresenter: presenter,
                                                 pushCenter: userPushCenter)
        navigator.push(dest, from: from)
    }

    // 通过联系人邀请
    func pushAddFromContactsViewController(vc: BaseUIViewController,
                                           presenter: ContactImportPresenter,
                                           fromEntrance: ExternalInviteSourceEntrance) {
        let block = {
            let enableContactOpt = self.userResolver.fg.staticFeatureGatingValue(with: "lark.client.contact.opt")

            if enableContactOpt {
                self.pushAddrBookContactListVC(
                    from: vc,
                    presenter: presenter,
                    fromEntrance: fromEntrance
                )
            } else {
                self.pushSelectContactListVC(
                    from: vc,
                    presenter: presenter,
                    fromEntrance: fromEntrance
                )
            }
        }

        requestSystemContactAuthorization(token: "LARK-PSDA-push_add_from_contacts", rootVc: vc, userOperationHandler: { (granted) in
            if granted {
                block()
            } else {
                Tracer.trackInvitePeopleExternalImport(
                    access: "deny",
                    source: fromEntrance.rawValue
                )
            }
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(vc, cancelCompletion: {
                Tracer.trackInvitePeopleExternalImport(
                    access: "deny",
                    source: fromEntrance.rawValue
                )
            }, goSettingCompletion: {
                Tracer.trackInvitePeopleExternalImport(
                    access: "goto setting",
                    source: fromEntrance.rawValue
                )
            })
        }
    }

    // 通过手机/邮箱邀请外部联系人
    func pushExternalContactsSearchViewController(vc: BaseUIViewController,
                                                  inviteMsg: String,
                                                  uniqueId: String,
                                                  fromEntrance: ExternalInviteSourceEntrance) {
        let body = ContactsSearchBody(inviteMsg: inviteMsg, uniqueId: uniqueId, fromEntrance: fromEntrance)
        navigator.push(body: body, from: vc)
    }

    // 外部邀请帮助中心
    func pushHelpCenterForExternalInvite(vc: BaseUIViewController) {
        guard let userGeneralSettings = self.userGeneralSettings else { return }
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        let helpCenterHost = userGeneralSettings.helpDeskBizDomainConfig.helpCenterHost
        let host = helpCenterHost.isEmpty ? "www.feishu.cn" : helpCenterHost
        let lang = LanguageManager.currentLanguage.languageIdentifier
        let urlString = isOversea ?
                    "https://\(host)/hc/\(lang)/articles/360043763493" :
                    "https://\(host)/hc/\(lang)/articles/360043505973"
        if let url = URL(string: urlString) {
            navigator.push(url, from: vc)
        }
    }

    // 隐私设置
    func pushPrivacySettingViewController(vc: BaseUIViewController, from: ExternalContactsInvitationScenes) {
        let body = PrivacySettingBody()
        var scenes = ""
        switch from {
        case .myQRCode:
            scenes = "share_to_external_contacts"
        case .externalInvite:
            scenes = "invite_external_contacts"
        }
        Tracer.trackEnterPrivacySetting(from: scenes)
        navigator.push(body: body, from: vc)
    }

    // 扫码
    func pushQRCodeControllerr(vc: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance) {
        navigator.presentOrPush(
            body: QRCodeControllerBody(),
            from: vc,
            prepareForPresent: { (viewController) in
                viewController.modalPresentationStyle = .fullScreen
            })
    }
}

extension ContactRouter: ExternalContactSplitRouter {
    // 引导页
    func presentGuidePage(
        from: BaseUIViewController,
        fromEntrance: ExternalInviteSourceEntrance,
        completion: @escaping () -> Void
    ) {
        let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        let body = ExternalInviteGuideBody(fromEntrance: fromEntrance) {
            if from.hasBackPage {
                from.popSelf(animated: false, dismissPresented: true, completion: nil)
            } else {
                from.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { (vc) in
                vc.modalPresentationStyle = style
            },
            animated: false) { _, _ in
            completion()
        }
    }

    // 我的二维码
    func pushMyQRCodeController(from: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance) {
        let body = ExternalContactsInvitationControllerBody(scenes: .myQRCode, fromEntrance: fromEntrance)
        navigator.push(body: body, from: from)
    }

    // 面对面建群
    func pushFaceToFaceCreateGroupController(vc: BaseUIViewController) {
        if LarkLocationAuthority.checkAuthority() {
            let body = CreateGroupWithFaceToFaceBody(type: .externalContact)
            navigator.push(body: body, from: vc)
        } else {
            LarkLocationAuthority.showDisableTip(on: vc.view)
        }
    }
}

extension ContactRouter: MemberInviteGuideRouter {
    // nolint: duplicated_code 跳转代码有差异
    func presentSelectContactListVC(from: BaseUIViewController, presenter: ContactBatchInvitePresenter) {
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        let isOversea = passportService.isOversea
        let dataSourceType: ContactContentType = isOversea ? .email : .phone
        let block = { [weak self] in
            guard let `self` = self else { return }
            UDToast.showLoading(on: from.view)
            self.passportService.getPhoneNumberRegionList { [weak self] allowRegionList, blockRegionList, _ in
                UDToast.removeToast(on: from.view)

                AddressBookAppReciableTrack.addressBookPageLoadTimeStart(isNewPage: false, source: .addMember)
                AddressBookAppReciableTrack.addressBookPageInitViewCostTrack()

                let validCountryCodeProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                                                  topCountryList: [],
                                                                  allowCountryList: allowRegionList ?? [],
                                                                  blockCountryList: blockRegionList ?? [])
                let dest = SelectContactListController(
                    contactContentType: dataSourceType,
                    contactTableSelectType: .multiple,
                    naviBarTitle: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsTitle,
                    contactNumberLimit: 50,
                    validCountryCodeProvider: validCountryCodeProvider,
                    invalidCountryCodeErrorMessage: self?.invalidCountryCodeErrorMessage
                )
                dest.rightItemTitle = BundleI18n.LarkContact.Lark_Invitation_MembersBatchContactsSendButton
                dest.delegate = presenter

                self?.navigator.present(dest,
                                         wrap: LkNavigationController.self,
                                         from: from,
                                         prepare: {
                    $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                })
            }
        }
        requestSystemContactAuthorization(token: "LARK-PSDA-present_select_contact", rootVc: from, userOperationHandler: { (granted) in
            if granted { block() }
            Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                  access: granted ? "approve" : "deny")
        }, authorizedHandler: {
            block()
        }) {
            self.showRequestAuthorizationAlert(from, cancelCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "deny")
            }, goSettingCompletion: {
                Tracer.trackInviteMemberImportContact(location: isOversea ? "email" : "phone",
                                                      access: "goto setting")
            })
        }
    }
    // enable-lint: duplicated_code
}

/// 三方分享 & lark内分享
extension ContactRouter: ShareRouter {
    func routeToForwardLarkInviteMsg(
        with msg: String,
        newTitle: String?,
        from: UIViewController,
        nextHandler: @escaping ForwardTextBody.SentHandler
    ) {
        let body = ForwardTextBody(text: msg, sentHandler: nextHandler)
        let resource = navigator.response(for: body).resource
        guard let dest = (resource as? UINavigationController)?.viewControllers[0] else { return }
        navigator.push(dest, from: from, animated: true, completion: {

        })
    }
}

extension ContactRouter: InviteByContactsSearchRouter {
    /// profile page
    func pushContactProfileViewController(vc: BaseUIViewController,
                                          userProfile: UserProfile,
                                          searchContentType: SearchContentType) {
        var type: RustPB.Basic_V1_ContactSource = .unknownSource
        switch searchContentType {
        case .email:
            type = .searchEmail
        case .phone:
            type = .searchPhone
        }
        let body = AddFriendBody(token: userProfile.contactToken, source: type)
        if Display.pad {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.push(body: body, from: vc)
        }
    }

    /// invite send page
    func presentInviteSendViewController(vc: UIViewController,
                                         source: SourceScene,
                                         type: InviteSendType,
                                         content: String,
                                         countryCode: String,
                                         inviteMsg: String,
                                         uniqueId: String,
                                         sendCompletionHandler: @escaping () -> Void) {
        let body = ExternalInviteSendControllerBody(source: source,
                                                    type: type,
                                                    content: content,
                                                    countryCode: countryCode,
                                                    inviteMsg: inviteMsg,
                                                    uniqueId: uniqueId,
                                                    sendCompletionHandler: sendCompletionHandler)
        if Display.pad {
            navigator.present(
                body: body,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.present(body: body, from: vc)
        }
    }
}

/// Invite Send Page Router
extension ContactRouter: ExternalInviteSendRouter {
    func presentCountryCodeSelectController(vc: UIViewController, selectCompletionHandler: @escaping (String) -> Void) {
        self.showCountryCodeSelectController(vc: vc, selectCompletionHandler: selectCompletionHandler)
    }
}

extension ContactRouter: ExternalContactImportRouter {
    /// 跳转个人卡片页面
    func pushPersonalCardVC(from: UIViewController,
                            userProfile: UserProfile,
                            inviteType: InviteSendType) {
        var type: RustPB.Basic_V1_ContactSource = .unknownSource
        switch inviteType {
        case .email:
            type = .searchEmail
        case .phone:
            type = .searchPhone
        }
        let body = AddFriendBody(token: userProfile.contactToken, source: type)
        navigator.push(body: body, from: from)
    }
}

extension ContactRouter: AddrBookContactRouter {
    /// 个人信息详情页
    func pushPersonalCardVC(from: UIViewController,
                            userId: String) {
        let body = PersonCardBody(chatterId: userId)
        navigator.push(body: body, from: from)
    }
    /// 添加好友
    func pushApplyFriendsVC(from: UIViewController,
                            userId: String,
                            userName: String,
                            completionHandler: @escaping (String?) -> Void) {
        let body = AddContactRelationBody(userId: userId,
                                          chatId: "",
                                          token: nil,
                                          source: Source(),
                                          addContactBlock: completionHandler,
                                          userName: userName,
                                          businessType: .onboardingConfirm)
        navigator.push(body: body, from: from)
    }
}
/// Read system address book permissions related
private extension ContactRouter {
    func requestSystemContactAuthorization(token: String,
                                           rootVc: UIViewController,
                                           userOperationHandler: ((Bool) -> Void)?,
                                           authorizedHandler: (() -> Void)?,
                                           deniedHandler: (() -> Void)?) {

        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            DispatchQueue.main.async { deniedHandler?() }
        case CNAuthorizationStatus.notDetermined:
            do {
                let tk = Token(token)
                try ContactsEntry.requestAccess(forToken: tk, contactsStore: CNContactStore(), forEntityType: .contacts, completionHandler: { (granted, _) -> Void in
                    DispatchQueue.main.async {
                        if granted {
                            LKMetric.C.getContactsPermissionSuccess()
                        } else {
                            LKMetric.C.getContactsPermissionFailed()
                        }
                        userOperationHandler?(granted)
                    }
                })
            } catch {
                ContactLogger.shared.error(module: .action, event: "\(Self.self) no request contact token \(token): \(error.localizedDescription)")
            }
        case  CNAuthorizationStatus.authorized:
            DispatchQueue.main.async { authorizedHandler?() }
        @unknown default:
            fatalError("unknown")
        }
    }

    func showRequestAuthorizationAlert(_ rootVc: UIViewController,
                                       cancelCompletion: (() -> Void)? = nil,
                                       goSettingCompletion: (() -> Void)? = nil) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersContactsPermission)
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsCancel, dismissCompletion: {
            cancelCompletion?()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsSettings, dismissCompletion: {
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
            goSettingCompletion?()
        })
        navigator.present(alertController, from: rootVc)
    }
}

/// CountryCode select page
private extension ContactRouter {
    func showCountryCodeSelectController(vc: UIViewController, selectCompletionHandler: @escaping (String) -> Void) {
        UDToast.showLoading(on: vc.view)
        passportService.getPhoneNumberRegionList { [weak self] allowList, blockList, _ in
            guard let `self` = self else { return }
            UDToast.removeToast(on: vc.view)

            let mobileVC = MobileCodeSelectViewController(mobileCodeLocale: LanguageManager.currentLanguage,
                                                          topCountryList: self.passportService.getTopCountryList(),
                                                          allowCountryList: allowList ?? [],
                                                          blockCountryList: blockList ?? self.passportService.getBlackCountryList()) { (mobileCode) in
                selectCompletionHandler(mobileCode.code)
            }

            if Display.pad {
                self.navigator.present(
                    mobileVC,
                    from: vc,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                self.navigator.present(mobileVC, from: vc)
            }
        }
    }
}
