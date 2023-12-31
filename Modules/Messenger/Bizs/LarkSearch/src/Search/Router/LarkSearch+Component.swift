//
//  File.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/4/20.
//
// LarkSearch对外提供服务的实现。
// 对外提供的服务定义在 LarkContainer 模块的 LarkInterface+Search.swift 中

import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import SuiteAppConfig
import LarkSearchCore
import RustPB
import LarkSegmentedView
import LarkUIKit
import UniverseDesignToast
import LarkSearchFilter
import Accessibility
import LarkOpenFeed
import LarkNavigator
import LarkTab

typealias AppConfig = RustPB.Basic_V1_AppConfig

final class SearchMainHandler: UserTypedRouterHandler {

    func handle(_ body: SearchMainBody, req: EENavigator.Request, res: Response) throws {
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        if let service = searchOuterService,
           let currentRootViewController = service.getCurrentSearchRootVCOnWindow() as? SearchRootViewControllerProtocol {
            currentRootViewController.routTo(tab: .main, query: body.searchText, shouldForceOverwriteQueryIfEmpty: body.shouldForceOverwriteQueryIfEmpty)
            return
        }
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            var entryAction: SearchEntryAction = .pageicon_or_shortcut
            if body.sourceOfSearch == .messageMenu {
                entryAction = .highlight_search
            }
            let model = SearchEnterModel(sourceOfSearchStr: body.sourceOfSearch.rawValue,
                                         initQuery: body.searchText, entryAction: entryAction)
            let body = SearchOnPadJumpBody(searchEnterModel: model)
            res.redirect(body: body)
            return
        }
        let searchSession = SearchSession()
        let searchDependency = try userResolver.resolve(assert: SearchDependency.self)
        let searchRouter: SearchRouter = SearchRouter(userResolver: userResolver, dependency: searchDependency)
        let searchAPI = try userResolver.resolve(assert: SearchAPI.self)
        searchSession.sourceOfSearch = body.sourceOfSearch
        if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) && !AppConfigManager.shared.leanModeIsOn {
            let searchRootContainer = SearchNewRootDependencyContainer(userResolver: userResolver,
                                                                       sourceOfSearch: body.sourceOfSearch,
                                                                       searchSession: searchSession,
                                                                       router: searchRouter,
                                                                       historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                       resolver: resolver,
                                                                       initQuery: body.searchText)
            let searchRootViewController = searchRootContainer.makeSearchRootViewController()
            res.end(resource: searchRootViewController)
        } else {
            let searchNavBar = SearchNaviBar(style: .search)
            let searchRootContainer = SearchRootDependencyContainer(userResolver: userResolver,
                                                                    sourceOfSearch: body.sourceOfSearch,
                                                                    searchSession: searchSession,
                                                                    searchNavBar: searchNavBar,
                                                                    router: searchRouter,
                                                                    historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                    initQuery: body.searchText)
            let searchRootViewController = searchRootContainer.makeSearchRootViewController()
            res.end(resource: searchRootViewController)
        }
    }
}

final class SearchMainJumpHandler: UserTypedRouterHandler {

    func handle(_ body: SearchMainJumpBody, req: EENavigator.Request, res: Response) throws {
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        let targetTab = makeSearchTab(withAction: body.jumpTab, appId: body.appId, tabName: body.searchTabName)
        if let service = searchOuterService,
           let currentRootViewController = service.getCurrentSearchRootVCOnWindow() as? SearchRootViewControllerProtocol {
            currentRootViewController.routTo(tab: targetTab, query: body.searchText, shouldForceOverwriteQueryIfEmpty: body.shouldForceOverwriteQueryIfEmpty)
            return
        }
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            var entryAction: SearchEntryAction = .pageicon_or_shortcut
            if body.sourceOfSearch == .messageMenu {
                entryAction = .highlight_search
            }
            let model = SearchEnterModel(sourceOfSearchStr: body.sourceOfSearch.rawValue,
                                         initQuery: body.searchText,
                                         appLinkSource: body.appLinkSource,
                                         jumpTab: body.jumpTab.rawValue,
                                         appId: body.appId,
                                         searchTabName: body.searchTabName, entryAction: entryAction)
            let body = SearchOnPadJumpBody(searchEnterModel: model)
            res.redirect(body: body)
            return
        }
        let resolver = self.userResolver
        let searchSession = SearchSession()
        let searchRouter: SearchRouter = SearchRouter(userResolver: userResolver, dependency: try userResolver.resolve(assert: SearchDependency.self))
        let searchAPI = try userResolver.resolve(assert: SearchAPI.self)
        searchSession.sourceOfSearch = body.sourceOfSearch
        if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) && !AppConfigManager.shared.leanModeIsOn {
            let searchRootContainer = SearchNewRootDependencyContainer(userResolver: userResolver,
                                                                       sourceOfSearch: body.sourceOfSearch,
                                                                       searchSession: searchSession,
                                                                       router: searchRouter,
                                                                       historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                       resolver: resolver,
                                                                       initQuery: body.searchText,
                                                                       applinkSource: body.appLinkSource,
                                                                       jumpTab: targetTab)
            let searchRootViewController = searchRootContainer.makeSearchRootViewController()
            res.end(resource: searchRootViewController)
        } else {
            let searchNavBar = SearchNaviBar(style: .search)
            let searchRootContainer = SearchRootDependencyContainer(userResolver: userResolver,
                                                                    sourceOfSearch: body.sourceOfSearch,
                                                                    searchSession: searchSession,
                                                                    searchNavBar: searchNavBar,
                                                                    router: searchRouter,
                                                                    historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                    initQuery: body.searchText,
                                                                    applinkSource: body.appLinkSource,
                                                                    jumpTab: targetTab)
            let searchRootViewController = searchRootContainer.makeSearchRootViewController()
            res.end(resource: searchRootViewController)
        }
    }

    private func makeSearchTab(withAction action: SearchSectionAction, appId: String?, tabName: String?) -> SearchTab {
        switch action {
        case .main: return .main
        case .message: return .message
        case .doc: return .doc
        case .app: return .app
        case .contacts: return .chatter
        case .group: return .chat
        case .calendar: return .calendar
        case .oncall: return .oncall
        case .slashCommand, .openSearch:
            if let appId = appId,
               let tabName = tabName {
            return .open(SearchTab.OpenSearch(id: appId, label: tabName, icon: nil, resultType: .customization, filters: []))
            }
            return .main
        default: return .main
        }
    }
}

final class SearchUserCalendarVCHandler: UserTypedRouterHandler {
    func handle(_ body: SearchUserCalendarBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let searchAPI = try resolver.resolve(assert: SearchAPI.self)

        let vc = SearchUserCalendarViewController(userResolver: userResolver,
                                                  searchAPI: searchAPI,
                                                  eventOrganizerId: body.eventOrganizerId,
                                                  doTransfer: body.doTransfer)

        res.end(resource: vc)
    }
}

final class SearchInChatHandler: UserTypedRouterHandler {

    func handle(_ body: SearchInChatBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let searchAPI = try resolver.resolve(assert: SearchAPI.self)
        let messageAPI = try resolver.resolve(assert: MessageAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let searchCache = try resolver.resolve(assert: SearchCache.self)
        let searchInChatRouter = try resolver.resolve(assert: SearchInChatRouter.self)
        let enableMindnote = SearchFeatureGatingKey.docMindNoteFilter.isUserEnabled(userResolver: userResolver)
        let enableBitable = SearchFeatureGatingKey.bitableFilter.isUserEnabled(userResolver: userResolver)

        var searchItemTypes: [SearchInChatType] = [.message]
        searchItemTypes.append(.docWiki)
        searchItemTypes.append(.file)
        searchItemTypes.append(.image)
        searchItemTypes.append(.url)
        var isThreadGroup: Bool?

        if let localChat = chatAPI.getLocalChat(by: body.chatId) {
            isThreadGroup = localChat.chatMode == .threadV2
        }

        let type = convertTypeToSeachInChatType(type: body.type, enableSearchDocWiki: true)
        let vc = SearchInChatContainerViewController(userResolver: resolver,
                                                     chatId: body.chatId,
                                                     chatType: body.chatType,
                                                     isMeetingChat: body.isMeetingChat,
                                                     searchCache: searchCache,
                                                     searchAPI: searchAPI,
                                                     messageAPI: messageAPI,
                                                     chatAPI: chatAPI,
                                                     router: searchInChatRouter,
                                                     enableMindnote: enableMindnote,
                                                     enableBitable: enableBitable,
                                                     searchTypes: searchItemTypes,
                                                     defaultType: type,
                                                     isThreadGroup: isThreadGroup)
        res.end(resource: vc)
    }
}

final class SearchInChatSingleHandler: UserTypedRouterHandler {
    func handle(_ body: SearchInChatSingleBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let searchAPI = try resolver.resolve(assert: SearchAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let searchCache = try resolver.resolve(assert: SearchCache.self)
        let searchInChatRouter = try resolver.resolve(assert: SearchInChatRouter.self)
        let enableMindnote = SearchFeatureGatingKey.docMindNoteFilter.isUserEnabled(userResolver: userResolver)
        let enableBitable = SearchFeatureGatingKey.bitableFilter.isUserEnabled(userResolver: userResolver)
        var isThreadGroup: Bool?

        let type = convertTypeToSeachInChatType(type: body.type, enableSearchDocWiki: true)

        guard let vcConfig = type?.getVCConfig(userResolver: userResolver) else {
            assertionFailure("unsupported type: \(body.type)")
            return
        }
        if let localChat = chatAPI.getLocalChat(by: body.chatId) {
            isThreadGroup = localChat.chatMode == .threadV2
        }
        let vc = SearchInChatViewController(
            userResolver: resolver,
            config: vcConfig,
            chatId: body.chatId,
            chatType: body.chatType,
            searchSession: SearchSession(),
            searchCache: searchCache,
            isSingle: true,
            isMeetingChat: body.isMeetingChat,
            searchAPI: searchAPI,
            chatAPI: chatAPI,
            router: searchInChatRouter,
            enableMindnote: enableMindnote,
            enableBitable: enableBitable,
            isThreadGroup: isThreadGroup
        )
        res.end(resource: vc)
    }
}

final class SearchInThreadHandler: UserTypedRouterHandler {

    func handle(_ body: SearchInThreadBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let searchAPI = try resolver.resolve(assert: SearchAPI.self)
        let messageAPI = try resolver.resolve(assert: MessageAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let searchCache = try resolver.resolve(assert: SearchCache.self)
        let searchInChatRouter = try resolver.resolve(assert: SearchInChatRouter.self)
        let enableMindnote = SearchFeatureGatingKey.docMindNoteFilter.isUserEnabled(userResolver: userResolver)
        let enableBitable = SearchFeatureGatingKey.bitableFilter.isUserEnabled(userResolver: userResolver)
        let enableSearchDocWiki = true

        var searchItemTypes: [SearchInChatType] = [.message]
        if enableSearchDocWiki {
            searchItemTypes.append(.docWiki)
        } else {
            searchItemTypes.append(.doc)
            searchItemTypes.append(.wiki)
        }
        searchItemTypes.append(.wiki)
        searchItemTypes.append(.image)
        searchItemTypes.append(.url)
        let type = convertTypeToSeachInChatType(type: body.type, enableSearchDocWiki: enableSearchDocWiki)
        let vc = SearchInChatContainerViewController(userResolver: resolver,
                                                     chatId: body.chatId,
                                                     chatType: body.chatType,
                                                     isMeetingChat: false,
                                                     searchCache: searchCache,
                                                     searchAPI: searchAPI,
                                                     messageAPI: messageAPI,
                                                     chatAPI: chatAPI,
                                                     router: searchInChatRouter,
                                                     enableMindnote: enableMindnote,
                                                     enableBitable: enableBitable,
                                                     searchTypes: searchItemTypes,
                                                     defaultType: type,
                                                     isThreadGroup: true)
        res.end(resource: vc)
    }
}

final class SearchChatPickerHandler: UserTypedRouterHandler {

    func handle(_ body: SearchChatPickerBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let vc = SearchChatPickerViewController(resolver: resolver,
                                                selectedItems: body.selectedItems,
                                                searchAPI: try resolver.resolve(assert: SearchAPI.self),
                                                feedService: try resolver.resolve(assert: FeedSyncDispatchService.self),
                                                currentAccount: (try resolver.resolve(assert: PassportUserService.self)).user,
                                                pickType: body.pickType)
        vc.didFinishChooseItem = body.didFinishPickChats
        res.end(resource: vc)
    }
}

final class SearchUniversalPickerHandler: UserTypedRouterHandler {
    func handle(_ body: SearchUniversalPickerBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let currentAccount = (try resolver.resolve(assert: PassportUserService.self)).user
        let feedService = try resolver.resolve(assert: FeedSyncDispatchService.self)
        let vc = SearchUniversalPickerViewController(resolver: resolver,
                                                     selectedItems: body.selectedItems,
                                                     currentAccount: currentAccount,
                                                     pickType: body.pickType,
                                                     selectMode: body.selectMode,
                                                     feedService: feedService,
                                                     enableMyAi: body.enableMyAi,
                                                     supportFrozenChat: body.supportFrozenChat)
        vc.didFinishChooseItem = body.didFinishPick
        res.end(resource: vc)
    }
}

final class SearchOnPadJumpHandler: UserTypedRouterHandler {
    func handle(_ body: SearchOnPadJumpBody, req: EENavigator.Request, res: Response) throws {
        guard let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() else { return }
        let navigationSearchEnterBody = NavigationSearchEnterBody(fromTabURL: body.searchEnterModel.fromTabURL,
                                                                  sourceOfSearchStr: body.searchEnterModel.sourceOfSearchStr,
                                                                  initQuery: body.searchEnterModel.initQuery,
                                                                  appLinkSource: body.searchEnterModel.appLinkSource,
                                                                  jumpTab: body.searchEnterModel.jumpTab,
                                                                  appId: body.searchEnterModel.appId,
                                                                  searchTabName: body.searchEnterModel.searchTabName,
                                                                  entryAction: body.searchEnterModel.entryAction.rawValue)
        res.redirect(body: navigationSearchEnterBody)
    }
}

func convertTypeToSeachInChatType(type: MessengerSearchInChatType?, enableSearchDocWiki: Bool = false) -> SearchInChatType? {
    guard let type = type else {
        return nil
    }
    let newType: SearchInChatType
    switch type {
    case .doc:
        newType = enableSearchDocWiki ? .docWiki : .doc
    case .wiki:
        newType = enableSearchDocWiki ? .docWiki : .wiki
    case .url:
        newType = .url
    case .image:
        newType = .image
    case .file:
        newType = .file
    case .message:
        newType = .message
    }
    return newType
}

enum SearchRouterFilterType {
    case normal([SearchFilter])
    case common([SearchFilter.CommonFilter])
}
