//
//  ChatterPickerHandler.swift
//  LarkSearch
//
//  Created by qihongye on 2019/7/25.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class ChatterPickerHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { SearchContainer.userScopeCompatibleMode }
    func handle(_ body: SearchChatterPickerBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        guard !body.chatID.isEmpty,
              let chat = (try? resolver.resolve(assert: ChatAPI.self))?.getLocalChat(by: body.chatID),
              let passportService = try? resolver.resolve(assert: PassportUserService.self) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }

        let viewModel = ChatterPickerViewModel(
            chat: chat,
            tenantID: passportService.userTenant.tenantID,
            currentChatterID: passportService.user.userID,
            pickInChatterIDs: body.chatterIDs,
            searchEnabled: (body.searchEnabled && !body.isPopup),
            showChatChatters: body.showChatChatters,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
            serverNTPTimeService: try resolver.resolve(assert: ServerNTPTimeService.self),
            currentUserType: passportService.user.type,
            navibarTitle: body.navibarTitle,
            preSelectIDs: body.preSelectIDs
        )
        let controller = ChatterPickerViewController(viewModel: viewModel, isMulti: body.isMulti, isPopup: body.isPopup)
        controller.confirmSelect = {
            body.selectChatterCallback?($0)
        }
        res.end(resource: controller)
    }
}
