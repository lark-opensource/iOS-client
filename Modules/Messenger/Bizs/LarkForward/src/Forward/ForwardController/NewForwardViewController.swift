//
//  ForwardVIewController.swift
//  LarkForward
//
//  Created by 姚启灏 on 2018/11/26.
//

import UIKit
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import LarkCore
import LarkAlertController
import EENavigator
import LarkKeyboardKit
import LarkBaseKeyboard
import LarkKeyCommandKit
import LarkMessengerInterface
import LarkSearchCore
import LKCommonsTracker
import LarkSDKInterface
import LarkRichTextCore
import LarkContainer
import EditTextView
import Foundation
import LarkFeatureGating
import LKCommonsLogging
import LarkSetting
import Homeric
import UniverseDesignToast
import UniverseDesignIcon
import RustPB

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
public protocol NewForwardViewControllerRouter: AnyObject {
    func creatChat(vc: NewForwardViewController)
    func creatChat(forwardVC: ForwardComponentVCType,
                   forwardIncludeConfigs: [EntityConfigType]?,
                   forwardEnabledConfigs: [EntityConfigType]?,
                   forwardDisabledClosure: ForwardItemDisabledBlock?)
}

public class NewForwardViewController: BaseUIViewController, ForwardComponentVCType, PickerDelegate, UITextViewDelegate {
    var router: NewForwardViewControllerRouter?
    let logger = Logger.log("NewForwardViewController")
    static let loggerKeyword = "Forward.NewForwardViewController:"
    private let disposeBag = DisposeBag()
    let provider: ForwardAlertProvider
    private var selectItems: [Option] { picker.selected }
    private var selectRecordInfos: [ForwardSelectRecordInfo] = []
    var textViewInputProtocolSet = TextViewInputProtocolSet()
    var contentTextView: LarkEditTextView?
    // 确认发送Alert文本框中at标签的个数
    var curAtUserNumber = 0
    var isOpenChatAfterCreateGroup: Bool {
        return self.provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.open_chat_after_create_group"))
    }
    var isRemoteSyncFG: Bool {
        return self.provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.duoduan_sync"))
    }
    var enableThreadForwardCard: Bool {
        return self.provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.new_thread_forward_card"))
    }

    /// 点击导航左边的x按钮退出分享界面
    var cancelCallBack: (() -> Void)?
    /// 分享成功回调
    var successCallBack: (() -> Void)?
    var shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    var forwardResultsCallBack: ((ForwardResult?) -> Void)?

    var inputNavigationItem: UINavigationItem?
    private weak var currentAlertFromVC: UIViewController?
    private weak var delegate: ForwardComponentDelegate?

    //为true时 切出app会该vc会被隐藏。
    //仅在从其他app分享到飞书时会设为true
    var shouldDismissWhenResignActive = false

    public var isMultiSelectMode: Bool {
        get { picker.isMultiple }
        set { picker.isMultiple = newValue }
    }

    public var currentSelectItems: [ForwardItem] {
        return picker.selected.compactMap { cast(option: $0) }
    }

    private(set) lazy var leftBarButtonItem: UIBarButtonItem = {
        if hasBackPage, navigationItem.leftBarButtonItem == nil {
            return addBackItem()
        }
        if !hasBackPage, presentingViewController != nil, navigationItem.leftBarButtonItem == nil {
            return addCancelItem()
        }
        return addCancelItem()
    }()

    private(set) lazy var rightBarButtonItem: UIBarButtonItem? = {
        if provider.isSupportMultiSelectMode {
            return self.multiSelectItem
        }
        return nil
    }()

    public var picker: ChatPicker

    public func content() -> ForwardAlertContent { return provider.content }

    private lazy var creatChatView: UIView = {
        let creatChatView = UIView()
        creatChatView.lu.addTapGestureRecognizer(action: #selector(didTapCreatChatView), target: self, touchNumber: 1)

        // 创建新的聊天View
        let creatChatViewLabel = UILabel()
        creatChatViewLabel.text = BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Button
        creatChatViewLabel.textAlignment = .center
        creatChatViewLabel.font = UIFont.systemFont(ofSize: 16)
        creatChatView.addSubview(creatChatViewLabel)
        creatChatViewLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        let creatChatIcon = UIImageView(image: Resources.mine_right_arrow)
        creatChatView.addSubview(creatChatIcon)
        creatChatIcon.snp.makeConstraints { (make) in
            make.centerY.equalTo(creatChatViewLabel)
            make.right.equalToSuperview().offset(-18)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        creatChatView.backgroundColor = UIColor.ud.bgBody
        creatChatView.snp.makeConstraints { (make) in
            make.height.equalTo(48)
        }
        return creatChatView
    }()

    private(set) lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkForward.Lark_Legacy_Send, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private(set) lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_Cancel)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16))
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return btnItem
    }()

    private(set) lazy var multiSelectItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_Select)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapMultiSelect), for: .touchUpInside)
        return btnItem
    }()

    // MARK: Key bindings
    public override func subProviders() -> [KeyCommandProvider] {
        return [picker]
    }
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + confirmKeyBinding
    }

    private var confirmKeyBinding: [KeyBindingWraper] {
        return isMultiSelectMode && sureButton.isEnabled ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkForward.Lark_Legacy_Sure
            )
            .binding(target: self, selector: #selector(didTapSure))
            .wraper
        ] : []
    }

    private var currentAlertController: LarkAlertController?

    public override func addCancelItem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeBtnTapped))
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    public init(provider: ForwardAlertProvider,
                router: NewForwardViewControllerRouter,
                picker: ChatPicker,
                inputNavigationItem: UINavigationItem? = nil) {
        self.provider = provider
        self.router = router
        self.picker = picker
        self.inputNavigationItem = inputNavigationItem
        self.picker.filterParameters = self.provider.filterParameters
        super.init(nibName: nil, bundle: nil)
        self.logger.info("\(Self.loggerKeyword) provider: \(provider.self)")
        self.logForwardEnabledConfigs(enabledConfigs: self.provider.getForwardItemsIncludeConfigsForEnabled())
        picker.delegate = self
        picker.fromVC = self
    }

    public convenience init(provider: ForwardAlertProvider,
                            router: NewForwardViewControllerRouter,
                            canForwardToMsgThread: Bool,
                            canForwardToTopic: Bool = false,
                            inputNavigationItem: UINavigationItem? = nil
    ) {
        var forwardInitTime = CACurrentMediaTime()
        var pickerParam = ChatPicker.InitParam()
        pickerParam.includeOuterTenant = provider.needSearchOuterTenant
        pickerParam.includeOuterChat = provider.includeOuterChat
        pickerParam.includeThread = canForwardToTopic
        pickerParam.filter = provider.getFilter()
        pickerParam.scene = provider.pickerTrackScene
        pickerParam.includeMsgThread = canForwardToMsgThread
        pickerParam.targetPreview = provider.targetPreview
        //转发面板支持搜索密盾聊/密盾单聊
        pickerParam.includeShieldP2PChat = true
        pickerParam.includeShieldGroup = true
        let isRemoteSyncFG = provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.duoduan_sync"))
        if isRemoteSyncFG, let includeConfigs = provider.getForwardItemsIncludeConfigs() {
            //picerkParam传给转发搜索的部分参数，需要由includConfigs映射后再传给searchFactory使用
            pickerParam = ForwardConfigUtils.convertIncludeConfigsToPickerInitParams(includeConfigs: includeConfigs, pickerParam: pickerParam)
            //pickerParam.includeConfigs可直接传给最近访问接口使用
            pickerParam.includeConfigs = includeConfigs
        }
        pickerParam.shouldShowRecentForward = provider.shouldShowRecentForward
        if let infos = (provider.content as? ChatChooseAlertContent)?.preSelectInfos {
            pickerParam.preSelects = infos.map({
                var type = OptionIdentifier.Types.chatter.rawValue
                var id = ""
                switch $0 {
                case .chatID(let chatID):
                    type = OptionIdentifier.Types.chat.rawValue
                    id = chatID
                case .chatterID(let chatterID):
                    type = OptionIdentifier.Types.chatter.rawValue
                    id = chatterID
                default:
                    break
                }
                return OptionIdentifier(type: type, id: id)
            })
        }
        /// 如果FG打开，不用补充特殊逻辑，上面代码已经处理
        /// 如果FG关闭，需要在下面做处理
        if !provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "lark.my_ai.main_switch")) {
            pickerParam.includeMyAi = false
            pickerParam.includeConfigs?.removeAll(where: { $0.type == .myAi })
        }
        pickerParam.permissions = provider.permissions ?? [.shareMessageSelectUser]
        let picker = ChatPicker(resolver: provider.userResolver, frame: .zero, params: pickerParam)
        picker.filterParameters = provider.filterParameters
        self.init(provider: provider,
                  router: router,
                  picker: picker,
                  inputNavigationItem: inputNavigationItem)
        if let view = picker.defaultView as? DefaultChatView {
            view.forwardInitTime = forwardInitTime
        }
        self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> picker params:\(pickerParam.description)")
    }

    public convenience init(provider: ForwardAlertProvider,
                            router: NewForwardViewControllerRouter,
                            canForwardToTopic: Bool = false,
                            inputNavigationItem: UINavigationItem? = nil,
                            delegate: ForwardComponentDelegate? = nil
    ) {
        self.init(provider: provider,
                  router: router,
                  canForwardToMsgThread: false,
                  canForwardToTopic: canForwardToTopic,
                  inputNavigationItem: inputNavigationItem)
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.logger.info("\(Self.loggerKeyword) \(self) deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        Tracker.post(TeaEvent("im_msg_forward_select_view"))

        self.title = BundleI18n.LarkForward.Lark_Legacy_SelectTip

        if provider.shouldCreateGroup {
            // must set before picker add to window
            picker.topView = creatChatView
        }

        self.view.addSubview(picker)
        picker.frame = view.bounds
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.closeCallback = { [weak self] () in
            guard let `self` = self else { return }
            Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                                  params: ["click": "close",
                                           "target": "none"]))
            self.provider.dismissAction()
            self.cancelCallBack?()
        }
        self.backCallback = { [weak self] in
            guard let `self` = self else { return }
            self.provider.dismissAction()
            self.cancelCallBack?()
        }
        bindViewModel()
        initInputHandlers()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.currentAlertFromVC = self
    }

    func isMultipleChanged() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        if isMultiSelectMode {
            currentNavigationItem.leftBarButtonItem = self.cancelItem
            currentNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        } else {
            currentNavigationItem.leftBarButtonItem = self.leftBarButtonItem
            currentNavigationItem.rightBarButtonItem = self.rightBarButtonItem
        }
        self.updateSureStatus()
    }

    private func bindViewModel() {
        picker.selectedChangeObservable.bind(onNext: { [weak self] _ in
            self?.updateSelectedInfo()
        }).disposed(by: disposeBag)
        picker.isMultipleChangeObservable.bind(onNext: { [weak self] _ in
            self?.isMultipleChanged()
        }).disposed(by: disposeBag)
        self.isMultipleChanged() // init UI Set
    }

    func initInputHandlers() {
        if !self.provider.isSupportMention {
            return
        }

        let deleteAtInput = TagInputHandler(key: AtTransformer.UserIdAttributedKey)
        deleteAtInput.deleteAtTagBlock = { [weak self] (_, _, _) in
            guard let `self` = self else { return }
            if self.curAtUserNumber > 0 {
                self.curAtUserNumber -= 1
            }
        }

        let atPickerInputHandler = AtPickerInputHandler { [weak self] (textView, range, _) in
            guard let `self` = self else { return }
            Tracker.post(TeaEvent("im_msg_send_confirm_click",
                                  params: ["scene": "msg_forward",
                                           "click": "at_mention_in_postscript_bar",
                                           "target": "public_at_mention_select_view"]))
            var body = AtUserBody(provider: self.provider)
            body.atSuccessCallBack = { selectItems in
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()
                // 插入at标签
                selectItems.forEach { (item) in
                    self.insertAtTag(userName: item.name,
                                     actualName: item.name,
                                     userId: item.id,
                                     isOuter: false)
                }
            }
            body.atCancelCallBack = {
                textView.becomeFirstResponder()
            }
            var topController: UIViewController = self
            while let newTopController = topController.presentedViewController {
                topController = newTopController
            }
            self.provider.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: topController,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
        let textViewInputProtocolSet = TextViewInputProtocolSet([atPickerInputHandler, deleteAtInput])
        self.textViewInputProtocolSet = textViewInputProtocolSet
    }

    func insertAtTag(userName: String, actualName: String, userId: String = "", isOuter: Bool = false) {
        guard let contentTextView else { return }
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId, name: userName, isOuter: isOuter, actualName: actualName)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: contentTextView.defaultTypingAttributes)
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: contentTextView.defaultTypingAttributes))
            contentTextView.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            contentTextView.insertText(userName)
        }
        self.curAtUserNumber += 1
        contentTextView.becomeFirstResponder()
    }

    @objc
    private func willResignActive() {
        guard let vc = currentAlertController, vc.presentingViewController != nil, shouldDismissWhenResignActive else { return }

        vc.dismiss(animated: false, completion: nil)
        self.dismiss(animated: true, completion: { [weak self] in self?.cancelCallBack?() })
    }

    // TODO: isMultipleChanged 动效

    @objc
    private func didTapCreatChatView() {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "create_new_chat",
                                       "target": "im_group_create_view"]))
        Tracer.trackMessageForwardCreateGroupAttempt()
        if self.provider.userResolver.fg.staticFeatureGatingValue(with: "core.forward.create_group_chat_with_filter") {
            self.router?.creatChat(forwardVC: self,
                                   forwardIncludeConfigs: self.provider.getForwardItemsIncludeConfigs(),
                                   forwardEnabledConfigs: self.provider.getForwardItemsIncludeConfigsForEnabled(),
                                   forwardDisabledClosure: self.provider.getDisabledBlock())
        } else {
            self.router?.creatChat(vc: self)
        }
    }

    @objc
    func didTapSure(isCreateGroup: Bool = false) {
        var title = selectItems.count == 1 ? BundleI18n.LarkForward.Lark_Legacy_ChatViewSendTo : BundleI18n.LarkForward.Lark_Legacy_ChatViewDeliverSendTo
        if isCreateGroup {
            title = BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Title
        }

        self.view.endEditing(false)
        self.showConfirmVC(alertTitle: title, isCreateGroup: isCreateGroup, fromVC: self.currentAlertFromVC ?? self)
    }

    fileprivate func forwardMessage(items: [ForwardItem], attrText: NSAttributedString? = nil, text: String? = nil, toNewChat chatId: String?, fromVC: UIViewController) {
        //其他场景保持老方法，只返回chatID，后续可以考虑切新方法
        var signal: Observable<[String]>?
        if let attrText = attrText {
            signal = provider.sureAction(items: items, attributeInput: attrText, from: fromVC)
        }
        if let text = text {
            signal = provider.sureAction(items: items, input: text, from: fromVC)
        }
        guard let signal = signal else {
            fatalError("no forward content")
        }
        signal.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (newChatIds) in
                guard let self = self else { return }
                self.logger.info("\(Self.loggerKeyword) forward message \(items.count)")
                self.trackAction(
                    isMultiSelectMode: self.isMultiSelectMode,
                    selectRecordInfo: self.selectRecordInfos,
                    chatIds: newChatIds)
                self.dismiss(with: chatId)
            }, onError: { [weak self] error in
                self?.logger.error("\(Self.loggerKeyword) Forward message error: \(error)")
            }).disposed(by: self.disposeBag)
    }
    // 图片,文档
    private func forwardImageOrDoc(items: [ForwardItem], attrText: NSAttributedString? = nil, text: String? = nil, toNewChat chatId: String?, fromVC: UIViewController) {
        var signal: Observable<ForwardResult>?
        if let attrText = attrText {
            signal = provider.shareSureAction(items: items, attributeInput: attrText, from: fromVC)
        }
        if let text = text {
            signal = provider.shareSureAction(items: items, input: text, from: fromVC)
        }
        guard let signal = signal else {
            fatalError("no forward content")
        }
        signal.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (forwardResult) in
                guard let self = self else { return }
                var chatIds = [String]()
                switch forwardResult {
                case .success(let forwardParam):
                    forwardParam.forwardItems.forEach({ forwardItemParam in
                        chatIds.append(forwardItemParam.chatID)
                        self.shareResultsCallBack?([(forwardItemParam.chatID, forwardItemParam.isSuccess)])
                    })
                default: break
                }
                self.forwardResultsCallBack?(forwardResult)
                self.logger.info("\(Self.loggerKeyword) forward image call shareResults callback:\(self.shareResultsCallBack)")
                self.trackAction(
                    isMultiSelectMode: self.isMultiSelectMode,
                    selectRecordInfo: self.selectRecordInfos,
                    chatIds: chatIds)
                self.dismiss(with: chatId)
            }, onError: { [weak self] error in
                self?.logger.error("\(Self.loggerKeyword) Forward image error: \(error)")
            }).disposed(by: self.disposeBag)
    }
    // 合并, 日程
    private func mergeForward(items: [ForwardItem], attrText: NSAttributedString? = nil, text: String? = nil, toNewChat chatId: String?, alert: LarkAlertController?, fromVC: UIViewController) {
        var signal: Observable<[String]>?
        if let attrText = attrText {
            signal = provider.sureAction(items: items, attributeInput: attrText, from: fromVC)
        }
        if let text = text {
            signal = provider.sureAction(items: items, input: text, from: fromVC)
        }
        guard let signal = signal else {
            fatalError("no forward content")
        }
        signal.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (newChatIds)  in
                // 出现二次弹框时触发onNext，隐藏第一弹窗。
                guard let self = self, !newChatIds.isEmpty else { return }
                self.trackAction(
                    isMultiSelectMode: self.isMultiSelectMode,
                    selectRecordInfo: self.selectRecordInfos,
                    chatIds: newChatIds)
                alert?.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] error in
                self?.logger.error("\(Self.loggerKeyword) merge forward error: \(error)")
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                self.logger.error("\(Self.loggerKeyword) merge forward success: \(items.count)")
                alert?.dismiss(animated: true, completion: nil)
                self.dismiss(with: chatId)
            }).disposed(by: self.disposeBag)
    }
    private func showConfirmVC(alertTitle: String, isCreateGroup: Bool, fromVC: UIViewController) {
        provider.beforeShowAction()
        let selectItems: [ForwardItem] = picker.selected.compactMap { cast(option: $0) }
        let recentlyForwardChatCount = selectItems.filter { $0.source == .recentForward }.count
        let recentlyChatIndex = selectItems.filter { $0.source == .recentChat }.map { $0.index + 1 }
        let serachChatCount = selectItems.filter { $0.source == .search }.count
        let itemTypeToCount = countSelectedForwardItems(items: selectItems)
        let creater = ForwardAlertViewCreater(userResolver: provider.userResolver,
                                              forwardChats: selectItems,
                                              forwardProvider: provider)
        let alertController = LarkAlertController()
        let title = provider.getTitle(by: selectItems) ?? alertTitle
        alertController.setTitle(text: title, alignment: .left)
        let contents = creater.createConfirmContentView()
        self.contentTextView = contents.1
        self.contentTextView?.delegate = self
        if let contentTV = self.contentTextView {
            self.textViewInputProtocolSet.register(textView: contentTV)
        }
        let scene = isCreateGroup ? "group_create_from_forward" : "msg_forward"
        alertController.setContent(view: contents.0)
        alertController.addCancelButton(dismissCheck: { [weak self] in
            Tracker.post(TeaEvent("im_msg_send_confirm_click",
                                  params: ["scene": "msg_forward",
                                           "click": "cancel",
                                           "target": "none"]))
            self?.provider.cancelAction()
            return true
        })
        self.logger.info("\(Self.loggerKeyword) Forward show alert: {isMultiple: \(picker.isMultiple)}")

        func getSendText() -> String {
            if let customText = provider.getConfirmButtonText(isMultiple: picker.isMultiple, selectCount: selectItems.count) {
                return customText
            }
            let sendText = picker.isMultiple
            ? BundleI18n.LarkForward.Lark_IM_Forward_SendToNum_Button("\(selectItems.count)")
            : BundleI18n.LarkForward.Lark_Legacy_Send
            return sendText
        }

        let sendText = getSendText()
        let chatId = isCreateGroup ? selectItems.first?.chatId : nil
        alertController.addPrimaryButton(
            text: sendText, dismissCompletion: { [weak self, weak alertController] in
                guard let `self` = self else { return }
                let messageIsEmpty = contents.1?.text.isEmpty ?? true
                let params: [AnyHashable: Any] = ["scene": scene,
                                                  "click": "send",
                                                  "target": "none",
                                                  "recently_forward_chat_count": recentlyForwardChatCount,
                                                  "recently_chat_index": recentlyChatIndex,
                                                  "search_chat_count": serachChatCount,
                                                  "selected_crypto_group_count": itemTypeToCount["selected_crypto_group_count"],
                                                  "selected_member_count": itemTypeToCount["selected_member_count"],
                                                  "selected_group_count": itemTypeToCount["selected_group_count"],
                                                  "selected_bot_count": itemTypeToCount["selected_bot_count"],
                                                  "is_postscript": messageIsEmpty ? false : true,
                                                  "is_at_mention_in_postscript": self.curAtUserNumber > 0 ? true : false]
                Tracker.post(TeaEvent("im_msg_send_confirm_click", params: params))
                // 合并转发会出现二次弹窗，所以逻辑不一样。
                let isSupportMention = self.provider.isSupportMention
                // 支持Mention时发送attribute string, 不支持时发送text
                let attrText = isSupportMention ? contents.1?.attributedText ?? NSAttributedString(string: "") : nil
                let text = isSupportMention ? nil : contents.1?.text ?? ""
                self.logger.info("\(Self.loggerKeyword) send message count: \(selectItems.count) mention: \(isSupportMention) chat: \(chatId ?? "")")
                if self.provider is MergeForwardAlertProvider ||
                   self.provider is EventShareAlertProvider ||
                   self.provider is ShareContentAlertProvider ||
                   (self.provider is ShareThreadTopicAlertProvider && self.enableThreadForwardCard) {
                    self.mergeForward(items: selectItems,
                                      attrText: attrText,
                                      text: text,
                                      toNewChat: chatId,
                                      alert: alertController,
                                      fromVC: fromVC)
                } else if (self.provider is ShareImageAlertProvider) ||
                          (self.provider is ForwardTextAlertProvider) ||
                          (self.provider is ForwardFileAlertProvider) ||
                          (self.provider is ShareMailAttachmentProvider) {
                    //链接和二维码分享单独用新action方法返回分享结果和chatID，避免影响其他场景
                    self.forwardImageOrDoc(items: selectItems,
                                           attrText: attrText,
                                           text: text,
                                           toNewChat: chatId,
                                           fromVC: fromVC)
                } else {
                    self.forwardMessage(items: selectItems,
                                        attrText: attrText,
                                        text: text,
                                        toNewChat: chatId,
                                        fromVC: fromVC)
                }
            })
        Tracker.post(TeaEvent("im_msg_send_confirm_view",
                              params: ["scene": "msg_forward"]))
        currentAlertController = alertController
        self.provider.userResolver.navigator.present(alertController, from: self)
        self.provider.targetVc = alertController
    }
    private func dismiss(with newChatId: String?) {
        self.logger.info("\(Self.loggerKeyword) dismiss \(isOpenChatAfterCreateGroup) \(newChatId ?? "")")
        if isOpenChatAfterCreateGroup, let chatId = newChatId {
            self.pushToChat(chatId: chatId) { [ weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: { [weak self] in self?.successCallBack?() })
            }
        } else {
            self.dismiss(animated: true, completion: { [weak self] in self?.successCallBack?() })
        }
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            completion?()
            if let dismissBlock = self.provider.getForwardVCDismissBlock() {
                dismissBlock()
            }
        }
    }

    private func pushToChat(chatId: String, completion: (() -> Void)? = nil) {
        let body = ChatControllerByIdBody(chatId: chatId, fromWhere: .mygroupCreated)
        let chatNav = self.presentingViewController
        var params = EENavigator.NaviParams()
        params.forcePush = true
        params.animated = false
        if Display.pad,
           let nav = chatNav as? UINavigationController,
           let tabbarVc = nav.topViewController as? UITabBarController,
           let splitVc = tabbarVc.viewControllers?.first {
            self.provider.userResolver.navigator.showDetail(body: body, naviParams: params, from: splitVc) {_, _ in
                completion?()
            }
        } else if let nav = chatNav as? UINavigationController {
            self.provider.userResolver.navigator.push(body: body, naviParams: params, from: nav, animated: false) { _, _  in
                completion?()
            }
        } else {
            completion?()
        }
    }

    @objc
    public func didTapCancel() {
        self.isMultiSelectMode = false
    }

    @objc
    public func didTapMultiSelect() {
        self.isMultiSelectMode = true
    }

    private func updateSelectedInfo() {
        assert(Thread.isMainThread, "should occur on main thread!")
        updateSureStatus()
        let idSet = Set(self.selectItems.map { $0.optionIdentifier.id })
        self.selectRecordInfos.removeAll { !idSet.contains($0.id) }
    }

    private func updateSureStatus() {
        self.updateSureButton(count: self.selectItems.count)
        if !self.selectItems.isEmpty {
            self.sureButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            self.sureButton.isEnabled = true
        } else {
            self.sureButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .normal)
            self.sureButton.isEnabled = false
        }
    }

    func updateSureButton(count: Int) {
        var title = BundleI18n.LarkForward.Lark_Legacy_Sure
        if count >= 1 {
            title = BundleI18n.LarkForward.Lark_Legacy_Sure + "(\(count))"
        }
        self.sureButton.setTitle(title, for: .normal)
    }

    // 用于router回调
    public func selectNew(item: ForwardItem) {
        self.selectRecordInfos.removeAll()
        self.picker.selected = [item]
        didTapSure(isCreateGroup: true)
    }

    public func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        if isRemoteSyncFG {
            if let disabledBlock = self.provider.getDisabledBlock() {
                let pickerItem = PickerItemFactory.shared.makeItem(forward: item)
                return disabledBlock(pickerItem)
            }
            return !ForwardConfigUtils.isForwardItemEnabled(item, self.provider.getForwardItemsIncludeConfigsForEnabled(), provider.userResolver.userID)
        }
        if self.provider is BatchTransmitAlertProvider {
            return item.isThread
        }
        if self.provider is ShareThreadTopicAlertProvider {
            return item.isThread && item.type == .threadMessage
        }
        return item.isCrypto
    }

    public func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: sureButton.titleLabel?.text ?? BundleI18n.LarkForward.Lark_Legacy_Send,
            allowSelectNone: false,
            shouldDisplayCountTitle: false,
            targetPreview: self.picker.targetPreview,
            completion: { [weak self] fromVC in
                if let delegate = self?.delegate {
                    delegate.confirmButtonTapped(pickerSelectedVC: fromVC)
                    return
                }
                self?.currentAlertFromVC = fromVC
                self?.didTapSure()
            })
        self.provider.userResolver.navigator.push(body: body, from: self)
    }

    public func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        guard traceClick(item: item, selected: true) else { return false }
        if picker.isMultiple {
            if picker.selected.count >= provider.maxSelectCount {
                let alertController = LarkAlertController()
                alertController.setContent(text: String(format: BundleI18n.LarkForward.Lark_Legacy_MaxChooseLimit, provider.maxSelectCount))
                alertController.addButton(text: BundleI18n.LarkForward.Lark_Legacy_Sure)
                self.provider.userResolver.navigator.present(alertController, from: self)
                return false
            }
        }
        if picker.state(for: option, from: from).disabled {
            showDisabledToast()
            return false
        }
        return true
    }

    func showDisabledToast() {
        guard let window = view.window else { return }
        UDToast.showFailure(
            with: BundleI18n.LarkForward.Lark_Legacy_ShareUnsupportTypeError,
            on: window
        )
    }

    public func picker(_ picker: Picker, willDeselected option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        return traceClick(item: item, selected: false)
    }

    func traceClick(item: ForwardItem, selected: Bool) -> Bool {
        if let content = content() as? OpenShareContentAlertContent {
            Tracer.trackForwardSelectChat(source: content.sourceAppName ?? "")
        }
        if selected {
            guard let window = view.window else {
                assertionFailure()
                return false
            }
            if !item.hasInvitePermission {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_NewContacts_CantForwardDueToBlockOthers,
                    on: window
                )
                return false
            }
            if item.isCrypto {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_Forward_CantForwardToSecretChat,
                    on: window
                )
                return false
            }
            return true
        }
        return true
    }

    public func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        if let info = Self.asForwardSelectRecordInfo(option: option, from: from) {
            if !picker.isMultiple { selectRecordInfos.removeAll() }
            selectRecordInfos.append(info)
        } else {
            assertionFailure("option \(option) can't convert to ForwardSelectRecordInfo")
        }
        if let delegate = self.delegate,
           let item = self.cast(option: option) {
            delegate.forwardVC(self,
                               didSelectItem: item,
                               isMultipleMode: self.picker.isMultiple,
                               addSelected: true)
            // didSelected时逻辑交由业务处理，组件逻辑中断
            return
        }

        if !picker.isMultiple {
            didTapSure()
        }
    }

    public func picker(_ picker: Picker, didDeselected option: Option, from: Any?) {
        if let delegate = self.delegate,
           let item = self.cast(option: option) {
           delegate.forwardVC(self, didSelectItem: item, isMultipleMode: picker.isMultiple, addSelected: false)
        }
    }

    static func asForwardSelectRecordInfo(option: Option, from: Any?) -> ForwardSelectRecordInfo? {
        if
            let info = from as? PickerSelectedFromInfo,
            let indexPath = info.indexPath,
            let type = ForwardSelectRecordInfo.ResultType(rawValue: info.tag)
        {
            return ForwardSelectRecordInfo(
                id: option.optionIdentifier.id,
                offset: Int32(indexPath.row),
                resultType: type)
        }
        return nil
    }

    func trackAction(isMultiSelectMode: Bool,
                     selectRecordInfo: [ForwardSelectRecordInfo],
                     chatIds: [String]) {
        var chatId = ""
        if !isMultiSelectMode {
            if let data = selectRecordInfo.first {
                if !chatIds.isEmpty, let selectedChatId = chatIds.first {
                    chatId = selectedChatId
                }
                if let content = provider.content as? OpenShareContentAlertContent {
                    Tracer.trackSingleClick(location: data.resultType.rawValue, position: Int(data.offset), chatId: chatId, source: content.sourceAppName)
                } else {
                    Tracer.trackSingleClick(location: data.resultType.rawValue, position: Int(data.offset), chatId: chatId)
                }
            }
        } else {
            selectRecordInfo.enumerated().forEach { (index, info) in
                if chatIds.count > index {
                    chatId = chatIds[index]
                }
                if let content = provider.content as? OpenShareContentAlertContent {
                    Tracer.trackMultiClick(location: info.resultType.rawValue, position: Int(info.offset), chatId: chatId, source: content.sourceAppName)
                } else {
                    Tracer.trackMultiClick(location: info.resultType.rawValue, position: Int(info.offset), chatId: chatId)
                }
            }
        }
    }
    func cast(option: Option) -> ForwardItem? {
        let v = option as? ForwardItem
        assert(v != nil, "all option should be forwarditem")
        return v
    }

    // MARK: UITextViewDelegate
    // 点击附言框上报埋点
    public func textViewDidBeginEditing(_ textView: UITextView) {
        Tracker.post(TeaEvent("im_msg_send_confirm_click",
                              params: ["scene": "msg_forward",
                                       "click": "postscript_bar",
                                       "target": "none"]))
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    // 统计被选中项中各类别的个数
    func countSelectedForwardItems(items: [ForwardItem]) -> [String: Int] {
        var result = [String: Int]()
        var crypto = 0
        var member = 0
        var group = 0
        var bot = 0
        for i in 0..<items.count {
            if items[i].isCrypto {
                crypto += 1
                continue
            }

            switch items[i].type {
            case .bot:
                bot += 1
            case .chat:
                group += 1
            case .user:
                member += 1
            case .unknown, .threadMessage, .replyThreadMessage, .generalFilter, .myAi:
                break
            @unknown default: break
            }
        }
        result["selected_crypto_group_count"] = crypto
        result["selected_member_count"] = member
        result["selected_group_count"] = group
        result["selected_bot_count"] = bot
        return result
    }

    func logForwardEnabledConfigs(enabledConfigs: [EntityConfigType]?) {
        guard let enabledConfigs = enabledConfigs else {
            self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> enabledConfigs is nil")
            return
        }
        var logStr = ""
        for enabledConfig in enabledConfigs {
            if let userConfig = enabledConfig as? ForwardUserEnabledEntityConfig {
                logStr += userConfig.description + "; "
            }
            if let groupChatConfig = enabledConfig as? ForwardGroupChatEnabledEntityConfig {
                logStr += groupChatConfig.description + "; "
            }
            if let botConfig = enabledConfig as? ForwardBotEnabledEntityConfig {
                logStr += botConfig.description + "; "
            }
            if let threadConfig = enabledConfig as? ForwardThreadEnabledEntityConfig {
                logStr += threadConfig.description
            }
        }
        self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> enabledConfigs: \(logStr)")
    }
}
