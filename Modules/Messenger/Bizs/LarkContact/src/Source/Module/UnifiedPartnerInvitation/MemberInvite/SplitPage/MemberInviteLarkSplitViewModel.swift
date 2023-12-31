//
//  MemberInviteLarkSplitViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/6/8.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LKCommonsLogging
import LarkLocalizations
import LKMetric
import LarkReleaseConfig
import LarkContainer
import LarkAccountInterface
import LarkFeatureGating

final class MemberInviteLarkSplitViewModel {
    static private let logger = Logger.log(MemberInviteLarkSplitViewModel.self,
                                           category: "LarkContact.MemberInviteLarkSplitViewModel")
    let sourceScenes: MemberInviteSourceScenes
    let router: MemberInviteSplitPageRouter
    let departments: [String]
    let isOversea: Bool
    let dependency: UnifiedInvitationDependency
    let batchInvitePresenter: ContactBatchInvitePresenter
    private let memberInviteAPI: MemberInviteAPI
    private let passportUserService: PassportUserService
    private let userResolver: UserResolver
    var tenantName: String {
        return passportUserService.userTenant.tenantName
    }
    var userName: String {
        return passportUserService.user.localizedName
    }
    var currentTenantIsSimpleB: Bool {
        return passportUserService.user.type == .undefined ||
            passportUserService.user.type == .simple
    }
    var hasEmailInvitation: Bool = false
    var hasPhoneInvitation: Bool = false
    var hasInappInvitation: Bool = false
    var channelContexts: [SplitChannel] = []

    let headerCoverURL: String?

    init(sourceScenes: MemberInviteSourceScenes,
         isOversea: Bool,
         router: MemberInviteSplitPageRouter,
         dependency: UnifiedInvitationDependency,
         departments: [String],
         resolver: UserResolver) throws {
        self.sourceScenes = sourceScenes
        self.isOversea = isOversea
        self.router = router
        self.dependency = dependency
        self.departments = departments
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.memberInviteAPI = MemberInviteAPI(resolver: resolver)
        self.batchInvitePresenter = ContactBatchInvitePresenter(
            isOversea: isOversea,
            departments: departments,
            memberInviteAPI: memberInviteAPI,
            sourceScenes: sourceScenes,
            resolver: userResolver
        )
        self.hasEmailInvitation = userResolver.fg.staticFeatureGatingValue(with: "invite.member.email.enable")
        self.hasPhoneInvitation = true
        self.headerCoverURL = dependency.addEnterpriseMemberPic()
        genSplitChannelsContext()
    }

    func forwordInviteLinkInLark(from: UIViewController,
                                 closeHandler: @escaping () -> Void) {
        memberInviteAPI.forwardInviteLinkInLark(source: sourceScenes,
                                                departments: departments,
                                                router: router,
                                                from: from,
                                                closeHandler: closeHandler)
    }

    private func genSplitChannelsContext() {
        var icons = [Resources.lark_split_link,
                     Resources.lark_split_contact]
        var titles = [BundleI18n.LarkContact.Lark_Invitation_AddMembersTeamLinkInvite,
                      BundleI18n.LarkContact.Lark_Invitation_AddMembersImportContactsNew]
        let subtitles = [BundleI18n.LarkContact.Lark_Invitation_AddMembersTeamLinkDes]
        var channelFlags: [ChannelFlag] = [.nonDirectedLink, .addressbookImport]
        let hasDirectionalEntrance = hasEmailInvitation || hasPhoneInvitation
        if hasDirectionalEntrance {
            icons.insert(Resources.lark_split_form, at: 2)
            if hasEmailInvitation && hasPhoneInvitation {
                titles.insert(BundleI18n.LarkContact.Lark_Invitation_AddMembersInputPhoneorEmail, at: 2)
            } else if hasEmailInvitation {
                titles.insert(BundleI18n.LarkContact.Lark_Invitation_AddMembersInputEmail, at: 2)
            } else {
                titles.insert(BundleI18n.LarkContact.Lark_Invitation_AddMembersInputPhone, at: 2)
            }
            channelFlags.insert(.directed, at: 2)
        }
        /// 添加飞书联系人
        icons.insert(Resources.lark_split_inapp, at: hasDirectionalEntrance ? 3 : 2)
        titles.insert(BundleI18n.LarkContact.Lark_Invitation_AddMembersInviteInLark, at: hasDirectionalEntrance ? 3 : 2)
        channelFlags.insert(.larkInvite, at: hasDirectionalEntrance ? 3 : 2)
        icons.enumerated().forEach { (index, icon) in
            let title = titles[index]
            let subtitle = subtitles.count > index ? subtitles[index] : ""
            let channelFlag = channelFlags[index]
            let context = SplitChannel(icon, title, subtitle, channelFlag)
            channelContexts.append(context)
        }
    }
}
