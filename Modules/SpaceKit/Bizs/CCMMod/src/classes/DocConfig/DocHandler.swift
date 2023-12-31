//
//  DocHandler.swift
//  LarkSpaceKit
//
//  Created by maxiao on 2019/4/8.
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
import SKResource

#if MessengerMod
import LarkSearchFilter
import LarkSearchCore
import LarkMessengerInterface
import LarkSDKInterface
#endif

#if TodoMod
import TodoInterface
#endif

import LarkNavigation
import AnimatedTabBar
import SKCommon
import SKDrive
import SKSpace
import SKWikiV2
import SKBrowser
import LarkTab
import SKFoundation
import RustPB
import LarkQuickLaunchInterface
import WebAppContainer

class DocsViewControllerHandler: RouterHandler {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private var isDocsInTab: Bool {
        guard let service = resolver.resolve(NavigationService.self) else { return false }
        return service.checkInTabs(for: Tab.doc)
    }

    private var isWikiInTab: Bool {
        guard let service = resolver.resolve(NavigationService.self) else { return false }
        return service.checkInTabs(for: Tab.wiki)
    }
    
    var pagekeeperService: PageKeeperService? {
        return resolver.resolve(PageKeeperService.self)
    }

    func handle(req: EENavigator.Request, res: Response) {
        var infos = req.parameters["infos"] as? [String: Any] ?? [:]
        infos[ContextKeys.from] = req.context[ContextKeys.from]
        infos[ContextKeys.openType] = req.context[ContextKeys.openType]
        
        //这里取反，fg默认是关闭的
        if !UserScopeNoChangeFG.HZK.openDocAddFromParamDisable {
            //小程序/网络来源，如果有appid，则上传appid，没有则上传网页地址（openDocDesc）
            if let openDocAppId = req.context[RouterDefine.openDocAppId] as? String, !openDocAppId.isEmpty {
                infos[DocsTracker.Params.openDocDesc] = openDocAppId
            } else if let openDocDesc = req.context[DocsTracker.Params.openDocDesc] as? String, !openDocDesc.isEmpty  {
                //这里网页一般给的是url，只取host上传
                if let urlComponent = URLComponents(string: openDocDesc),
                   let host = urlComponent.host, !host.isEmpty {
                    infos[DocsTracker.Params.openDocDesc] = host
                } else { //非url，则直接上传desc
                    infos[DocsTracker.Params.openDocDesc] = openDocDesc
                }
            }
        }
        
        infos[RouterDefine.associateAppUrl] = req.context[RouterDefine.associateAppUrl]
        infos[RouterDefine.associateAppUrlMetaId] = req.context[RouterDefine.associateAppUrlMetaId]
        
        var showTemporary = req.context["showTemporary"] as? Bool ?? true
        if let fromH5 = req.parameters["showTemporary"] as? String, let h5Value = fromH5.boolValue {
            showTemporary = h5Value
        }
        infos[SKEntryBody.fromKey] = req.context[SKEntryBody.fromKey]
        let docUrl = appendDocParameters(url: req.url, parameters: req.parameters)

        let dependency = resolver.resolve(DocsDependency.self)!
        let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
        guard let pathAfterUrl = URLValidator.pathAfterBaseUrl(req.url) else {
            res.end(resource: EmptyResource())
            return
        }
        guard let dest = DocsUrlUtil.jumpDirectionfor(pathAfterUrl) else {

            //先看下是否来自主导航打开，如果是则尝试从缓存池里面取vc
            var vc = self.tryGetCacheVCFromMainNavigation(req: req, docUrl: docUrl)
            if vc == nil {
                vc = docsViewControllerFactory.create(dependency: dependency, url: docUrl, infos: infos)
            }
            
            guard let browser = vc else {
                res.end(resource: EmptyResource())
                return
            }
            let viewController = vc
            if browser is ContinuePushedVC {
                res.end(resource: EmptyResource())
            } else {
                guard let from = req.context.from()?.fromViewController else {
                    res.end(resource: viewController)
                    return
                }
                if let vc = viewController as? TabContainable , showTemporary {
                    let openType = infos[ContextKeys.openType] as? EENavigator.OpenType ?? .none
                    switch openType {
                    case .present:
                        Navigator.shared.showTemporary(vc, other: .present, from: from)
                        res.end(resource: EmptyResource())
                    case .showDetail:
                        Navigator.shared.showTemporary(vc, other: .showDetail, from: from)
                        res.end(resource: EmptyResource())
                    default:
                        Navigator.shared.showTemporary(vc, from: from)
                        res.end(resource: EmptyResource())
                    }
                } else {
                    DocsLogger.info("DocHander: viewController is not  TabContainable or showTemporary is false")
                    res.end(resource: browser)
                }
            }
            return
        }
        if dest.isInDocsTab /* && isDocsInTab */ {
            let docHome = Tab.doc.url.append(fragment: pathAfterUrl)
            guard let from = req.context.from() else { return }
            Navigator.shared.switchTab(docHome, from: from, animated: true)
            res.end(resource: EmptyResource())
        } else if dest == .wikiHome && isWikiInTab {
            let wikiHome = Tab.wiki.url.append(fragment: pathAfterUrl)
            guard let from = req.context.from() else { return }
            Navigator.shared.switchTab(wikiHome, from: from, animated: true)
            res.end(resource: EmptyResource())
        } else if dest == .bitableHome {
            guard let from = req.context.from() else { return }
            let bitableHome = docsViewControllerFactory.createBitableHomeViewController(url: req.url)
            Navigator.shared.push(bitableHome, from: from)
            res.end(resource: EmptyResource())
        } else {
            let browser = docsViewControllerFactory.create(dependency: dependency, url: docUrl, infos: infos)
            if browser is ContinuePushedVC {
                res.end(resource: EmptyResource())
            } else {
                res.end(resource: browser)
            }
            return
        }
    }

    private func appendDocParameters(url: URL, parameters: [String: Any]) -> URL {
        let keys = ["from", "message_type", "chat_type", "ccm_open_type"]
        var param = parameters.filter { keys.contains($0.key) }
        
        //优先级：路由业务自定义from参数 >  路由 from参数 >  url链接里面query from参数
        
        //主导航业务自定义来源
        if UserScopeNoChangeFG.HZK.mainTabbarDisableForceRefresh,
           let value = parameters["launcher_from"] as? String,
           !value.isEmpty {
            param["from"] = value
        } else if !UserScopeNoChangeFG.HZK.openDocAddFromParamDisable, //这里取反，fg默认是关闭的
                  let openDocSoucre = parameters["open_doc_source"] as? String,
                  !openDocSoucre.isEmpty {
            //小程序和网页来源
            param["from"] = openDocSoucre
        }
        
        return url.lf.appendPercentEncodedQuery(param)
    }
    
    private func interceptCCMUrl(infos: [String: Any]) {
        
    }
}

#if MessengerMod
extension BrowserViewController: FeedSelectionInfoProvider {

    public func getFeedIdForSelected() -> String? {
        if let feed_id = self.feedID, !feed_id.isEmpty {
            DocsLogger.info("LarkFeedSelection from CCM: get feedID from self.feedID:\(feed_id)")
            return feed_id
        }
        if let feed_id = self.fileConfig?.feedID, !feed_id.isEmpty {
            DocsLogger.info("LarkFeedSelection from CCM: get feedID from fileConfig.feedID:\(feed_id)")
            return feed_id
        }
        if let feed_id = self.fileConfig?.feedFromInfo?.feedId, !feed_id.isEmpty {
            DocsLogger.info("LarkFeedSelection from CCM: get feedID from feedFromInfo.feedID:\(feed_id)")
            return feed_id
        }
        DocsLogger.info("LarkFeedSelection from CCM: feedID is nil !")
        return nil
    }
}
#endif

#if MessengerMod
class AskOwnerViewControllerHandler: TypedRouterHandler<AskOwnerBody> {
    override func handle(_ body: AskOwnerBody, req: EENavigator.Request, res: Response) {
        let askOwnerVC = AskOwnerForInviteCollaboratorViewController(collaboratorID: body.collaboratorID,
                                                                     ownerName: body.ownerName,
                                                                     ownerID: body.ownerID,
                                                                     docsType: body.docsType,
                                                                     objToken: body.objToken,
                                                                     imageKey: body.imageKey,
                                                                     title: body.title,
                                                                     detail: body.detail,
                                                                     isExternal: body.isExternal,
                                                                     isCrossTenanet: body.isCrossTenanet,
                                                                     roleType: body.roleType)
        if body.needPopover {
            askOwnerVC.modalPresentationStyle = .formSheet
            askOwnerVC.preferredContentSize = CGSize(width: 540, height: askOwnerVC.getPopoverHeight())
            res.end(resource: askOwnerVC)
        } else {
            let nav = LkNavigationController(rootViewController: askOwnerVC)
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            res.end(resource: nav)
        }
    }
}
#endif


class EmbedDocAuthControllerHandler: TypedRouterHandler<EmbedDocAuthControllerBody> {
    override func handle(_ body: EmbedDocAuthControllerBody, req: EENavigator.Request, res: Response) {
        let vc = EmbedDocAuthViewController(body: body)
        res.end(resource: vc)
    }
}


class TabDocsViewControllerHandler: RouterHandler {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(req: EENavigator.Request, res: Response) {
        let dependency = resolver.resolve(DocsDependency.self)!
        let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
        let controller = docsViewControllerFactory
            .createNativeDocsTabController(dependency: dependency)
        res.end(resource: controller)
    }
}

class CreateDocHandler: TypedRouterHandler<CreateDocBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: CreateDocBody, req: EENavigator.Request, res: Response) {
        let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
        var infos = req.parameters["infos"] as? [String: Any] ?? [:]
        infos["showTemporary"] = req.context["showTemporary"]
        docsViewControllerFactory.docs.createDocs(from: req.from.fromViewController, context: infos)
        res.end(resource: EmptyResource())
    }
}

class LarkSearchChatPickerHandler: TypedRouterHandler<LarkSearchChatPickerBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: LarkSearchChatPickerBody, req: EENavigator.Request, res: Response) {
        #if MessengerMod
        guard let selectedItems = body.selectedItems as? [SearchChatPickerItem],
            let didFinishPickChats = body.didFinishPickChats else {
                assertionFailure()
                return
        }
        var body = SearchChatPickerBody()
        body.selectedItems = selectedItems
        body.didFinishPickChats = didFinishPickChats
        res.redirect(body: body)
        #endif
    }
}

class LarkSearchContactPickerHandler: TypedRouterHandler<LarkSearchContactPickerBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: LarkSearchContactPickerBody, req: EENavigator.Request, res: Response) {
        #if MessengerMod
        let didFinishChoosenItems = body.didFinishChoosenItems as (([SearchChatterPickerItem]) -> Void)
        guard let items = body.selectedItems as? [SearchChatterPickerItem] else {
            res.end(error: RouterError.invalidParameters("selectedItems"))
            return
        }
        let chatterAPI = resolver.resolve(ChatterAPI.self)!
        var pickerBody = ChatterPickerBody()
        pickerBody.defaultSelectedChatterIds = items.map { $0.chatterID }
        pickerBody.selectStyle = items.isEmpty ? .singleMultiChangeable : .multi
        pickerBody.title = body.title
        
        pickerBody.allowSelectNone = items.isEmpty ? false : true
        pickerBody.selectedCallback = { (vc, result) in
            guard let vc = vc else { return }
            let chatterIDs = result.chatterInfos.map { $0.ID }
            _ = chatterAPI.getChatters(ids: chatterIDs)
                .observeOn(MainScheduler.instance)
                .takeUntil(vc.rx.deallocated)
                .subscribe(onNext: { (chatterMap) in
                    let chatterItems = chatterIDs
                        .compactMap { chatterMap[$0] }
                        .map { SearchChatterPickerItem.chatter($0) }
                    didFinishChoosenItems(chatterItems)
                    vc.dismiss(animated: true)
                })
        }
        res.redirect(body: pickerBody)
        #endif
    }
}

class DocPushBodyHandler: TypedRouterHandler<DocPushBody> {
    private let resolver: Resolver
    private let disposeBag: DisposeBag = DisposeBag()

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: DocPushBody, req: EENavigator.Request, res: Response) {
        #if MessengerMod
        let docAPI = resolver.resolve(DocAPI.self)!
        let channelID = body.channelID
        docAPI.fetchDocFeeds(feedIds: [channelID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (result) in
                if let docFeed = result[channelID],
                    let url = URL(string: docFeed.docURL) {
                    let docNoticeURL = url.docs.addQuery(parameters: [
                        "sourceType": body.sourceType,
                        "last_doc_message_id": body.lastMessageID,
                        "feed_id": channelID
                    ])
                    res.redirect(docNoticeURL)
                } else {
                    res.end(resource: EmptyResource())
                }
            }, onError: { (error) in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
        #endif
    }

}

class DriveLocalFilePreviewControllerHandler: TypedRouterHandler<DriveLocalFileControllerBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: DriveLocalFileControllerBody, req: EENavigator.Request, res: Response) {
        let previewController = DriveVCFactory.shared.makeDriveLocalPreview(files: body.files, index: body.index)
        res.end(resource: previewController)
    }
}

#if MessengerMod
extension SearchChatPickerItem: LarkSearchChatPickerItemProtocol { }
#endif

#if MessengerMod
extension SearchChatterPickerItem: LarkSearchChatterPickerItemProtocol { }
#endif

class SendDocRouterHandler: TypedRouterHandler<SendDocBody> {
    private let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    override func handle(_ body: SendDocBody, req: EENavigator.Request, res: Response) {
        
#if MessengerMod
        if UserScopeNoChangeFG.HZK.customIconPart {
            //自定义图标走pick组件
            let pickController = createSendDocsPickController(context: body.context,
                                                              sendDocBlock: body.sendDocBlock)
            res.end(resource: pickController)
            return
        }
#endif
        //原来旧的选择页面
        let viewModel = SendDocViewModel(context: body.context,
                                         resolver: resolver,
                                         sendDocBlock: body.sendDocBlock)
        let viewController = SendDocController(viewModel: viewModel)
        res.end(resource: viewController)
        
    }
#if MessengerMod
    private func createSendDocsPickController(context: SendDocBody.Context,
                                      sendDocBlock: @escaping SendDocBlock) -> UIViewController {
        let resolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let userID = resolver.userID
        let delegateProxy = SendDocsPickDelegate(sendDocBlock: sendDocBlock)
        let controller = SearchPickerNavigationController(resolver: resolver)
        // topView 没有内容，目的是为了强持有 delegateProxy，否则 proxy 会因为没有强引用直接析构
        controller.topView = CCMPickerPlaceHolderTopView(proxy: delegateProxy)
        controller.defaultView = PickerRecommendListView(resolver: resolver)
        controller.pickerDelegate = delegateProxy
        
        //配置搜索全部doc文档
        var docConfig = PickerConfig.DocEntityConfig(belongUser: .all,
                                                     belongChat: .all,
                                                     types: Basic_V1_Doc.TypeEnum.allCases,
                                                     folderTokens: [])
        
        
        //配置搜索全部wiki文档
        var wikiConfig =  PickerConfig.WikiEntityConfig(belongUser: .all,
                                                        belongChat: .all,
                                                        types: Basic_V1_Doc.TypeEnum.allCases,
                                                        spaceIds: [])
        
        controller.searchConfig = PickerSearchConfig(entities: [
            docConfig, wikiConfig
        ])
        
        //配置多选设置
        let multiSelectionConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                      isDefaultMulti: true,
                                                                      canSwitchToMulti: true,
                                                                      canSwitchToSingle: false,
                                                                      selectedViewStyle: .label {
            BundleI18n.CCMMod.Lark_Legacy_SelectedCountHint($0)
        })
        //配置导航栏
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: context.title ?? BundleI18n.CCMMod.Lark_Legacy_SendDocTitle,
                                                              sureText: context.confirmText ?? BundleI18n.CCMMod.Lark_Legacy_Send,
                                                              canSelectEmptyResult: true)
        //配置搜索栏
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .imSelectDocs,
                                                       multiSelection: multiSelectionConfig,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        
        return controller
    }
#endif
}

// MARK: - Wiki

class TabWikiViewControllerHandler: RouterHandler {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(req: EENavigator.Request, res: Response) {
        let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
        let controller = docsViewControllerFactory
            .createNativeWikiTabControllerV2(params: req.parameters as [AnyHashable: Any],
                                             navigationBarDependency: WikiHomePageViewController
                                                .NavigationBarDependency(navigationBarHeight: LarkNaviBarConsts.naviHeight,
                                                                         shouldShowCustomNaviBar: false,
                                                                         shouldShowNetworkBanner: true))
        res.end(resource: controller)
    }
}

// MARK: - Base
class TabBaseViewControllerHandler: RouterHandler {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(req: EENavigator.Request, res: Response) {
        if let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self) {
            let controller = docsViewControllerFactory.createNativeBaseTabControllerV2(params: req.parameters as [AnyHashable: Any])
            res.end(resource: controller)
        } else {
            DocsLogger.error("DocsViewControllerFactory not found")
        }
    }
}


class DocsOpenChatHandler: TypedRouterHandler<WAOpenChatBody> {
    init(resolver: Resolver) {
        super.init()
    }
    
    override func handle(_ body: WAOpenChatBody, req: EENavigator.Request, res: Response) {
        gotoChat(chatID: body.chatId, isGroup: false, switchFeedTab: false, from: req.from, res: res)
    }
    
    /// 聊天页面
    func gotoChat(chatID: String, isGroup: Bool, switchFeedTab: Bool, from: NavigatorFrom, res: Response) {
        #if MessengerMod
        DocsLogger.info("gotoChat: \(chatID), isGroup = \(isGroup), switchFeedTab = \(switchFeedTab)")
        if switchFeedTab {
            Navigator.shared.switchTab(Tab.feed.url, from: from, animated: true) {
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chatID, selectionType: .skipSame)
                ]
                Navigator.shared.showDetail(body: ChatControllerByIdBody(chatId: chatID),
                                            context: context, wrap: LkNavigationController.self, from: from)
//                if isGroup {
//                    Navigator.shared.showDetail(body: ChatControllerByIdBody(chatId: chatID),
//                                                context: context, wrap: LkNavigationController.self, from: from)
//                } else {
//                    Navigator.shared.showDetail(body: ChatControllerByChatterIdBody(chatterId: chatID, isCrypto: false),
//                                                context: context, wrap: LkNavigationController.self, from: from)
//                }
            }
        } else {
            Navigator.shared.push(body: ChatControllerByIdBody(chatId: chatID), from: from)
//            if isGroup {
//                Navigator.shared.push(body: ChatControllerByIdBody(chatId: chatID), from: from)
//            } else {
//                Navigator.shared.push(body: ChatControllerByChatterIdBody(chatterId: chatID, isCrypto: false),
//                                      from: from)
//            }
        }
        #endif
    }
}

private extension String {
    var boolValue: Bool? {
        switch self.lowercased() {
        case "true", "t", "yes", "y":
            return true
        case "false", "f", "no", "n":
            return false
        default:
            if let int = Int(self) {
                return int != 0
            }
            return nil
        }
    }
}
