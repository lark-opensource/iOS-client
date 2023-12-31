//
//  MemberInviteGuideViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/4/7.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface

final class MemberInviteGuideViewModel: UserResolverWrapper {
    @ScopedProvider private var guideAPI: LDRGuideAPI?
    let router: MemberInviteGuideRouter
    var userResolver: LarkContainer.UserResolver
    let memberInviteAPI: MemberInviteAPI
    let isOversea: Bool
    let inviteType: MemberInviteGuideType
    var prensenter: ContactBatchInvitePresenter
    private let disposeBag = DisposeBag()

    init(router: MemberInviteGuideRouter, inviteType: MemberInviteGuideType, isoversea: Bool, resolver: UserResolver) {
        self.router = router
        self.isOversea = isoversea
        self.inviteType = inviteType
        self.userResolver = resolver
        self.memberInviteAPI = MemberInviteAPI(resolver: resolver)
        prensenter = ContactBatchInvitePresenter(
            isOversea: isOversea,
            departments: [],
            memberInviteAPI: memberInviteAPI,
            sourceScenes: .upgrade,
            resolver: userResolver
        )
    }

    func shareContext(tenantName: String, url: String, teamCode: String) -> (title: String, content: String) {
        let title = BundleI18n.LarkContact.Lark_Invitation_InviteViaWeChat_TeamLinkCopied
        let content = BundleI18n.LarkContact.Lark_Guide_InviteLinkMsg(
            tenantName,
            url
        )
        return (title: title, content: content)
    }

    func reportEndGuide() {
        let event = "new_user_create_team_strong_guide"
        _ = guideAPI?.reportEvent(eventKeyList: [event]).subscribe().disposed(by: disposeBag)
    }
}
