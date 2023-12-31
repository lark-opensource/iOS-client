//
//  UnifiedInvitationService.swift
//  LarkMessengerInterface
//
//  Created by shizhengyu on 2020/1/9.
//

import UIKit
import Foundation
import RxSwift

public enum ExternalDependencyBodyResource {
    case memberFeishuSplit(_ body: MemberInviteSplitBody)
    case memberLarkSplit(_ body: MemberInviteLarkSplitBody)
    case memberDirected(_ body: MemberDirectedInviteBody)
}

public enum InviteEntryType {
    case union, member, external, none
}

public protocol UnifiedInvitationService {
    func dynamicMemberInvitePageResource(baseView: UIView?,
                                         sourceScenes: MemberInviteSourceScenes,
                                         departments: [String]) -> Observable<ExternalDependencyBodyResource>
    func handleInviteEntryRoute(routeHandler: @escaping (InviteEntryType) -> Void)
    func hasExternalContactInviteEntry() -> Bool
}
