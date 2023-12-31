//
//  SearchRouter.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/8/10.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkModel
import LarkCore
import EENavigator
import LKCommonsLogging
import LarkContainer
import Swinject
import LarkSDKInterface
import LarkMessengerInterface
import LarkKASDKAssemble
import LarkOpenFeed
import LarkSearchFilter
import LarkSearchCore

extension Navigatable {
    func pushOrShowDetail<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any]? = nil,
        wrap: UINavigationController.Type? = LkNavigationController.self,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            showDetail(body: body,
                       naviParams: naviParams,
                       context: context ?? [String: Any](),
                       wrap: wrap,
                       from: from,
                       completion: completion)
        } else {
            push(body: body,
                 naviParams: naviParams,
                 from: from,
                 animated: animated,
                 completion: completion)
        }
    }

    func pushOrShowDetail(_ url: URL,
                          context: [String: Any] = [:],
                          wrap: UINavigationController.Type? = LkNavigationController.self,
                          from: UIViewController,
                          animated: Bool = true,
                          completion: Handler? = nil) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            showDetail(url,
                       context: context,
                       wrap: wrap,
                       from: from,
                       completion: completion)
        } else {
            push(url,
                context: context,
                from: from,
                animated: animated,
                completion: completion)
        }
    }
}

public protocol SearchRouterDependency {
    func pushCalendarEventDetail(eventKey: String,
                                 calendarId: String,
                                 originalTime: Int64,
                                 startTime: Int64,
                                 endTime: Int64,
                                 from: UIViewController)
    func showDetailCalendarEventDetail(eventKey: String,
                                       calendarId: String,
                                       originalTime: Int64,
                                       startTime: Int64,
                                       endTime: Int64,
                                       from: UIViewController)
    func eventChildViewController(searchNavBar: SearchNaviBar) -> SearchContentContainer
    func getEmailSearchViewController(searchNavBar: SearchNaviBar) -> SearchContentContainer
    func hasEmailService() -> Bool
    func isConversationModeEnable() -> Bool
    func getAllCalendarsForSearchBiz(isNeedSelectedState: Bool) -> Observable<[MainSearchCalendarItem]>
}

final class SearchRouter: UserResolverWrapper {
    static let log = Logger.log(SearchRouter.self, category: "Search.router")
    private let dependency: SearchRouterDependency
    private let disposeBag = DisposeBag()
    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()
    private lazy var specificSource: SpecificSourceFromWhere? = {
        var source: SpecificSourceFromWhere?
        if let searchOuterService = searchOuterService, searchOuterService.enableSearchiPadSpliteMode() {
            source = .searchResultMessage
        }
        return source
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver, dependency: SearchRouterDependency) {
        self.userResolver = userResolver
        self.dependency = dependency
    }

    func gotoConcatPicker(with items: [SearchChatterPickerItem], fromVC: UIViewController,
                          didFinishChoosenItems: @escaping ([SearchChatterPickerItem]) -> Void) {
        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else { return }

        var body = ChatterPickerBody()
        body.defaultSelectedChatterIds = items.map { $0.chatterID }
        body.selectStyle = items.isEmpty ? .singleMultiChangeable : .multi
        body.title = BundleI18n.LarkSearch.Lark_Legacy_SelectLark
        body.allowSelectNone = items.isEmpty ? false : true
        body.selectedCallback = { [weak self] (vc, result) in
            guard let `self` = self else { return }
            let chatterIDs = result.chatterInfos.map { $0.ID }
            chatterAPI.getChatters(ids: chatterIDs)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (chatterMap) in
                    let chatterItems = chatterIDs
                        .compactMap { chatterMap[$0] }
                        .map { SearchChatterPickerItem.chatter($0) }
                    didFinishChoosenItems(chatterItems)
                    vc?.dismiss(animated: true, completion: nil)
                })
                .disposed(by: self.disposeBag)
        }
        navigator.present(body: body, from: fromVC, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func gotoChat(withChat chat: Chat, showNormalBack: Bool = false, fromVC: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            let body = ChatControllerByChatBody(
                chat: chat,
                fromWhere: .search,
                showNormalBack: showNormalBack
            )
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            self?.navigator.pushOrShowDetail(body: body, context: context, from: fromVC) { (_, res) in
                if let err = res.error {
                    SearchRouter.log.error("[LarkSerch] search result jump to chat error",
                                           additionalData: ["chatID": chat.id],
                                           error: err)
                } else {
                    SearchRouter.log.info("[LarkSerch] search result jump to chat success",
                                          additionalData: ["chatID": chat.id])
                }
            }
        }
    }

    func gotoChat(withChat chat: Chat, position: Int32, fromVC: UIViewController) {
        let body = ChatControllerByChatBody(
            chat: chat, position: position,
            fromWhere: .search,
            specificSource: specificSource
        )
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
        ]
        navigator.pushOrShowDetail(body: body, context: context, from: fromVC) { (_, res) in
            if let err = res.error {
                SearchRouter.log.error("[LarkSerch] search result jump to chat error",
                                       additionalData: ["chatID": chat.id, "position": "\(position)"],
                                       error: err)
            } else {
                SearchRouter.log.info("[LarkSerch] search result jump to chat success",
                                      additionalData: ["chatID": chat.id, "position": "\(position)"])
            }
        }
    }

    func gotoThreadDetail(withThreadId id: String, position: Int32, fromVC: UIViewController) {
        let body = ThreadDetailByIDBody(threadId: id, loadType: .position, position: position, specificSource: specificSource)
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: id, selectionType: .skipSame)
        ]
        navigator.pushOrShowDetail(body: body, context: context, from: fromVC) { (_, res) in
        if let err = res.error {
            SearchRouter.log.error("[LarkSerch] search result jump to thread detail error",
                                   additionalData: ["threadID": id, "position": "\(position)"],
                                   error: err)
        } else {
            SearchRouter.log.info("[LarkSerch] search result jump to thread detail success",
                                  additionalData: ["threadID": id, "position": "\(position)"])
            }
        }
    }

    func gotoChat(chatterID: String, chatId: String, fromVC: UIViewController, onError: ((Error) -> Void)?, onCompleted: (() -> Void)?) {
        let body = ChatControllerByChatterIdBody(
            chatterId: chatterID,
            fromWhere: .search,
            isCrypto: false
        )
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: chatId, selectionType: .skipSame)
        ]
        navigator.pushOrShowDetail(body: body, context: context, from: fromVC) { (_, res) in
            if let err = res.error {
                SearchRouter.log.error("[LarkSerch] search result jump to chatter chat error",
                                       additionalData: ["chatterID": chatterID, "chatID": chatId],
                                       error: err)
                onError?(err)
            } else {
                SearchRouter.log.info("[LarkSerch] search result jump to chatter chat success",
                                       additionalData: ["chatterID": chatterID, "chatID": chatId])
                onCompleted?()
            }
        }
    }

    func gotoReplyInThreadDetail(threadId: String, threadPosition: Int32, fromVC: UIViewController) {
        let body = ReplyInThreadByIDBody(threadId: threadId,
                                         loadType: .position,
                                         position: threadPosition,
                                         sourceType: .search,
                                         specificSource: specificSource)
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: threadId, selectionType: .skipSame)
        ]
        navigator.pushOrShowDetail(body: body, context: context, from: fromVC) { (_, res) in
            if let err = res.error {
                SearchRouter.log.error("[LarkSerch] search result jump to reply thread detail error",
                                       additionalData: ["threadPosition": "\(threadPosition)",
                                                        "threadId": threadId],
                                       error: err)
            } else {
                SearchRouter.log.info("[LarkSerch] search result jump to reply thread detail success",
                                       additionalData: ["threadPosition": "\(threadPosition)",
                                                       "threadId": threadId])
            }
        }
    }

    func gotoPersonCardWith(chatterID: String, fromVC: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, fromWhere: .search)
        if Display.phone {
            navigator.push(body: body, from: fromVC) { (_, res) in
                if let err = res.error {
                    SearchRouter.log.error("[LarkSerch] search result jump to personal card error",
                                           additionalData: ["chatterID": chatterID],
                                           error: err)
                } else {
                    SearchRouter.log.info("[LarkSerch] search result jump to personal card success",
                                           additionalData: ["chatterID": chatterID])
                }
            }
        } else {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self, from: fromVC,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                }) { (_, res) in
                    if let err = res.error {
                        SearchRouter.log.error("[LarkSerch] search result present personal card error",
                                               additionalData: ["chatterID": chatterID],
                                               error: err)
                    } else {
                        SearchRouter.log.info("[LarkSerch] search result present personal card success",
                                               additionalData: ["chatterID": chatterID])
                    }
            }
        }
    }

    func gotoMyAI(fromVC: UIViewController) {
        let myAIService = try? userResolver.resolve(type: MyAIService.self)
        myAIService?.openMyAIChat(from: fromVC)
    }

    func gotoMyAIProfile(fromVC: UIViewController) {
        let myAIService = try? userResolver.resolve(type: MyAIService.self)
        myAIService?.openMyAIProfile(from: fromVC)
    }

    func gotoDocs(withURL url: URL?, infos: [String: String]?, feedId: String = "", fromVC: UIViewController) {
        guard let url = url else {
            SearchRouter.log.error("[LarkSearch]: search result jump to doc fail because docsurl is empty")
            return
        }
        navigator.pushOrShowDetail(url, context: [
            "infos": infos ?? [:],
            FeedSelection.contextKey: FeedSelection(feedId: feedId, selectionType: .skipSame),
            "from": "docs_search_default"
        ], from: fromVC) { (_, res) in
            if let err = res.error {
                SearchRouter.log.error("[LarkSerch] search result jump to doc error",
                                       additionalData: ["feedId": feedId],
                                       error: err)
            } else {
                SearchRouter.log.info("[LarkSerch] search result jump to doc success",
                                       additionalData: ["feedId": feedId])
            }
        }
    }

    func gotoChatBox(chatBoxId: String, from: UIViewController) {
        navigator.push(body: ChatBoxBody(chatBoxId: chatBoxId), from: from) { (_, res) in
            if let err = res.error {
                SearchRouter.log.error("[LarkSerch] search result jump to chat box error",
                                       additionalData: ["chatBoxId": chatBoxId],
                                       error: err)
            } else {
                SearchRouter.log.info("[LarkSerch] search result jump to chat box success",
                                       additionalData: ["chatBoxId": chatBoxId])
            }
        }
    }

    @ScopedInjectedLazy var messageAPI: MessageAPI?
    func pushFileBrowserViewController(chatId: String,
                                       messageId: String,
                                       fromVC: UIViewController) {
        messageAPI?.fetchMessage(id: messageId).observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (message) in
            guard let `self` = self,
                  let fileContent = message.content as? FileContent else { return }
            let body = MessageFileBrowseBody(messageId: messageId, scene: .search)
            self.navigator.pushOrShowDetail(body: body, from: fromVC) { (_, res) in
                if let err = res.error {
                    SearchRouter.log.error("[LarkSerch] search result jump to file browser error",
                                           additionalData: ["chatID": chatId, "messageId": messageId], error: err)
                } else {
                    SearchRouter.log.info("[LarkSerch] search result jump to file browser success",
                                          additionalData: ["chatID": chatId, "messageId": messageId])
                }
            }
        }).disposed(by: disposeBag)
    }

    func gotoCalendarDetail(eventKey: String,
                            calendarId: String,
                            originalTime: Int64,
                            startTime: Int64,
                            endTime: Int64,
                            from: UIViewController) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            dependency.showDetailCalendarEventDetail(eventKey: eventKey,
                                                     calendarId: calendarId,
                                                     originalTime: originalTime,
                                                     startTime: startTime,
                                                     endTime: endTime,
                                                     from: from)
        } else {
            dependency.pushCalendarEventDetail(eventKey: eventKey,
                                               calendarId: calendarId,
                                               originalTime: originalTime,
                                               startTime: startTime,
                                               endTime: endTime,
                                               from: from)
        }
    }
}
