//
//  MemberNoDirectionalViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

import Foundation
import Swinject
import RxSwift
import LKCommonsLogging
import LarkMessengerInterface
import LKMetric

final class MemberNoDirectionalViewModel {
    let router: MemberInviteNoDirectionalControllerRouter
    let sourceScenes: MemberInviteSourceScenes
    let isOversea: Bool
    let displayPriority: MemberNoDirectionalDisplayPriority
    let departments: [String]
    let dependency: UnifiedInvitationDependency

    static private let logger = Logger.log(MemberNoDirectionalViewModel.self, category: "LarkContact.MemberNoDirectionalViewModel")

    init(dependency: UnifiedInvitationDependency,
         isOversea: Bool,
         departments: [String],
         sourceScenes: MemberInviteSourceScenes,
         priority: MemberNoDirectionalDisplayPriority,
         router: MemberInviteNoDirectionalControllerRouter) {
        self.dependency = dependency
        self.sourceScenes = sourceScenes
        self.isOversea = isOversea
        self.departments = departments
        self.displayPriority = priority
        self.router = router
    }

    func shareContext(tenantName: String, url: String, teamCode: String) -> (title: String, content: String) {
        let title = BundleI18n.LarkContact.Lark_Invitation_InviteViaWeChat_TeamLinkCopied
        let content: String
        if isOversea {
            content = BundleI18n.LarkContact.Lark_Invitation_FeishuCopyToken(
                tenantName,
                url,
                teamCode.replacingOccurrences(of: " ", with: "")
            )
        } else {
            content = BundleI18n.LarkContact.Lark_AdminUpdate_Link_MobileJoinOrgContactAdminDetail(
                tenantName,
                url,
                teamCode.replacingOccurrences(of: " ", with: "")
            )
        }
        return (title: title, content: content)
    }
}
