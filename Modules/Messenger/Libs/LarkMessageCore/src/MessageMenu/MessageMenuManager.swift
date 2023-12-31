//
//  MessageMenuServiceImp.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/20.
//

import Foundation
import LarkMessageBase
import LarkOpenChat
import LarkModel
import LarkCore
import RxSwift
import LarkSDKInterface
import LarkContainer
import LarkMenuController
import LarkSheetMenu
import LarkEmotion
import LarkEmotionKeyboard
import LarkAccountInterface
import UniverseDesignMenu
import Homeric
import LKCommonsTracker
import LarkLocalizations
import UniverseDesignToast
import LarkSetting
import LarkMessengerInterface
import LarkFeatureGating
import LKCommonsLogging

private let logger = Logger.log(MessageMenuOpenService.self)
/// IM内部的消息菜单服务实现, 旧有MenuManager能力的增强
/// 实现OpenChat内的MenuService协议, 将两种菜单UI的能力进行封装向外暴露
public class MessageMenuServiceImp<C: MessageActionContext>: MessageMenuOpenService {
    private lazy var reactionService: ReactionService? = {
        return try? self.actionModule.context.userResolver.resolve(assert: ReactionService.self)
    }()
    private lazy var abTestService: MenuInteractionABTestService? = {
        return try? self.actionModule.context.userResolver.resolve(assert: MenuInteractionABTestService.self)
    }()

    public var isSheetMenu: Bool {
        return self.messageMenuType == .sheet
    }

    public var hasDisplayMenu: Bool { self.hasMenu }

    /// 根据用户选择的语言环境来决定消息菜单的样式 不同语言展示的状态不同
    private lazy var messageMenuType: MessageMeenuType = {
        /// 海外版消息菜单FG
        let fgService = self.actionModule.userResolver.fg
        if !fgService.staticFeatureGatingValue(with: "messenger.message.mobile_message_menu_transformation") {
            return .hover
        }

        if fgService.staticFeatureGatingValue(with: "messenger.message.mobile_message_menu_language") {
            return .sheet
        }
        switch LanguageManager.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            return .hover
        default:
            return .sheet
        }
    }()

    public var currentSelectedRect: (() -> CGRect?)?
    private var hasCursor: Bool {
        return currentSelectedRect != nil
    }

    public func hideMenuIfNeeded (animated: Bool) {
        switch messageMenuType {
        case .sheet:
            if currentSelectedRect != nil {
                // 有选中区域先隐藏菜单
                sheetMenu?.hide(animated: animated, completion: nil)
            } else {
                // 无文本选区第一次隐藏直接dismiss
                sheetMenu?.dismiss(completion: nil)
            }
        case .hover:
            hoverMenu?.hiddenMenuBar(animation: animated)
        }
    }

    public func unhideMenuIfNeeded(animated: Bool) {
        switch messageMenuType {
        case .sheet:
            if isInPartialSelectMode {
                sheetMenu?.showMenu(animated: animated)
            }
        case .hover:
            hoverMenu?.showMenuBar(animation: animated)
        }
    }

    lazy var reactionHandler = ReactionMenuActionHandler(
        currentChatterId: self.actionModule.context.userResolver.userID,
        scene: .newChat,
        reactionAPI: try? self.actionModule.context.userResolver.resolve(assert: ReactionAPI.self),
        targetVC: self.actionModule.context.pageAPI ?? UIViewController())

    private let actionModule: BaseMessageActionModule<C>
    private let pushWrapper: ChatPushWrapper?
    // 部分场景没有订阅更新机制,只能传入chat
    private let _chat: Chat?
    private let disposeBag: DisposeBag = DisposeBag()

    /// MenuManager宿主Chat
    private var chat: Chat! {
        if let pushWrapper = self.pushWrapper {
            return pushWrapper.chat.value
        } else if let _chat = self._chat {
            return _chat
        } else {
            assertionFailure("both wrapper and chat equals nil")
            return nil
        }
    }

    private var hasMenu: Bool {
        return sheetMenu != nil || hoverMenu != nil
    }

    /// 当前正在展示菜单的Message
    public private(set) var currentMessage: Message?
    /// 当前的顶部菜单压缩状态
    private var currrentTopCompressState: Bool = false
    /// 当前正在展示菜单的View
    public weak var currentTriggerView: UIView?
    private var currentOpenState: Bool = true
    /// 当前光标选择类型
    public private(set) var currentSelectType: CopyMessageSelectedType? {
        didSet {
            switch oldValue {
            case .none:
                if isInPartialSelectMode == true {
                    updateMenuDataWithCurrent()
                }
            case .all:
                if isInPartialSelectMode == true {
                    updateMenuDataWithCurrent()
                }
            default:
                if isInPartialSelectMode == false {
                    updateMenuDataWithCurrent()
                }
            }
        }
    }
    /// 当前正在展示菜单的触发点击类型
    public private(set) var currentCopyType: CopyMessageType?
    /// 当前正在展示菜单的触发Component特征值
    public private(set) var currentComponentKey: String?
    /// 当前是否在局部选择状态
    private var isInPartialSelectMode: Bool {
        // sheet样式菜单进入部分选择态后锁定在局部选择状态
        if currentForceInPartialSelectMode {
            return true
        }
        switch currentSelectType {
        case .all: return false
        case .none:
            return false
        default:
            // sheet样式菜单一旦进入部分选择态,会锁定状态
            if messageMenuType == .sheet {
                currentForceInPartialSelectMode = true
            }
            return true
        }
    }
    private var currentForceInPartialSelectMode: Bool = false

    /// 当前正在展示的HoverMenuVC的VM
    weak var currentHoverMenuVM: HoverMenuViewModel?
    /// 当前菜单的开启展示的时间
    private var currentStartTime: TimeInterval?
    /// 当前菜单展示时长
    private var currentDisplayDuration: TimeInterval? {
        if let startTime = currentStartTime {
            return Date().timeIntervalSince1970 - startTime
        } else {
            return nil
        }
    }
    private weak var sheetMenu: LarkSheetMenuInterface?
    private weak var hoverMenu: MenuVCProtocol?

    /// MessageMenuServiceDelegate
    public weak var delegate: MessageMenuServiceDelegate?

    /// 获取最上层的 UIViewController
    private var targetVC: UIViewController? {
        guard let vc: UIViewController = actionModule.context.pageAPI else { return nil }
        if let topVC = vc.navigationController?.topViewController {
            return topVC
        } else {
            return vc
        }
    }

    /// 更新光标选择状态
    /// - Parameter selected: 新的选择类型
    public func updateMenuSelectInfo(_ selected: CopyMessageSelectedType) {
        guard (messageMenuType == .sheet && sheetMenu != nil) || (messageMenuType == .hover && hoverMenu != nil) else { return }
        currentSelectType = selected
    }

    /// Update Message Action Module IF Could Use Current Info
    fileprivate func updateMenuDataWithCurrent() {
        guard let message = currentMessage else {
            return
        }
        let model = MessageActionMetaModel(chat: chat,
                                           message: message,
                                           myAIChatMode: (try? self.actionModule.context.userResolver.resolve(type: MyAIPageService.self))?.chatMode ?? false,
                                           isOpen: currentOpenState,
                                           copyType: currentCopyType ?? .message,
                                           isInPartialSelect: isInPartialSelectMode,
                                           selected: { [weak self] in self?.currentSelectType ?? .all })
        actionModule.handler(model: model)
        switch messageMenuType {
        case .hover:
            let items = self.getMenuActionItems(message: message)
            currentHoverMenuVM?.update(showEmojiHeader: actionModule.showEmojiHeader, actionItems: items)
        case .sheet:
            sheetMenu?.updateMenuWith(getSheetMenuDatasource(message: message), willShowInPartial: isInPartialSelectMode)
        }
        self.trackMenuView()
    }

    /// 更新当前存在菜单数据
    fileprivate func updateMenuData(with message: Message, info: MessageMenuExtraInfo) {
        /// 固化当前状态
        self.currentMessage = message
        self.currentComponentKey = info.selectConstraintKey
        self.currentCopyType = info.copyType
        self.currentOpenState = info.isOpen
        self.currentStartTime = Date().timeIntervalSince1970
        /// 通知Module生产按钮
        let model = MessageActionMetaModel(chat: chat,
                                           message: message,
                                           myAIChatMode: (try? self.actionModule.context.userResolver.resolve(type: MyAIPageService.self))?.chatMode ?? false,
                                           isOpen: currentOpenState,
                                           copyType: currentCopyType ?? .message,
                                           isInPartialSelect: isInPartialSelectMode,
                                           selected: { [weak self] in self?.currentSelectType ?? .all })
        actionModule.handler(model: model)
        self.trackMenuView()
    }

    /// 根据Message获取菜单无分组面板按钮数据
    fileprivate func getMenuActionItems(message: Message) -> [MenuActionItem] {
        let model = MessageActionMetaModel(chat: chat,
                                           message: message,
                                           myAIChatMode: (try? self.actionModule.context.userResolver.resolve(type: MyAIPageService.self))?.chatMode ?? false,
                                           isOpen: currentOpenState,
                                           copyType: currentCopyType ?? .message,
                                           isInPartialSelect: isInPartialSelectMode,
                                           selected: { [weak self] in self?.currentSelectType ?? .all })
        return actionModule.getActionItems(model: model).map { actionItem in
            let action = getTapAction(actionItem, message: message)
            return MenuActionItem(name: actionItem.text,
                                  image: actionItem.icon,
                                  enable: !actionItem.isGrey,
                                  isShowDot: actionItem.showDot,
                                  action: { _ in action() },
                                  disableAction: actionItem.isGrey ? { _ in action() } : nil)
        }
    }

    /// 根据Message获取菜单分组后面板按钮数据
    fileprivate func getMenuActionItemSections(message: Message) -> [[MessageActionItem]] {
        let model = MessageActionMetaModel(chat: self.chat,
                                           message: message,
                                           myAIChatMode: (try? self.actionModule.context.userResolver.resolve(type: MyAIPageService.self))?.chatMode ?? false,
                                           isOpen: currentOpenState,
                                           copyType: currentCopyType ?? .message,
                                           isInPartialSelect: isInPartialSelectMode,
                                           selected: { [weak self] in self?.currentSelectType ?? .all })
        return actionModule.getActionItemSections(model: model)
    }

    private func showErrorToast(str: String) {
        let toView: UIView
        switch messageMenuType {
        case .hover:
            guard let view = self.hoverMenu?.view else { return }
            toView = view
        case .sheet:
            guard let view = self.sheetMenu?.view else { return }
            toView = view
        }
        UDToast.showFailure(with: str, on: toView)
    }

    private func getTapAction(_ item: MessageActionItem, message: Message) -> (() -> Void) {
        let action: () -> Void
        if item.isGrey {
            switch item.disableActionType {
            case .showToast(let errorMessage):
                action = { [weak self] in
                    self?.showErrorToast(str: errorMessage)
                }
            case .action(let disableAction):
                action = disableAction
            case .none:
                action = {}
            }
        } else {
            action = { [weak self] in
                guard let self = self else { return }
                if item.subItems.isEmpty {
                    self.dissmissMenu(completion: {
                        item.tapAction()
                    })
                } else {
                    item.tapAction()
                }
                /// 菜单按钮埋点收敛,统一上报
                self.trackMenuClick(params: item.trackExtraParams)
            }
        }
        return action
    }

    ///
    fileprivate func getSheetMenuDatasource(message: Message) -> [LarkSheetMenuActionSection] {
        self.getMenuActionItemSections(message: message).map { section in
            return LarkSheetMenuActionSection(section.map { item in
                let subItems = item.subItems.map { LarkSheetMenuActionItem(icon: $0.icon,
                                                                           text: $0.text,
                                                                           isShowDot: $0.showDot,
                                                                           isGrey: $0.isGrey,
                                                                           subItems: [],
                                                                           subText: $0.subText,
                                                                           tapAction: getTapAction($0, message: message))
                }
                return LarkSheetMenuActionItem(icon: item.icon,
                                               text: item.text,
                                               isShowDot: item.showDot,
                                               isGrey: item.isGrey,
                                               subItems: subItems,
                                               subText: item.subText,
                                               tapAction: getTapAction(item, message: message))
            })
        }
    }

    private func forcedDismissAll() {
        if let menu = sheetMenu {
            menu.dismiss(completion: nil)
            sheetMenu = nil
        }
        if let menu = hoverMenu {
            menu.dismiss(animated: false, params: nil, completion: nil)
            hoverMenu = nil
        }
    }

    private func resetCurrent() {
        forcedDismissAll()
        /// 重置当前菜单参数
        self.currentForceInPartialSelectMode = false
        self.currentMessage = nil
        self.currentComponentKey = nil
        self.currentCopyType = nil
        self.currentSelectType = nil
        self.currentHoverMenuVM = nil
        self.currentTriggerView = nil
        self.currentSelectedRect = nil
        self.currrentTopCompressState = false
        self.currentStartTime = nil
        self.currentOpenState = true
    }

    /// 展示消息菜单
    public func showMenu(
        message: Message,
        source: MessageMenuLayoutSource,
        extraInfo: MessageMenuExtraInfo) {
            /// 防止重复唤起菜单
            guard !hasMenu else { return }
            #if DEBUG || ALPHA
            /// 调用菜单时，检查是否对菜单项进行了处理
            checkIntegrityForMenu()
            #endif
            /// 调起菜单前, 清空当前界面的菜单逻辑避免逻辑影响
            resetCurrent()
            guard let targetVC = targetVC else { return }
            updateMenuData(with: message, info: extraInfo)
            /// 唤起菜单
            switch messageMenuType {
            case .hover:
                self.showHoverMenu(fromVC: targetVC,
                                   message: message,
                                   source: source,
                                   selectConstraintKey: extraInfo.selectConstraintKey)
            case .sheet:
                self.showSheetMenu(fromVC: targetVC,
                                   message: message,
                                   source: source,
                                   selectConstraintKey: extraInfo.selectConstraintKey,
                                   layout: DefaultLarkSheetMenuLayout(messageOffset: extraInfo.messageOffset,
                                                                      expandedSheetHeight: extraInfo.expandedSheetHeight,
                                                                      moreViewMaxHeight: extraInfo.moreViewMaxHeight))
            }
        }

    #if DEBUG || ALPHA
    /// 新增菜单项之后，检查三类菜单是否都有处理
    func checkIntegrityForMenu() {

        let MessageActionAllCases = Set(MessageActionType.allCases)
        let hoverAction = Set(MessageActionOrder.hover + MessageActionOrder.unusedHoverAction)
        let sheetAction = Set(MessageActionOrder.defaultSheet.flatMap { $0 } + MessageActionOrder.unusedSheetAction)
        let settingAction = Set(
            MessageActionOrder.settingToMenuType.values.flatMap { $0 } + MessageActionOrder.unusedSettingAction
        )
        if MessageActionAllCases != hoverAction {
            /// MessageActionOrder.hover是旧版菜单，请注意是否处理了对应的菜单项
            fatalError("there is a menu item not handle in HoverMenu")
        }
        if MessageActionAllCases != sheetAction {
            /// MessageActionOrder.defaultSheet 是新版菜单的兜底，请注意是否处理了对应的菜单项
            fatalError("there is a menu item not handle in SheetDefaultMenu")
        }
        if MessageActionAllCases != settingAction {
            /// MessageActionOrder.settingToMenuType 是setting到本地菜单的映射，请注意是否添加了映射
            fatalError("there is a menu item not handle in Setting")
        }
    }
    #endif

    /// 隐藏并销毁消息菜单
    public func dissmissMenu(completion: (() -> Void)?) {
        if let menu = sheetMenu {
            menu.dismiss(completion: completion)
        }
        if let menu = hoverMenu {
            menu.dismiss(animated: true, params: nil, completion: completion)
        }
    }

    public init(pushWrapper: ChatPushWrapper,
                actionModule: BaseMessageActionModule<C>) {
        self.actionModule = actionModule
        self.pushWrapper = pushWrapper
        self._chat = nil
    }

    @available(*, message: "直接传入chat会导致MenuManager的chat无法接受更新push,若页面存在chatwrapper,请使用chatwrapper")
    public init(chat: Chat,
                actionModule: BaseMessageActionModule<C>) {
        self.actionModule = actionModule
        self.pushWrapper = nil
        self._chat = chat
    }
}

enum MessageMeenuType {
    case hover
    case sheet
}

/// 表情相关
extension MessageMenuServiceImp {
    private var userReactionKeys: [String] {
        return reactionService?.getMRUReactions().map { $0.key } ?? []
    }

    private var allReactionGroups: [ReactionGroup] {
        return reactionService?.getAllReactions() ?? []
    }

    private func createClickReactionBlock(message: Message, chat: Chat) -> ClickReactionBlock {
        return { [weak self] reactionKey, index, isSkintonePanel, skintoneEmojiSelectWay in
            guard let self = self else { return }
            self.dissmissMenu(completion: { [weak self] in
                self?.reactionHandler.handle(message: message,
                                             chat: chat,
                                             reactionKey: reactionKey,
                                             reactionSource: .ReactionPanel(index),
                                             isSkintonePanel: isSkintonePanel,
                                             skintoneEmojiSelectWay: skintoneEmojiSelectWay,
                                             time: self?.currentDisplayDuration ?? 0)
            })
        }
    }

    private func createUserReactionItem(keys: [String], message: Message, chat: Chat) -> [MenuReactionItem] {
        return keys.map { keyStr -> MenuReactionItem in
            let reactionEntity = ReactionEntity(key: keyStr,
                                        selectSkinKey: keyStr,
                                        skinKeys: [],
                                        size: EmotionResouce.shared.sizeBy(key: keyStr))
            return MenuReactionItem(reactionEntity: reactionEntity, action: { [weak self] keyStr in
                guard let self = self else { return }
                self.reactionHandler.handle(message: message,
                                            chat: chat,
                                            reactionKey: keyStr,
                                            reactionSource: .ReactionBar,
                                            time: self.currentDisplayDuration ?? 0)
                self.dissmissMenu(completion: nil)
            })
        }
    }
}

///展示悬浮菜单
extension MessageMenuServiceImp {
    func generateMenuViewModel(actionItems: [MenuActionItem], message: Message, chat: Chat) -> MenuBarViewModel {
        let menuVM = HoverMenuViewModel(
            recentReactionMenuItems: actionModule.showEmojiHeader ? createUserReactionItem(keys: userReactionKeys, message: message, chat: chat) : [],
            clickReactionBlock: self.createClickReactionBlock(message: message, chat: chat),
            allReactionGroups: self.allReactionGroups,
            actionItems: actionItems)
        currentHoverMenuVM = menuVM
        menuVM.menuBar.reactionBarAtTop = false
        menuVM.menuBar.reactionSupportSkinTones = true
        return menuVM
    }
    func showHoverMenu(
        fromVC: UIViewController,
        message: Message,
        source: MessageMenuLayoutSource,
        selectConstraintKey: String?) {
            let menuItems = getMenuActionItems(message: message)
            if menuItems.isEmpty && !actionModule.showEmojiHeader {
                return
            }
            /// 通知消息选择控制器将要唤起菜单
            delegate?.messageMenuWillLoad(self,
                                          message: message,
                                                                componentConstant: selectConstraintKey)
            let menuViewModel = generateMenuViewModel(actionItems: menuItems, message: message, chat: chat)
            let layout = ChatMenuLayout(
                insets: source.inserts,
                displayViewBlcok: { [weak self] _ in
                    if let self = self {
                        return source.displayViewBlcok?(self.hasCursor)
                    } else {
                        return nil
                    }
                },
                isNewLayoutStyle: actionModule.useNewLayout,
                extraInfo: [:]
            )
            let menuVc = MenuViewController(
                viewModel: menuViewModel,
                layout: layout,
                trigerView: source.trigerView,
                trigerLocation: source.trigerLocation
            )
            self.hoverMenu = menuVc
            self.currentTriggerView = source.trigerView
            delegate?.messageMenuDidLoad(self, message: message, touchTest: self)
            menuVc.delegate = self
            menuVc.show(in: fromVC)
        }
}

///展示弹出式菜单
extension MessageMenuServiceImp {
    private var sheetHeader: LarkSheetMenuHeader {
        if let message = currentMessage, actionModule.showEmojiHeader {
            return .emoji(createUserReactionItem(keys: userReactionKeys, message: message, chat: chat))
        } else {
            return .invisible
        }
    }
    func showSheetMenu(
        fromVC: UIViewController,
        message: Message,
        source: MessageMenuLayoutSource,
        selectConstraintKey: String?,
        layout: LarkSheetMenuLayout) {
            let moduleSections = getMenuActionItemSections(message: message)
            let showHeader = actionModule.showEmojiHeader
            if moduleSections.flatMap { $0 }.isEmpty && !showHeader {
                return
            }
            let sections = getSheetMenuDatasource(message: message)
            /// 通知消息选择控制器将要唤起菜单
            delegate?.messageMenuWillLoad(self,
                                          message: message,
                                          componentConstant: selectConstraintKey)
            let vm = LarkSheetMenuViewModel(dataSource: sections,
                                            header: sheetHeader,
                                            moreView: .emoji(allReactionGroups, self.createClickReactionBlock(message: message, chat: chat)))
            let trigger: UIView
            if let cell = (source.trigerView as? MessageCommonCell)?.getView(by: PostViewComponentConstant.bubbleKey) {
                trigger = cell
            } else {
                trigger = source.trigerView
            }
            let menuVc = LarkSheetMenu.getMenu(model: vm,
                                               delegate: self,
                                               trigger: trigger,
                                               selected: hasCursor ? source.displayViewBlcok?(true) : nil,
                                               partialRect: currentSelectedRect,
                                               layout: layout)
            self.currentTriggerView = source.trigerView
            self.sheetMenu = menuVc
            delegate?.messageMenuDidLoad(self, message: message, touchTest: self)
            self.sheetMenu?.show(in: fromVC)
        }
}

/// 不同样式菜单触控管理收敛接口
extension MessageMenuServiceImp: MenuTouchTestInterface {
    public var enableTransmitTouch: Bool {
        get {
            switch messageMenuType {
            case .sheet: return sheetMenu?.enableTransmitTouch ?? false
            case .hover: return hoverMenu?.enableTransmitTouch ?? false
            }
        }
        set {
            switch messageMenuType {
            case .sheet: sheetMenu?.enableTransmitTouch = newValue
            case .hover: hoverMenu?.enableTransmitTouch = newValue
            }
        }
    }

    public var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? {
        get {
            switch messageMenuType {
            case .sheet: return sheetMenu?.handleTouchArea
            case .hover: return hoverMenu?.handleTouchArea
            }
        }
        set {
            switch messageMenuType {
            case .sheet: sheetMenu?.handleTouchArea = newValue
            case .hover: hoverMenu?.handleTouchArea = newValue
            }
        }
    }

    public var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? {
        get {
            switch messageMenuType {
            case .sheet: return sheetMenu?.handleTouchView
            case .hover: return hoverMenu?.handleTouchView
            }
        }
        set {
            switch messageMenuType {
            case .sheet: sheetMenu?.handleTouchView = newValue
            case .hover: hoverMenu?.handleTouchView = newValue
            }
        }
    }
}
/// 老版菜单生命周期代理
extension MessageMenuServiceImp: MenuVCLifeCycleDelegate {
    public func menuWillAppear(_ menuVC: MenuVCProtocol) {
        #if DEBUG
        if !(menuVC === hoverMenu) {
            fatalError("menu not found!")
        }
        #endif
        delegate?.messageMenuWillAppear(self)
    }
    public func menuDidAppear(_ menuVC: MenuVCProtocol) {
        #if DEBUG
        if !(menuVC === hoverMenu) {
            fatalError("menu not found!")
        }
        #endif
        delegate?.messageMenuDidAppear(self)
    }
    public func menuWillDismiss(_ menuVC: MenuVCProtocol) {
        #if DEBUG
        if !(menuVC === hoverMenu) {
            fatalError("menu not found!")
        }
        #endif
        delegate?.messageMenuWillDismiss(self)
    }
    public func menuDidDismiss(_ menuVC: MenuVCProtocol) {
        #if DEBUG
        if !(menuVC === hoverMenu) {
            fatalError("menu not found!")
        }
        #endif
        delegate?.messageMenuDidDismiss(self)
        self.hoverMenu = nil
    }
}
/// 新版菜单代理
extension MessageMenuServiceImp: SheetMenuLifeCycleDelegate {
    private func highlight(_ highlight: Bool) {
        ((currentTriggerView as? MessageCommonCell)?
            .getView(by: MessageCommonCell.highlightBubbleViewKey) as? CanHighlightFront)?
            .setHighlighted(highlight)
    }

    public func suggestVerticalOffset(_ menuVC: LarkSheetMenuInterface, offset: MenuVerticalOffset) {
        switch offset {
        case .normalSizeBegin(let cGFloat):
            delegate?.offsetTableView(self, offset: .normalSizeBegin(cGFloat))
        case .longSizeBegin(let view):
            delegate?.offsetTableView(self, offset: .longSizeBegin(view))
        case .move(let cGFloat):
            delegate?.offsetTableView(self, offset: .move(cGFloat))
        case .end:
            delegate?.offsetTableView(self, offset: .end)
        }
    }

    public func menuWillExpand(_ menuVC: LarkSheetMenuInterface) {
        self.currrentTopCompressState = true
    }

    public func menuWillAppear(_ menuVC: LarkSheetMenuInterface) {
        delegate?.messageMenuWillAppear(self)
        if currentSelectedRect == nil {
            highlight(true)
        }
    }

    public func menuDidAppear(_ menuVC: LarkSheetMenuInterface) {
        delegate?.messageMenuDidAppear(self)
    }

    public func menuWillDismiss(_ menuVC: LarkSheetMenuInterface) {
        highlight(false)
        delegate?.messageMenuWillDismiss(self)
    }
    public func menuDidDismiss(_ menuVC: LarkSheetMenuInterface) {
        delegate?.messageMenuDidDismiss(self)
        self.sheetMenu = nil
    }
}

// IM内菜单相关埋点上报收敛
extension MessageMenuServiceImp {
    var pageTypeParam: [AnyHashable: Any] {
        switch messageMenuType {
        case .hover:
            return ["page_type": "floating_menu"]
        case .sheet:
            return ["page_type": "overlay_menu"]
        }
    }
    func trackMenuClick(params: [AnyHashable: Any]) {
        guard let message = currentMessage else { return }
        var params = params
        params += IMTracker.Param.message(message, doc: true)
        params += IMTracker.Param.chat(chat)
        params += pageTypeParam
        if let duration = currentDisplayDuration {
            params += ["show_time": Int(duration)]
        }
        let event = (isInPartialSelectMode == true) ? "im_msg_select_text_menu_click" : Homeric.IM_MSG_MENU_CLICK
        Tracker.post(TeaEvent(event,
                              params: params,
                              md5AllowList: ["file_id"],
                              bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
    }
    func trackMenuView() {
        guard let message = currentMessage else { return }
        var params: [AnyHashable: Any] = [:]
        params += IMTracker.Param.message(message, doc: true)
        params += IMTracker.Param.chat(self.chat)
        params += pageTypeParam

        if isInPartialSelectMode != true, !self.chat.isCrypto {
            let result: Int
            switch self.abTestService?.abTestResult ?? .none {
            case .radical:
                result = 2
            case .gentle:
                result = 1
            case .none:
                result = 0
            }
            params += ["ab_version": result]
        }

        let event = (isInPartialSelectMode == true) ? "im_msg_select_text_menu_view" : Homeric.IM_MSG_MENU_VIEW
        Tracker.post(TeaEvent(event,
                              params: params,
                              md5AllowList: ["file_id"],
                              bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
    }
}
