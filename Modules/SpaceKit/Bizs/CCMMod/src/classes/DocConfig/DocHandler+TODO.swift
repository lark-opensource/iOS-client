//
//  DocHandler+TODO.swift
//  CCMMod
//
//  Created by lijuyou on 2023/8/9.
//

import Foundation
import UIKit
import LarkContainer
import LarkModel
import Swinject
import RxSwift
import RxCocoa
import LarkUIKit
import LarkRustClient
import EENavigator
import SpaceKit
import SpaceInterface
#if MessengerMod
import LarkSearchFilter
import LarkSearchCore
import LarkMessengerInterface
import LarkSDKInterface
#endif
#if TodoMod
import TodoInterface
#endif

// MARK: - Assignee
class LarkShowTaskAssigneeHandler: TypedRouterHandler<LarkShowTaskAssigneeBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: LarkShowTaskAssigneeBody, req: EENavigator.Request, res: Response) {
        #if TodoMod
        var todoBody = TodoUserBody()
        todoBody.param = body.params
        todoBody.callback = body.finishHandler
        res.redirect(body: todoBody)
        return
        #endif
    }
}

class LarkSearchAssigneePickerHandler: TypedRouterHandler<LarkSearchAssigneePickerBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: LarkSearchAssigneePickerBody, req: EENavigator.Request, res: Response) {
        #if MessengerMod
        let didFinishChoosenItems = body.didFinishChoosenItems as (([LarkSearchAssigneePickerItem]) -> Void)
        let items = body.selectedItems
        var pickerBody = ChatterPickerBody()
        pickerBody.defaultSelectedChatterIds = items.map { $0.id }
        pickerBody.title = body.title
        pickerBody.source = .todo(ChatterPickerSource.TodoInfo(chatId: nil, isAssignee: false))
        pickerBody.supportCustomTitleView = true
        pickerBody.allowDisplaySureNumber = false
        pickerBody.needSearchOuterTenant = true
        pickerBody.selectedCallback = { (vc, result) in
            guard let vc = vc else { return }
            let assignees = result.chatterInfos.map { LarkSearchAssigneePickerItem(id: $0.ID, name: $0.name) }
            didFinishChoosenItems(assignees)
            vc.dismiss(animated: true)
        }
        res.redirect(body: pickerBody)
        #endif
    }
}

class LarkShowCreateTaskHandler: TypedRouterHandler<LarkShowCreateTaskBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: LarkShowCreateTaskBody, req: EENavigator.Request, res: Response) {
        #if TodoMod
        let body = CreateTaskFromDocBody(param: body.params, callback: body.finishHandler)
        res.redirect(body: body)
        return
        #endif
    }
}
