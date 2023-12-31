//
//  ExternalInviteMenuSubModule.swift
//  LarkContact
//
//  Created by liuxianyu on 2023/1/4.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessengerInterface
import LarkAccountInterface
import LarkOpenFeed
import LarkOpenIM
import LarkContainer
import LarkNavigator
import LarkFeatureGating
import RxSwift
import EENavigator
import UniverseDesignIcon
import LarkKAFeatureSwitch
import Homeric
import LKCommonsTracker

final class ExternalInviteMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "ExternalInviteMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .inviteExternal
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        let enableAddContact = self.context.userResolver.fg.staticFeatureGatingValue(with: "suite_to_c_enable")
        if enableAddContact {
            trackReferTenantEnterView(rewardNewTenant: 0)
        }
        return enableAddContact
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    private func trackReferTenantEnterView(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.REFER_TENANT_ENTER_VIEW, params: ["reward_new_tenant": rewardNewTenant]))
    }

    public override func didClick() {
        self.trackInviteExternalInFeedMenu()
        presentInviteContactsController()
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        guard let passportUserService = try? self.context.userResolver.resolve(assert: PassportUserService.self) else {
            return nil
        }
        let userType = passportUserService.user.type
        let isStandardBUser = userType == .standard
        let inviteUnionEnable = self.context.userResolver.fg.staticFeatureGatingValue(with: "invite.union.enable")
        let inviteExternalEnable = self.context.userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
        var title = ""
        if !inviteUnionEnable || !inviteExternalEnable {
            title = BundleI18n.LarkContact.Lark_Legacy_AddContact
        } else {
            self.trackInvitePeopleEntryFeedView()
            title = isStandardBUser ?
            BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
            BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
        }
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: title,
            type: type
        )
    }

    // 添加外部联系人
    func presentInviteContactsController() {
        guard let from = context.feedContext.page else { return }
        let unionEntryHandler = { [weak self] in
            guard let self = self else { return }
            self.trackInvitePeopleEntryFeedClick(entry_type: "union")
            let navigator = self.context.userResolver.navigator
            if Display.pad {
                navigator.present(
                    body: UnifiedInvitationBody(),
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                navigator.push(body: UnifiedInvitationBody(), from: from)
            }
        }
        let memberEntryHandler = { [weak self] in
            self?.inviteMember(from: from)
        }
        let externalEntryHandler = { [weak self] in
            guard let self = self else { return }
            self.trackInvitePeopleEntryFeedClick(entry_type: "external")
            let body = ExternalContactDynamicBody(scenes: .externalInvite, fromEntrance: .feedMenu)
            if Display.pad {
                self.context.userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                self.context.userResolver.navigator.push(body: body, from: from)
            }
        }
        let invitationService = try? context.resolver.resolve(assert: UnifiedInvitationService.self)
        invitationService?.handleInviteEntryRoute(routeHandler: { (routeType) in
            switch routeType {
            case .union: unionEntryHandler()
            case .external: externalEntryHandler()
            case .member: memberEntryHandler()
            case .none: externalEntryHandler()
            }
        })
    }

    // 添加团队成员
    func inviteMember(from: UIViewController) {
        self.trackInvitePeopleEntryFeedClick(entry_type: "internal")
        let invitationService = try? context.resolver.resolve(assert: UnifiedInvitationService.self)
        invitationService?.dynamicMemberInvitePageResource(
            baseView: from.view,
            sourceScenes: .feedMenu,
            departments: [])
        .subscribe(onNext: { [weak from] (resource) in
            guard let from = from else { return }
            let navigator = self.context.userResolver.navigator
            switch resource {
            case .memberFeishuSplit(let body):
                if Display.pad {
                    navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    navigator.push(body: body, from: from)
                }
            case .memberLarkSplit(let body):
                if Display.pad {
                    navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    navigator.push(body: body, from: from)
                }
            case .memberDirected(let body):
                if Display.pad {
                    navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    navigator.push(body: body, from: from)
                }
            }
        }).disposed(by: context.dispose)
    }

    // 点击 feed 流搜索旁 + 号→点击「添加外部联系人」
    func trackInviteExternalInFeedMenu() {
        guard let passportUserService = try? self.context.userResolver.resolve(assert: PassportUserService.self) else {
            return
        }
        guard let inviteStorageService = try? self.context.userResolver.resolve(assert: InviteStorageService.self) else {
            return
        }
        let userType = passportUserService.user.type
        let isStandardBUser = userType == .standard
        let isAdmin = inviteStorageService.getInviteInfo(key: InviteStorage.isAdministratorKey)
        let inviteMemberEnable = self.context.userResolver.fg.staticFeatureGatingValue(with: "invite.member.enable") && isAdmin && isStandardBUser
        // 0: 个人用户, 1: 团队成员, 2: 租户管理员
        var user: Int = 0
        if isStandardBUser {
            let isTenantManager = inviteMemberEnable
            user = isTenantManager ? 2 : 1
        }
        Tracker.post(TeaEvent(Homeric.ADD_PEOPLE_ENTRY_FEED_EXTERNAL_CLICK, params: ["ug_user_type": user]))
    }

    /// 邀请人_+入口点击
    /// entry_type: union=统一入口，internal = 直接跳转成员页，external = 直接跳转外部联系人页
    func trackInvitePeopleEntryFeedClick(entry_type: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_ENTRY_FEED_CLICK, params: ["entry_type": entry_type]))
    }

    /// 邀请人_+入口展示
    func trackInvitePeopleEntryFeedView() {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_ENTRY_FEED_VIEW))
    }
}
