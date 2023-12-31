//
//  LarkSearchAssembly.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/8/10.
//

import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkRustClient
import LarkSearchCore
import LarkAppLinkSDK
import LarkOpenChat
import LarkAssembler
import LarkUIKit
import LarkFeatureGating
import LarkQuickLaunchInterface

public typealias SearchDependency = SearchRouterDependency

public final class SearchAssembly: LarkAssemblyInterface {
    public func registContainer(container: Container) {
        let user = container.inObjectScope(SearchContainer.userScope)
        let userGraph = container.inObjectScope(SearchContainer.userGraph)
        userGraph.register(SearchInChatRouter.self) { (r) -> SearchInChatRouter in
            return SearchInChatRouterImpl(userResolver: r)
        }

        user.register(SearchCache.self) { _ -> SearchCache in
            return SearchCacheImpl()
        }

        user.register(SearchMainTabService.self) { (r) in
            SearchMainTabService(userResolver: r)
        }

        user.register(SearchOuterService.self) { (userResolver) -> SearchOuterService in
            return SearchOuterServiceImpl(userResolver: userResolver)
        }
        user.register(OpenNavigationProtocol.self) { (userResolver) -> OpenNavigationProtocol in
            return SearchNativeAppService(userResolver: userResolver)
        }
    }

    public func registRouter(container: Container) {

        Navigator.shared.registerRoute.type(SearchMainBody.self)
            .factory(SearchMainHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchMainJumpBody.self)
            .factory(SearchMainJumpHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchUserCalendarBody.self)
            .factory(SearchUserCalendarVCHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchInChatBody.self)
            .factory(SearchInChatHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchInChatSingleBody.self)
            .factory(SearchInChatSingleHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchInThreadBody.self)
            .factory(SearchInThreadHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchChatPickerBody.self)
            .factory(SearchChatPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchUniversalPickerBody.self)
            .factory(SearchUniversalPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchGroupChatterPickerBody.self)
            .factory(SearchGroupChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchChatterPickerBody.self)
            .factory(ChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchDateFilterBody.self)
            .factory(SearchDateFilterHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SearchOnPadJumpBody.self).factory(SearchOnPadJumpHandler.init(resolver:))
    }

    public func registLarkAppLink(container: Container) {
        /// 大搜界面
        LarkAppLinkSDK.registerHandler(path: "/client/search/main") { (resp) in
            let userResolver = container.getCurrentUserResolver(compatibleMode: SearchContainer.userScopeCompatibleMode)
            let queryParameters = resp.url.queryParameters
            var queryString = ""
            if let query = queryParameters["query"] {
                queryString = query
            }
            let body = SearchMainBody(searchText: queryString, sourceOfSearch: .todayWidget)
            if let from = resp.context?.from() {
                userResolver.navigator.push(body: body, from: from)
            } else {
                assertionFailure("resp context from nil")
            }
        }

        LarkAppLinkSDK.registerHandler(path: "/client/search/open") { (appLink) in
            let userResolver = container.getCurrentUserResolver(compatibleMode: SearchContainer.userScopeCompatibleMode)
            // 目前只提供跳转综合搜索以及开发搜索
            var queryString: String?
            var appId = ""
            var jumpTab: SearchSectionAction = .main
            var appLinkSource = ""

            if let query = appLink.url.queryParameters["query"] {
                queryString = query
            }
            if let commandId = appLink.url.queryParameters["commandId"] {
                appId = commandId
            }

            if let target = appLink.url.queryParameters["target"],
               let tab = SearchSectionAction(rawValue: target) {
                jumpTab = tab
            }
            if let source = appLink.url.queryParameters["source"] {
                appLinkSource = source
            }
            let title = appLink.url.queryParameters["title"]
            let body = SearchMainJumpBody(searchText: queryString, searchTabName: title, jumpTab: jumpTab, appId: appId, appLinkSource: appLinkSource)

            if let from = appLink.context?.from() {
                if let fromViewController = from.fromViewController as? SearchResultViewController {
                    fromViewController.openSearchTab(appId: appId, tabName: title ?? "")
                } else if Display.pad {
                    userResolver.navigator.present(body: body, from: from)
                } else {
                    userResolver.navigator.push(body: body, from: from)
                }
            } else {
                assertionFailure("resp context from nil")
            }
        }
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        SearchCoreAssembly()
    }

    public init() {}
}

public enum SearchContainer {
    private static var userScopeFG: Bool {
        let v = Container.shared.getCurrentUserResolver().fg.dynamicFeatureGatingValue(with: "ios.container.scope.user.ai")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
