//
//  ChatLinkedPageService.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/10/20.
//

import Foundation
import LarkQuickLaunchInterface
import LarkUIKit
import LarkContainer
import LarkModel
import LKCommonsLogging
import RxSwift
import LarkAccountInterface
import LarkRustClient
import LarkSetting
import RustPB
import RxCocoa
import LarkSDKInterface
import LarkCore
import UniverseDesignBadge
import UniverseDesignIcon
import UniverseDesignToast
import LarkMessengerInterface
import LarkBadge
import SuiteAppConfig

/// 群插件按钮状态
enum ChatLinkedPageBarStatus: Equatable, CustomStringConvertible {
    case none /// 不展示按钮
    case unknown(Error?) /// 获取关联关系失败，不展示按钮
    case createGroup /// 创建群组
    case associateChat(chatID: String) /// 关联了一个群，但是 chat 实体没有拿到
    case joinGroup(chatID: String) /// 加入群组
    case inGroup(chat: Chat) /// 打开群组

    var chatID: String? {
        switch self {
        case .none, .createGroup, .unknown:
            return nil
        case .associateChat(chatID: let chatID), .joinGroup(chatID: let chatID):
            return chatID
        case .inGroup(chat: let chat):
            return chat.id
        }
    }

    static func == (lhs: ChatLinkedPageBarStatus, rhs: ChatLinkedPageBarStatus) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.unknown, .unknown):
            return true
        case (.createGroup, .createGroup):
            return true
        case let (.associateChat(chatID1), .associateChat(chatID2)):
            return chatID1 == chatID2
        case let (.joinGroup(chatID1), .joinGroup(chatID2)):
            return chatID1 == chatID2
        case let (.inGroup(chat1), .inGroup(chat2)):
            return chat1.id == chat2.id && chat1.badge == chat2.badge
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .none:
            return "none"
        case .unknown:
            return "unknown"
        case .createGroup:
            return "createGroup"
        case .associateChat(chatID: let chatID):
            return "associateChat \(chatID)"
        case .joinGroup(chatID: let chatID):
            return "joinGroup \(chatID)"
        case .inGroup(chat: let chat):
            return "inGroup \(chat.id) \(chat.badge)"

        }
    }
}

enum GetChatPluginInfoResult: CustomStringConvertible {
    case notVisible /// 不支持关联
    case referenceNotExist /// 支持关联，没有找到关联 chat
    case chatId(String) /// 找到关联 chat
    case error(Error?) /// 接口失败

    var description: String {
        switch self {
        case .notVisible:
            return "notVisible"
        case .referenceNotExist:
            return "referenceNotExist"
        case .chatId(let chatID):
            return "chatID: \(chatID)"
        case .error:
            return "error"
        }
    }
}

public class ImPluginForWebImp: ChatLinkedPageService {

    private let logger = Logger.log(ImPluginForWebImp.self, category: "Module.IM.ChatLinkedPages")
    private let logID: String = "\(Date().timeIntervalSince1970)"
    private let userResolver: UserResolver
    private let client: RustService
    private var disposeBag = DisposeBag()
    private var pushDisposeBag = DisposeBag()
    private let scheduler: ImmediateSchedulerType = SerialDispatchQueueScheduler(internalSerialQueueName:
        "ChatLinkedPages.scheduler")
    private var url: URL?
    private var urlMetaID: Int?
    private weak var targetVC: UIViewController?
    private var completion: ((ChatLinkedPageBarItemsForWeb) -> Void)?

    private var statusPublishSubject = PublishSubject<ChatLinkedPageBarStatus>()
    private lazy var statusDriver: Driver<ChatLinkedPageBarStatus> = {
        return statusPublishSubject.asDriver(onErrorJustReturn: .none)
    }()

    private var chatAPI: ChatAPI? {
        return try? self.userResolver.resolve(assert: ChatAPI.self)
    }

    private var subscribeService: SubscribeChatEventService? {
        return try? self.userResolver.resolve(assert: SubscribeChatEventService.self)
    }

    public init(client: RustService, userResolver: UserResolver) {
        self.client = client
        self.userResolver = userResolver
    }

    private var currentChatID: String?
    private var currentBarStatus: ChatLinkedPageBarStatus = .none
    @discardableResult
    private func updateBarStatus(_ newBarStatus: ChatLinkedPageBarStatus) -> Bool {
        self.logger.info("ImPluginForWebImp \(logID) updateBarStatus currentBarStatus: \(currentBarStatus) newBarStatus: \(newBarStatus)")
        if currentBarStatus != newBarStatus {
            if currentBarStatus.chatID != newBarStatus.chatID {
                pushDisposeBag = DisposeBag()
                if let oldChatID = currentBarStatus.chatID {
                    self.currentChatID = nil
                    subscribeService?.decreaseSubscriber(chatID: oldChatID)
                }
                if let newChatID = newBarStatus.chatID {
                    self.currentChatID = newChatID
                    subscribeService?.increaseSubscriber(chatID: newChatID)
                    observeChat(newChatID)
                }
            }

            if let url = self.url {
                switch newBarStatus {
                case .createGroup:
                    if currentBarStatus != .createGroup {
                        IMTracker.Chat.ChatLinkPage.View(nil, url: url, barType: .createGroup, urlMetaID: urlMetaID)
                    }
                case .joinGroup(let newChatID):
                    switch currentBarStatus {
                    case .joinGroup(let currentChatID):
                        if currentChatID != newChatID {
                            IMTracker.Chat.ChatLinkPage.View(newChatID, url: url, barType: .joinGroup, urlMetaID: urlMetaID)
                        }
                    default:
                        IMTracker.Chat.ChatLinkPage.View(newChatID, url: url, barType: .joinGroup, urlMetaID: urlMetaID)
                    }
                case .inGroup(let newChat):
                    switch currentBarStatus {
                    case .inGroup(let currentChat):
                        if currentChat.id != newChat.id {
                            IMTracker.Chat.ChatLinkPage.View(newChat.id, url: url, barType: .openGroup, urlMetaID: urlMetaID)
                        }
                    default:
                        IMTracker.Chat.ChatLinkPage.View(newChat.id, url: url, barType: .openGroup, urlMetaID: urlMetaID)
                    }
                default:
                    break
                }
            }

            if let url = self.url {
                let barItem = transformToBarItem(status: newBarStatus, url: url)
                completion?(barItem)
            }
            currentBarStatus = newBarStatus
            return true
        } else {
            return false
        }
    }

    deinit {
        if let currentChatID = self.currentChatID {
            subscribeService?.decreaseSubscriber(chatID: currentChatID)
        }
    }

    public func createBarItems(for url: URL, on vc: UIViewController, with completion: @escaping (ChatLinkedPageBarItemsForWeb) -> Void) {
        guard !AppConfigManager.shared.leanModeIsOn else {
            return
        }
        guard self.userResolver.fg.staticFeatureGatingValue(with: "messenger.chat_plugin.whitelist") else {
            return
        }

        self.url = url
        self.targetVC = vc
        self.completion = completion

        self.logger.info("ImPluginForWebImp \(logID) createBarItems begin getChatPluginInfo")
        self.getBarStatus()
            .drive(onNext: { [weak self] barStatus in
                guard let self = self else { return }
                self.logger.info("ImPluginForWebImp \(self.logID) createBarItems barStatus: \(barStatus)")
                self.updateBarStatus(barStatus)
            }).disposed(by: disposeBag)
    }

    /// 判断群插件展示状态
    private func getBarStatus() -> Driver<ChatLinkedPageBarStatus> {
        guard let url = self.url else { return .just(.none) }
        let logID = self.logID
        return self.getChatPluginInfo(url.absoluteString)
            .catchError { [weak self] error -> Observable<GetChatPluginInfoResult> in
                self?.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo request error", error: error)
                return .just(.error(error))
            }
            .observeOn(scheduler: MainScheduler.instance)
            .flatMap { [weak self] info -> Observable<ChatLinkedPageBarStatus> in
                guard let self = self,
                      let chatAPI = self.chatAPI else { return .just(.none) }
                switch info {
                case .error(let error):
                    return .just(.unknown(error))
                case .notVisible:
                    return .just(.none)
                case .referenceNotExist:
                    return .just(.createGroup)
                case .chatId(let chatID):
                    return chatAPI.fetchChat(by: chatID, forceRemote: false)
                        .map { [weak self] chat -> ChatLinkedPageBarStatus in
                            guard let self = self else { return .associateChat(chatID: chatID) }
                            if let chat = chat {
                                return self.handleChatModel(chat)
                            } else {
                                return .associateChat(chatID: chatID)
                            }
                        }.catchErrorJustReturn(.associateChat(chatID: chatID))
                }
            }.asDriver(onErrorJustReturn: .none)
    }

    /// 获取关联关系
    private func getChatPluginInfo(_ url: String) -> Observable<GetChatPluginInfoResult> {

        func getSessionHeader() -> [String: String]? {
            guard let sessionKey = try? userResolver.resolve(assert: PassportUserService.self).user.sessionKey else {
                return nil
            }
            var header: [String: String] = [:]
            let sessionStr = "session=" + sessionKey
            header["Cookie"] = sessionStr
            return header
        }

        guard let domain = DomainSettingManager.shared.currentSetting[DomainKey.docsApi]?.first else {
            self.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo can not get domain")
            return .just(.error(nil))
        }
        guard let header = getSessionHeader() else {
            self.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo can not get sessionHeader")
            return .just(.error(nil))
        }
        var httpRequest = Basic_V1_SendHttpRequest()
        httpRequest.headers = header
        httpRequest.url = "https://" + domain + "/space/api/plugins?app_url=\(url)&type=1"
        httpRequest.method = .get
        let logID = self.logID
        return client.sendAsyncRequest(httpRequest, transform: { (res: RustPB.Basic_V1_SendHttpResponse) -> GetChatPluginInfoResult in
            switch res.status {
            case .normal:
                guard let json = try? JSONSerialization.jsonObject(with: res.body, options: []) as? [String: Any] else {
                    self.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo res parse error json serialization")
                    return .error(nil)
                }
                if let dataDic = json["data"] as? [String: Any],
                   let pluginsInfo = dataDic["plugins_info"] as? [String: Any],
                   let chatPluginInfo = pluginsInfo["chat_plugin"] as? [String: Any] {
                    self.urlMetaID = pluginsInfo["url_meta_id"] as? Int
                    let visible = (chatPluginInfo["visible"] as? Bool) ?? false
                    let referenceExist = (chatPluginInfo["reference_exist"] as? Bool) ?? false
                    let chatID = (chatPluginInfo["chat_list"] as? [String])?.first
                    if visible {
                        if referenceExist, let chatID = chatID {
                            self.logger.info("ImPluginForWebImp \(logID) getChatPluginInfo json parse referenceExist chatID: \(chatID)")
                            return .chatId(chatID)
                        } else {
                            self.logger.info("ImPluginForWebImp \(logID) getChatPluginInfo json parse referenceNotExist")
                            return .referenceNotExist
                        }
                    } else {
                        self.logger.info("ImPluginForWebImp \(logID) getChatPluginInfo json parse notVisible")
                        return .notVisible
                    }
                } else {
                    self.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo res parse error json key")
                    return .error(nil)
                }
            default:
                self.logger.error("ImPluginForWebImp \(logID) getChatPluginInfo res parse res status")
                return .error(nil)
            }
        }).subscribeOn(scheduler)
    }

    private func observeChat(_ chatID: String) {
        let pushCenter = try? self.userResolver.userPushCenter

        pushCenter?
            .observable(for: PushChat.self)
            .observeOn(scheduler: MainScheduler.instance)
            .filter { $0.chat.id == chatID }
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.updateBarStatus(self.handleChatModel(push.chat))
            }).disposed(by: pushDisposeBag)

        pushCenter?
            .observable(for: PushRemoveMeFromChannel.self)
            .observeOn(scheduler: MainScheduler.instance)
            .filter { $0.channelId == chatID }
            .subscribe(onNext: { [weak self] deleteMeInfo in
                guard let self = self else { return }
                if deleteMeInfo.isDissolved {
                    self.updateBarStatus(.createGroup)
                    self.logger.info("ImPluginForWebImp \(self.logID) handle PushRemoveMeFromChannel isDissolved chatID: \(chatID)")
                } else {
                    self.updateBarStatus(.joinGroup(chatID: chatID))
                    self.logger.info("ImPluginForWebImp \(self.logID) handle PushRemoveMeFromChannel leave chatID: \(chatID)")
                }
            }).disposed(by: pushDisposeBag)
    }

    private func handleChatModel(_ chat: Chat) -> ChatLinkedPageBarStatus {
        if chat.isDissolved {
            return .createGroup
        } else if chat.role != .member {
            return .joinGroup(chatID: chat.id)
        } else {
            return .inGroup(chat: chat)
        }
        self.logger.info("ImPluginForWebImp \(logID) handleChatModel chatID: \(chat.id) isDissolved: \(chat.isDissolved) isMember: \(chat.role != .member)")
    }

    public func destroyBarItems() {
        self.disposeBag = DisposeBag()
        self.pushDisposeBag = DisposeBag()
        self.logger.info("ImPluginForWebImp \(logID) destroyBarItems")
    }

    private var isClicking: Bool = false
    private func excuteTask(_ clickHandler: @escaping () -> Void) {
        guard !isClicking else {
            return
        }
        isClicking = true
        self.logger.info("ImPluginForWebImp \(logID) begin click currentBarStatus: \(currentBarStatus)")
        self.getBarStatus()
            .drive(onNext: { [weak self] barStatus in
                guard let self = self, let targetVC = self.targetVC else { return }
                self.logger.info("ImPluginForWebImp \(self.logID) handle click result currentBarStatus: \(currentBarStatus) newBarStatus: \(barStatus)")

                if case .unknown(let error) = barStatus {
                    if let error = error {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: targetVC.view, error: error)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: targetVC.view)
                    }
                } else {
                    if !self.updateBarStatus(barStatus) {
                        clickHandler()
                    }
                }
                self.isClicking = false
            }, onCompleted: { [weak self] in
                self?.isClicking = false
            }, onDisposed: { [weak self] in
                self?.isClicking = false
            }).disposed(by: disposeBag)

        if let url = self.url {
            switch currentBarStatus {
            case .none, .associateChat, .unknown:
                break
            case .createGroup:
                IMTracker.Chat.ChatLinkPage.Click(nil, url: url, barType: .createGroup, urlMetaID: urlMetaID)
            case .joinGroup(let chatID):
                IMTracker.Chat.ChatLinkPage.Click(chatID, url: url, barType: .joinGroup, urlMetaID: urlMetaID)
            case .inGroup(let chat):
                IMTracker.Chat.ChatLinkPage.Click(chat.id, url: url, barType: .openGroup, urlMetaID: urlMetaID)
            }
        }
    }

    private func transformToBarItem(status: ChatLinkedPageBarStatus, url: URL) -> ChatLinkedPageBarItemsForWeb {
        var lkBarButtonItem: LKBarButtonItem?
        var quickLaunchBarItem: QuickLaunchBarItem?
        let iconSize = CGSize(width: 24, height: 24)
        let icon = UDIcon.getIconByKey(.tabChatColorful, renderingMode: .alwaysOriginal, size: iconSize)

        switch status {
        case .none, .associateChat, .unknown:
            return ChatLinkedPageBarItemsForWeb(url: url, navigationBarItem: nil, launchBarItem: nil)
        case .createGroup:
            let barItem = LKBarButtonItem(image: icon)
            barItem.addTarget(
                self,
                action: #selector(createGroup),
                for: .touchUpInside
            )
            lkBarButtonItem = barItem
            quickLaunchBarItem = QuickLaunchBarItem(
                nomalImage: icon,
                badge: nil,
                action: { [weak self] _ in
                    self?.createGroup()
                }
            )
        case .joinGroup(chatID: let chatID):
            let barItem = LKBarButtonItem(image: icon)
            barItem.addTarget(
                self,
                action: { [weak self] in
                    self?.joinGroup(chatID: chatID)
                },
                for: .touchUpInside
            )
            lkBarButtonItem = barItem
            quickLaunchBarItem = QuickLaunchBarItem(
                nomalImage: icon,
                badge: nil,
                action: { [weak self] _ in
                    self?.joinGroup(chatID: chatID)
                }
            )
        case .inGroup(chat: let chat):
            let barItem = LKBarButtonItem(image: icon)
            barItem.addTarget(
                self,
                action: { [weak self] in
                    self?.jumpGroup(chat)
                },
                for: .touchUpInside
            )
            if chat.badge > 0 {
                barItem.button.addBadge(UDBadgeConfig.dot)
            }
            lkBarButtonItem = barItem
            quickLaunchBarItem = QuickLaunchBarItem(
                nomalImage: icon,
                badge: chat.badge > 0 ? Badge(type: BadgeType.dot(.web), style: BadgeStyle.strong) : nil,
                action: { [weak self] _ in
                    self?.jumpGroup(chat)
                }
            )
        }
        return ChatLinkedPageBarItemsForWeb(url: url, navigationBarItem: lkBarButtonItem, launchBarItem: quickLaunchBarItem)
    }
}

extension ImPluginForWebImp {

    /// 创建会话
    @objc
    private func createGroup() {
        self.excuteTask { [weak self] in
            guard let self = self,
                  let targetVC = self.targetVC,
                  let url = self.url else { return }
            self.logger.info("ImPluginForWebImp \(self.logID) click bar createGroup")
            let body = CreateGroupBody(
                createGroupBlock: getCreateGroupHandler(from: targetVC),
                canCreateSecretChat: false,
                canCreateThread: false,
                canCreatePrivateChat: false,
                needSearchOuterTenant: false,
                linkPageURL: url.absoluteString
            )
            self.userResolver.navigator.present(
                body: body,
                from: targetVC,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        }
    }

    private func getCreateGroupHandler(from: UIViewController) -> (Chat?, UIViewController, Int64, [AddExternalContactModel], Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void {
        let logID = self.logID
        return { (chat, vc, _, _, pageLinkResult) in
            vc.dismiss(animated: true, completion: { [weak from, weak self] in
                guard let chat = chat, let from = from, let self = self else { return }
                if let pageLinkResult = pageLinkResult, !pageLinkResult.success {
                    let errorMsg = pageLinkResult.errorMsg
                    if !errorMsg.isEmpty {
                        UDToast.showFailure(with: errorMsg, on: from.view)
                    }
                    self.logger.info("ImPluginForWebImp \(logID) getCreateGroupHandler begin getBarStatus chatID: \(chat.id)")
                    self.getBarStatus()
                        .drive(onNext: { [weak self] barStatus in
                            self?.logger.info("ImPluginForWebImp \(logID) getCreateGroupHandler chatID: \(chat.id) barStatus: \(barStatus)")
                            self?.updateBarStatus(barStatus)
                        }).disposed(by: self.disposeBag)
                } else {
                    self.logger.info("ImPluginForWebImp \(logID) getCreateGroupHandler create chat success chatID: \(chat.id)")
                    self.updateBarStatus(.inGroup(chat: chat))
                    let body = ChatControllerByChatBody(chat: chat, showNormalBack: true)
                    if Display.pad {
                        self.userResolver.navigator.push(body: body, from: from)
                    } else {
                        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: from)
                    }
                }
            })
        }
    }

    /// 加入会话
    private func joinGroup(chatID: String) {
        self.excuteTask { [weak self] in
            guard let self = self,
                  let targetVC = self.targetVC,
                  let linkPageURL = self.url?.absoluteString else { return }
            self.logger.info("ImPluginForWebImp \(self.logID) click bar joinGroup chatID: \(chatID)")
            let body = PreviewChatCardByLinkPageBody(
                chatID: chatID,
                linkPageURL: linkPageURL
            )
            self.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC
            )
        }
    }

    /// 打开会话
    private func jumpGroup(_ chat: Chat) {
        self.excuteTask { [weak self] in
            guard let self = self,
                  let targetVC = self.targetVC else { return }
            self.logger.info("ImPluginForWebImp \(self.logID) click bar jumpGroup chatID: \(chat.id)")
            let body = ChatControllerByChatBody(chat: chat, showNormalBack: true)
            if Display.pad {
                self.userResolver.navigator.push(body: body, from: targetVC)
            } else {
                self.userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: targetVC
                )
            }
        }
    }
}
