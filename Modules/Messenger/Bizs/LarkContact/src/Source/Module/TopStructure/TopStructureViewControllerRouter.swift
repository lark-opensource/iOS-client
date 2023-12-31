//
//  TopStructureViewControllerRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/11.
//

import Foundation
import LarkModel
import LarkContainer
import Swinject
import EENavigator
import RxSwift
import LarkUIKit
import LarkNavigator
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkAddressBookSelector
import LarkFeatureGating
import RustPB
import LarkAccountInterface
import LKCommonsLogging

protocol TopStructureViewControllerRouter: AnyObject {
    /// 我的群组
    func didSelectMyGroups(_ vc: TopStructureViewController)
    /// 机器人
    func didSelectBots(_ vc: TopStructureViewController)
    /// 服务台
    func didSelectOnCalls(_ vc: TopStructureViewController)
    /// 新的联系人
    func didSelectContactApplication(_ vc: TopStructureViewController)
    /// 新的联系人-新接口
    func didSelectNewContactApplication(_ vc: TopStructureViewController)
    /// 外部联系人
    func didSelectExternal(_ vc: TopStructureViewController)
    /// 特别关注的人
    func didSelectSpecialFocusList(_ vc: TopStructureViewController)
    /// 组织架构
    func didSelectDepartment(_ vc: TopStructureViewController,
                             department: Department,
                             departmentPath: [Department],
                             subDepartmentsItems: [SubDepartmentItem])

    /// 内部关联组织
    func didSelectInternalCollaboration(_ vc: TopStructureViewController, tenantID: String, department: Department, departmentPath: [Department])

    ///关联组织
    func didSelectCollaborationDepartment(_ vc: TopStructureViewController,
                             department: Department,
                             departmentPath: [Department])
    /// 搜索
    func jumpSearch(_ vc: TopStructureViewController)
    func jumpTeamConversion(navigator: Navigatable)

    /// 名片夹
    func didSelectNameCards(_ vc: TopStructureViewController)

    ///ai助手
    func didSelectMyAI(_ vc: TopStructureViewController)
}

final class TopStructureRouterFactory {
    static func create(with resolver: UserResolver) -> TopStructureViewControllerRouter {
        return TopStructureViewControllerRouterImpl(resolver: resolver)
    }
}

final class TopStructureViewControllerRouterImpl: TopStructureViewControllerRouter, UserResolverWrapper {

    private static let logger = Logger.log(TopStructureViewControllerRouterImpl.self, category: "Contact.TopStructureViewControllerRouterImpl")

    var userResolver: LarkContainer.UserResolver
    let passportService: PassportService?
    @ScopedInjectedLazy private var myAIService: MyAIService?

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.passportService = try? resolver.resolve(assert: PassportService.self)
    }

    func didSelectDepartment(
        _ vc: TopStructureViewController,
        department: Department,
        departmentPath: [Department],
        subDepartmentsItems: [SubDepartmentItem]
    ) {
        let body = DepartmentBody(department: department,
                                  departmentPath: departmentPath,
                                  showNameStyle: ShowNameStyle.nameAndAlias,
                                  showContactsTeamGroup: true,
                                  isFromContactTab: true,
                                  subDepartmentsItems: subDepartmentsItems)
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectInternalCollaboration(
        _ vc: TopStructureViewController,
        tenantID: String,
        department: Department,
        departmentPath: [Department]
    ) {
        let body = CollaborationDepartmentBody(
                                  tenantId: tenantID,
                                  department: department,
                                  departmentPath: departmentPath,
                                  showNameStyle: ShowNameStyle.nameAndAlias,
                                  showContactsTeamGroup: true,
                                  isFromContactTab: true,
                                  associationContactType: .internal)
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectCollaborationDepartment(
        _ vc: TopStructureViewController,
        department: Department,
        departmentPath: [Department]
    ) {
        let body = CollaborationDepartmentBody(
                                  tenantId: nil,
                                  department: department,
                                  departmentPath: departmentPath,
                                  showNameStyle: ShowNameStyle.nameAndAlias,
                                  showContactsTeamGroup: true,
                                  isFromContactTab: true,
                                  associationContactType: .external)
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectMyGroups(_ vc: TopStructureViewController) {
        let body = GroupsViewControllerBody(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup)
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectNameCards(_ vc: TopStructureViewController) {
        let body = NameCardListBody()
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
        NameCardTrack.trackClickNameCard()
    }

    func didSelectSpecialFocusList(_ vc: TopStructureViewController) {
        let body = SpecialFocusListBody()
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectBots(_ vc: TopStructureViewController) {
        navigator.showDetailOrPush(body: RobotViewControllerBody(), wrap: LkNavigationController.self, from: vc)
    }

    func didSelectNewContactApplication(_ vc: TopStructureViewController) {
        guard let userPushCenter = try? userResolver.userPushCenter else { return }
        let dest = AddrBookContactListController(addContactScene: .newContact, resolver: self.userResolver, pushCenter: userPushCenter)
        navigator.push(dest, from: vc)
    }

    func didSelectContactApplication(_ vc: TopStructureViewController) {
        navigator.showDetailOrPush(body: ContactApplicationsBody(), wrap: LkNavigationController.self, from: vc)
    }

    func didSelectExternal(_ vc: TopStructureViewController) {
        let body = ExternalContactsBody()
        navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)
    }

    func didSelectOnCalls(_ vc: TopStructureViewController) {
        navigator.showDetailOrPush(body: OnCallViewControllerBody(showSearch: true), wrap: LkNavigationController.self, from: vc)
    }

    func jumpSearch(_ vc: TopStructureViewController) {
        let body = SearchMainBody(
            topPriorityScene: .rustScene(.searchChatters),
            sourceOfSearch: .contact
        )
        navigator.push(body: body, from: vc)
    }

    func jumpTeamConversion(navigator: Navigatable) {
        guard let nav = navigator.navigation else {
            Self.logger.error("jumpTeamConversion failed nav is nil")
            return
        }
        passportService?.pushToTeamConversion(
            fromNavigation: nav,
            trackPath: "contact_page"
        )
    }

    ///ai助手
    func didSelectMyAI(_ vc: TopStructureViewController) {
        self.myAIService?.openMyAIProfile(from: vc)
    }
}
