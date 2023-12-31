//
//  FoldMessageDetailHander.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/27.
//

import Foundation
import UIKit
import EENavigator
import LarkContainer
import LarkMessengerInterface
import LarkNavigator

final class FoldMessageDetailHander: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: FoldMessageDetailBody, req: EENavigator.Request, res: Response) throws {
        let vm = try FoldMessagesDetailInfoViewModel(userResolver: userResolver,
                                                 content: body.richText,
                                                 chat: body.chat,
                                                 message: body.message,
                                                 atColor: body.atColor)
        let vc = FoldMessagesDetailInfoViewController(viewModel: vm)
        res.end(resource: vc)
    }
}
