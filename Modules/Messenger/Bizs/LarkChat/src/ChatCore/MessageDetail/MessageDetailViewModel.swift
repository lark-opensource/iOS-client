//
//  MessageDetailViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/7/25.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkRustClient
import RustPB
import LKCommonsLogging
import LarkFoundation
import LarkMessageCore
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface

final class MessageDetailViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    public var chat: LarkModel.Chat {
        return self.chatWrapper.chat.value
    }
    private let rootId: String

    let chatWrapper: ChatPushWrapper

    fileprivate let disposeBag = DisposeBag()

    static let logger = Logger.log(MessageDetailViewModel.self, category: "Business.MessageDetail")

    let currentChatterId: String

    let chatAPI: ChatAPI
    let userGeneralSettings: UserGeneralSettings
    let translateService: NormalTranslateService

    /// 自动翻译开关变化
    private let chatAutoTranslateSettingPublish: PublishSubject<Void> = PublishSubject<Void>()
    var chatAutoTranslateSettingDriver: Driver<()> {
        return chatAutoTranslateSettingPublish.asDriver(onErrorJustReturn: ())
    }

    let chatterAPI: ChatterAPI
    let messageAPI: MessageAPI
    @ScopedInjectedLazy var modelService: ModelService?
    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?

    // 是否展示unblock的序列
    lazy var isShowUnBlockObservable: Observable<Bool>? = {
        return self.contactControlService.getIsShowUnBlockObservable(chat: self.chat)
    }()

    // 联系人控件服务
    private var contactControlService: ContactControlService

    // 导致IM会话的引导banner状态发生变化的实时事件的推送
    private var pushContactApplicationBannerAffectEvent: Observable<PushContactApplicationBannerAffectEvent> {
        return self.pushCenter.observable(for: PushContactApplicationBannerAffectEvent.self)
    }

    lazy var pushScheduleMessage: Observable<PushScheduleMessage> = self.pushCenter.observable(for: PushScheduleMessage.self)
    lazy var scheduleMsgEnable = scheduleSendService?.scheduleSendEnable ?? false

    private let pushCenter: PushNotificationCenter
    lazy var quasiMsgCreateByNative: Bool = {
        return chat.anonymousId.isEmpty && !chat.isCrypto
    }()
    init(userResolver: UserResolver,
         rootId: String,
         pushCenter: PushNotificationCenter,
         chatWrapper: ChatPushWrapper,
         chatAPI: ChatAPI,
         currentChatterId: String,
         userGeneralSettings: UserGeneralSettings,
         translateService: NormalTranslateService,
         contactControlService: ContactControlService
    ) throws {
        self.userResolver = userResolver
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        self.rootId = rootId
        self.pushCenter = pushCenter
        self.chatWrapper = chatWrapper
        self.chatAPI = chatAPI
        self.currentChatterId = currentChatterId
        self.userGeneralSettings = userGeneralSettings
        self.translateService = translateService
        self.contactControlService = contactControlService
        chatWrapper.chat.map({ $0.isAutoTranslate }).distinctUntilChanged().subscribe(onNext: { [weak self] (_) in
            self?.chatAutoTranslateSettingPublish.onNext(())
        }).disposed(by: self.disposeBag)
    }

    deinit {
        /// 退会话时，清空一次标记
        self.translateService.resetMessageCheckStatus(key: self.chat.id)
    }

    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool {
        guard let itemId = messageItems.first?.itemID else {
            return false
        }
        // replyInThread的push不响应
        if let message = entity.messages[itemId] {
            if message.threadMessageType != .unknownThreadMessage {
                return false
            }
            return message.rootID == self.rootId
        } else if let quasi = entity.quasiMessages[itemId] {
            if quasi.threadID.isEmpty == false {
                return false
            }
            return quasi.rootID == self.rootId
        }
        return true
    }
}
