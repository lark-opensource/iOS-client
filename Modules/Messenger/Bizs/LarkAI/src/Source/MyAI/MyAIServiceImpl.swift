//
//  MyAIServiceImpl.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/10.
//

import Foundation
import Swinject
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import LarkAIInfra
import LarkContainer
import LarkSDKInterface
import LarkGuide
import LarkRustClient
import LarkMessengerInterface
import LarkSceneManager
import LarkMessageBase
import LKCommonsLogging
import UniverseDesignIcon
import ServerPB
import LarkModel

public class MyAIServiceImpl: MyAIService {
    // MARK: - MyAIOnboardingService、MyAIInfoService等协议共用属性
    static let logger = Logger.log(MyAIServiceImpl.self, category: "Module.LarkAI")
    let userResolver: UserResolver
    let disposeBag = DisposeBag()
    /// Onboarding完成、业务方传入的ChatID
    var myAIChatId: Int64 = 0
    /// 获取到的MyAI ID，Onboarding前也能获取到
    var myAIChatterId: String = ""
    /// 正在请求打开（但还没有真正打开页面）的分会场ChatModeID集合。用于防止连点打开多个分会场。
    var requestingChatModeSet: SafeSet<Int64> = SafeSet<Int64>([], synchronization: .semaphore)

    // MARK: - MyAIOnboardingService独用属性
    static let myAIOnboardingGuideKey = "global_my_ai_init_guide"
    let newGuideManager: NewGuideService?
    var onboardingDisposeBag = DisposeBag()
    /// 用于Onboarding流程，Feed Mock MyAI；其他场景不需要访问
    public let needOnboarding: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    // MARK: - MyAIInfoService独用属性
    let rustClient: RustService?
    /// 是否开启MyAI功能：后台 + FG，如果没有开启，则主导航、联系人tab、Feed、大搜等处不应该显示MyAI入口
    let larkMyAIMainSwitch: Bool
    public let canOpenOthersAIProfile: Bool
    public let enable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    var quickActionsCache: [String: [AIQuickActionModel]] = [:]
    var quickActionsVersionCache: [String: Int64] = [:]

    /// MyAI的头像等信息，用户可以修改MyAI的头像；用于联系人tab实时更新入口
    public let info: BehaviorRelay<MyAIInfo> = BehaviorRelay<MyAIInfo>(value: MyAIInfo(
        id: "",
        name: BundleI18n.LarkAI.MyAI_Common_Faye_AiNameFallBack,
        avatarKey: "",
        avatarImage: UDIcon.myaiColorful)
    )

    /// MyAI 的默认资源，包括默认名称、小头像、大头像
    public var defaultResource: MyAIResource {
        MyAIResource(name: MyAIResourceManager.getMyAIBrandNameFromSetting(userResolver: userResolver),
                     iconSmall: Resources.my_ai_avatar_small,
                     iconLarge: Resources.my_ai_avatar_large)
    }

    // MARK: - MyAIChatModeService独用属性
    let myAiAPI: MyAIAPI?

    // MARK: - MyAIExtensionService独用属性
    /// 用于选择插件后给其他业务进行监听
    public let selectedExtension: BehaviorRelay<MyAIExtensionCallBackInfo> = BehaviorRelay<MyAIExtensionCallBackInfo>(value: MyAIExtensionCallBackInfo.default)

    // MARK: - MyAISceneService独用属性
    public var cacheScenes: [ServerPB_Office_ai_MyAIScene] = []
    /// 场景创建成功：本设备，非多端同步
    public let createSceneSubject: PublishSubject<ServerPB_Office_ai_MyAIScene> = PublishSubject<ServerPB_Office_ai_MyAIScene>()
    /// 更新某个场景：本设备，非多端同步
    public let editSceneSubject: PublishSubject<ServerPB_Office_ai_MyAIScene> = PublishSubject<ServerPB_Office_ai_MyAIScene>()

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        self.rustClient = try? userResolver.resolve(assert: RustService.self)
        self.newGuideManager = try? userResolver.resolve(assert: NewGuideService.self)
        self.myAiAPI = try? userResolver.resolve(assert: MyAIAPI.self)
        self.larkMyAIMainSwitch = userResolver.fg.staticFeatureGatingValue(with: "lark.my_ai.main_switch")
        self.canOpenOthersAIProfile = userResolver.fg.staticFeatureGatingValue(with: "lark.my_ai.profile_by_others")
        MyAIServiceImpl.logger.info("my ai service init, lark.my_ai.main_switch: \(self.larkMyAIMainSwitch)")
        // 依次获取必要信息
        self.fetchMyAIEnable()
        self.getMyAIOnboarding(); self.fetchMyAIOnboarding()
        self.observableMyAIInfo()
    }

    // MARK: - MyAIOnboardingService、MyAIInfoService等协议之外方法
    public func pageService(userResolver: UserResolver, chatId: String, chatMode: Bool, chatModeConfig: MyAIChatModeConfig, chatFromWhere: ChatFromWhere) -> MyAIPageService {
        return MyAIPageServiceImpl(userResolver: userResolver, chatId: chatId, chatMode: chatMode, chatModeConfig: chatModeConfig, chatFromWhere: chatFromWhere)
    }

    public func imInlineService(delegate: IMMyAIInlineServiceDelegate, scenarioType: InlineAIConfig.ScenarioType) -> IMMyAIInlineService {
        return IMMyAIInlineServiceImpl(userResolver: self.userResolver, delegate: delegate, scenarioType: scenarioType)
    }

    public func stopGeneratingView(userResolver: UserResolver, chat: Chat, targetVC: UIViewController) -> UIView {
        let stopGeneratingViewModel = MyAIStopGeneratingViewModel(userResolver: userResolver, chat: chat)
        let stopGeneratingView = MyAIStopGeneratingView(viewModel: stopGeneratingViewModel)
        stopGeneratingView.targetVC = targetVC
        return stopGeneratingView
    }

    // MARK: - MyAIOnboardingService、MyAIInfoService等协议共用方法
    private let chatAPI: ChatAPI?
    /// 检测是否有ChatterId，然后再执行后续动作
    func checkChatterIdAndThen(exec: @escaping () -> Void) {
        MyAIServiceImpl.logger.info("my ai begin check chatter id")
        // 如果已经有chatterId，直接执行后续动作
        if !self.myAIChatterId.isEmpty {
            MyAIServiceImpl.logger.info("my ai finish check chatter id, already has chatter id")
            exec()
            return
        }

        MyAIServiceImpl.logger.info("my ai finish check chatter id, need fetch chatter")
        self.fetchMyAIInfo { [weak self] in
            guard let `self` = self else { return }
            if self.myAIChatterId.isEmpty { assertionFailure() }
            exec()
        }
    }

    /// 检测是否有ChatId，然后再执行后续动作
    func checkChatIdAndThen(exec: @escaping () -> Void) {
        MyAIServiceImpl.logger.info("my ai begin check chatid")
        // 如果已经有chatId，直接执行后续动作
        if self.myAIChatId > 0 {
            MyAIServiceImpl.logger.info("my ai finish check chatid, already has chatid")
            exec()
            return
        }

        // 如果没有chatId，则用ChatterId从远端拉取一次，和服务端确认可以通过此接口拉取
        MyAIServiceImpl.logger.info("my ai finish check chatid, need fetch chat")
        self.chatAPI?.fetchLocalP2PChatsByUserIds(uids: [self.myAIChatterId]).subscribe(onNext: { [weak self] (chats) in
            guard let `self` = self else { return }
            guard let chat = chats[self.myAIChatterId] else {
                MyAIServiceImpl.logger.info("my ai fetch chat error, no chat")
                assertionFailure()
                exec()
                return
            }
            self.myAIChatId = Int64(chat.id) ?? 0
            MyAIServiceImpl.logger.info("my ai fetch chat success, chatid: \(self.myAIChatId)")
            if self.myAIChatId <= 0 { assertionFailure() }
            exec()
        }, onError: { error in
            MyAIServiceImpl.logger.info("my ai fetch chat error, error: \(error)")
            assertionFailure()
            exec()
        }).disposed(by: self.disposeBag)
    }

}
