//
//  MemberInviteMenuSubModule.swift
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
import LarkOpenChat
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
import LarkSetting

final class MemberInviteMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "ContactInviteMemberMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .inviteMember
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        guard let passportUserService = try? self.context.userResolver.resolve(assert: PassportUserService.self) else {
            return false
        }
        guard let inviteStorageService = try? self.context.userResolver.resolve(assert: InviteStorageService.self) else {
            return false
        }
        let userType = passportUserService.user.type
        let isStandardBUser = userType == .standard
        let isAdmin = inviteStorageService.getInviteInfo(key: InviteStorage.inviteAdministratorAccessKey)
        let inviteMemberEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.member.enable") && isAdmin && isStandardBUser
        return inviteMemberEnable
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func didClick() {
        inviteMember()
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.teamAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.LarkContact.Lark_Invitation_Feed_AddTeamMember,
            type: type
        )
    }

    // 添加团队成员
    func inviteMember() {
        guard let from = context.feedContext.page else { return }
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

    func trackInvitePeopleEntryFeedClick(entry_type: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_ENTRY_FEED_CLICK, params: ["entry_type": entry_type]))
    }
}
