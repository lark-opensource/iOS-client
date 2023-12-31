//
//  ChatChooseAlertProvider.swift
//  Action
//
//  Created by yin on 2019/6/10.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import Swinject
import LarkModel
import LarkContainer

public enum ChatChooseType: Int {
    case all = 0     //全部
    case group = 1   //群聊
    case user = 2   //单聊
}

struct ChatChooseAlertContent: ForwardAlertContent {
    // 非阻塞式的回调形式，转发页点击确定即 dismiss
    let callback: (([String: Any]?, Bool) -> Void)?
    // 阻塞式的回调形式，转发页点击确定等待外部信号发送 onNext 事件后才会 dismiss
    let blockingCallback: (([String: Any]?, Bool) -> Observable<Void>)?
    // 回调转发VC页关闭的时机
    let forwardVCDismissBlock: ForwardVCDismissBlock?
    let allowCreateGroup: Bool
    let multiSelect: Bool
    let ignoreSelf: Bool
    let ignoreBot: Bool
    let includeMyAI: Bool
    let selectType: ChatChooseType
    let confirmTitle: String?
    let confirmDesc: String
    let confirmOkText: String?
    let showInputView: Bool
    var needSearchOuterTenant: Bool
    var includeOuterChat: Bool?
    let preSelectInfos: [PreSelectInfo]?
    let showRecentForward: Bool
    var targetPreview: Bool = true
    // nolint: duplicated_code -- 与识别出来的重复代码差异较大，不建议合并
    init(allowCreateGroup: Bool,
         multiSelect: Bool,
         ignoreSelf: Bool,
         ignoreBot: Bool,
         needSearchOuterTenant: Bool,
         includeMyAI: Bool,
         includeOuterChat: Bool? = nil,
         selectType: Int,
         confirmTitle: String? = nil,
         confirmDesc: String,
         confirmOkText: String? = nil,
         showInputView: Bool,
         preSelectInfos: [PreSelectInfo]? = nil,
         showRecentForward: Bool = true,
         callback: (([String: Any]?, Bool) -> Void)? = nil,
         blockingCallback: (([String: Any]?, Bool) -> Observable<Void>)? = nil,
         forwardVCDismissBlock: ForwardVCDismissBlock? = nil) {
        self.allowCreateGroup = allowCreateGroup
        self.multiSelect = multiSelect
        self.ignoreSelf = ignoreSelf
        self.ignoreBot = ignoreBot
        self.needSearchOuterTenant = needSearchOuterTenant
        self.includeMyAI = includeMyAI
        self.includeOuterChat = includeOuterChat
        self.selectType = ChatChooseType(rawValue: selectType) ?? .all
        self.confirmTitle = confirmTitle
        self.confirmDesc = confirmDesc
        self.confirmOkText = confirmOkText
        self.showInputView = showInputView
        self.callback = callback
        self.blockingCallback = blockingCallback
        self.forwardVCDismissBlock = forwardVCDismissBlock
        self.preSelectInfos = preSelectInfos
        self.showRecentForward = showRecentForward
    }
    // enable-lint: duplicated_code
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ChatChooseAlertProvider: ForwardAlertProvider {
    let disposeBag = DisposeBag()
    required init(userResolver: UserResolver, content: ForwardAlertContent) {
        super.init(userResolver: userResolver, content: content)
        var filter = ForwardFilterParameters()
        filter.includeThread = true
        filter.includeOuterChat = (content as? ChatChooseAlertContent)?.includeOuterChat ?? true
        self.filterParameters = filter
    }

    // 开启开放平台mention能力
    override var isSupportMention: Bool {
        return true
    }

    override var targetPreview: Bool {
        guard let chatContent = content as? ChatChooseAlertContent else { return true }
        return chatContent.targetPreview
    }

    // 是否展示最近转发
    override var shouldShowRecentForward: Bool {
        guard let chatContent = content as? ChatChooseAlertContent else { return true }
        return chatContent.showRecentForward
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ChatChooseAlertContent != nil {
            return true
        }
        return false
    }
    override var shouldCreateGroup: Bool {
        guard let chatContent = content as? ChatChooseAlertContent else { return true }
        if chatContent.selectType == .user {
            return false
        }
        return chatContent.allowCreateGroup
    }
    /// 是否支持多选
    override var isSupportMultiSelectMode: Bool {
        guard let chatContent = content as? ChatChooseAlertContent else { return false }
        return chatContent.multiSelect
    }
    /// 是否支持搜索外部租户
    override var needSearchOuterTenant: Bool {
        guard let chatContent = content as? ChatChooseAlertContent else {
            return super.needSearchOuterTenant
        }
        return chatContent.needSearchOuterTenant
    }
    override var includeOuterChat: Bool? {
        guard let chatContent = content as? ChatChooseAlertContent else {
            return super.includeOuterChat
        }
        return chatContent.includeOuterChat
    }

    override func getTitle(by items: [ForwardItem]) -> String? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        return chatContent.confirmTitle
    }

    /// 获取ForwardViewController确认按钮标题
    ///
    /// - Parameter items: 选中的标题
    /// - Returns: 返回title
    override func getConfirmButtonTitle(by items: [ForwardItem]) -> String? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        guard let confirmOkText = chatContent.confirmOkText, !confirmOkText.isEmpty else {
            return nil
        }
        return confirmOkText
    }

    /// 获取NewForwardViewController确认框自定义确认文案
    override func getConfirmButtonText(isMultiple: Bool, selectCount: Int) -> String? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        guard let confirmOKText = chatContent.confirmOkText, !confirmOKText.isEmpty else { return nil }
        if isMultiple {
            return confirmOKText + "(\(selectCount))"
        }
        return confirmOKText
    }

    override func getFilter() -> ForwardDataFilter? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        let ignoreSelf = chatContent.ignoreSelf
        let ignoreBot = chatContent.ignoreBot
        let selectType = chatContent.selectType
        let userId = userResolver.userID
        return { (item) -> Bool in
            if item.type == .user {
                if selectType == .group {
                    return false
                } else {
                    if ignoreSelf == true {
                        return item.id != userId
                    } else {
                        return true
                    }
                }
            } else if item.type == .chat {
                if selectType == .user {
                    return false
                } else {
                    return true
                }
            } else if item.type == .bot {
                if ignoreBot == true {
                    return false
                } else {
                    if selectType == .group {
                        return false
                    }
                    return true
                }
            }
            return true
        }
    }

    override func getForwardVCDismissBlock() -> ForwardVCDismissBlock? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        return chatContent.forwardVCDismissBlock
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let chatContent = content as? ChatChooseAlertContent else { return nil }
        let ignoreSelf = chatContent.ignoreSelf
        let ignoreBot = chatContent.ignoreBot
        let includeMyAI = chatContent.includeMyAI
        let selectType = chatContent.selectType
        let includeOuterChat = chatContent.includeOuterChat
        let needSearchOuterTenant = chatContent.needSearchOuterTenant
        var includeConfigs = IncludeConfigs()
        switch selectType {
        case .all:
            includeConfigs = [
                ForwardUserEnabledEntityConfig(tenant: needSearchOuterTenant ? .all : .inner, selfType: ignoreSelf ? .other : .all),
                ForwardGroupChatEnabledEntityConfig(tenant: includeOuterChat == false ? .inner : .all)
            ]
            if !ignoreBot {
                includeConfigs.append(ForwardBotEnabledEntityConfig())
            }
            if includeMyAI {
                includeConfigs.append(ForwardMyAiEnabledEntityConfig())
            }
        case .user:
            includeConfigs = [
                ForwardUserEnabledEntityConfig(tenant: needSearchOuterTenant ? .all : .inner, selfType: ignoreSelf ? .other : .all)
            ]
            if !ignoreBot {
                includeConfigs.append(ForwardBotEnabledEntityConfig())
            }
            if includeMyAI {
                includeConfigs.append(ForwardMyAiEnabledEntityConfig())
            }
        case .group:
            includeConfigs = [
                ForwardGroupChatEnabledEntityConfig(tenant: includeOuterChat == false ? .inner : .all)
            ]
        }
        return includeConfigs
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        guard let content = content as? ChatChooseAlertContent else { return false }
        return content.showInputView
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let chatContent = content as? ChatChooseAlertContent,
              let modelService = try? resolver.resolve(assert: ModelService.self)
        else { return nil }
        let message = chatContent.confirmDesc
        if message.isEmpty {
            return nil
        }
        let view = ForwardChatChooseMessageConfirmFooter(message: message, modelService: modelService)
        return view
    }
    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let chatContent = content as? ChatChooseAlertContent else { return .just([]) }
        func genItemDict() -> [String: Any]? {
            var itemArr = [[String: Any]]()
            for item: ForwardItem in items {
                var p = [String: Any]()
                //在这里补充extra，不影响现有业务
                let type: Int
                switch item.type {
                //  需求要求：会话类型，0 单聊,1 群聊 2 Bot
                case .user:
                    type = 0
                case .bot:
                    type = 2
                case .chat:
                    type = 1
                default:
                    type = -1
                }
                let extra = [
                    "chatId": item.id,
                    "name": item.name,
                    "avatarKey": item.avatarKey,
                    "chatType": type
                ] as [String: Any]
                p["extra"] = extra
                //有业务用是否有下面字段做业务，下边的代码一行都不能改，只能在上面被迫额外加上字段进行新业务逻辑，建议owner把这段代码彻底废弃，不要再用字典传参了
                if item.type == .user || item.type == .bot {
                    p["type"] = item.type == .user ? 0 : 2
                    p["chatterid"] = item.id
                    p["avatarKey"] = item.avatarKey
                    let semaphore = DispatchSemaphore(value: 0)
                    self.getChatId(userId: item.id) { (chatId: String?) in
                        guard let c = chatId else {
                            return
                        }
                        p["chatid"] = c
                        itemArr.append(p)
                        semaphore.signal()
                    }
                    semaphore.wait()
                } else if item.type == .chat {
                    p["type"] = 1
                    p["chatid"] = item.id
                    itemArr.append(p)
                }
            }
            return ["items": itemArr, "input": input ?? ""]
        }
        if let c = chatContent.callback {
            DispatchQueue.global(qos: .background).async {
                let itemDict = genItemDict()
                DispatchQueue.main.async {
                    c(itemDict, false)
                }
            }
            return .just([])
        }
        if let c = chatContent.blockingCallback {
            let itemDict = genItemDict()
            return c(itemDict, false).take(1).flatMap { (_) -> Observable<[String]> in
                return .just([])
            }
        }
        return .just([])
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let chatContent = content as? ChatChooseAlertContent else { return .just([]) }
        func genItemDict() -> [String: Any]? {
            var itemArr = [[String: Any]]()
            for item: ForwardItem in items {
                var p = [String: Any]()
                //在这里补充extra，不影响现有业务
                let type: Int
                switch item.type {
                //  需求要求：会话类型，0 单聊,1 群聊 2 Bot 3 MyAi
                case .user:
                    type = 0
                case .bot:
                    type = 2
                case .chat:
                    type = 1
                case .myAi:
                    type = 3
                default:
                    type = -1
                }
                let extra = [
                    "chatId": item.id,
                    "name": item.name,
                    "avatarKey": item.avatarKey,
                    "chatType": type
                ] as [String: Any]
                p["extra"] = extra
                //有业务用是否有下面字段做业务，下边的代码一行都不能改，只能在上面被迫额外加上字段进行新业务逻辑，建议owner把这段代码彻底废弃，不要再用字典传参了
                if item.type == .user || item.type == .bot || item.type == .myAi {
                    p["type"] = item.type == .user ? 0 : (item.type == .bot ? 2 : 3)
                    p["chatterid"] = item.id
                    p["avatarKey"] = item.avatarKey
                    let semaphore = DispatchSemaphore(value: 0)
                    self.getChatId(userId: item.id) { (chatId: String?) in
                        guard let c = chatId else {
                            return
                        }
                        p["chatid"] = c
                        itemArr.append(p)
                        semaphore.signal()
                    }
                    semaphore.wait()
                } else if item.type == .chat {
                    p["type"] = 1
                    p["chatid"] = item.id
                    itemArr.append(p)
                }
            }
            return ["items": itemArr, "input": attributeInput?.string ?? "", "attributedInput": attributeInput]
        }
        if let c = chatContent.callback {
            DispatchQueue.global(qos: .background).async {
                let itemDict = genItemDict()
                DispatchQueue.main.async {
                    c(itemDict, false)
                }
            }
            return .just([])
        }
        if let c = chatContent.blockingCallback {
            let itemDict = genItemDict()
            return c(itemDict, false).take(1).flatMap { (_) -> Observable<[String]> in
                return .just([])
            }
        }
        return .just([])
    }

    override func dismissAction() {
        guard let chatContent = content as? ChatChooseAlertContent, let c = chatContent.callback else { return }
        let p = [String: Any]()
        c(p, true)
    }

    func getChatId(userId: String, cb: @escaping (String?) -> Void) {
        guard let chatService = try? self.resolver.resolve(assert: ChatService.self) else { return }
        chatService.createP2PChat(userId: userId, isCrypto: false, chatSource: nil)
            .subscribe(onNext: { (chat) in
                cb(chat.id)
            }, onError: { (_ err) in
                cb(nil)
            }).disposed(by: disposeBag)
    }
}
