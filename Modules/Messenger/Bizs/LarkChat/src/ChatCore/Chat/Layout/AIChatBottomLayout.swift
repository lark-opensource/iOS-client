//
//  AIChatBottomLayout.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/13.
//
import Foundation
import LarkContainer
import LarkCore
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsLogging
import LarkMessageCore
import LarkOpenChat
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkRustClient
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import RustPB
import SnapKit
import EditTextView
import LarkChatKeyboardInterface
import LarkNavigator
import TangramService
import ByteWebImage
import LarkSendMessage
import LarkStorage
import LarkKeyCommandKit
import UIKit
import LarkUIKit

protocol AIChatBottomLayoutDelegate: AnyObject {
    var tableHeightLock: Bool { get }
    func keyboardContentHeightWillChange(_ isFold: Bool)
    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType)
    func removeHightlight(needRefresh: Bool)
}

class AIChatBottomLayout: NSObject, UserResolverWrapper {
    static let logger = Logger.log(AIChatBottomLayout.self, category: "Module.IM.Message")
    private var componentGenerator: ChatViewControllerComponentGeneratorProtocol
    var chatBottomStatus: ChatBottomStatus = .none(display: true)
    private let chatWrapper: ChatPushWrapper
    let userResolver: UserResolver
    internal let chatFromWhere: ChatFromWhere
    let chatId: String
    private let chatKeyPointTracker: ChatKeyPointTracker
    private let pushCenter: PushNotificationCenter
    private let keyBoardTopExtendContext: ChatKeyboardTopExtendContext
    private let tableView: ChatTableView
    private var guideManager: ChatBaseGuideManager?
    /// 定制键盘初始化状态
    private let keyboardStartState: KeyboardStartupState

    @ScopedInjectedLazy var chatAPI: ChatAPI?

    private var chat: BehaviorRelay<Chat> {
        return self.chatWrapper.chat
    }

    weak var delegate: AIChatBottomLayoutDelegate?

    private let disposeBag: DisposeBag = DisposeBag()

    private weak var _containerViewController: UIViewController?
    var containerViewController: UIViewController {
        return self._containerViewController ?? UIViewController()
    }

    private let isMyAIChatMode: Bool
    private var getMessageSender: () -> MessageSender?
    private let context: ChatModuleContext
    private var viewDidAppeared = false

    init(userResolver: UserResolver,
         context: ChatModuleContext,
         chatWrapper: ChatPushWrapper,
         componentGenerator: ChatViewControllerComponentGeneratorProtocol,
         containerViewController: UIViewController,
         chatFromWhere: ChatFromWhere,
         chatKeyPointTracker: ChatKeyPointTracker,
         pushCenter: PushNotificationCenter,
         tableView: ChatTableView,
         delegate: AIChatBottomLayoutDelegate?,
         guideManager: ChatBaseGuideManager?,
         keyboardStartState: KeyboardStartupState,
         isMyAIChatMode: Bool,
         getMessageSender: @escaping () -> MessageSender?) {
        self.componentGenerator = componentGenerator
        self._containerViewController = containerViewController
        self.userResolver = userResolver
        self.chatWrapper = chatWrapper
        self.chatFromWhere = chatFromWhere
        self.chatId = chatWrapper.chat.value.id
        self.chatKeyPointTracker = chatKeyPointTracker
        self.context = context
        self.pushCenter = pushCenter
        self.keyBoardTopExtendContext = context.keyBoardTopExtendContext
        self.tableView = tableView
        self.delegate = delegate
        self.guideManager = guideManager
        self.keyboardStartState = keyboardStartState
        self.isMyAIChatMode = isMyAIChatMode
        self.getMessageSender = getMessageSender
    }

    private lazy var _messageSender: MessageSender? = {
        return self.getMessageSender()
    }()

    private var messageSender: MessageSender? {
        switch self.chatBottomStatus {
        case .none:
            return nil
        default:
            return _messageSender
        }
    }

    private lazy var quasiMsgCreateByNative: Bool = {
        return false
    }()

    /// 键盘区域
    private var _defaultKeyboard: ChatInternalKeyboardService?
    var defaultKeyboard: ChatInternalKeyboardService? {
        switch self.chatBottomStatus {
        case .keyboard:
            if let keyboard = _defaultKeyboard {
                return keyboard
            }
            guard let messageSender = self._messageSender else {
                return nil
            }
            _defaultKeyboard = self.componentGenerator.keyboard(moduleContext: self.context,
                                                                delegate: self,
                                                                chat: self.chat.value,
                                                                messageSender: { return messageSender },
                                                                chatKeyPointTracker: self.chatKeyPointTracker)
            //目前存在键盘上来不存在的情况，手动调用
            _defaultKeyboard?.afterMessagesRender()
            if let keyboardView = _defaultKeyboard?.view {
                keyboardView.keyboardShareDataService.isMyAIChatMode = self.isMyAIChatMode
                self.containerViewController.view.addSubview(keyboardView)
                keyboardView.snp.makeConstraints({ make in
                    make.left.right.bottom.equalToSuperview()
                })
                keyboardView.inputTextView.accessibilityIdentifier = "ChatInput"
                keyboardView.inputTextView.setAcceptablePaste(types: [UIImage.self, NSAttributedString.self])
            }
            return _defaultKeyboard
        default:
            return nil
        }
    }

    var keyboardView: ChatKeyboardView? {
        return self.defaultKeyboard?.view
    }

    private lazy var canCreateKeyboard: Bool = {
        return self.componentGenerator.canCreateKeyboard(chat: self.chatWrapper.chat.value)
    }()

    /// 键盘上方区域，包含扩展区+timezone等
    private lazy var keyboardTopStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.lu.setBackgroundColor(UIColor.ud.bgBodyOverlay)
        return stackView
    }()

    /// 如果为nil，则不会显示keyboardTopStackView
    private var keyboardTopStackDependView: UIView? {
        switch self.chatBottomStatus {
        case .keyboard:
            return self.keyboardView
        case .none, .footerView, .frozenMask, .createThread, .chatMenu:
            return nil
        }
    }

    /// 键盘上方可扩展区域
    private lazy var keyboardTopExtendView: ChatKeyboardTopExtendView? = {
        let view = self.componentGenerator.chatKeyboardTopExtendView(pushWrapper: self.chatWrapper,
                                                                     context: self.keyBoardTopExtendContext,
                                                                     delegate: self)
        self.keyBoardTopExtendContext.container.register(ChatOpenKeyboardTopExtendService.self) { [weak view] (_) -> ChatOpenKeyboardTopExtendService in
            return view ?? DefaultChatOpenKeyboardTopExtendService()
        }
        return view
    }()

    private func saveInputDraft() {
        if self.isMyAIChatMode {
            return //my ai分会场不存草稿
        }
        self.defaultKeyboard?.saveInputViewDraft(isExitChat: true, callback: { [weak self] (draft, _) in
            self?.saveChatDraft(draft: draft)
        })
    }
}

extension AIChatBottomLayout: BottomLayout {
    func setupBottomView() {
        if self.canCreateKeyboard {
            self.chatBottomStatus = .keyboard(display: true)
        } else {
            self.chatBottomStatus = .none(display: true)
        }
        self.setupKeyboardTopStackView()
    }

    private func setupKeyboardTopStackView() {
        if let keyboardTopExtendView = self.keyboardTopExtendView {
            self.keyboardTopStackView.addArrangedSubview(keyboardTopExtendView)
            keyboardTopExtendView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
            keyboardTopExtendView.shouldShow = self.shouldShowKeyboardTopExtend()
        }
        guard let dependView = self.keyboardTopStackDependView else {
            // 目前keyboardTopStackView中部分内容有阴影，需要下方视图先添加上去（上面keyboardTopStackDependView会触发）再添加keyboardTopStackView
            self.containerViewController.view.addSubview(self.keyboardTopStackView)
            self.keyboardTopStackView.isHidden = true
            return
        }
        // 目前keyboardTopStackView中部分内容有阴影，需要下方视图先添加上去（上面keyboardTopStackDependView会触发）再添加keyboardTopStackView
        self.containerViewController.view.addSubview(self.keyboardTopStackView)
        self.keyboardTopStackView.snp.remakeConstraints { make in
            make.bottom.equalTo(dependView.snp.top)
            make.left.right.equalToSuperview()
            /// 如果键盘上方有内容，目前的体验不太好：首屏渲染后，键盘上方内容渲染完成，然后ChatKeyboardTopExtendSubModule调用refresh，减少tableView的高度约束，用户就会看到表格被顶起来，这里做了一个优化：
            /// 对于一些场景，能确定键盘上方一定有内容的，则可以设置一个初始高度，优化此问题，原因：首屏前keyboardFrameChanged会执行，此时self.keyboardTopStackView.bounds.height就有值了，tableView的高度也就会设置正确，所以用户就看不到表格被顶起来了
            // MyAI分会场没有「新话题」入口了，也就没有默认高度了
            if !isMyAIChatMode {
                let initHeight = 28.auto() + ChatKeyboardTopExtendView.contentTopMargin
                make.height.greaterThanOrEqualTo(initHeight)
            }
        }
    }

    func viewWillDisappear(_ animated: Bool) {
        self.saveInputDraft()
        self.keyboardView?.showNewLine = false
        if self.keyboardView?.keyboardPanel.selectIndex == nil,
            self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0,
           (self.containerViewController.navigationController?.interactivePopGestureRecognizer?.state ?? .possible != .began) {
            self.keyboardView?.fold()
        }
        self.keyboardView?.viewControllerWillDisappear()
    }

    func afterFirstScreenMessagesRender() {
        keyboardTopExtendView?.setupModule()
        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }
    }

    func getBottomHeight() -> CGFloat {
        var bottomHeight: CGFloat = 0
        switch self.chatBottomStatus {
        case .keyboard:
            bottomHeight = (self.keyboardView?.frame.height ?? 0) + self.keyboardTopStackView.bounds.height
        case .none, .createThread, .frozenMask, .chatMenu, .footerView:
            break
        }
        return bottomHeight
    }

    func toggleBottomStatus(to: ChatBottomStatus, animation: Bool) {
    }

    func getTableBottomConstraintItem() -> SnapKit.ConstraintItem {
        return getBottomControlTopConstraintInView() ?? containerViewController.view.snp.bottom
    }

    // 获取view最底部控件的top约束(如果有)
    func getBottomControlTopConstraintInView() -> SnapKit.ConstraintItem? {
        var result: SnapKit.ConstraintItem?
        switch self.chatBottomStatus {
        case .keyboard:
            result = self.keyboardTopStackView.snp.top
        case .none, .chatMenu, .createThread, .frozenMask, .footerView:
            break
        }
        return result
    }

    func toggleShowAndHideBottom(display: Bool) {
        Self.logger.info("toggleShowAndHideBottom \(self.chatId) \(self.chatBottomStatus) \(display)")
        if self.chatBottomStatus.display == display { return }
        switch self.chatBottomStatus {
        case .keyboard(display: let display):
            self.chatBottomStatus = .keyboard(display: !display)
            if display {
                keyboardView?.isHidden = true
                keyboardView?.fold()
                keyboardView?.inputTextView.resignFirstResponder()
                break
            }
            keyboardView?.isHidden = false
        case .none:
            self.chatBottomStatus = .none(display: !display)
        case .createThread, .frozenMask, .chatMenu, .footerView:
            break
        }
        self.keyboardTopStackView.isHidden = !self.chatBottomStatus.display || self.keyboardTopStackDependView == nil
    }

    func pageSupportReply() -> Bool {
        switch self.chatBottomStatus {
        case .none:
            return false
        default:
            return true
        }
    }

    func hasInputViewInFirstResponder() -> Bool {
        return self.keyboardView?.inputTextView.isFirstResponder ?? false
    }

    func menuWillShow(isSheetMenu: Bool) {
        let beginKeyboardHeight = self.keyboardView?.frame.height ?? 0
        let beginTableViewOffset = self.tableView.contentOffset

        // 出现菜单之前如果键盘弹起
        let needBecomFirstResponder = self.keyboardView?.inputTextView.isFirstResponder ?? false
        var showKeyboard = false
        if needBecomFirstResponder {
            self.keyboardView?.inputTextView.resignFirstResponder()
            showKeyboard = true
        } else if self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0 {
            self.keyboardView?.foldKeyboard()
            showKeyboard = true
        }
        if showKeyboard, isSheetMenu {
            /// 键盘收起之后 计算高度的差值，调整tableView的高度
            let changeHeight = beginKeyboardHeight - (self.keyboardView?.frame.height ?? 0)
            if changeHeight <= 0 {
                Self.logger.info("MessageSelectControl beginKeyboardHeight:\(beginKeyboardHeight) " +
                                 "keyboardView?.frame.height: \(self.keyboardView?.frame.height) " +
                                 "changeHeight: \(changeHeight)")
            } else {
                let tableHeight = self.tableView.frame.height + changeHeight
                ///lockChatTable 会保证一定可以 updateConstraints height
                self.tableView.snp.updateConstraints { make in
                    make.height.equalTo(tableHeight)
                }
                self.tableView.layoutIfNeeded()
                /// 这个要保证偏移不变，需要设置为原来的offset
                self.tableView.setContentOffset(beginTableViewOffset, animated: false)
            }
        }
    }

    func tapTableHandler() {
        self.keyboardView?.fold()
    }

    func viewWillAppear(_ animated: Bool) {
        self.keyboardView?.showNewLine = true
    }

    func viewDidAppear(_ animated: Bool) {
        if let defaultKeyboard = self.defaultKeyboard, !self.viewDidAppeared {
            if Display.pad {
                self.containerViewController.view.layoutIfNeeded()
            }
            // 设置键盘初始状态
            defaultKeyboard.setupStartupKeyboardState()
        }
        self.keyboardView?.viewControllerDidAppear()

        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }

        self.viewDidAppeared = true
    }

    func subProviders() -> [KeyCommandProvider] {
        if let keyboardView = self.keyboardView {
            return [keyboardView]
        }
        return []
    }

    func lockForShowEnterpriseEntityWordCard() {
        self.keyboardView?.inputTextView.resignFirstResponder()
    }

    func keyboardExpending() -> Bool {
        return self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0
    }

    func keepTableOffset() -> Bool {
        return false
    }

    func showToBottomTipIfNeeded() -> Bool {
        return !self.keyboardExpending()
    }

    func screenCaptured(captured: Bool) {
        if captured {
            self.keyboardView?.inputTextView.resignFirstResponder()
        }
    }

    func widgetExpand(expand: Bool) {
        if expand {
            self.keyboardView?.fold()
        }
    }

    func canHandleDropInteraction() -> Bool {
        switch self.chatBottomStatus {
        case .none:
            return false
        default:
            return self.chat.value.isAllowPost
       }
    }

    func handleTextTypeDropItem(text: String) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        guard let keyboard = self.keyboardView else { return }
        keyboard.inputTextView.insertText(text)
        keyboard.inputTextView.becomeFirstResponder()
    }
}

// MARK: - 键盘代理
extension AIChatBottomLayout: ChatInputKeyboardDelegate {
    func getScheduleMsgSendTime() -> Int64? {
        return nil
    }

    func getSendScheduleMsgIds() -> ([String], [String]) {
        return ([], [])
    }

    func jobDidChange(old: KeyboardJob?, new: KeyboardJob) {
    }

    func setScheduleTipViewStatus(_ status: ScheduleMessageStatus) {
    }

    func clickChatMenuEntry() {
    }

    func replaceViewWillChange(_ view: UIView?) {
        if view == nil {
            keyboardTopExtendView?.shouldShow = self.shouldShowKeyboardTopExtend()
        } else {
            keyboardTopExtendView?.shouldShow = false
        }
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.delegate?.keyboardContentHeightWillChange(isFold)
    }

    func openMyAIInlineMode(source: IMMyAIInlineSource) {
    }

    func onExitReply() {
    }

    func textChange(text: String, textView: LarkEditTextView) {
    }

    func setEditingMessage(message: Message?) {
    }

    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        self.delegate?.handleKeyboardAppear(triggerType: triggerType)
    }
    // nolint: duplicated_code
    func keyboardFrameChanged(frame: CGRect) {
        if self.delegate?.tableHeightLock ?? false { return }
        guard let keyboardView = self.keyboardView,
              case .keyboard(display: true) = self.chatBottomStatus else { return }

        if keyboardView.keyboardPanel.contentHeight == 0 {
            let originHeight = self.tableView.frame.height
            let maxVisibleY = originHeight + self.tableView.contentOffset.y
            let height = self.containerViewController.view.bounds.height - keyboardView.frame.height - self.keyboardTopStackView.bounds.height
            self.tableView.remakeConstraints(height: height, bottom: keyboardView.snp.top, bottomOffset: -self.keyboardTopStackView.bounds.height)
            if maxVisibleY > height {
                // 可见区域没有在底部 或者 TableView 没有被触碰或者滚动时
                // 更新 ContentOffset 修正位置
                // 此次修改是为了适配键盘因为适配 safeArea 高度发生变化
                if maxVisibleY <= self.tableView.contentSize.height ||
                    !(self.tableView.isTracking ||
                    self.tableView.isDragging ||
                    self.tableView.isDecelerating) {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: maxVisibleY - height), animated: false)
                }
                (self.tableView as? CanSetClearAnchorTableView)?.adjustAnchorBottomInset()
            }
        } else {
            let height = self.containerViewController.view.bounds.height - keyboardView.frame.height - self.keyboardTopStackView.bounds.height
            if CGFloat(self.tableView.contentSize.height) <= self.tableView.frame.height {
                self.tableView.remakeConstraints(height: height, bottom: getTableBottomConstraintItem())
                if self.tableView.contentSize.height >= height {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height - height), animated: false)
                }
            } else {
                self.delegate?.removeHightlight(needRefresh: true)
                let originHeight = self.tableView.frame.height
                let heightChange = height - originHeight
                self.tableView.remakeConstraints(height: height, bottom: getTableBottomConstraintItem())
                if !self.tableView.stickToBottom() {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - heightChange), animated: false)
                }
            }
        }
    }
    // enable-lint: duplicated_code

    func inputTextViewFrameChanged(frame: CGRect) {
    }

    func inputTextViewWillInput(image: UIImage) -> Bool {
        let alert = ImageInputHandler.createSendAlert(userResolver: userResolver, with: image, for: chat.value, confirmCompletion: { [weak self] in
            guard let self = self else { return }
            let imageMessageInfo = generateSendImageMessageInfoInChat(image)
            self.messageSender?.sendImages(
                parentMessage: nil,
                useOriginal: false,
                imageMessageInfos: [imageMessageInfo],
                chatId: self.chat.value.id,
                lastMessagePosition: self.chat.value.lastMessagePosition,
                quasiMsgCreateByNative: self.quasiMsgCreateByNative,
                extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                      ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.other.rawValue]
            )
        })
        self.userResolver.navigator.present(alert, from: self.containerViewController)
        return false
    }

    func rootViewController() -> UIViewController {
        return self.containerViewController.navigationController ?? self.containerViewController
    }

    func baseViewController() -> UIViewController {
        return self.containerViewController
    }

    func keyboardWillExpand() {
        self.guideManager?.removeHintBubbleView()
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return self.keyboardStartState
    }

    func keyboardCanAutoBecomeFirstResponder() -> Bool {
        switch self.chatBottomStatus {
        case .keyboard:
            return true
        default:
            return false
        }
    }

    private func shouldShowKeyboardTopExtend() -> Bool {
        return true
    }
}

extension AIChatBottomLayout: ChatKeyboardTopExtendViewDelegate {
    func keyboardTopExtendViewOnRefresh() {
        let currentTableHeight = self.tableView.frame.height
        self.containerViewController.view.layoutIfNeeded()
        let height = self.containerViewController.view.bounds.height - getBottomHeight()
        var offset = currentTableHeight - height
        if offset <= 0 {
            offset = 0
        }
        self.remakeTableConstrainWithHeight(height: height,
                                            offsetHeight: offset,
                                            animated: true)
    }

    private func remakeTableConstrainWithHeight(height: ConstraintRelatableTarget,
                                                offsetHeight: CGFloat,
                                                animated: Bool = false) {
        self.tableView.remakeConstraints(height: height, bottom: self.getTableBottomConstraintItem())

        let totalHeight = self.tableView.adjustedContentInset.top + self.tableView.adjustedContentInset.bottom + self.tableView.contentSize.height
        let completeShow = (totalHeight <= self.tableView.frame.size.height)
        if completeShow {
            self.tableView.scrollToBottom(animated: animated)
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y + offsetHeight), animated: animated)
        }
    }
}

extension AIChatBottomLayout: SaveChatDraft {
}
