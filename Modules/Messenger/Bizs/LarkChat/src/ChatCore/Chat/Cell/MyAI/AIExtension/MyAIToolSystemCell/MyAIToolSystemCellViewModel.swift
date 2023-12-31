//
//  MyAIToolSystemCellViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/1.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkMessageCore
import LarkUIKit
import LKCommonsLogging
import LarkSetting
import LarkStorage
import RxSwift

open class MyAIToolSystemCellViewModel<C: PageContext>: CellViewModel<C> {
    private let logger = Logger.log(MyAIToolSystemCellViewModel.self, category: "MyAITool")
    private var binderUpdateMutex = pthread_mutex_t()
    override open var identifier: String {
        return "myAI-tool-system"
    }

    open private(set) var metaModel: CellMetaModel
    open var message: Message {
        return metaModel.message
    }

    open var chat: Chat {
        return metaModel.getChat()
    }

    var displayable: Bool {
        let cardExtensionFg = self.context.userResolver.fg.dynamicFeatureGatingValue(with: "lark.my_ai.card_swich_extension")
        guard self.context.userResolver.fg.staticFeatureGatingValue(with: "lark.my_ai.plugin"), let myAIPageService = self.context.myAIPageService, !cardExtensionFg else { return false }
        if !myAIPageService.chatMode,
           message.aiChatModeID > 0 {
            //my ai主会场的分会场消息不展示tools胶囊
            return false
        }
        return true
    }

    var newTopicCotent: SystemContent.SystemNewTopicContent {
        guard let systemContent = message.content as? SystemContent else { return .init() }
        return systemContent.systemExtraContent.newTopicSystemMessageExtraContent
    }

    var toolIds: [String] {
        return newTopicCotent.toolIds
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    var displayTopic: Bool {
        return true
    }

    open var centerText: String {
        return (message.content as? SystemContent)?.template ?? BundleI18n.AI.Lark_MyAI_IM_Server_StartNewTopic_Text
    }

    open var textFont: UIFont {
        return UIFont.ud.body2
    }

    open var textColor: UIColor {
        return UIColor.ud.textPlaceholder
    }

    open var isLastNewTopic: Bool {
        guard let myAIPageService = self.context.myAIPageService else {
            return false
        }
        // myAI分会场
        let isMyAIChatMode = myAIPageService.chatMode
        let aiRoundInfo = myAIPageService.aiRoundInfo.value
        if (aiRoundInfo.roundLastPosition > message.position && !isMyAIChatMode) ||
            (aiRoundInfo.roundLastPosition > message.threadPosition && isMyAIChatMode) {
            // 当前tools 已产生过会话，不是最新new topic
            self.logger.info("isLastNewTopic false")
            return false
        } else {
            self.logger.info("isLastNewTopic true")
            return true
        }
    }

    open var aiChatModeID: Int64 {
        let aiChatModeId = self.context.myAIPageService?.chatModeConfig.aiChatModeId ?? 0
        return aiChatModeId
    }

    open var isSingleMode: Bool {
        let userStore = KVStores.MyAITool.build(forUser: self.context.userResolver.userID)
        let isSingleExtensionMode = userStore[KVKeys.MyAITool.myAIModelType]
        self.logger.info("isSingleMode: \(isSingleExtensionMode)")
        return isSingleExtensionMode
    }

    public init(metaModel: CellMetaModel, context: C) {
        self.metaModel = metaModel
        pthread_mutex_init(&binderUpdateMutex, nil)
        super.init(context: context, binder: MyAIToolSystemCellComponentBinder(context: context))
        if let systemContent = message.content as? SystemContent {
            self.logger.info("init metaModel toolIds: \(systemContent.systemExtraContent.newTopicSystemMessageExtraContent.toolIds) messageId:\(self.message.id)")
        }
        self.calculateRenderer()
        self.listenAIExtensionConfig()
    }

    public func update(metaModel: CellMetaModel) {
        self.metaModel = metaModel
        if let systemContent = message.content as? SystemContent {
            self.logger.info("update metaMode toolIds: \(systemContent.systemExtraContent.newTopicSystemMessageExtraContent.toolIds) messageId:\(self.metaModel.message.id)")
        }
        self.calculateRenderer()
    }

    func listenAIExtensionConfig() {
        guard let myAIPageService = self.context.myAIPageService else {
            self.logger.info("myAIPageService is nil")
            return
        }
        myAIPageService.aiExtensionConfig.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("aiExtensionConfig reload")
            self.calculateRenderer()
            self.safeUpdate(animation: .none)
        }).disposed(by: self.disposeBag)
        // 目前能达到效果的前提是因为aiRoundInfo会先更新，而refreshExtension信号后发出，不然的话isLastNewTopic还是和之前一样就有bug了
        // 目前依赖UITableView滚动触发ChatMessagesViewController-getLastNewTopicSystemMsgPosition，再按需触发refreshExtension信号
        // 后面重构为监听aiRoundInfo，不需要refreshExtension信号了
        myAIPageService.refreshExtension.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] messageId in
            guard let self = self, self.message.id == messageId else { return }
            self.logger.info("refreshExtension reload messageId:\(messageId)")
            self.calculateRenderer()
            self.safeUpdate(animation: .none)
        }).disposed(by: self.disposeBag)
    }

    private func safeUpdate(animation: UITableView.RowAnimation) {
        pthread_mutex_lock(&binderUpdateMutex)
        self.binder.update(with: self)
        self.context.reloadRow(by: self.message.id, animation: animation)
        pthread_mutex_unlock(&binderUpdateMutex)
    }

    public func tapCloseAction() {
        self.logger.info("click close current tool")
    }

    public func tapAction(toolIds: [String]) {
        let chat = self.metaModel.getChat()
        if chat.isInMeetingTemporary {
            if let targetVC = self.context.targetVC {
                UDToast.showTips(with: "", on: targetVC.view)
            }
            return
        }
        guard let myAIPageService = self.context.myAIPageService else {
            self.logger.info("myAIPageService is nil")
            return
        }
        // myAI分会场
        let isMyAIChatMode = myAIPageService.chatMode
        let aiRoundInfo = myAIPageService.aiRoundInfo.value
        let aiChatModeId = myAIPageService.chatModeConfig.aiChatModeId
        let extra = ["messageId": message.id, "chatId": chat.id, "source": "systemMessage"]
        self.logger.info("click tool roundLastPosition:\(aiRoundInfo.roundLastPosition) currentPosition\(message.position) isMyAIChatMode:\(isMyAIChatMode) " +
                         "lastThreadPosition:\(chat.lastThreadPosition) threadPosition:\(message.threadPosition)")
        if (aiRoundInfo.roundLastPosition > message.position && !isMyAIChatMode) ||
            (aiRoundInfo.roundLastPosition > message.threadPosition && isMyAIChatMode) {
            self.logger.info("newTopicSelected toolIds: \(self.toolIds) messageId:\(message.id) aiChatModeId:\(aiChatModeId)")
            //当前tools 已产生过会话，不可以修改了，只可查看详情
            let myAIToolsService = try? self.context.userResolver.resolve(assert: MyAIToolsService.self)
            let toolsSelectedPanel = myAIToolsService?.generateAIToolSelectedUDPanel(panelConfig: MyAIToolsSelectedPanelConfig(
                userResolver: self.context.userResolver,
                toolIds: toolIds,
                aiChatModeId: aiChatModeId,
                myAIPageService: myAIPageService,
                extra: extra),
                                                            chat: self.chat)
            toolsSelectedPanel?.show(from: context.targetVC)
        } else {
            self.logger.info("newTopicUnSelect toolIds: \(newTopicCotent.toolIds) messageId:\(message.id) \(toolIds)")
            let body = MyAIToolsBody(chat: self.chat,
                                     scenario: myAIPageService.chatModeConfig.objectType.getScenarioID(),
                                     selectedToolIds: toolIds,
                                     aiChatModeId: self.message.aiChatModeID,
                                     myAIPageService: myAIPageService,
                                     extra: extra)
            context.navigator(
                type: .present,
                body: body, params: NavigatorParams(
                    wrap: LkNavigationController.self
                )
            )
        }
    }
}

final class MyAIToolSystemCellComponentBinder<C: PageContext>: ComponentBinder<C> {
    private let logger = Logger.log(MyAIToolSystemCellComponentBinder.self, category: "MyAITool")
    let props = MyAIToolSystemCellComponent<C>.Props()
    let style = ASComponentStyle()

    lazy var _component: MyAIToolSystemCellComponent<C> = .init(props: .init(), style: .init())

    override var component: MyAIToolSystemCellComponent<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MyAIToolSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        self.logger.info("update newTopic toolIds: \(vm.newTopicCotent.toolIds) messageId:\(vm.message.id)")
        props.chatComponentTheme = vm.chatComponentTheme
        props.centerText = vm.centerText
        props.displayTopic = vm.displayTopic
        component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = MyAIToolSystemCellComponent(props: props, style: style, context: context)
    }
}
