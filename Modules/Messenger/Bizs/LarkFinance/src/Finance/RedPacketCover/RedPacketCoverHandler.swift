//
//  RedPacketCoverHandler.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/9.
//

import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

// 红包封面
final class RedPacketCoverHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketCoverBody, req: EENavigator.Request, res: Response) throws {
        let redPacketAPI = try userResolver.resolve(assert: RedPacketAPI.self)
        let vm = RedPacketCoverViewModel(selectedCoverId: body.selectedCoverId) {
            return redPacketAPI.pullHongbaoCoverListRequest()
        }
        let vc = RedPacketCoverController(viewModel: vm, userResolver: userResolver)
        res.end(resource: vc)
    }
}
