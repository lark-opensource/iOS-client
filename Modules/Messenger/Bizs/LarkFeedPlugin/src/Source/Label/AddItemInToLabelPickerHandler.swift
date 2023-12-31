//
//  AddItemInToLabelPickerHandler.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2022/4/26.
//

import Foundation
import LarkOpenFeed
import LarkContainer
import Swinject
import EENavigator
import RustPB
import LarkFeed
import LarkNavigator

final class AddItemInToLabelPickerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: AddItemInToLabelPickerBody, req: EENavigator.Request, res: Response) throws {
        let vc = try LabelAddItemPickerController(
            resolver: userResolver,
            labelId: body.labelId,
            disabledSelectedIds: body.disabledSelectedIds)
        res.end(resource: vc)
    }
}
