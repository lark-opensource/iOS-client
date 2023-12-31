//
//  TeamCodeInviteViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/26.
//

import Foundation
import LKCommonsLogging
import LarkMessengerInterface
import LKMetric
import LarkFeatureGating
import RxSwift
import LarkContainer

final class TeamCodeInviteViewModel {
    private lazy var memberInviteAPI: MemberInviteAPI = {
        return MemberInviteAPI(resolver: self.userResolver)
    }()
    let router: TeamCodeInviteControllerRouter
    let sourceScenes: MemberInviteSourceScenes
    let teamCodeCopyEnable: Bool
    let isOversea: Bool
    let departments: [String]
    let dependency: UnifiedInvitationDependency

    static private let logger = Logger.log(TeamCodeInviteViewModel.self,
                                           category: "LarkContact.TeamCodeInviteViewModel")

    private let userResolver: UserResolver
    init(dependency: UnifiedInvitationDependency,
         teamCodeCopyEnable: Bool,
         isOversea: Bool,
         departments: [String],
         sourceScenes: MemberInviteSourceScenes,
         router: TeamCodeInviteControllerRouter,
         resolver: UserResolver) {
        self.dependency = dependency
        self.sourceScenes = sourceScenes
        self.teamCodeCopyEnable = teamCodeCopyEnable
        self.isOversea = isOversea
        self.departments = departments
        self.router = router
        self.userResolver = resolver
    }

    func fetchInviteInfo(forceRefresh: Bool = false) -> Observable<InviteAggregationInfo> {
        return memberInviteAPI.fetchInviteAggregationInfo(forceRefresh: forceRefresh, departments: departments)
    }

    func shareContext(tenantName: String, url: String, teamCode: String) -> (title: String, content: String) {
        let title = BundleI18n.LarkContact.Lark_Invitation_InviteViaWeChat_TeamLinkCopied

        let helpURL = dependency.teamCodeUsageHelpCenterURL()
        let content = isOversea ?
            BundleI18n.LarkContact.Lark_Invitation_FeishuCopyToken_LarkDocsAdded(
                tenantName,
                teamCode.replacingOccurrences(of: " ", with: ""),
                helpURL ?? "",
                url
            ) :
            BundleI18n.LarkContact.Lark_AdminUpdate_Descrip_MobileInviteMemberJoin(
                tenantName,
                teamCode.replacingOccurrences(of: " ", with: ""),
                helpURL ?? "",
                url
            )
        return (title: title, content: content)
    }
}
