//
//  LarkOpenPlatformAssembly.swift
//  Lark
//
//  Created by 赵家琛 on 2020/9/27.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.

import Swinject
import RxSwift
import RxRelay
import LarkOpenPlatform
import LarkModel
import LarkContainer
import LKCommonsLogging
import RustPB
import EENavigator
import LarkMicroApp
import Lynx
import LarkTab
import TTMicroApp
import LarkOPInterface
import LarkDebugExtensionPoint
import LarkShareContainer
import LarkAssembler
import BootManager
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import AnimatedTabBar
import LarkAIInfra
import LarkRustClient

#if MessengerMod
import LarkMessengerInterface
import LarkSendMessage
#endif

#if CCMMod
import SpaceInterface
#endif

public final class LarkOpenPlatformAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        let userGraph = container.inObjectScope(OPUserScope.userGraph)
        userContainer.register(OpenPlatformDependency.self) { (r) -> OpenPlatformDependency in
            return OpenPlatformDependencyImpl(resolver: r)
        }
        container.register(AppReviewService.self) { _ in
            return AppReviewManager()
        }.inObjectScope(.container)
        #if MessengerMod
        userGraph.register(ImPluginForWebProtocol.self) { (r) -> ImPluginForWebProtocol in
            let service = try r.resolve(assert: ChatLinkedPageService.self)
            return ImPluginForWebImp(service: service)
        }
        #endif
        userContainer.register(OPBadgeAPI.self) { (r) -> OPBadgeAPI in
            let rustService = try r.resolve(assert: RustService.self)
            return RustOpenAppBadgeAPI(rustService: rustService)
        }
    }
    #if ALPHA
    public func registDebugItem(container: Container) {
        ({ LynxDebugItem() }, SectionType.debugTool)
    }
    #endif
    public func registLaunch(container: Container) {
        NewBootManager.register(LarkLynxDevtoolTask.self)
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        OpenPlatformAssembly()
    }
}

class OpenPlatformDependencyImpl: OpenPlatformDependency {

    static let logger = Logger.log(OpenPlatformDependency.self)
    
    private let disposeBag = DisposeBag()

    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func getMessageContent(messageIds: [String]) -> Observable<[String: Message]>? {
#if MessengerMod
        let messageContentService = try? resolver.resolve(assert: MessageContentService.self)
        return messageContentService?.getMessageContent(messageIds: messageIds)
#else
        return .just([:])
#endif
    }
    
    func sendShareTextMessage(
        text: String,
        chatContexts: [ShareViaChooseChatMaterial.SelectContext],
        input: RustPB.Basic_V1_RichText?
    ) -> Observable<Void> {
        #if MessengerMod
        let sendMessageAPI = try? resolver.resolve(assert: SendMessageAPI.self)
        let richText = RustPB.Basic_V1_RichText.text(text)
        for chatContext in chatContexts {
            sendMessageAPI?.sendText(
                context: nil,
                content: richText,
                parentMessage: nil,
                chatId: chatContext.chatId,
                threadId: nil,
                stateHandler: nil
            )
            if input == nil {
                continue
            }
            sendMessageAPI?.sendText(
                context: nil,
                content: input!,
                parentMessage: nil,
                chatId: chatContext.chatId,
                threadId: nil,
                stateHandler: nil
            )
        }
        #endif
        return .just(())
    }


    func sendShareAppRichTextCardMessage(
        type: ShareAppCardType,
        chatContexts: [ShareViaChooseChatMaterial.SelectContext],
        input: RustPB.Basic_V1_RichText?
    ) -> Observable<Void> {
        Self.logger.info("send share appcard message", additionalData: [
            "num": "\(chatContexts.count)",
            "hasInput": "\((input != nil) ? true : false)"
        ])
#if MessengerMod
        let sendMessageAPI = try? resolver.resolve(assert: SendMessageAPI.self)
        guard let sendMessageAPI = sendMessageAPI else {
            Self.logger.error("sendMessageAPI is nil")
            return .just(())
        }
        var obserList: [Observable<Void>] = []
        for chatContext in chatContexts {
            let obser: Observable<Void> = sendMessageAPI
                .sendShareAppCardMessage(context: nil, type: type, chatId: chatContext.chatId) ?? .just(())
            obserList.append(obser)
        }

        return Observable.from(obserList).merge().single().do(onNext: { [weak self] in
            Self.logger.info("did send app card, will send input message,hasInput:\(input != nil)")
            guard let self = self, let input = input else { return }
            for chatContext in chatContexts {
                sendMessageAPI.sendText(
                    context: nil,
                    content: input,
                    parentMessage: nil,
                    chatId: chatContext.chatId,
                    threadId: nil,
                    stateHandler: nil
                )
            }
        })
#else
        return .just(())
#endif
    }

    func canOpenDocs(url: String) -> Bool {
#if CCMMod
        let docsAPI = try? resolver.resolve(assert: DocSDKAPI.self)
        return docsAPI?.canOpen(url: url) ?? false
#else
        return false
#endif
    }
    
    func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                enableTitle: Bool,
                                enableAIItem: Bool,
                                quickLaunchBarEventHandler: OPMyAIQuickLaunchBarEventHandler?) -> MyAIQuickLaunchBarInterface? {
#if MessengerMod
        guard let quickLaunchBarservice = try? resolver.resolve(assert: MyAIQuickLaunchBarService.self) else {
            Self.logger.error("MyAIQuickLaunchBarService is nil")
            return nil
        }
        let extraItemClickEvent : ((MyAIQuickLaunchBarExtraItemType) -> Void)? = { extraItemType in
            if let quickLaunchBarEventHandler = quickLaunchBarEventHandler {
                switch extraItemType {
                case MyAIQuickLaunchBarExtraItemType.ai(_):
                    quickLaunchBarEventHandler(OPMyAIQuickLaunchBarExtraItemType.ai)
                case MyAIQuickLaunchBarExtraItemType.more:
                    quickLaunchBarEventHandler(OPMyAIQuickLaunchBarExtraItemType.more)
                @unknown default:
                    break
                }
            }
        }
        // 7.0 版本没上，暂时注释掉了，7.6版本也不通过这个属性传递 aiChatModeConfig，所以继续注释
//        let myAIBusinessInfoProvider :  MyAIChatModeConfigProvider? = {
//            if let aiBusinessInfoProvider = aiBusinessInfoProvider {
//                let publishSubject = PublishSubject<MyAIChatModeConfig?>()
//                aiBusinessInfoProvider({ chatModeConfig in
//                    if let opchatModeConfig = chatModeConfig {
//                        let chatModeConfig :MyAIChatModeConfig = MyAIChatModeConfig(chatId: opchatModeConfig.chatId, aiChatModeId: opchatModeConfig.aiChatModeId, objectId: "", objectType: .SHEET, actionButtons: [], greetingMessageType: .default, appContextDataProvider: nil)
//                        publishSubject.onNext(chatModeConfig)
//                    } else {
//                        publishSubject.onNext(nil)
//                    }
//                })
//                return publishSubject.asObserver()
//            } else {
//                return .just(nil)
//            }
//        }

//        let quickLaunchBar = quickLaunchBarservice.createAIQuickLaunchBar(items: items, enableTitle: enableTitle, enableAIItem: enableAIItem, extraItemClickEvent: extraItemClickEvent, aiBusinessInfoProvider: myAIBusinessInfoProvider)
        let quickLaunchBar = quickLaunchBarservice.createAIQuickLaunchBar(items: items, enableTitle: enableTitle, enableAIItem: enableAIItem, extraItemClickEvent: extraItemClickEvent, aiBusinessInfoProvider: nil)
        return quickLaunchBar
#else
        return nil
#endif
    }
    
    func isQuickLaunchBarEnable() -> Bool {
#if MessengerMod
        guard let quickLaunchBarservice = try? resolver.resolve(assert: MyAIQuickLaunchBarService.self) else {
            Self.logger.error("MyAIQuickLaunchBarService is nil")
            return false
        }
        return quickLaunchBarservice.isQuickLaunchBarEnable
#else
        return false
#endif
    }
    
    func isTemporaryEnabled() -> Bool {
#if MessengerMod
        guard let temporaryTabService = try? resolver.resolve(assert: TemporaryTabService.self) else {
            Self.logger.error("TemporaryTabService is nil")
            return false
        }
        return temporaryTabService.isTemporaryEnabled
#else
        return false
#endif
    }

    func showTabVC(_ vc: UIViewController) {
#if MessengerMod
        guard let temporaryTabService = try? resolver.resolve(assert: TemporaryTabService.self), let tabContainable = vc as? TabContainable else {
            Self.logger.error("TemporaryTabService is nil")
            return
        }
        return temporaryTabService.showTab(tabContainable)
#else
#endif
    }
    
    func updateTabVC(_ vc: UIViewController) {
#if MessengerMod
        guard let temporaryTabService = try? resolver.resolve(assert: TemporaryTabService.self), let tabContainable = vc as? TabContainable else {
            Self.logger.error("TemporaryTabService is nil")
            return
        }
        return temporaryTabService.updateTab(tabContainable)
#else
#endif
    }
    
//    func getTabVCBy(id: String) -> TabContainable?
    func removeTabVC(_ vc: UIViewController) {
#if MessengerMod
        guard let temporaryTabService = try? resolver.resolve(assert: TemporaryTabService.self), let tabContainable = vc as? TabContainable else {
            Self.logger.error("TemporaryTabService is nil")
            return
        }
        Self.logger.error("removeTabVC: \(tabContainable.tabContainableIdentifier)")
        return temporaryTabService.removeTab(id: tabContainable.tabContainableIdentifier)
#else
#endif
    }
}

#if MessengerMod
class ImPluginForWebImp: ImPluginForWebProtocol {
    private let service: ChatLinkedPageService

    init(service: ChatLinkedPageService) {
        self.service = service
    }

    func createBarItems(for url: URL, on vc: UIViewController, with completion: @escaping (BusinessBarItemsForWeb) -> Void) {
        service.createBarItems(
            for: url,
            on: vc,
            with: { barItem in
                completion(barItem.transform())
            }
        )
    }

    func destroyBarItems() {
        service.destroyBarItems()
    }
}

extension ChatLinkedPageBarItemsForWeb {
    func transform() -> BusinessBarItemsForWeb {
        return BusinessBarItemsForWeb(
            url: url,
            navigationBarItem: navigationBarItem,
            launchBarItem: launchBarItem,
            extraMap: extraMap
        )
    }
}
#endif
