//
//  LarkOpenAPIServiceImpl.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation
import LarkOPInterface
import OPFoundation
import LKCommonsLogging
import LarkMessengerInterface
import LarkTab
import LarkNavigation
import LarkContainer
import EENavigator
import LarkUIKit
import RxSwift
import LarkSDKInterface
import RustPB
import LarkAccountInterface
import LarkModel
import LarkMicroApp

@objc
final class LarkOpenAPIServiceImpl: NSObject, LarkOpenAPIService {
    
    private let resolver: UserResolver
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()
    private var chatterAPI: ChatterAPI
    private var chatAPI: ChatAPI
    private var messageAPI: MessageAPI
    private var kaLoginService: KaLoginService
    private var appBadgeService: AppBadgeListenerService
    private var appBadgeAPI: AppBadgeAPI
    
    init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.messageAPI = try resolver.resolve(assert: MessageAPI.self)
        self.kaLoginService = try resolver.resolve(assert: KaLoginService.self)
        self.appBadgeService = try resolver.resolve(assert: AppBadgeListenerService.self)
        self.appBadgeAPI = try resolver.resolve(assert: AppBadgeAPI.self)
    }
    
    private static let logger = Logger.oplog(LarkOpenAPIServiceImpl.self, category: "LarkOpenAPIServiceImpl")
    
    func enterChat(chatID: String, showBadge: Bool, from: UINavigationController?) {
        guard let fromVC = from else {
            Self.logger.error("LarkOpenAPIServiceImpl: enterChat fromVC is nil")
            return
        }
        var body = ChatControllerByIdBody(chatId: chatID)
        body.showNormalBack = !showBadge
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: chatID, selectionType: .skipSame)
        ]
        self.resolver.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, context: context, wrap: LkNavigationController.self, from: fromVC)
    }
    
    func enterProfile(userID: String, from: UINavigationController?) {
        guard let fromVC = from else {
            Self.logger.error("LarkOpenAPIServiceImpl: enterProfile fromVC is nil")
            return
        }
        let body = PersonCardBody(chatterId: userID)
        self.resolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: fromVC,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
    }
    
    
    func enterBot(botID: String, from: UINavigationController?) {
        guard let fromVC = from else {
            Self.logger.error("LarkOpenAPIServiceImpl: enterBot fromVC is nil")
            return
        }
        guard let chatService = try? self.resolver.resolve(assert: ChatService.self) else {
            Self.logger.error("[EMAProtocolImpl]: can not open bot chat without chat service")
            return }
        chatService.createP2PChat(userId: botID, isCrypto: false, chatSource: nil).observeOn(MainScheduler.instance).subscribe(onNext: { (chat) in
            let body = ChatControllerByChatBody(chat: chat)
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            self.resolver.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, context: context, wrap: LkNavigationController.self, from: fromVC)
        }).disposed(by: self.disposeBag)
    }
    
    func chooseContact(config: LarkOPInterface.ChooseContactConfig, sourceVC: UIViewController, presentCompletion: (() -> Void)? = nil, selectedNameCompletion: @escaping ([String]?, [String]?, [String]?) -> (() -> Void)?) {
        
        let body = generateChooseContactBody(config: config, selectedNameCompletion: selectedNameCompletion)
        
        guard let nav = self.resolver.navigator.response(for: body).resource as? LkNavigationController, let vc = nav.viewControllers.last as? BaseUIViewController else { return }
        vc.closeCallback = {
            if let completion = selectedNameCompletion(nil, nil, nil) {
                completion()
            }
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            nav.modalPresentationStyle = .formSheet
            nav.popoverPresentationController?.sourceView = sourceVC.view
        } else {
            nav.modalPresentationStyle = .fullScreen
        }
        sourceVC.present(nav, animated: true, completion: presentCompletion)
    }
    
    func chooseChat(config: LarkOPInterface.ChooseChatConfig) {
        let body = generateChooseChatBody(config: config)
        let window = config.window ?? self.resolver.navigator.mainSceneWindow
        if let fromVC = window?.fromViewController {
            let modalStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            self.resolver.navigator.present(body: body, from: fromVC, prepare: { $0.modalPresentationStyle = modalStyle})
        } else {
            Self.logger.error("chooseChat can not present vc because no fromViewController")
        }
    }
    
    func getChatInfo(chatID: String) -> [AnyHashable: Any]? {
        guard let chatMap = try? chatAPI.getLocalChats([chatID]), let chat = chatMap[chatID] else { return nil }
        return ["badge": chat.unreadBadge]
    }
    
    func getAtInfo(chatID: String, block: @escaping (([String : Any]?) -> Void)) {
        var d = [String: Any]()
        messageAPI.fetchUnreadAtMessages(chatIds: [chatID], ignoreBadged: false, needResponse: true).map({ (chatMessagesMap) -> [Message] in
            return chatMessagesMap[chatID] ?? []
        }).subscribe(onNext: { (unreadAtMessages) in
            var arr = [Any]()
            for message in unreadAtMessages {
                d["isAtMe"] = message.isAtMe
                d["isAtAll"] = message.isAtAll
                arr.append(d)
            }
            block(["atMsgs": arr])
        }).disposed(by: disposeBag)
    }
    
    func getUserInfoEx(successBlock: @escaping (([String : Any]) -> Void), failBlock: @escaping (() -> Void)) {
        if let config = kaLoginService.getKaConfig() {
            kaLoginService.getExtraIdentity(onSuccess: { extra in
                let merged = config.merging(extra) { (current, _) in  current }
                Self.logger.info("get userInfoEx success config: \(config.keys.count)")
                successBlock(merged)
            }, onError: { error in
                Self.logger.error("\(error)")
                failBlock()
            })
        } else {
            Self.logger.error("invalidKaConfig")
            failBlock()
        }
    }
    
    func onServerBadgePush(appID: String, subAppIDs: [String], completion: @escaping ((LarkOPInterface.AppBadgeNode) -> Void)) {
        appBadgeService.observeBadge(appId: appID, subAppIds: subAppIDs, callback: completion)
    }
    
    func offServerBadgePush(appID: String, subAppIDs: [String]) {
        appBadgeService.removeObserver(appId: appID, subAppIds: subAppIDs)
    }
    
    func updateAppBadge(appID: String, appType: AppBadgeAppType, extra: LarkOPInterface.UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        self.appBadgeAPI.updateAppBadge(appID, appType: appType, extra: extra, completion: completion)
    }
    
    func pullAppBadge(appID: String, appType: AppBadgeAppType, extra: LarkOPInterface.PullBadgeRequestParameters?, completion: ((PullAppBadgeNodeResponse?, Error?) -> Void)?) {
        self.appBadgeAPI.pullAppBadge(appID, appType: appType, extra: extra, completion: completion)
    }
    
    ///Private Method
     
    private func generateChooseChatBody(config: LarkOPInterface.ChooseChatConfig) -> ChatChooseBody {
        let allowCreateGroup = config.params["allowCreateGroup"] as? Bool ?? true
        let multiSelect = config.params["multiSelect"] as? Bool ?? true
        let ignoreSelf = config.params["ignoreSelf"] as? Bool ?? false
        let ignoreBot = config.params["ignoreBot"] as? Bool ?? false
        let externalChat = config.params["externalChat"] as? Bool ?? true
        let confirmDesc = config.params["confirmDesc"] as? String ?? ""
        let showMessageInput = config.params["showMessageInput"] as? Bool ?? false
        let confirmText = config.params["confirmText"] as? String
        let chosenOpenIds = (config.params["chosenOpenIds"] as? [String])?.map{ PreSelectInfo.chatterID($0) } ?? []
        let chosenOpenChatIds = (config.params["chosenOpenChatIds"] as? [String])?.map{ PreSelectInfo.chatID($0) } ?? []
        let preSelectInfos = chosenOpenIds + chosenOpenChatIds
        let showRecentForward = preSelectInfos.count <= 0
        var body: ChatChooseBody
        var res: [String: Any]? = nil
        var cancel = false
        var callbackDone = false
        var forwardVCDismissDone = false
        let dispatchGroup: DispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        body = ChatChooseBody(allowCreateGroup: allowCreateGroup, multiSelect: multiSelect, ignoreSelf: ignoreSelf, ignoreBot: ignoreBot, needSearchOuterTenant: externalChat, selectType: config.selectType, confirmTitle: config.title, confirmDesc: confirmDesc, confirmOkText: confirmText, showInputView: showMessageInput, preSelectInfos: preSelectInfos, showRecentForward: showRecentForward, callback: { resData, isCancel in
            guard callbackDone == false else {
                Self.logger.error("chooseChat callback multi")
                return
            }
            callbackDone = true
            res = resData
            cancel = isCancel
            dispatchGroup.leave()
            Self.logger.info("chooseChat callback")
        }, forwardVCDismissBlock:  {
            guard forwardVCDismissDone == false else {
                Self.logger.error("chooseChat forwardVCDismissBlock multi")
                return
            }
            forwardVCDismissDone = true
            dispatchGroup.leave()
            Self.logger.info("chooseChat forwardVCDismissBlock")
        })
        body.permissions = [.checkBlock]
        body.targetPreview = false
        dispatchGroup.notify(queue: .main) {
            guard let realBlock = config.completion else { return }
            realBlock(res, cancel)
        }
        return body
    }
    
    private func generateChooseContactBody(config: LarkOPInterface.ChooseContactConfig, selectedNameCompletion: @escaping ([String]?, [String]?, [String]?) -> (() -> Void)?) -> ChatterPickerBody {
        var body = ChatterPickerBody()
        body.title = BundleI18n.LarkOpenPlatform.Lark_Legacy_ChooseContact
        body.permissions = [.checkBlock]
        body.selectStyle = config.multi ? .multi : .single(style: .callback)
        body.disabledSelectedChatterIds = config.ignore ? [self.resolver.userID] : []
        body.targetPreview = false
        body.supportUnfoldSelected = true
        if let externalSearch = config.enableExternalSearch as? Bool, let relatedOrg = config.showRelatedOrganizations as? Bool {
            // 过渡逻辑: externalSearch影响是否能搜索; externalSearch开的情况下, externalContact和showRelatedOrganizations的值才有意义
            body.showExternalContact = config.externalContact
            body.needSearchOuterTenant = externalSearch
            body.enableRelatedOrganizations = relatedOrg
            if externalSearch, !config.externalContact {
                body.filterOuterContact = true
            }
        } else { // 老逻辑: externalContact 统一控制 外部联系人入口显隐和搜索 + 关联组织入口显隐和搜索
            body.needSearchOuterTenant = config.externalContact
        }
        if let selectedUserIDs = config.selectedUserIDs {
            body.defaultSelectedChatterIds = selectedUserIDs
        }
        if let tip = config.limitTips, config.hasMaxNum == true {
            body.limitInfo = SelectChatterLimitInfo(max: config.maxNum, warningTip: tip)
        }
        if let disables = config.disableIds {
            body.forceSelectedChatterIds = disables
        }
        body.supportSelectOrganization = config.enableChooseDepartment
        if let exEmployeeFilterTypeStr = config.exEmployeeFilterType { // 离职人员搜索配置
            body.userResignFilter = OpenAPIChooseContactAPIExEmployeeFilterType(rawValue: exEmployeeFilterTypeStr)?.mappedPickerUserResignFilterType()
        }
        body.selectedCallback = { [weak self] (vc, result) in
            // 回调回来的是chatterIds，这里需要先转成Chatter，然后再@
            guard let `self` = self, let controller = vc else {
                if let completion = selectedNameCompletion(nil, nil, nil) {
                    completion()
                }
                return
            }
            let selectedChatterIDs = result.chatterInfos.map { $0.ID }
            do {
                let chatterDict = try self.chatterAPI.getChattersFromLocal(ids: selectedChatterIDs)
                let departmentIds = result.departmentIds
                if !chatterDict.isEmpty {
                    // 确保联系人顺序与选择的顺序一致
                    var names: [String] = []
                    var IDs: [String] = []
                    for chatterID in selectedChatterIDs {
                        guard let chatter = chatterDict[chatterID] else {
                            continue
                        }
                        names.append(chatter.localizedName)
                        IDs.append(chatterID)
                    }
                    controller.dismiss(animated: true, completion: {
                        let completion = selectedNameCompletion(names, IDs, departmentIds)
                        completion?()
                    })
                } else {
                    controller.dismiss(animated: true, completion: {
                        let completion = selectedNameCompletion(nil, nil, departmentIds)
                        completion?()
                    })
                }
            } catch {
                controller.dismiss(animated: true, completion: {
                    let completion = selectedNameCompletion(nil, nil, nil)
                    completion?()
                })
            }
        }
        return body
    }
    
}

fileprivate extension OpenAPIChooseContactAPIExEmployeeFilterType {
    func mappedPickerUserResignFilterType() -> UserResignFilter {
        switch self {
        case .all: return .all
        case .exEmployee: return .resigned
        case .employee: return .unresigned
        }
    }
}

fileprivate extension Chat {
    var unreadBadge: Int32 {
        switch chatMode {
        case .thread, .threadV2:
            return threadBadge
        @unknown default:
            return badge
        }
    }
}
