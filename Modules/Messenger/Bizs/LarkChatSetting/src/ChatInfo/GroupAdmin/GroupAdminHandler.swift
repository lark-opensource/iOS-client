//
//  GroupAdminHandler.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/4/23.
//

import Foundation
import LarkMessengerInterface
import LKCommonsTracker
import LarkSDKInterface
import EENavigator
import LarkModel
import Swinject
import RxSwift
import Homeric
import LarkNavigator

final class GroupAdminHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupAdminBody, req: EENavigator.Request, res: Response) throws {
        let vm = GroupAdminViewModel(resolver: self.userResolver,
                                     chat: body.chat,
                                     title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminsTitle,
                                     initDisplayMode: body.isShowMulti ? .multiselect : .display,
                                     defaultUnableSelectedIds: body.defaultUnableSelectedIds,
                                     pushChatAdmin: try userResolver.userPushCenter.observable(for: PushChatAdmin.self))
        let vc = GroupAdminViewController(viewModel: vm)
        res.end(resource: vc)
    }
}
