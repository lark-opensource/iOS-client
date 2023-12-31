//
//  EventListBody.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import Foundation
import RustPB
import LarkModel
import EENavigator
import LarkSDKInterface
import Swinject
import LarkMessengerInterface
import LarkNavigator

public struct EventListBody: PlainBody {
    public static let pattern: String = "//client/im/event/list"
    public init() {}
}

final class EventListHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Event.userScopeCompatibleMode }

    func handle(_ body: EventListBody, req: EENavigator.Request, res: Response) throws {
        let eventManager = try userResolver.resolve(assert: EventManager.self)
        let viewModel = EventListViewModel(eventManager: eventManager)
        let vc = EventListViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
