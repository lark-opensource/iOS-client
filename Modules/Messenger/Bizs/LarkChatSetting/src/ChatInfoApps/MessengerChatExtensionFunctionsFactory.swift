//
//  MessengerChatExtensionFunctionsFactory.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/18.
//
import Foundation
import RxSwift
import LarkModel
import LarkBadge
import Swinject
import LarkAccountInterface
import RxRelay
import LarkFeatureGating
import LarkContainer
import LarkSDKInterface
import LarkFeatureSwitch
import LKCommonsLogging
import LarkCore
import EENavigator
import LarkMessengerInterface
import Homeric
import LKCommonsTracker
import LarkAppLinkSDK
import LarkSetting
import UniverseDesignIcon
import LarkMessageCore

final class MessengerChatExtensionFunctionsFactory: NSObject, ChatExtensionFunctionsFactory {
    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }

    let userResolver: LarkContainer.UserResolver

    private let functionsRelay: BehaviorRelay<[ChatExtensionFunction]> = BehaviorRelay<[ChatExtensionFunction]>(value: [])
    private let disposeBag = DisposeBag()
    private var functions: [ChatExtensionFunction] = [] {
        didSet {
            self.functionsRelay.accept(functions)
        }
    }
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy var appLinkService: AppLinkService?
    @ScopedInjectedLazy var pinAPI: PinAPI?
    @ScopedInjectedLazy var threadAPI: ThreadAPI?
    @ScopedInjectedLazy var featureGatingService: FeatureGatingService?
    public var currentChatterId: String {
        return self.userResolver.userID
    }

    func createExtensionFuncs(chatWrapper: ChatPushWrapper,
                              pushCenter: PushNotificationCenter,
                              rootPath: Path) -> Observable<[ChatExtensionFunction]> {
        let chat = chatWrapper.chat.value
        if chat.chatMode == .threadV2 {
            self.fetchChatAndTopicGroup(chat: chat, rootPath: rootPath, pushCenter: pushCenter)
        } else {
            self.createFunctionsForNormalChat(chat: chat, rootPath: rootPath)
            self.fetchCurrentAccountChatChatter(chat: chat, rootPath: rootPath)
            self.pinBadgeObserve(chat: chat, rootPath: rootPath, pushCenter: pushCenter)
        }
        return functionsRelay.asObservable()
    }

    private func createFunctionsForNormalChat(
        chat: Chat,
        rootPath: Path,
        currentAccountChatChatter: Chatter? = nil) {
        var functions: [ChatExtensionFunction] = []
        /// 服务端下发的sidebars放到最前面
        chat.sidebarButtons.forEach { (sidebarButton) in
            let remoteFunc = ChatExtensionFunction(type: .remote,
                                                   title: sidebarButton.i18NName,
                                                   imageInfo: .key(sidebarButton.iconKey)) { [weak self] vc in
                                                    guard let vc, let self else { return }
                                                    if let url = URL(string: sidebarButton.url) {
                                                        /// 先走AppLink逻辑，再走Navigator
                                                        self.appLinkService?.open(url: url, from: .chat, fromControler: vc) { (canOpen) in
                                                            if !canOpen {
                                                                self.userResolver.navigator.push(url, from: vc)
                                                            }
                                                        }
                                                        self.trackSidebarClick(chat: chat, type: .remote)
                                                    }
            }
            functions.append(remoteFunc)
        }
        let announcementFunc = self.announcementFunc(chat: chat, rootPath: rootPath)
        let pinFunc = self.oldPinFunc(chat: chat, rootPath: rootPath)
        if chat.isCrypto {
            self.functions = []
            return
        } else if chat.isOncall, let type = currentAccountChatChatter?.chatExtra?.oncallRole {
            // 如果是服务台则根据不同视角添加侧边栏按钮
            switch type {
            case .oncallHelper, .userHelper, .unknown, .user, .oncall:
                break
            @unknown default:
                break
            }
        } else {
            if chat.type == .group {
                functions.append(announcementFunc)
            }
            if ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
                functions.append(self.pinListFunc(chat: chat))
            } else {
                functions.append(pinFunc)
            }
        }
        self.functions = functions
    }

    private func createFunctionsForThreadChat(chat: Chat, rootPath: Path, topicGroup: TopicGroup, pushCenter: PushNotificationCenter) {
        let isDefaultTopicGroup = topicGroup.isDefaultTopicGroup
        var functions: [ChatExtensionFunction] = []
        if !isDefaultTopicGroup {
            let announcementFunc = self.announcementFunc(chat: chat, rootPath: rootPath)
            functions.append(announcementFunc)
        }

        if !topicGroup.isParticipant {
            let pinFunc = self.oldPinFunc(chat: chat, rootPath: rootPath)
            functions.append(pinFunc)
            self.pinBadgeObserve(chat: chat, rootPath: rootPath, pushCenter: pushCenter)
        }
        self.functions = functions
    }

    private func fetchCurrentAccountChatChatter(chat: Chat,
                                                rootPath: Path) {
        let currentAccountChatterId = self.currentChatterId
        self.chatterAPI?
            .fetchChatChatters(ids: [currentAccountChatterId], chatId: chat.id)
            .observeOn(MainScheduler.instance)
            .map { $0[currentAccountChatterId] }
            .subscribe(onNext: { [weak self] (chatter) in
                self?.createFunctionsForNormalChat(chat: chat, rootPath: rootPath, currentAccountChatChatter: chatter)
            })
            .disposed(by: self.disposeBag)
    }

    private func pinBadgeObserve(chat: Chat, rootPath: Path, pushCenter: PushNotificationCenter) {
        if ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
            return
        }
        let chatId = chat.id
        let pinPath = rootPath.raw(ChatExtensionFunctionType.pin.rawValue)
        self.pinAPI?
            .getPinReadStatus(chatId: chatId).subscribe(onNext: { [weak self] (hasRead) in
                self?.badgeShow(for: pinPath, show: !hasRead)
            }).disposed(by: self.disposeBag)

        pushCenter.observable(for: PushChatPinReadStatus.self)
            .filter({ (push) -> Bool in
                return push.chatId == chatId
            })
            .subscribe(onNext: { [weak self] (push) in
                self?.badgeShow(for: pinPath, show: !push.hasRead)
        }).disposed(by: self.disposeBag)
    }

    private func fetchChatAndTopicGroup(chat: Chat, rootPath: Path, pushCenter: PushNotificationCenter) {
        let chatId = chat.id
        self.threadAPI?.fetchChatAndTopicGroup(
            chatID: chatId,
            forceRemote: false,
            syncUnsubscribeGroups: true
        ).flatMap({ (res) -> Observable<TopicGroup> in
            guard let result = res else {
                let error = NSError(domain: "fetch topicGroup error", code: 0, userInfo: ["chatID": chatId]) as Error
                return .error(error)
            }
            let topicGroup: TopicGroup = result.1 ?? TopicGroup.defaultTopicGroup(id: chatId)
            return .just(topicGroup)
        }).observeOn(MainScheduler.instance)
        .subscribe(onNext: { (topicGroup) in
            self.createFunctionsForThreadChat(chat: chat, rootPath: rootPath, topicGroup: topicGroup, pushCenter: pushCenter)
        }).disposed(by: self.disposeBag)
    }

    private func announcementFunc(chat: Chat, rootPath: Path) -> ChatExtensionFunction {
        let image = Resources.announce_chatExFunc
        let isOwner = currentChatterId == chat.ownerId
        return ChatExtensionFunction(type: .announcement,
                                     title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncement,
                                     imageInfo: .image(image),
                                     badgePath: rootPath.raw(ChatExtensionFunctionType.announcement.rawValue)) { [weak self] vc in
            guard let self = self, let vc = vc else { return }
            if ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
                self.chatAPI?.createAnnouncementChatPin(chatId: Int64(chat.id) ?? 0)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            } else {
                self.chatAPI?.addChatTab(
                    chatId: Int64(chat.id) ?? 0,
                    name: "",
                    type: .chatAnnouncement,
                    jsonPayload: nil
                ).subscribe().disposed(by: self.disposeBag)
            }
            self.trackSidebarClick(chat: chat, type: .announcement)
            NewChatSettingTracker.imChatAnnouncementClick(chat: chat, isAdmin: isOwner)
            if !chat.announcement.docURL.isEmpty {
                ChatSettingTracker.trackClickAnnouncementWithType(chat.type)
            }
            let body = ChatAnnouncementBody(chatId: chat.id)
            self.userResolver.navigator.push(body: body, from: vc)
        }
    }

    private func oldPinFunc(chat: Chat, rootPath: Path) -> ChatExtensionFunction {
        let image = Resources.pin_chatExFunc
        let pinBadgePath = rootPath.raw(ChatExtensionFunctionType.pin.rawValue)
        let isOwner = currentChatterId == chat.ownerId
        return ChatExtensionFunction(type: .pin,
                                     title: BundleI18n.LarkChatSetting.Lark_Pin_PinButton,
                                     imageInfo: .image(image),
                                     badgePath: pinBadgePath) { [weak self] vc in
            guard let vc = vc, let self else { return }
            NewChatSettingTracker.imOldPinClick(chat: chat, isAdmin: isOwner)
            self.trackSidebarClick(chat: chat, type: .pin)
            self.userResolver.navigator.push(body: PinListBody(chatId: chat.id), from: vc)
            self.badgeShow(for: pinBadgePath, show: false)
        }
    }

    private func pinListFunc(chat: Chat) -> ChatExtensionFunction {
        let image = UDIcon.getIconByKey(.pinListFilled, size: CGSize(width: 25, height: 25)).ud.withTintColor(UIColor.ud.turquoise)
        return ChatExtensionFunction(type: .pinCard,
                                     title: BundleI18n.LarkChatSetting.Lark_IM_Pinned_Mobile_Title,
                                     imageInfo: .image(image)) { [weak self] vc in
            guard let vc = vc, let self = self else { return }
            self.userResolver.navigator.push(body: ChatPinCardListBody(chat: chat), from: vc)
            NewChatSettingTracker.imChatPinClick(chat: chat)
        }
    }
}
