//
//  RedPacketCoverDetailHandler.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/9.
//

import Swinject
import Foundation
import EENavigator
import LarkMessengerInterface
import LarkNavigator

// 红包封面详情
final class RedPacketCoverDetailHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketCoverDetailBody, req: EENavigator.Request, res: Response) throws {
        let vm = RedPacketCoverDetailViewModel(tapCoverId: body.tapCoverId,
                                               confirmHandler: body.confirmHandler,
                                               pushCenter: try userResolver.userPushCenter,
                                               coverIdToThemeTypeMap: body.coverIdToThemeTypeMap,
                                               datas: body.covers.map { RedPacketCoverDetailCellModel(cover: $0, isDefaultCover: $0 == body.covers.first) })
        let vc = RedPacketCoverDetailController(viewModel: vm, userResolver: userResolver)
        res.end(resource: vc)
    }
}
