////
////  MicroAppChatExtensionFunctionsFactory.swift
////  LarkChatSetting
////
////  Created by zc09v on 2020/5/18.
////
//import RxSwift
//import LarkModel
//import LarkBadge
//import Swinject
//import RxRelay
//import LarkFeatureGating
//import LarkContainer
//import LarkSDKInterface
//import LarkFeatureSwitch
//import LKCommonsLogging
//import LarkCore
//import EENavigator
//
//class MicroAppChatExtensionFunctionsFactory: NSObject, ChatExtensionFunctionsFactory {
//    private let functionsRelay: BehaviorRelay<[ChatExtensionFunction]> = BehaviorRelay<[ChatExtensionFunction]>(value: [])
//    private let disposeBag = DisposeBag()
//    private static let logger = Logger.log(MicroAppChatExtensionFunctionsFactory.self, category: "ChatExtensionFunctionsFactory")
//    private var functions: [ChatExtensionFunction] = [] {
//        didSet {
//            self.functionsRelay.accept(functions)
//        }
//    }
//
//    @ScopedInjectedLazy var chatAPI: ChatAPI?
//
//    func createExtensionFuncs(chatWrapper: ChatPushWrapper,
//                              pushCenter: PushNotificationCenter,
//                              rootPath: Path) -> Observable<[ChatExtensionFunction]> {
//        let chat = chatWrapper.chat.value
//        guard chat.chatMode != .threadV2, userResolver.fg.staticFeatureGatingValue(with: .init(key: .feedOpenAppV2)) else {
//            return .just([])
//        }
//        self.chatAPI.fetchOpenAppFeed(id: chat.id, type: .chatID)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] (openAppFeed) in
//                Feature.on(.openAppFeed).apply(on: {
//                    if let result = openAppFeed {
//                        self?.fireMiniAppSidebarState(openAppFeed: result, chat: chat, rootPath: rootPath)
//                    }
//                }, off: {})
//                self?.trackOpenAppFeed(message: "fetchOpenAppFeed", openAppFeed: openAppFeed)
//            }).disposed(by: self.disposeBag)
//
//        Feature.on(.openAppFeed).apply(on: { [weak self] in
//            guard let self = self else { return }
//            pushCenter.observable(for: PushOpenAppFeed.self)
//                .filter({ (push) -> Bool in
//                    return push.openAppFeed.chatID == chat.id
//                })
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] (push) in
//                    self?.fireMiniAppSidebarState(openAppFeed: push.openAppFeed, chat: chat, rootPath: rootPath)
//                    self?.trackOpenAppFeed(message: "pushOpenAppFeedDriver", openAppFeed: push.openAppFeed)
//            }).disposed(by: self.disposeBag)
//        }, off: {})
//        return functionsRelay.asObservable()
//    }
//
//    private func fireMiniAppSidebarState(openAppFeed: OpenAppFeed, chat: Chat, rootPath: Path) {
//        let badgePath = rootPath.raw(ChatExtensionFunctionType.miniApp.rawValue)
//        self.createFunction(openAppFeed: openAppFeed, chat: chat, path: badgePath)
//        let showBadge = (openAppFeed.appNotificationUnreadCount > 0)
//        self.badgeShow(for: badgePath, show: showBadge, type: .label(.number(1)))
//    }
//
//    private func createFunction(openAppFeed: OpenAppFeed, chat: Chat, path: Path) {
//        guard openAppFeed.hasAppID, openAppFeed.miniAppActive else {
//            functions = []
//            return
//        }
//        let avatarKey = chat.avatarKey
//        let function = ChatExtensionFunction(type: .miniApp,
//                                             title: chat.displayName,
//                                             imageInfo: .key(avatarKey),
//                                             badgePath: path) { vc in
//                                                guard let vc = vc else {
//                                                    return
//                                                }
//                                                if let url = URL(string: openAppFeed.appNotificationSchema) {
//                                                    let feedInfo = ["appID": openAppFeed.feedID,
//                                                                    "seqID": openAppFeed.lastNotificationSeqID]
//                                                    let routerContext: [String: Any] = ["from": "bot",
//                                                                                        "feedInfo": feedInfo
//                                                    ]
//                                                    userResolver.navigator.push(url, context: routerContext, from: vc, animated: true)
//                                                    MicroAppChatExtensionFunctionsFactory.trackSidebarClick(chat: chat, type: .miniApp)
//                                                }
//        }
//        self.functions = [function]
//    }
//
//    private func trackOpenAppFeed(message: String, openAppFeed: OpenAppFeed?) {
//        guard let result = openAppFeed else {
//            MicroAppChatExtensionFunctionsFactory.logger.info(message, additionalData: ["openAppFeed": "nil"])
//            return
//        }
//        MicroAppChatExtensionFunctionsFactory.logger.info(message,
//                                                         additionalData: ["unReadCount": "\(result.appNotificationUnreadCount)",
//                                                            "feedId": result.feedID,
//                                                            "seqId": result.lastNotificationSeqID,
//                                                            "appId": result.appID,
//                                                            "miniAppActive": "\(result.miniAppActive)"])
//    }
//}
