//
//  FeedEventAssembly.swift
//  LarkFeedEvent
//
//  Created by xiaruzhen on 2022/10/8.
//

import UIKit
import Foundation
import Swinject
import LarkNavigator
import EENavigator
import LarkNavigation
import LarkUIKit
import LarkAssembler
import RxSwift
import RxCocoa
import LarkOpenFeed
import LarkContainer

public final class FeedEventAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(EventListBody.self)
            .factory(cache: true, EventListHandler.init(resolver:))
    }

    @_silgen_name("Lark.Feed.Event.RegisterHeader")
    static public func registEvent() {
        let user = Container.shared.inObjectScope(Event.userScope)
        user.register(EventManager.self) { r -> EventManager in
            return EventManager(resolver: r)
        }

        FeedHeaderFactory.register(type: .event, viewModelBuilder: { (r) -> FeedHeaderItemViewModelProtocol? in
            guard r.fg.staticFeatureGatingValue(with: "core.event.mobile_event") else { return nil }
            let eventManager = try r.resolve(assert: EventManager.self)
            let context = try r.resolve(assert: FeedContextService.self)
            let eventModel = EventFeedHeaderViewModel(eventManager: eventManager, context: context, userResolver: r)
            return eventModel
        }) { viewModel -> UIView? in
            guard let viewModel = viewModel as? EventFeedHeaderViewModel else { return nil }
            return EventFeedHeaderView(viewModel: viewModel)
        }

//        EventFactory.register { (data) -> EventProvider? in
//            return VCEventProvider(data: data)
//        }
    }
}

import LarkSetting
/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
public enum Event {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.feed") // Global
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
