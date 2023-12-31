//
//  SearchGroupChatterPickerHandler.swift
//  LarkSearch
//
//  Created by kongkaikai on 2019/5/8.
//

import Foundation
import EENavigator
import LarkCore
import LarkModel
import LKCommonsLogging
import RxCocoa
import RxSwift
import Swinject
import UIKit
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkNavigator

final class SearchGroupChatterPickerHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { SearchContainer.userScopeCompatibleMode }
    func handle(_ body: SearchGroupChatterPickerBody, req _: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        guard !body.chatId.isEmpty,
              let chat = (try? resolver.resolve(assert: ChatAPI.self))?.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let viewModel = try ChatChatterControllerVM(
            userResolver: resolver,
            chat: chat,
            isOwnerSelectable: true)

        viewModel.defaultSelectedIds = body.selectedChatterIds
        let controller = SearchGroupChatterPicker(viewModel: viewModel,
                                                  forceMultiSelect: body.forceMultiSelect)

        controller.onConfirmSelected = body.confirm
        controller.onCancel = body.cancel
        controller.title = body.title

        res.end(resource: controller)

    }
}
