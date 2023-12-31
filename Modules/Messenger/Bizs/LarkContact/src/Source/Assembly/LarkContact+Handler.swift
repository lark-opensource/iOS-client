//
//  LarkContact+Handler.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/7/30.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import Swinject
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import LarkNavigation
import SuiteAppConfig
import LarkReleaseConfig
import LarkSnsShare
import LarkAlertController
import UniverseDesignToast
import LarkTab
import LarkSearchCore
import LarkSetting
import RustPB
import LarkLocalizations
import LarkNavigator

final class ContactTopStructureHandler: UserRouterHandler {
    static let logger = Logger.log(ContactTopStructureHandler.self, category: "ContactTopStructureHandler")

    func handle(req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let showNormalNavigationBar = req.context["showNormalNavigationBar"] as? Bool ?? false
        let rootVC: UIViewController
        if passportUserService.userTenant.isCustomer {
            rootVC = try handleToCContactTopStructure(req, showNormalNavigationBar)
        } else {
            rootVC = try handleToBContactTopStructure(req, showNormalNavigationBar)
        }
        res.end(resource: rootVC)
    }

    private func handleToCContactTopStructure (
        _ request: EENavigator.Request,
        _ showNormalNavigationBar: Bool) throws -> UIViewController {
        let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
        let externalContactsAPI = try userResolver.resolve(assert: ExternalContactsAPI.self)
        let customNaviEnable = try userResolver.resolve(assert: NavigationService.self).customNaviEnable

        let viewModel = CustomerContactViewModel(
            api: externalContactsAPI,
            pushDriver: pushDriver,
            showNormalNavigationBar: showNormalNavigationBar,
            isUsingNewNaviBar: customNaviEnable
        )
        let router = try userResolver.resolve(assert: CustomerContactRouter.self)
        let vc = CustomerContactController(viewModel: viewModel, router: router, resolver: userResolver)
        let contactTab = self.createContactTab()
        contactTab?.delegate = vc
        vc.contactTab = contactTab

        return vc
    }

    private func handleToBContactTopStructure(
        _ request: EENavigator.Request,
        _ showNormalNavigationBar: Bool) throws -> UIViewController {
        let r = userResolver
        let userAPI = try r.resolve(assert: UserAPI.self)
        let chatterAPI = try r.resolve(assert: ChatterAPI.self)
        let unifiedInvitationService = try r.resolve(assert: UnifiedInvitationService.self)
        let inviteStorageService = try r.resolve(assert: InviteStorageService.self)
        let isEnableOncall = SearchFeatureGatingKey.oncallEnable.isUserEnabled(userResolver: userResolver)
        let customNaviEnable = try r.resolve(assert: NavigationService.self).customNaviEnable
        let appConfigService = try r.resolve(assert: AppConfigService.self)
        let pushCenter = try userResolver.userPushCenter
        let router = try r.resolve(assert: TopStructureViewControllerRouter.self)
        let dependency = try userResolver.resolve(assert: ContactDataDependency.self)

        let viewModel = try TopStructureViewModel(
            userAPI: userAPI,
            chatterAPI: chatterAPI,
            appConfigService: appConfigService,
            dependency: dependency,
            unifiedInvitationService: unifiedInvitationService,
            inviteStorageService: inviteStorageService,
            isEnableOncall: isEnableOncall,
            showNormalNavigationBar: showNormalNavigationBar,
            isUsingNewNaviBar: customNaviEnable,
            pushContactsOb: pushCenter.observable(for: PushContactsInfo.self),
            resolver: userResolver
        )

        let homeVC = TopStructureViewController(viewModel: viewModel,
                                                router: router,
                                                resolver: userResolver)

        let contactTab = self.createContactTab()
        contactTab?.delegate = homeVC
        homeVC.contactTab = contactTab
        return homeVC
    }

    private func createContactTab() -> LarkContactTab? {
        return TabRegistry.resolve(.contact) as? LarkContactTab
    }
}

final class ContactSearchPickerHandler: UserTypedRouterHandler {
    func handle(_ body: ContactSearchPickerBody, req: EENavigator.Request, res: Response) throws {
        let contactView = PickerContactView(resolver: self.userResolver)
        contactView.config = body.contactConfig
        let pickerNav = SearchPickerNavigationController(resolver: self.userResolver)
        pickerNav.featureConfig = body.featureConfig
        pickerNav.searchConfig = body.searchConfig
        pickerNav.pickerDelegate = body.delegate
        pickerNav.defaultView = contactView
        res.end(resource: pickerNav)
    }
}

final class CalendarChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let pickerCalendarDepartmentFG = SearchFeatureGatingKey.pickerCalendarDepartment.isUserEnabled(userResolver: userResolver)
        let params = CalendarChatterPicker.InitParam()
        params.isMultiple = body.selectStyle == .multi
        params.includeOuterTenant = body.needSearchOuterTenant

        let forceSelectedChatter = body.forceSelectedChatterIds.map { OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: $0) }
        let defaultSelectedChatter = body.defaultSelectedChatterIds.map { OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: $0) }

        let forceSelectedChat = body.forceSelectedChatIds.map { OptionIdentifier(type: OptionIdentifier.Types.chat.rawValue, id: $0) }
        let defaultSelectedChat = body.defaultSelectedChatIds.map { OptionIdentifier(type: OptionIdentifier.Types.chat.rawValue, id: $0) }

        let forceSelectedMailContact = body.forceSelectedMailContactIds.map { OptionIdentifier(type: OptionIdentifier.Types.mailContact.rawValue, id: $0) }
        let defaultSelectedMailContact = body.defaultSelectedMailContactIds.map { OptionIdentifier(type: OptionIdentifier.Types.mailContact.rawValue, id: $0) }

        params.default = defaultSelectedChatter + defaultSelectedChat + defaultSelectedMailContact
        params.disabled = forceSelectedChat + forceSelectedChatter + forceSelectedMailContact

        if body.checkInvitePermission {
            params.permissions = [.inviteEvent, .checkBlock]
        }
        params.includeMailContact = body.needSearchMail
        params.includeMeetingGroup = body.eventSearchMeetingGroup
        params.includeChat = body.supportSelectGroup
        params.includeDepartment = body.supportSelectOrganization

        if !pickerCalendarDepartmentFG { params.includeDepartment = false }
        let chatterPicker = CalendarChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
        if let placeholder = body.searchPlaceholder {
            chatterPicker.searchPlaceholder = placeholder
        } else {
            if body.supportSelectOrganization && body.needSearchMail {
                chatterPicker.searchPlaceholder = BundleI18n.Calendar.Calendar_Edit_SearchPlaceholder
            } else if body.needSearchMail {
                chatterPicker.searchPlaceholder = BundleI18n.Calendar.Calendar_Edit_AddGuestPlaceholder
            }
        }

        if passportUserService.userTenant.isCustomer {
            let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
            let router = try userResolver.resolve(assert: CustomerSelectRouter.self)
            let vc = CalendarCustomerSelectViewController(
                navTitle: body.title,
                picker: chatterPicker,
                isShowGroup: false,
                allowSelectNone: body.allowSelectNone,
                limitInfo: nil,
                pushDriver: pushDriver,
                router: router,
                resolver: userResolver,
                tracker: nil,
                confirmCallBack: body.selectedCallback)
            vc.closeCallback = body.cancelCallback
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: nil)
            nav.viewControllers = [vc]
            nav.modalPresentationStyle = .fullScreen
            res.end(resource: nav)
        } else {
            var structureViewDependencyConfig = StructureViewDependencyConfig()
            structureViewDependencyConfig.enableExternal = body.needSearchOuterTenant && body.enableSearchingOuterTenant
            let includeSelectGroup = params.includeChat && pickerCalendarDepartmentFG // FG没开启时，还原旧版本的功能效果
            structureViewDependencyConfig.enableGroup = false
            structureViewDependencyConfig.supportSelectGroup = includeSelectGroup

            structureViewDependencyConfig.enableOrganization = true
            structureViewDependencyConfig.supportSelectOrganization = params.includeDepartment

            structureViewDependencyConfig.enableRelatedOrganizations = true
            structureViewDependencyConfig.enableEmailContact = body.enableEmailContact

            let structureView = StructureView(frame: .zero,
                                              dependency: DefaultStructureViewDependencyImpl(r: userResolver,
                                                                                             picker: chatterPicker,
                                                                                             config: structureViewDependencyConfig),
                                              resolver: userResolver)
            chatterPicker.defaultView = structureView
            var topStructureSelectViewVC = try CalendarTopStructureSelectViewController(
                navTitle: body.title,
                chatterPicker: chatterPicker,
                style: body.selectStyle,
                allowSelectNone: body.allowSelectNone,
                allowDisplaySureNumber: true,
                limitInfo: nil,
                tracker: nil,
                selectedCallback: body.selectedCallback,
                resolver: userResolver)
            topStructureSelectViewVC.enableSearchingOuterTenant = body.needSearchOuterTenant && body.enableSearchingOuterTenant
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: nil)
            topStructureSelectViewVC.closeCallback = body.cancelCallback
            nav.viewControllers = [topStructureSelectViewVC]
            nav.modalPresentationStyle = .fullScreen
            res.end(resource: nav)
        }
    }
}

final class MailChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: MailChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let params = MailChatterPicker.InitParam()
        params.isMultiple = true
        params.includeOuterTenant = true
        params.includeChat = true
        params.includeDepartment = body.pickerDepartmentFG
        params.includeAllChat = false
        let defualtSelectedMails = body.forceSelectedEmails + body.defaultSelectedEmails
        params.default = defualtSelectedMails.map({ email in
            return OptionIdentifier.mailContact(id: email)
        })
        params.disabled = body.forceSelectedEmails.map({ email in
            return OptionIdentifier.mailContact(id: email)
        })

        let chatterPicker = MailChatterPicker(resolver: self.userResolver, frame: .zero, params: params)

        var structureViewDependencyConfig = StructureViewDependencyConfig()
        structureViewDependencyConfig.enableEmailContact = true
        structureViewDependencyConfig.enableExternal = false
        structureViewDependencyConfig.enableGroup = false

        structureViewDependencyConfig.enableOrganization = true
        structureViewDependencyConfig.supportSelectOrganization = true

        structureViewDependencyConfig.enableRelatedOrganizations = false
        structureViewDependencyConfig.preferEnterpriseEmail = true

        let structureView = StructureView(frame: .zero,
                                          dependency: DefaultStructureViewDependencyImpl(r: userResolver,
                                                                                         picker: chatterPicker,
                                                                                         config: structureViewDependencyConfig),
                                          resolver: userResolver)
        chatterPicker.defaultView = structureView
        var navTitleView: UIView?
        if body.pickerDepartmentFG {
            navTitleView = PickerNavigationTitleView(
                title: body.title.isEmpty ? BundleI18n.LarkContact.Lark_Contacts_SelectContacts : body.title,
                observable: chatterPicker.selectedObservable,
                initialValue: []
            )
        }
        let mailTopStructSelectVCParams = MailTopStructSelectVCParams(
            navTitle: body.title.isEmpty ? BundleI18n.LarkContact.Lark_Contacts_SelectContacts : body.title,
            navTitleView: navTitleView,
            chatterPicker: chatterPicker,
            style: body.selectStyle,
            allowSelectNone: body.allowSelectNone,
            allowDisplaySureNumber: true,
            limitInfo: SelectChatterLimitInfo(max: body.maxSelectCount,
                                              warningTip: BundleI18n.LarkContact.Lark_Contacts_RecipientLimit),
            tracker: nil,
            selectedCount: body.selectedCount,
            selectedCallback: body.selectedCallback,
            resolver: userResolver,
            pickerDepartmentFG: body.pickerDepartmentFG
        )
        let topStructureSelectViewVC = try MailTopStructureSelectViewController(params: mailTopStructSelectVCParams)
        let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: nil)
        topStructureSelectViewVC.closeCallback = body.cancelCallback
        nav.viewControllers = [topStructureSelectViewVC]
        nav.modalPresentationStyle = .fullScreen
        res.end(resource: nav)
    }
}

final class MailGroupChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: MailGroupChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        var enbleDepartment = body.groupRoleType != .manager

        let params = MailChatterPicker.InitParam()
        params.isMultiple = true
        params.includeOuterTenant = false
        params.includeChat = false
        params.includeDepartment = enbleDepartment
        params.includeMailContact = false // 邮件组的不允许搜索

        let chatterPicker = MailChatterPicker(resolver: self.userResolver, frame: .zero, params: params)

        let enableSharedMail = body.groupRoleType != .manager
        let enableEmailAddress = body.groupRoleType == .member

        var structureViewDependencyConfig = StructureViewDependencyConfig()
        structureViewDependencyConfig.enableEmailContact = false
        structureViewDependencyConfig.enableExternal = false
        structureViewDependencyConfig.enableGroup = false
        structureViewDependencyConfig.enableSharedMailAccount = enableSharedMail
        structureViewDependencyConfig.enableEmailAddress = enableEmailAddress

        structureViewDependencyConfig.enableOrganization = true
        structureViewDependencyConfig.supportSelectOrganization = true

        structureViewDependencyConfig.enableRelatedOrganizations = false
        structureViewDependencyConfig.preferEnterpriseEmail = false

        let config = DefaultStructureViewDependencyImpl(r: userResolver,
                                                        picker: chatterPicker,
                                                        config: structureViewDependencyConfig)
        var type: MailGroupRole = .manager
        switch body.groupRoleType {
        case .manager:
            type = .manager
        case .member:
            type = .member
        case .permission:
            type = .permission
        }
        config.mailGroupId = body.groupId
        config.mailGroupRole = type

        let structureView = StructureView(frame: .zero,
                                          dependency: config,
                                          resolver: userResolver)
        chatterPicker.defaultView = structureView
        var topStructureSelectViewVC = try MailGroupManagerStructureSelectViewController(
            navTitle: body.title.isEmpty ? BundleI18n.LarkContact.Lark_Contacts_SelectContacts : body.title,
            chatterPicker: chatterPicker,
            style: body.selectStyle,
            allowSelectNone: body.allowSelectNone,
            allowDisplaySureNumber: true,
            limitInfo: SelectChatterLimitInfo(max: body.maxSelectCount,
                                              warningTip: BundleI18n.LarkContact.Lark_Contacts_RecipientLimit),
            tracker: nil,
            selectedCallback: body.selectedCallback,
            resolver: userResolver)
        structureView.targetVC = topStructureSelectViewVC
        let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: nil)
        topStructureSelectViewVC.closeCallback = body.cancelCallback
        nav.viewControllers = [topStructureSelectViewVC]
        nav.modalPresentationStyle = .fullScreen
        res.end(resource: nav)
    }
}

final class ChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: ChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let params = AddChatterPicker.InitParam()
        params.isMultiple = body.selectStyle == .multi
        params.includeOuterTenant = body.needSearchOuterTenant
        params.includeBot = body.enableSearchBot
        params.excludeOuterContact = body.filterOuterContact
        params.userResignFilter = body.userResignFilter
        params.includeMyAi = body.enableMyAi

        let defaultSelectedChatterIds = body.forceSelectedChatterIds + body.defaultSelectedChatterIds
        let defaultOption = defaultSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.default = defaultOption
        let disabled = body.forceSelectedChatterIds + body.disabledSelectedChatterIds
        params.disabled = disabled.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.forceSelectedInChatId = body.forceSelectedChatId
        if let permissions = body.permissions {
            params.permissions = permissions
        }
        if body.checkInvitePermission {
            if body.isCryptoModel {
                params.permissions = [.inviteSameCryptoChat]
            } else if body.isCrossTenantChat {
                params.permissions = [.inviteSameCrossTenantChat]
            } else {
                params.permissions = [.inviteSameChat]
            }
        }
        var tracker: PickerAppReciable?
        switch body.source {
        case .addGroupMember:
            tracker = PickerAppReciable(pageName: "LKContactPickerViewController", fromType: .addGroupMember)
            tracker?.initViewStart()
            Tracer.trackOpenPickerView(.group)
        case .p2p:
            Tracer.trackOpenPickerView(.p2p)
        default:
            break
        }

        let dataOptions = DataOptions(rawValue: body.dataOptions.rawValue)
        if passportUserService.userTenant.isCustomer || body.forceTreatAsCustomer {
            let isShowGroup = dataOptions.contains(.group)
            let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
            let router = try userResolver.resolve(assert: CustomerSelectRouter.self)
            let vc = CustomerSelectViewController(navTitle: body.title,
                                                  picker: ChatterPicker(resolver: self.userResolver, frame: .zero, params: params),
                                                     isShowGroup: isShowGroup,
                                                     allowSelectNone: body.allowSelectNone,
                                                     limitInfo: body.limitInfo,
                                                     pushDriver: pushDriver,
                                                     router: router,
                                                     resolver: userResolver,
                                                     tracker: tracker,
                                                     confirmCallBack: body.selectedCallback)
            vc.closeCallback = body.cancelCallback
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: body.toolbarClass)
            nav.viewControllers = [vc]
            nav.modalPresentationStyle = .formSheet
            res.end(resource: nav)
        } else {
            params.targetPreview = body.targetPreview
            params.supportUnfold = body.supportUnfoldSelected
            var structureViewDependencyConfig = StructureViewDependencyConfig()
            // 目前TopStructureSelectViewController中的选人都是不会加入外部联系人的，因此将fg直接设置在这里，不在各个场景分别接入
            // 相关场景：创建群组、单聊建群、添加群成员、转发时选择创建新会话并转发
            structureViewDependencyConfig.enableExternal = dataOptions.contains(.external) || body.needSearchOuterTenant
            if let showExternalContact = body.showExternalContact {
                structureViewDependencyConfig.enableExternal = showExternalContact
            }
            structureViewDependencyConfig.enableGroup = dataOptions.contains(.group)
            structureViewDependencyConfig.enableBot = dataOptions.contains(.robot)
            structureViewDependencyConfig.enableOnCall = dataOptions.contains(.onCall)
            structureViewDependencyConfig.isCrossTenantChat = body.isCrossTenantChat
            structureViewDependencyConfig.enableRelatedOrganizations = body.enableRelatedOrganizations
            structureViewDependencyConfig.enableSearchFromFilter = body.hasSearchFromFilterRecommend

            // task业务需要底部增加view，设置picker距底部的布局
            if case .todo(let info) = body.source, info.isBatchAdd, !info.isShare {
                params.bottomInset = TodoTopStructureSelectViewController.batchBottomHeight
            } else if case .todo(let info) = body.source, info.isShare {
                params.bottomInset = TodoTopStructureSelectViewController.shareBottomHeight
                params.myGroupContactBehavior = Picker.ContactPickerBehaviour(
                    pickerItemCanSelect: { _ in true }
                )
            }
            let chatterPicker: ChatterPicker
            if body.supportSelectGroup || body.supportSelectOrganization {
                if body.supportSelectGroup {
                    structureViewDependencyConfig.enableGroup = true
                    structureViewDependencyConfig.supportSelectGroup = true
                }
                params.includeChat = body.supportSelectGroup
                if body.supportSelectOrganization {
                    structureViewDependencyConfig.enableOrganization = true
                    structureViewDependencyConfig.supportSelectOrganization = true
                }
                params.includeDepartment = body.supportSelectOrganization
                if body.checkGroupPermissionForInvite {
                    params.includeChatForAddChatter = true
                }
                if body.checkOrganizationPermissionForInvite {
                    params.includeDepartmentForAddChatter = true
                }
                chatterPicker = AddChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
                if body.checkGroupPermissionForInvite {
                    chatterPicker.searchPlaceholder = body.checkOrganizationPermissionForInvite ? BundleI18n.LarkContact.Lark_Group_SearchContactsDepartmentsMyGroups :
                    BundleI18n.LarkContact.Lark_IM_SelectDepartmentForGroupChat
                }
            } else {
                chatterPicker = ChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
            }

            var navTitleView: UIView?
            if body.supportCustomTitleView {
                navTitleView = PickerNavigationTitleView(
                    title: body.title,
                    observable: chatterPicker.selectedObservable,
                    initialValue: chatterPicker.selected
                )
            }
            let dependencyImpl = DefaultStructureViewDependencyImpl(r: userResolver,
                                                                    picker: chatterPicker,
                                                                    config: structureViewDependencyConfig)
            dependencyImpl.source = body.source
            dependencyImpl.fromFilterRecommendList = body.recommendList
            dependencyImpl.defaultOption = defaultOption
            let structureView = StructureView(frame: .zero,
                                              dependency: dependencyImpl,
                                              resolver: userResolver)
            chatterPicker.defaultView = structureView
            let topStructureSelectViewVC: BaseUIViewController
            if case .todo(let info) = body.source {
                // 这里需要单独抽出去
                let vc = try TodoTopStructureSelectViewController(navTitle: body.title,
                                                                                   navTitleView: navTitleView,
                                                                                   chatterPicker: chatterPicker,
                                                                                   style: body.selectStyle,
                                                                                   allowSelectNone: body.allowSelectNone,
                                                                                   allowDisplaySureNumber: body.allowDisplaySureNumber,
                                                                                   limitInfo: body.limitInfo,
                                                                                   tracker: tracker,
                                                                                   selectedCallback: body.selectedCallback,
                                                                                   resolver: userResolver)
                vc.selectionDataSource = dependencyImpl.selectionSource
                structureView.targetVC = vc
                vc.closeCallback = body.cancelCallback
                vc.source = body.source
                vc.hideRightNaviBarItem = info.isShare
                topStructureSelectViewVC = vc
            } else {
                let vc = try TopStructureSelectViewController(navTitle: body.title,
                                                                                   navTitleView: navTitleView,
                                                                                   chatterPicker: chatterPicker,
                                                                                   style: body.selectStyle,
                                                                                   allowSelectNone: body.allowSelectNone,
                                                                                   allowDisplaySureNumber: body.allowDisplaySureNumber,
                                                                                   limitInfo: body.limitInfo,
                                                                                   tracker: tracker,
                                                                                   selectedCallback: body.selectedCallback,
                                                                                   resolver: userResolver)
                vc.closeCallback = body.cancelCallback
                vc.source = body.source
                topStructureSelectViewVC = vc
            }
            //defaultView跳转需要
            structureView.targetVC = topStructureSelectViewVC
            //picker跳转需要
            chatterPicker.fromVC = topStructureSelectViewVC
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: body.toolbarClass)
            nav.viewControllers = [topStructureSelectViewVC]
            nav.modalPresentationStyle = .formSheet
            res.end(resource: nav)
        }
    }
}

final class VCChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: VCChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let params = AddChatterPicker.InitParam()
        params.isMultiple = body.selectStyle == .multi
        params.includeOuterTenant = body.needSearchOuterTenant
        params.includeOuterChat = body.includeOuterChat
        params.includeBot = body.enableSearchBot
        params.includeOuterGroupForChat = body.includeOuterGroupForChat
        params.myGroupContactBehavior = ChatterPicker.ContactPickerBehaviour(pickerItemCanSelect: body.myGroupContactCanSelect, pickerItemDisableReason: body.myGroupContactDisableReason)

        params.externalContactBehavior = ChatterPicker.ContactPickerBehaviour(pickerItemCanSelect: body.externalContactCanSelect, pickerItemDisableReason: body.externalContactDisableReason)
        let defaultSelectedChatterIds = body.forceSelectedChatterIds + body.defaultSelectedChatterIds
        params.default = defaultSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.default += body.defaultSelectedResult?.chatterInfos ?? []
        params.default += body.defaultSelectedResult?.chatInfos ?? []
        params.default += body.defaultSelectedResult?.departments ?? []

        let disabled = body.forceSelectedChatterIds + body.disabledSelectedChatterIds
        params.disabled = disabled.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.forceSelectedInChatId = body.forceSelectedChatId
        if body.checkInvitePermission {
            if body.isCryptoModel {
                params.permissions = [.inviteSameCryptoChat]
            } else if body.isCrossTenantChat {
                params.permissions = [.inviteSameCrossTenantChat]
            } else {
                params.permissions = [.inviteSameChat]
            }
        }
        var tracker: PickerAppReciable = PickerAppReciable(pageName: "LKVCPickerViewController", fromType: .vc)

        let dataOptions = DataOptions(rawValue: body.dataOptions.rawValue)
        if passportUserService.userTenant.isCustomer || body.forceTreatAsCustomer {
            let isShowGroup = dataOptions.contains(.group)
            let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
            let router = try userResolver.resolve(assert: CustomerSelectRouter.self)
            let vc = CustomerSelectViewController(navTitle: body.title,
                                                  picker: ChatterPicker(resolver: self.userResolver, frame: .zero, params: params),
                                                  isShowGroup: isShowGroup,
                                                  allowSelectNone: body.allowSelectNone,
                                                  limitInfo: body.limitInfo,
                                                  pushDriver: pushDriver,
                                                  router: router,
                                                  resolver: userResolver,
                                                  tracker: tracker,
                                                  confirmCallBack: body.selectedCallback)
            vc.closeCallback = body.cancelCallback
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: body.toolbarClass)
            nav.viewControllers = [vc]
            nav.modalPresentationStyle = .formSheet
            res.end(resource: nav)
        } else {
            params.supportUnfold = body.supportUnfoldSelected
            var structureViewDependencyConfig = StructureViewDependencyConfig()
            // 目前TopStructureSelectViewController中的选人都是不会加入外部联系人的，因此将fg直接设置在这里，不在各个场景分别接入
            // 相关场景：创建群组、单聊建群、添加群成员、转发时选择创建新会话并转发
            structureViewDependencyConfig.enableExternal = dataOptions.contains(.external) || body.needSearchOuterTenant
            structureViewDependencyConfig.enableGroup = dataOptions.contains(.group)
            structureViewDependencyConfig.enableBot = dataOptions.contains(.robot)
            structureViewDependencyConfig.enableOnCall = dataOptions.contains(.onCall)
            structureViewDependencyConfig.isCrossTenantChat = body.isCrossTenantChat
            structureViewDependencyConfig.enableRelatedOrganizations = body.enableRelatedOrganizations

            let chatterPicker: ChatterPicker

            if body.supportSelectGroup || body.supportSelectOrganization {
                if body.supportSelectGroup {
                    structureViewDependencyConfig.enableGroup = true
                    structureViewDependencyConfig.supportSelectGroup = true
                }
                params.includeChat = body.supportSelectGroup
                if body.supportSelectOrganization {
                    structureViewDependencyConfig.enableOrganization = true
                    structureViewDependencyConfig.supportSelectOrganization = true
                }
                params.includeDepartment = body.supportSelectOrganization
                if body.checkGroupPermissionForInvite {
                    params.includeChatForAddChatter = true
                }
                if body.checkOrganizationPermissionForInvite {
                    params.includeDepartmentForAddChatter = true
                }
                chatterPicker = AddChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
                if body.checkGroupPermissionForInvite {
                    chatterPicker.searchPlaceholder = body.checkOrganizationPermissionForInvite ? BundleI18n.LarkContact.Lark_Group_SearchContactsDepartmentsMyGroups :
                    BundleI18n.LarkContact.Lark_IM_SelectDepartmentForGroupChat
                }
            } else {
                chatterPicker = ChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
            }

            var navTitleView: UIView?
            if body.supportCustomTitleView {
                navTitleView = PickerNavigationTitleView(
                    title: body.title,
                    observable: chatterPicker.selectedObservable,
                    initialValue: chatterPicker.selected
                )
            }
            let dependencyImpl = DefaultStructureViewDependencyImpl(r: userResolver,
                                                                    picker: chatterPicker,
                                                                    config: structureViewDependencyConfig)
            dependencyImpl.source = body.source
            let structureView = StructureView(frame: .zero,
                                              dependency: dependencyImpl,
                                              resolver: userResolver)
            if let view = body.customHeaderView {
                structureView.customTableViewHeader(customView: view)
            }
            chatterPicker.defaultView = structureView
            let topStructureSelectViewVC = try VCTopStructureSelectViewController(navTitle: body.title,
                                                                               navTitleView: navTitleView,
                                                                               chatterPicker: chatterPicker,
                                                                               style: body.selectStyle,
                                                                               allowSelectNone: body.allowSelectNone,
                                                                               allowDisplaySureNumber: body.allowDisplaySureNumber,
                                                                               limitInfo: body.limitInfo,
                                                                               tracker: tracker,
                                                                               selectedCallback: body.selectedCallback,
                                                                               resolver: userResolver)
            topStructureSelectViewVC.checkSearchChatDeniedReasonForWillSelected = body.checkChatDeniedReasonForWillSelected
            topStructureSelectViewVC.checkSearchChatDeniedReasonForDisabledPick = body.checkChatDeniedReasonForDisabledPick
            topStructureSelectViewVC.checkSearchChatterDeniedReasonForWillSelected = body.checkChatterDeniedReasonForWillSelected
            topStructureSelectViewVC.checkSearchChatterDeniedReasonForDisabledPick = body.checkChatterDeniedReasonForDisabledPick
            let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: body.toolbarClass)
            topStructureSelectViewVC.closeCallback = body.cancelCallback
            topStructureSelectViewVC.source = body.source
            nav.viewControllers = [topStructureSelectViewVC]
            nav.modalPresentationStyle = .formSheet
            res.end(resource: nav)
        }
    }
}

final class TeamChatterPickerHandler: UserTypedRouterHandler {

    func handle(_ body: TeamChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let params = AddChatterPicker.InitParam()
        params.isMultiple = body.selectStyle == .multi
        params.includeOuterTenant = true

        params.default = body.forceSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.default += body.defaultSelectedResult?.chatterInfos ?? []
        params.default += body.defaultSelectedResult?.chatInfos ?? []
        params.default += body.defaultSelectedResult?.departments ?? []

        let disabled = body.forceSelectedChatterIds + body.disabledSelectedChatterIds
        params.disabled = disabled.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.forceSelectedInChatId = body.forceSelectedChatId
        params.permissions = [.inviteSameChat]
        params.supportUnfold = body.supportUnfoldSelected
        params.targetPreview = userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "core.forward.target_preview"))

        var structureViewDependencyConfig = StructureViewDependencyConfig()
        structureViewDependencyConfig.enableExternal = false
        structureViewDependencyConfig.enableBot = false
        structureViewDependencyConfig.enableOnCall = false
        structureViewDependencyConfig.isCrossTenantChat = false
        structureViewDependencyConfig.enableRelatedOrganizations = false

        structureViewDependencyConfig.enableGroup = body.supportSelectGroup
        structureViewDependencyConfig.supportSelectGroup = body.supportSelectGroup
        params.includeChat = body.supportSelectGroup
        structureViewDependencyConfig.enableOrganization = body.supportSelectOrganization
        structureViewDependencyConfig.supportSelectOrganization = body.supportSelectOrganization
        params.includeDepartment = body.supportSelectOrganization
        params.includeChatter = body.supportSelectChatter
        params.includeDepartmentForAddChatter = true
        params.includeChatForAddChatter = false
        params.includeOuterGroupForChat = true
        params.includeShieldGroup = body.includeShieldGroup
        params.includeAllChat = false
        let addChatterPicker = AddChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
        addChatterPicker.contentConfigrations = body.pickerContentConfigurations
        addChatterPicker.searchPlaceholder = body.searchPlaceholder
        addChatterPicker.itemDisableBehavior = body.itemDisableBehavior
        addChatterPicker.itemDisableSelectedToastBehavior = body.itemDisableSelectedToastBehavior
        var navTitleView: UIView?
        if body.usePickerTitleView {
            navTitleView = PickerNavigationTitleView(
                title: body.title,
                observable: addChatterPicker.selectedObservable,
                initialValue: addChatterPicker.selected
            )
        } else if !body.subTitle.isEmpty {
            navTitleView = TopStructureSelectNavigationTitleView(title: body.title, subTitle: body.subTitle)
        }
        let dependencyImpl = DefaultStructureViewDependencyImpl(r: userResolver,
                                                                picker: addChatterPicker,
                                                                config: structureViewDependencyConfig,
                                                                checkMyGroupsSelectDeniedReason: MyGroupsCheckSelectDeniedReasonConfigurableImp(
                                                                    checkForDisabledPick: body.checkChatDeniedReasonForDisabledPick,
                                                                    checkForWillSelected: body.checkChatDeniedReasonForWillSelected
                                                                )
        )
        dependencyImpl.source = body.source
        let structureView = StructureView(frame: .zero,
                                          dependency: dependencyImpl,
                                          resolver: userResolver)
        addChatterPicker.defaultView = structureView
        let teamTopStructureSelectViewVC = try TeamTopStructureSelectViewController(
            navTitle: body.title,
            navTitleView: navTitleView,
            chatterPicker: addChatterPicker,
            style: body.selectStyle,
            allowSelectNone: false,
            allowDisplaySureNumber: false,
            limitInfo: nil,
            tracker: nil,
            selectedCallback: body.selectedCallback,
            resolver: userResolver)
        teamTopStructureSelectViewVC.customLeftBarButtonItem = body.customLeftBarButtonItem
        teamTopStructureSelectViewVC.hideRightNaviBarItem = body.hideRightNaviBarItem
        teamTopStructureSelectViewVC.headerTitle = body.waterChannelHeaderTitle
        teamTopStructureSelectViewVC.checkSearchChatDeniedReasonForWillSelected = body.checkChatDeniedReasonForWillSelected
        teamTopStructureSelectViewVC.checkSearchChatDeniedReasonForDisabledPick = body.checkChatDeniedReasonForDisabledPick
        teamTopStructureSelectViewVC.checkSearchChatterDeniedReasonForWillSelected = body.checkChatterDeniedReasonForWillSelected
        teamTopStructureSelectViewVC.checkSearchChatterDeniedReasonForDisabledPick = body.checkChatterDeniedReasonForDisabledPick
        let nav = LkNavigationController(navigationBarClass: nil, toolbarClass: nil)
        teamTopStructureSelectViewVC.closeCallback = body.cancelCallback
        teamTopStructureSelectViewVC.source = body.source
        //defaultView跳转需要
        structureView.targetVC = teamTopStructureSelectViewVC
        //picker跳转需要
        addChatterPicker.fromVC = teamTopStructureSelectViewVC
        nav.viewControllers = [teamTopStructureSelectViewVC]
        nav.modalPresentationStyle = .fullScreen
        res.end(resource: nav)
    }
}

final class CreateGroupPickHandler: UserTypedRouterHandler {
    static let logger = Logger.log(CreateGroupPickHandler.self, category: "CreateGroupPickHandler")

    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: CreateGroupPickBody, req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        if passportUserService.userTenant.isCustomer {
            try self.handleToCCreateGroup(body: body, res: res)
        } else {
            try self.handleToBCreateGroup(body: body, res: res)
        }
    }

    private func handleToCCreateGroup(body: CreateGroupPickBody, res: Response) throws {
        let tracker = PickerAppReciable(pageName: "LKContactPickerViewController", fromType: .createGroupChat)
        let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
        let router = try userResolver.resolve(assert: CustomerSelectRouter.self)
        let callback: (UIViewController, ContactPickerResult) -> Void = { (vc, result) in
            let chatterInfos = result.chatterInfos
            var context = CreateGroupContext()
            context.isPublic = false
            context.chatMode = .default
            body.selectCallback?(context, .pickEntities(CreateGroupResult.CreateGroupPickEntities(chatters: chatterInfos, chats: [], departments: [])), vc)
        }
        let params = ChatterPicker.InitParam()
        params.isMultiple = true
        params.includeOuterTenant = body.needSearchOuterTenant
        params.default = body.forceSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.disabled = body.forceSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        let vc = CustomerSelectViewController(navTitle: BundleI18n.LarkContact.Lark_Legacy_CreategroupTitle,
                                              picker: ChatterPicker(resolver: self.userResolver, frame: .zero, params: params),
                                                 isShowGroup: body.isShowGroup,
                                                 allowSelectNone: true,
                                                 limitInfo: nil,
                                                 pushDriver: pushDriver,
                                                 router: router,
                                                 resolver: userResolver,
                                                 tracker: tracker,
                                                 confirmCallBack: callback)
        let nav = LKToolBarNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        res.end(resource: nav)
    }

    private func handleToBCreateGroup(body: CreateGroupPickBody, res: Response) throws {
        let tracker = PickerAppReciable(pageName: "LKContactPickerViewController", fromType: .createGroupChat)
        // 能够创建哪些类型的群
        var ability = CreateAbility.none
        do {
            // 是否能创建密聊群
            let secretChatEnable = try userResolver.resolve(assert: SecretChatService.self).secretChatEnable

            let limitCreateSecrectGroup = userResolver.fg.staticFeatureGatingValue(with: "im.chat.secure.create.group")
            if secretChatEnable, !limitCreateSecrectGroup, body.canCreateSecretChat {
                ability.insert(.secret)
            }
            if body.canCreateThread {
                ability.insert(.thread)
            }
            if body.canCreatePrivateChat {
                ability.insert(.privateChat)
            }
        }

        let params = AddChatterPicker.InitParam()
        params.isMultiple = true
        params.includeOuterTenant = body.needSearchOuterTenant
        params.default = body.forceSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.disabled = body.forceSelectedChatterIds.map({ (chatterId) -> OptionIdentifier in
            return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: chatterId)
        })
        params.permissions = [.inviteSameChat]
        params.supportUnfold = true
        var config = StructureViewDependencyConfig()
        config.enableGroup = body.isShowGroup
        // 是否有关联组织的开关
        config.enableRelatedOrganizations = true
        config.tableBackgroundColor = UIColor.ud.bgBase
        params.targetPreview = body.targetPreview
        params.scene = "group_create"

        let disableSelectDepartmentPermission = userResolver.fg.staticFeatureGatingValue(with: "im.chat.depart_group_permission")
        config.enableGroup = true
        config.supportSelectGroup = true
        config.enableOrganization = true
        config.supportSelectOrganization = true
        params.includeChatForAddChatter = true
        params.includeDepartmentForAddChatter = !disableSelectDepartmentPermission
        params.includeOuterChat = true
        let chatterPicker = AddChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
        chatterPicker.searchPlaceholder = disableSelectDepartmentPermission ? BundleI18n.LarkContact.Lark_IM_SelectDepartmentForGroupChat :
        BundleI18n.LarkContact.Lark_Group_SearchContactsDepartmentsMyGroups

        let structureView = StructureView(frame: .zero,
                                          dependency: DefaultStructureViewDependencyImpl(r: userResolver,
                                                                                         picker: chatterPicker,
                                                                                         config: config),
                                          resolver: userResolver)
        chatterPicker.defaultView = structureView
        let createGroupVC = try CreateNewGroupViewController(ability: ability,
                                                            request: body,
                                                            chatterPicker: chatterPicker,
                                                            tracker: tracker,
                                                            resolver: userResolver,
                                                            createConfirmButtonTitle: body.createConfirmButtonTitle,
                                                            customTitle: body.title
        )
        structureView.targetVC = createGroupVC
        chatterPicker.fromVC = createGroupVC
        let nav = LKToolBarNavigationController(navigationBarClass: nil, toolbarClass: nil)
        nav.viewControllers = [createGroupVC]
        nav.modalPresentationStyle = .formSheet
        res.end(resource: nav)
    }
}

final class ContactApplicationHandler: UserTypedRouterHandler {

    func handle(_ body: ContactApplicationsBody, req: EENavigator.Request, res: Response) throws {
        let pushDriver = try userResolver.userPushCenter.driver(for: PushChatApplicationGroup.self)

        let viewModel = try ContactApplicationViewModel(
            pushDriver: pushDriver,
            resolver: userResolver
        )
        let router = try userResolver.resolve(assert: ContactApplicationViewControllerRouter.self)
        let vc = try ContactApplicationViewController(viewModel: viewModel,
                                                      router: router,
                                                      resolver: userResolver)
        res.end(resource: vc)
    }
}

/// 智能决策成员邀请目标页面的路由
final class SmartMemberInviteHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(SmartMemberInviteHandler.self, category: "LarkConatact.SmartMemberInviteHandler")

    func handle(_ body: SmartMemberInviteBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: UnifiedInvitationService.self)
        _ = service.dynamicMemberInvitePageResource(
            baseView: nil,
            sourceScenes: body.sourceScenes,
            departments: body.departments).subscribe(onNext: { (resource) in
                switch resource {
                case .memberFeishuSplit(let body):
                    res.redirect(body: body)
                case .memberLarkSplit(let body):
                    res.redirect(body: body)
                case .memberDirected(let body):
                    res.redirect(body: body)
                }
            }, onError: { (error) in
                SmartMemberInviteHandler.logger.error(error.localizedDescription)
                res.end(error: error)
            })
        res.wait()
    }
}

/// 国内成员邀请分流页面
final class MemberInviteSplitHandler: UserTypedRouterHandler {

    func handle(_ body: MemberInviteSplitBody, req: EENavigator.Request, res: Response) throws {
        InviteMemberApprecibleTrack.inviteMemberPageLoadTimeStart()
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let router = try userResolver.resolve(assert: MemberInviteSplitPageRouter.self)
        let dependency = try userResolver.resolve(assert: UnifiedInvitationDependency.self)
        let viewModel = try MemberInviteSplitViewModel(
            sourceScenes: body.sourceScenes,
            isOversea: isOversea,
            router: router,
            dependency: dependency,
            departments: body.departments,
            resolver: userResolver
        )
        let vc = try MemberInviteSplitViewController(viewModel: viewModel, resolver: userResolver)
        vc.rightButtonTitle = body.rightButtonTitle
        vc.rightButtonClickHandler = body.rightButtonClickHandler
        InviteMemberApprecibleTrack.inviteMemberPageInitViewCostTrack()
        res.end(resource: vc)
    }
}

/// 海外成员邀请分流页面
final class MemberInviteLarkSplitHandler: UserTypedRouterHandler {

    func handle(_ body: MemberInviteLarkSplitBody, req: EENavigator.Request, res: Response) throws {
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let router = try userResolver.resolve(assert: MemberInviteSplitPageRouter.self)
        let dependency = try userResolver.resolve(assert: UnifiedInvitationDependency.self)
        let viewModel = try MemberInviteLarkSplitViewModel(
            sourceScenes: body.sourceScenes,
            isOversea: isOversea,
            router: router,
            dependency: dependency,
            departments: body.departments,
            resolver: userResolver
        )
        let vc = try MemberInviteLarkSplitViewController(viewModel: viewModel, resolver: userResolver)
        vc.rightButtonTitle = body.rightButtonTitle
        vc.rightButtonClickHandler = body.rightButtonClickHandler
        res.end(resource: vc)
    }
}

/// 企业成员定向邀请页面
final class InviteMemberHandler: UserTypedRouterHandler {

    func handle(_ body: MemberDirectedInviteBody, req: EENavigator.Request, res: Response) throws {
        if let window = req.from.fromViewController?.view.window {
            UDToast.showLoading(on: window)
        }

        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        guard let router = try? userResolver.resolve(assert: MemberInviteRouter.self) else {
            fatalError("Router can not be resolved")
            return
        }
        guard let dependency = try? userResolver.resolve(assert: UnifiedInvitationDependency.self) else {
            fatalError("Dependency can not be resolved")
            return
        }
        passportService.getPhoneNumberRegionList { allowList, blockList, _ in
            if let window = req.from.fromViewController?.view.window {
                UDToast.removeToast(on: window)
            }

            let mobileCodeProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                                        topCountryList: [],
                                                        allowCountryList: allowList ?? [],
                                                        blockCountryList: blockList ?? [])

            guard let viewModel = try? MemberInviteViewModel(
                router: router,
                sourceScenes: body.sourceScenes,
                isFromInviteSplitPage: body.isFromInviteSplitPage,
                isOversea: isOversea,
                departments: body.departments,
                needShowType: body.needShowType,
                dependency: dependency,
                mobileCodeProvider: mobileCodeProvider,
                resolver: self.userResolver
            ) else { return }
            guard let vc = try? MemberInviteViewController(viewModel: viewModel, resolver: self.userResolver) else { return }
            vc.rightButtonTitle = body.rightButtonTitle
            vc.rightButtonClickHandler = body.rightButtonClickHandler
            viewModel.vc = vc
            res.end(resource: vc)
        }

        res.wait()
    }
}

/// 企业成员非定向邀请页面
final class MemberNoDirectionalHandler: UserTypedRouterHandler {

    func handle(_ body: MemberNoDirectionalBody, req: EENavigator.Request, res: Response) throws {
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let dependency = try userResolver.resolve(assert: UnifiedInvitationDependency.self)
        let router = try userResolver.resolve(assert: MemberInviteNoDirectionalControllerRouter.self)
        let viewModel = MemberNoDirectionalViewModel(
            dependency: dependency,
            isOversea: isOversea,
            departments: body.departments,
            sourceScenes: body.sourceScenes,
            priority: body.displayPriority,
            router: router)
        let vc = MemberInviteNoDirectionalController(viewModel: viewModel, resolver: userResolver)
        res.end(resource: vc)
    }
}

/// 团队码邀请页
final class TeamCodeInviteHandler: UserTypedRouterHandler {

    func handle(_ body: TeamCodeInviteBody, req: EENavigator.Request, res: Response) throws {
        let teamCodeCopyEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.member.teamcode.copy.enable")
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let dependency = try userResolver.resolve(assert: UnifiedInvitationDependency.self)
        let router = try userResolver.resolve(assert: TeamCodeInviteControllerRouter.self)
        let viewModel = TeamCodeInviteViewModel(
            dependency: dependency,
            teamCodeCopyEnable: teamCodeCopyEnable,
            isOversea: isOversea,
            departments: body.departments,
            sourceScenes: body.sourceScenes,
            router: router,
            resolver: userResolver
        )
        let vc = TeamCodeInviteController(viewModel: viewModel, resolver: userResolver)
        res.end(resource: vc)
    }
}

/// 成员邀请引导页
final class MemberInviteGuideHandler: UserTypedRouterHandler {

    func handle(_ body: MemberInviteGuideBody, req: EENavigator.Request, res: Response) throws {
        let router = try userResolver.resolve(assert: MemberInviteGuideRouter.self)
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = MemberInviteGuideViewModel(router: router, inviteType: body.inviteType, isoversea: isOversea, resolver: userResolver)
        let dest = MemberInviteGuideController(viewModel: viewModel, resolver: userResolver)
        res.end(resource: dest)
    }
}

/// 统一邀请分流页
final class UnifiedPartnerInvitationControllerHandler: UserTypedRouterHandler {

    func handle(_ body: UnifiedInvitationBody, req: EENavigator.Request, res: Response) throws {
        let router = try userResolver.resolve(assert: UnifiedPartnerInvitationRouter.self)
        let dependency = try userResolver.resolve(assert: UnifiedInvitationDependency.self)
        let vc = UnifiedPartnerInvitationViewController(fgService: userResolver.fg,
                                                        router: router,
                                                        dependency: dependency)
        res.end(resource: vc)
    }
}

/// 统一邀请分流页
final class SmartUnifiedInvitationHandler: UserTypedRouterHandler {
    func handle(_ body: SmartUnifiedInvitationBody, req: EENavigator.Request, res: Response) throws {
        if userResolver.fg.staticFeatureGatingValue(with: "invite.union.enable") {
            res.redirect(body: UnifiedInvitationBody())
        } else {
            res.redirect(body: AddContactViewControllerBody())
        }
    }
}

/// 外部联系人邀请动态路由
final class ExternalContactDynamicHandler: UserTypedRouterHandler {

    func handle(_ body: ExternalContactDynamicBody, req: EENavigator.Request, res: Response) throws {
        AppReciableTrack.addExternalContactPageLoadTimeStart()
        let scenes = body.scenes
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let addMeSettingPush = try userResolver.userPushCenter.observable(for: PushWayToAddMeSettingMessage.self)
        let userType = try userResolver.resolve(assert: PassportUserService.self).user.type
        let isStandardBUser = userType == .standard
        let viewModel = ExternalContactSplitViewModel(
            fromEntrance: body.fromEntrance,
            isOversea: isOversea,
            isStandardBUser: isStandardBUser,
            resolver: userResolver
        )
        let vc = ExternalContactSplitController(viewModel: viewModel, resolver: userResolver)

        AppReciableTrack.addExternalContactPageInitViewCostTrack()
        res.end(resource: vc)
    }
}

/// 外部联系人非定向邀请
final class ExternalContactsInvitationControllerHandler: UserTypedRouterHandler {

    func handle(_ body: ExternalContactsInvitationControllerBody, req: EENavigator.Request, res: Response) throws {
        AppReciableTrack.addExternalContactPageLoadTimeStart()
        let scenes = body.scenes
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let addMeSettingPush = try userResolver.userPushCenter.observable(for: PushWayToAddMeSettingMessage.self)
        let userType = try userResolver.resolve(assert: PassportUserService.self).user.type
        let isStandardBUser = userType == .standard

        var vc: UIViewController?
        let viewModel = ExternalInvitationIndexViewModel(
            scenes: scenes,
            fromEntrance: body.fromEntrance,
            isOversea: isOversea,
            addMeSettingPush: addMeSettingPush,
            isStandardBUser: isStandardBUser,
            resolver: userResolver
        )
        vc = try ExternalContactsInvitationViewController(viewModel: viewModel, resolver: userResolver)

        AppReciableTrack.addExternalContactPageInitViewCostTrack()
        res.end(resource: vc)
    }
}

/// 外部联系人邀请分流页
final class ExternalContactSplitHandler: UserTypedRouterHandler {

    func handle(_ body: ExternalContactSplitBody, req: EENavigator.Request, res: Response) throws {
        AppReciableTrack.addExternalContactPageLoadTimeStart()
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let userType = try userResolver.resolve(assert: PassportUserService.self).user.type
        let isStandardBUser = userType == .standard

        let viewModel = ExternalContactSplitViewModel(
            fromEntrance: body.fromEntrance,
            isOversea: isOversea,
            isStandardBUser: isStandardBUser,
            resolver: userResolver
        )
        let vc = ExternalContactSplitController(viewModel: viewModel, resolver: userResolver)
        res.end(resource: vc)
    }
}

/// 外部联系人定向搜索邀请
final class ContactsSearchHandler: UserTypedRouterHandler {

    func handle(_ body: ContactsSearchBody, req: EENavigator.Request, res: Response) throws {
        let chatApplicationAPI = try userResolver.resolve(assert: ChatApplicationAPI.self)
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = ContactSearchViewModel(
            chatApplicationAPI: chatApplicationAPI,
            isOversea: isOversea,
            fromEntrance: body.fromEntrance
        )
        let router = try userResolver.resolve(assert: InviteByContactsSearchRouter.self)
        let vc = try InviteByContactsSearchController(
            viewModel: viewModel,
            router: router,
            inviteMsg: body.inviteMsg,
            uniqueId: body.uniqueId,
            userResolver: userResolver
        )
        res.end(resource: vc)
    }
}

final class AddContactViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: AddContactViewControllerBody, req: EENavigator.Request, res: Response) throws {
        let chatApplicationAPI = try userResolver.resolve(assert: ChatApplicationAPI.self)
        let router = try userResolver.resolve(assert: AddContactViewControllerRouter.self)
        let enableInviteFriends = userResolver.fg.staticFeatureGatingValue(with: "add.contacts.invite")
        let vc = AddContactViewController(
            router: router,
            chatApplicationAPI: chatApplicationAPI,
            enableInviteFriends: enableInviteFriends
        )
        res.end(resource: vc)
    }
}

final class AssociationInviteHandler: UserTypedRouterHandler {

    func handle(_ body: AssociationInviteBody, req: EENavigator.Request, res: Response) throws {
        let router = try userResolver.resolve(assert: CollaborationDepartmentViewControllerRouter.self)
        let vc = AssociationInviteSelectViewController(resolver: userResolver, router: router, associationType: body.contactType)
        let enableInternalAssociationInvite = userResolver.fg.staticFeatureGatingValue(with: "lark.admin.orm.b2b.high_trust_parties")
        if !enableInternalAssociationInvite {
            res.redirect(body: AssociationInviteQRPageBody(source: body.source, contactType: .external))
        } else {
            res.end(resource: vc)
        }
    }
}

final class AssociationInviteQRPageHandler: UserTypedRouterHandler {
    func handle(_ body: AssociationInviteQRPageBody, req: EENavigator.Request, res: Response) throws {
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = AssociationQRCodeViewModel(source: body.source, isOversea: isOversea, resolver: userResolver, contactType: body.contactType)
        let vc = AssociationQRCodeInviteController(viewModel: viewModel, resolver: userResolver)

        res.end(resource: vc)
    }
}

final class OnCallViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: OnCallViewControllerBody, req: EENavigator.Request, res: Response) throws {
        OncallContactsApprecibleTrack.oncallContactsPageLoadTimeStart()
        let userAPI = try userResolver.resolve(assert: UserAPI.self)
        let userId = userResolver.userID
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let oncallAPI = try userResolver.resolve(assert: OncallAPI.self)
        let searchAPI = try userResolver.resolve(assert: SearchAPI.self)
        let fgService = userResolver.fg
        let viewModel = try OnCallViewModel(
            userAPI: userAPI,
            userId: userId,
            chatAPI: chatAPI,
            oncallAPI: oncallAPI,
            searchAPI: searchAPI,
            fgService: fgService,
            resolver: userResolver
        )
        let router = try userResolver.resolve(assert: OnCallViewControllerRouter.self)
        let vc = OnCallViewController(viewModel: viewModel, router: router, showSearch: body.showSearch)
        OncallContactsApprecibleTrack.oncallContactsPageInitViewCostTrack()
        res.end(resource: vc)
    }
}

final class RobotViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: RobotViewControllerBody, req: EENavigator.Request, res: Response) throws {
        let userAPI = try userResolver.resolve(assert: UserAPI.self)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let viewModel = RobotViewModel(userAPI: userAPI, chatAPI: chatAPI)
        let router = try userResolver.resolve(assert: RobotViewControllerRouter.self)
        let vc = RobotViewController(viewModel: viewModel, router: router)
        res.end(resource: vc)
    }
}

final class GroupsViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: GroupsViewControllerBody, req: EENavigator.Request, res: Response) throws {
        MyGroupAppReciableTrack.myGroupPageLoadTimeStart()
        let userAPI = try userResolver.resolve(assert: UserAPI.self)
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let currentTenantId = passportUserService.userTenant.tenantID
        let viewModel = GroupsViewModel(userAPI: userAPI,
                                        currentTenantId: currentTenantId,
                                        chatId: nil,
                                        currentUserType: Account.userTypeFromPassportUserType(passportUserService.user.type))
        let router = try userResolver.resolve(assert: GroupsViewControllerRouter.self)
        let vc = GroupsViewController(
            viewModel: viewModel,
            router: router,
            newGroupBtnHidden: body.newGroupBtnHidden,
            chooseGroupHandler: body.chooseGroupHandler,
            dismissHandler: body.dismissHandler,
            resolver: userResolver
        )
        vc.title = body.title ?? BundleI18n.LarkContact.Lark_Legacy_MyGroup
        MyGroupAppReciableTrack.myGroupPageInitViewCostTrack()
        res.end(resource: vc)
    }
}

final class ContactPickListHandler: UserTypedRouterHandler {

    func handle(_ body: ContactPickListBody, req: EENavigator.Request, res: Response) throws {
        let tracker = PickerAppReciable(pageName: "ContactAddListController", fromType: .addGroupMember)
        tracker.initViewStart()
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = ContactAddListViewModel(isOversea: isOversea,
                                                resolver: userResolver,
                                                isShowBehaviorPush: body.isShowBehaviorPush)
        let vc = ContactAddListController(viewModel: viewModel,
                                          finishCallBack: body.pickFinishCallBack,
                                          appreciableTracker: tracker)
        res.end(resource: vc)
    }
}

final class SetAliasViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: SetAliasViewControllerBody, req: EENavigator.Request, res: Response) throws {
        let vc = SetAliasViewController()
        vc.setConfiguration(
            title: BundleI18n.LarkContact.Lark_Legacy_EditAlias,
            tabTitle: BundleI18n.LarkContact.Lark_Legacy_Save,
            inputText: body.currentAlias,
            tabbarBlock: body.setBlock
        )
        res.end(resource: vc)
    }
}

final class SetInformationViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: SetInformationViewControllerBody, req: EENavigator.Request, res: Response) throws {
        let condition = SetInformationCondition(isBlocked: body.isBlocked,
                                                isSameTenant: body.isSameTenant,
                                                setNumebrEnable: body.setNumebrEnable,
                                                isCanReport: body.isCanReport,
                                                isMe: body.isMe,
                                                isFriend: body.isFriend,
                                                shareInfo: body.shareInfo,
                                                isSpecialFocus: body.isSpecialFocus,
                                                isFromPrivacy: body.isFromPrivacy,
                                                isResigned: body.isResigned,
                                                isShowBlockMenu: body.isShowBlockMenu)

        let setInformationViewModel = SetInformationViewModel(userId: body.userId,
                                                              contactToken: body.contactToken,
                                                              condition: condition,
                                                              aliasAndMemoInfo: body.aliasAndMemoInfo,
                                                              resolver: userResolver) {
            body.dismissCallback?()
        }
        setInformationViewModel.showAddBtn = body.showAddBtn
        setInformationViewModel.pushToAddContactHandler = body.pushToAddContactHandler
        let vc = SetInformationViewController(viewModel: setInformationViewModel, resolver: userResolver)
        res.end(resource: vc)
    }
}

// 邀请外部联系人
final class ExternalInviteSendControllerHandler: UserTypedRouterHandler {

    func handle(_ body: ExternalInviteSendControllerBody, req: EENavigator.Request, res: Response) throws {
        let chatApplicationAPI = try userResolver.resolve(assert: ChatApplicationAPI.self)
        let passportService = try userResolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = ExternalInviteSendViewModel(chatApplicationAPI: chatApplicationAPI,
                                                    sendType: body.type,
                                                    content: body.content,
                                                    countryCode: body.countryCode,
                                                    inviteMsg: body.inviteMsg,
                                                    uniqueId: body.uniqueId,
                                                    isOversea: isOversea)
        let inviteSendVc = ExternalInviteSendController(viewModel: viewModel,
                                                        router: try userResolver.resolve(assert: ExternalInviteSendRouter.self),
                                                        source: body.source,
                                                        sendCompletionHandler: body.sendCompletionHandler)
        res.end(resource: inviteSendVc)
    }
}

// 邀请外部联系人引导页
final class ExternalInviteGuideHandler: UserTypedRouterHandler {

    func handle(_ body: ExternalInviteGuideBody, req: EENavigator.Request, res: Response) throws {
        let dest = ExternalInviteGuideController(fromEntrance: body.fromEntrance)
        dest.closeCallback = body.closeHandler
        res.end(resource: dest)
    }
}

// 部门
final class DepartmentHandler: UserTypedRouterHandler {

    func handle(_ body: DepartmentBody, req: EENavigator.Request, res: Response) throws {
        let userAPI = try userResolver.resolve(assert: UserAPI.self)
        let departmentAPI = DepartmentAPI(userAPI: userAPI)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        let chatterDriver = try userResolver.userPushCenter.driver(for: PushChatters.self)
        let router = try userResolver.resolve(assert: DepartmentViewControllerRouter.self)
        let contactSearchVC = try userResolver.resolve(assert: ContactSearchViewController.self)

        let vc = try DepartmentViewController(
            department: body.department,
            departmentPath: body.departmentPath,
            showNameStyle: body.showNameStyle,
            departmentAPI: departmentAPI,
            chatAPI: chatAPI,
            chatterAPI: chatterAPI,
            chatterDriver: chatterDriver,
            router: router,
            searchVC: contactSearchVC,
            isPublic: body.isPublic,
            showContactsTeamGroup: body.showContactsTeamGroup,
            isFromContactTab: body.isFromContactTab,
            subDepartmentsItems: body.subDepartmentsItems,
            departmentsAdministratorStatus: body.departmentsAdministratorStatus,
            resolver: userResolver
        )

        res.end(resource: vc)
    }
}

// 关联组织
final class CollaborationDepartmentHandler: UserTypedRouterHandler {

    func handle(_ body: CollaborationDepartmentBody, req: EENavigator.Request, res: Response) throws {
        let userAPI = try userResolver.resolve(assert: UserAPI.self)
        let departmentAPI = CollaborationDepartmentAPI(userAPI: userAPI)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        let chatterDriver = try userResolver.userPushCenter.driver(for: PushChatters.self)
        let router = try userResolver.resolve(assert: CollaborationDepartmentViewControllerRouter.self)
        let contactSearchVC: ContactSearchable & UIViewController

        if body.tenantId == nil, body.isFromContactTab {
            contactSearchVC = try createCollaborationSearchViewController(resolver: userResolver, associationContactType: body.associationContactType)
        } else {
            contactSearchVC = try userResolver.resolve(assert: ContactSearchViewController.self)
        }
        let vc = try CollaborationDepartmentViewController(
            tenantId: body.tenantId,
            department: body.department,
            departmentPath: body.departmentPath,
            showNameStyle: body.showNameStyle,
            departmentAPI: departmentAPI,
            chatAPI: chatAPI,
            chatterAPI: chatterAPI,
            chatterDriver: chatterDriver,
            router: router,
            searchVC: contactSearchVC,
            isPublic: body.isPublic,
            showContactsTeamGroup: body.showContactsTeamGroup,
            isFromContactTab: body.isFromContactTab,
            associationContactType: body.associationContactType,
            resolver: userResolver
        )

        res.end(resource: vc)
    }

    func createCollaborationSearchViewController(resolver: UserResolver, associationContactType: AssociationContactType?) throws -> CollaborationSearchViewController {
        let userAPI = try resolver.resolve(assert: UserAPI.self)
        let departmentAPI = CollaborationDepartmentAPI(userAPI: userAPI)
        let vm = CollaborationSearchResultViewModel(departmentAPI: departmentAPI, associationContactType: associationContactType)
        let searchResultViewController = CollaborationSearchResultViewController(vm: vm)
        let chatterDriver = try resolver.userPushCenter.driver(for: PushChatters.self)
        let router = try resolver.resolve(assert: CollaborationSearchViewControllerRouter.self)
        return CollaborationSearchViewController(
            searchResultViewController: searchResultViewController,
            departmentAPI: departmentAPI,
            chatterDriver: chatterDriver,
            router: router,
            associationContactType: associationContactType,
            resolver: resolver
        )
    }
}

// 外部联系人列表
final class ExternalContactsHandler: UserTypedRouterHandler {
    static let logger = Logger.log(ExternalContactsHandler.self, category: "ExternalContactsHandler")

    func handle(_ body: ExternalContactsBody, req: EENavigator.Request, res: Response) throws {
        ExternalContactsAppReciableTrack.externalContactsPageLoadTimeStart(isNewPage: true)
        let enableContactsInteractionOpt = userResolver.fg.staticFeatureGatingValue(with: "contact.external.alphabetic.group")
        let externalVC: UIViewController
        if !enableContactsInteractionOpt {
            // 未分组的外部联系人
            externalVC = try userResolver.resolve(assert: NewExternalContactsViewController.self)
        } else {
            // 分组外部联系人
            externalVC = try userResolver.resolve(assert: GroupedExternalContactsViewController.self)
        }
        ExternalContactsAppReciableTrack.externalContactsPageInitViewCostTrack()
        res.end(resource: externalVC)
    }
}

// 特别关注人列表
final class SpecialFocusListHandler: UserTypedRouterHandler {
    static let logger = Logger.log(SpecialFocusListHandler.self, category: "SpecialFocusListHandler")

    func handle(_ body: SpecialFocusListBody, req: EENavigator.Request, res: Response) throws {
        let vm = SpecialFocusListViewModel(resolver: userResolver)
        let vc = SpecialFocusListViewController(viewModel: vm, resolver: userResolver)
        res.end(resource: vc)
    }
}

// 邀请人
final class InvitationHandler: UserTypedRouterHandler {

    func handle(_ body: InvitationBody, req: EENavigator.Request, res: Response) throws {
        let newVC = try userResolver.resolve(assert: InvitationViewController.self, argument: body.content)
        res.end(resource: newVC)
    }
}

// 选择区号
final class SelectCountryNumberHandler: UserTypedRouterHandler {

    func handle(_ body: SelectCountryNumberBody, req: EENavigator.Request, res: Response) throws {
        let selectCountryNumberViewController = SelectCountryNumberViewController()
        selectCountryNumberViewController.setDatasource(
            hotDatasource: body.hotDatasource,
            allDatasource: body.allDatasource
        ) { [weak selectCountryNumberViewController] (number) in
            body.selectAction?(number)
            selectCountryNumberViewController?.dismiss(animated: true, completion: nil)
        }
        selectCountryNumberViewController.modalPresentationStyle = .overCurrentContext
        res.end(resource: selectCountryNumberViewController)
    }
}

// 添加联系人
final class AddContactRelationControllerHandler: UserTypedRouterHandler {

    func handle(_ body: AddContactRelationBody, req: EENavigator.Request, res: Response) throws {
        let chatApplicationAPI = try userResolver.resolve(assert: ChatApplicationAPI.self)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let pushCenter = try userResolver.userPushCenter
        let vc = try AddFriendsViewController(chatApplicationAPI: chatApplicationAPI,
                                             chatAPI: chatAPI,
                                             resolver: userResolver,
                                             userId: body.userId,
                                             chatId: body.chatId,
                                             token: body.token,
                                             source: body.source,
                                             addContactBlock: body.addContactBlock,
                                             userName: body.userName,
                                             isAuth: body.isAuth,
                                             hasAuth: body.hasAuth,
                                             pushCenter: pushCenter,
                                             businessType: body.businessType,
                                             dissmissBlock: body.dissmissBlock)
        res.end(resource: vc)
    }
}

// 单向联系人多人添加弹窗
final class MAddContactApplicationAlertBodyHandler: UserTypedRouterHandler {
    private let disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(MAddContactApplicationAlertBodyHandler.self,
                                           category: "Module.IM.ChatContact.ApplyCollaborationAlertHandler")

    func handle(_ body: MAddContactApplicationAlertBody, req: EENavigator.Request, res: Response) throws {
        let externalContactsAPI = try userResolver.resolve(assert: ExternalContactsAPI.self)
        let viewModel = MAddContactApplicationViewModel(
            contacts: body.contacts,
            text: body.text,
            showCheckBox: body.showConfirmApplyCheckBox
        )
        let contactIDs = body.contacts.map { $0.ID }
        let alertController = LarkAlertController()
        let alertTitle = body.title ?? BundleI18n.LarkContact.Lark_NewContacts_NeedToAddToContactsDialogTitle
        alertController.setTitle(text: alertTitle)
        let applyCollaborationContentView = ApplyCollaborationContentView()
        // 添加进入非好友列表的事件
        applyCollaborationContentView.showDetailBlock = { [weak alertController, weak self] () in
            let detailAlertController = LarkAlertController()
            let detailContentView = ApplyCollaborationDetailContentView(
                viewModel: ApplyCollaborationDetailViewModel(contacts: viewModel.contacts)
            )
            detailContentView.setDismissBlock { [weak detailAlertController] () in
                detailAlertController?.dismiss(animated: true, completion: nil)
            }
            detailAlertController.setContent(
                view: detailContentView,
                padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            )
            guard let from = alertController, let `self` = self else { return }
            self.userResolver.navigator.present(detailAlertController, from: from)
        }
        applyCollaborationContentView.setupContentView(
            contacts: viewModel.contacts,
            text: viewModel.text,
            showCheckBox: false
        )
        alertController.setContent(
            view: applyCollaborationContentView,
            padding: UIEdgeInsets(top: 13, left: 20, bottom: 22.5, right: 20)
        )
        alertController.addCancelButton(dismissCompletion: body.cancelCallBack)
        // 添加确定按钮
        let buttonTitle = body.sureButtonTitle ?? BundleI18n.LarkContact.Lark_Legacy_Completed
        alertController.addPrimaryButton(text: buttonTitle, dismissCompletion: {
            if let businessType = body.businessType {
                // 打点： authorize_collaboration_request
                Tracer.trackBusinessToAddContactSend(
                    type: businessType,
                    toUserIds: contactIDs
                )
            }
            var hud: UDToast?
            if let window = req.from.fromViewController?.view.window {
                hud = UDToast.showLoading(on: window)
            }
            let postscriptMessage = applyCollaborationContentView.getInputText()
            // 根据chatterIds去请求相应的chatIds
            externalContactsAPI.checkP2PChatsExistByUserRequest(chatterIds: contactIDs)
                .flatMap { (res) -> Observable<MSendContactApplicationResponse> in
                    var sourceInfos = [String: RustPB.Contact_V2_SourceInfo]()
                    contactIDs.forEach { (id) in
                        guard let chatId = res.chatterChatMap[id] else {
                            Self.logger.info("chatId is empty in chatterChatMap, chatterId = \(id)")
                            return
                        }
                        var source = RustPB.Contact_V2_SourceInfo()
                        source.sourceID = chatId
                        source.source = body.dependecy.source ?? .unknownSource
                        sourceInfos[id] = source
                    }
                    // 得到chatIds后去发送好友申请
                    return externalContactsAPI.mSendContactApplicationRequest(userIds: contactIDs,
                                                                              extraMessage: postscriptMessage,
                                                                              sourceInfos: sourceInfos)
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    hud?.remove()
                    body.sureCallBack?(postscriptMessage, true)
                }, onError: { (error) in
                    hud?.remove()
                    if let window = req.from.fromViewController?.view.window {
                        hud?.showFailure(
                            with: BundleI18n.LarkContact.Lark_UserGrowth_InviteTenantToastFailed,
                            on: window,
                            error: error
                        )
                    }
                    MAddContactApplicationAlertBodyHandler.logger.error("show addContact alert error", error: error)
                    body.sureCallBack?(postscriptMessage, false)
                }).disposed(by: self.disposeBag)
        })
        Tracer.trackShowApplyCollaborationAlert(
            source: body.source,
            number: body.contacts.count
        )
        res.end(resource: alertController)
    }
}

// 单向联系人添加好友弹窗
final class AddContactApplicationAlertHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(AddContactApplicationAlertHandler.self, category: "Module.IM.ChatContact.AddContactApplicationAlertHandler")

    func handle(_ body: AddContactApplicationAlertBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        var chatId = body.chatId ?? ""
        if chatId.isEmpty, let id = chatAPI.getLocalChat(by: body.userId)?.id {
            chatId = id
        }
        var source = body.source
        if source.sourceID.isEmpty {
            source.sourceID = chatId
        }
        let alert = LarkAlertController()
        alert.setTitle(text: body.title ?? BundleI18n.LarkContact.Lark_NewContacts_NeedToAddToContactsDialogTitle)
        alert.setContent(text: body.content ?? BundleI18n.LarkContact.Lark_NewContacts_NeedToAddToContactstGroupOneDialogContent(body.displayName))
        alert.addCancelButton(dismissCompletion: body.cancelCallBack)
        alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Add, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            if let from = body.targetVC {
                let addContactBody = AddContactRelationBody(userId: body.userId,
                                                            chatId: chatId,
                                                            token: body.token,
                                                            source: source,
                                                            addContactBlock: body.addContactBlock,
                                                            userName: body.displayName,
                                                            businessType: body.businessType,
                                                            dissmissBlock: body.dissmissBlock)
                self.userResolver.navigator.push(body: addContactBody, from: from)
            }
        })
        res.end(resource: alert)
    }
}
