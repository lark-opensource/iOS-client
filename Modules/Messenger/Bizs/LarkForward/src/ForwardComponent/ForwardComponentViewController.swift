//
//  ForwardComponentViewController.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/16.
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
import LarkAccountInterface

public protocol ForwardComponentViewControllerRouter: AnyObject {
    func creatChat(vc: ForwardComponentViewController)
    func creatChat(forwardVC: ForwardComponentVCType,
                   forwardIncludeConfigs: [EntityConfigType]?,
                   forwardEnabledConfigs: [EntityConfigType]?,
                   forwardDisabledClosure: ForwardItemDisabledBlock?)
}

public class ForwardComponentViewController: BaseUIViewController, PickerDelegate, ForwardComponentVCType, UITextViewDelegate {
    var router: ForwardComponentViewControllerRouter
    private let disposeBag = DisposeBag()
    var forwardConfig: ForwardConfig
    private var selectItems: [Option] { picker.selected }
    private var selectRecordInfos: [ForwardSelectRecordInfo] = []
    var textViewInputProtocolSet = TextViewInputProtocolSet()
    var contentTextView: LarkEditTextView?
    // 确认发送Alert文本框中at标签的个数
    var curAtUserNumber = 0
    var isOpenChatAfterCreateGroup: Bool {
        return self.forwardConfig.alertConfig.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.open_chat_after_create_group"))
    }
    private var forwardContentParam: ForwardContentParam?
    private let forwardExecuteQueue: DispatchQueue = DispatchQueue(label: "com.Foraward.Execute",
                                                                   attributes: .concurrent)
    private let forwardExecuteSemaphore = DispatchSemaphore(value: 0) // 转发执行信号量
    var shouldDismissWhenResignActive = false
    private weak var currentAlertFromVC: UIViewController?

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
        if forwardConfig.chooseConfig.enableSwitchSelectMode {
            return self.multiSelectItem
        }
        return nil
    }()

    private var picker: ChatPicker
    /// 作为subVC时，利用该属性打通containerVC和subVC的导航栏表现
    public var inputNavigationItem: UINavigationItem?
    public func content() -> ForwardAlertContent { return forwardConfig.alertConfig.content }

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
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
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
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_MultipleChoice)
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

    public init(forwardConfig: ForwardConfig,
                router: ForwardComponentViewControllerRouter? = nil) {
        //构造ChatPicker.InitParam
        let forwardInitTime = CACurrentMediaTime()
        self.forwardConfig = forwardConfig
        self.router = router ?? ForwardViewControllerRouterImpl(userResolver: forwardConfig.alertConfig.userResolver)
        var pickerParam = ChatPicker.InitParam()
        pickerParam.permissions = forwardConfig.commonConfig.permissions ?? [.shareMessageSelectUser]
        pickerParam.scene = forwardConfig.commonConfig.forwardTrackScene.rawValue
        pickerParam.shouldShowRecentForward = forwardConfig.commonConfig.enableShowRecentForward
        pickerParam.targetPreview = forwardConfig.targetConfig.enableTargetPreview
        pickerParam.includeConfigs = forwardConfig.targetConfig.includeConfigs
        pickerParam.enableConfigs = forwardConfig.targetConfig.enabledConfigs
        pickerParam = ForwardConfigUtils.convertIncludeConfigsToPickerInitParams(includeConfigs: forwardConfig.targetConfig.includeConfigs,
                                                                                 pickerParam: pickerParam)
        /// 如果FG打开，不用补充特殊逻辑，上面代码已经处理
        /// 如果FG关闭，需要在下面做处理
        if !forwardConfig.alertConfig.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "lark.my_ai.main_switch")) {
            pickerParam.includeMyAi = false
            pickerParam.includeConfigs?.removeAll(where: { $0.type == .myAi })
        }
        // DefaultChatView需要通过是否在新转发组件，来决定最近转发的参数映射逻辑
        pickerParam.isInForwardComponent = true
        //构造Picker
        let picker = ChatPicker(resolver: forwardConfig.alertConfig.userResolver, frame: .zero, params: pickerParam)
        self.picker = picker
        super.init(nibName: nil, bundle: nil)
        picker.delegate = self
        picker.fromVC = self
        //切子线程进行转发内容预加载
        self.forwardExecuteQueue.async { [weak self] in
            guard let self = self else { return }
            self.getForwardContentParam(self.forwardConfig.alertConfig.content.getForwardContentCallback)
        }
        // 埋点时间
        if let view = picker.defaultView as? DefaultChatView {
            view.forwardInitTime = forwardInitTime
        }
        //打日志
        ForwardLogger.shared.info(module: .search, event: "IOS_RECENT_VISIT", parameters: pickerParam.description)
        ForwardLogger.shared.info(module: .forwardMessage, event: "ForwardScene", parameters: self.forwardConfig.commonConfig.forwardTrackScene.rawValue)
        ForwardConfigUtils.logForwardEnabledConfigs(enabledConfigs: self.forwardConfig.targetConfig.enabledConfigs)
    }

    private func getForwardContentParam(_ getContentCallback: GetForwardContentCallback) {
        guard let getContentCallback = getContentCallback else { return }
        getContentCallback().subscribe(
            onNext: { [weak self] param in
                guard let self = self else { return }
                ForwardLogger.shared.info(module: .forwardMessage, event: "preload forward content success, param: \(param)")
                self.forwardContentParam = param
                self.forwardExecuteSemaphore.signal()
            },
            onError: { error in
                ForwardLogger.shared.error(module: .forwardMessage, event: "preload forward content failed, error: \(error)")
            }
        ).disposed(by: self.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        ForwardLogger.shared.info(module: .recentVisit, event: "forward component deinit")
    }

    public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            self.currentAlertFromVC = self
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        Tracker.post(TeaEvent("im_msg_forward_select_view"))

        self.title = BundleI18n.LarkForward.Lark_Legacy_SelectTip

        if forwardConfig.commonConfig.enableCreateGroupChat {
            // must set before picker add to window
            picker.topView = creatChatView
        }

        self.view.addSubview(picker)
        picker.frame = view.bounds
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.closeCallback = { [weak self] () in
            guard let `self` = self else { return }
            // VC关闭时打埋点，执行业务传入的dismissAction
            Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                                  params: ["click": "close",
                                           "target": "none"]))
            self.forwardConfig.commonConfig.dismissAction?()
        }
        self.backCallback = { [weak self] in
            guard let `self` = self else { return }
            self.forwardConfig.commonConfig.dismissAction?()
        }
        bindViewModel()
        initInputHandlers()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    public override func addCancelItem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeBtnTapped))
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
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
        picker.selectedChangeObservable.bind(onNext: { [weak self] _ in self?.updateSelectedInfo() }).disposed(by: disposeBag)
        picker.isMultipleChangeObservable.bind(onNext: { [weak self] _ in self?.isMultipleChanged() }).disposed(by: disposeBag)

        self.isMultipleChanged() // init UI Set
    }

    func initInputHandlers() {
        if !self.forwardConfig.addtionNoteConfig.enableAdditionNoteMention {
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
            var body = ForwardMentionBody(forwardConfig: self.forwardConfig)
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
            self.forwardConfig.alertConfig.userResolver.navigator.present(
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
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: self.contentTextView?.defaultTypingAttributes))
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
        self.dismiss(animated: true, completion: { [weak self] in self?.forwardConfig.commonConfig.dismissAction?() })
    }

    // TODO: isMultipleChanged 动效

    @objc
    private func didTapCreatChatView() {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "create_new_chat",
                                       "target": "im_group_create_view"]))
        Tracer.trackMessageForwardCreateGroupAttempt()
        let userResolver = self.forwardConfig.alertConfig.userResolver
        if userResolver.fg.staticFeatureGatingValue(with: "core.forward.create_group_chat_with_filter") {
            self.router.creatChat(forwardVC: self,
                                  forwardIncludeConfigs: self.forwardConfig.targetConfig.includeConfigs,
                                  forwardEnabledConfigs: self.forwardConfig.targetConfig.enabledConfigs,
                                  forwardDisabledClosure: self.forwardConfig.targetConfig.disadledBlock)
        } else {
            self.router.creatChat(vc: self)
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
    private func showConfirmVC(alertTitle: String, isCreateGroup: Bool, fromVC: UIViewController) {
        self.forwardConfig.alertConfig.beforeShowAlertController()
        let selectItems: [ForwardItem] = picker.selected.compactMap { cast(option: $0) }
        let recentlyForwardChatCount = selectItems.filter { $0.source == .recentForward }.count
        let recentlyChatIndex = selectItems.filter { $0.source == .recentChat }.map { $0.index + 1 }
        let serachChatCount = selectItems.filter { $0.source == .search }.count
        let itemTypeToCount = countSelectedForwardItems(items: selectItems)
        let alertViewProvider = ForwardAlertViewProvider(forwardChats: selectItems, forwardConfig: forwardConfig)
        let alertController = LarkAlertController()
        self.forwardConfig.alertConfig.targetVc = alertController
        let title = forwardConfig.alertConfig.getAlertControllerTitle() ?? alertTitle
        alertController.setTitle(text: title, alignment: .left)
        let contents = alertViewProvider.createConfirmContentView()
        self.contentTextView = contents.1
        self.contentTextView?.delegate = self
        if let contentTV = self.contentTextView {
            self.textViewInputProtocolSet.register(textView: contentTV)
        }
        let scene = isCreateGroup ? "group_create_from_forward" : "msg_forward"
        let sendText = getSendText()
        let chatId = isCreateGroup ? selectItems.first?.chatId : nil

        func getSendText() -> String {
            var sendText: String
            if let customText = forwardConfig.alertConfig.getAlertControllerConfirmButtonText() {
                // 业务自定义确认框确认按钮文案
                sendText = picker.isMultiple
                ? customText + "(\(selectItems.count))"
                : customText
            } else {
                // 转发组件默认确认框确认按钮文案
                sendText = picker.isMultiple
                ? BundleI18n.LarkForward.Lark_IM_Forward_SendToNum_Button("\(selectItems.count)")
                : BundleI18n.LarkForward.Lark_Legacy_Send
            }
            return sendText
        }

        func getConfirmClickTrackParams() -> [AnyHashable: AnyHashable] {
            let messageIsEmpty = contents.1?.text.isEmpty ?? true
            return ["scene": scene,
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
        }

        alertController.setContent(view: contents.0)
        alertController.addCancelButton(dismissCheck: { [weak self] in
            Tracker.post(TeaEvent("im_msg_send_confirm_click",
                                  params: ["scene": "msg_forward",
                                           "click": "cancel",
                                           "target": "none"]))
            self?.forwardConfig.alertConfig.allertCancelAction()
            return true
        })
        ForwardLogger.shared.info(module: .forwardAlert, event: "show forward alert, isMultiple: \(picker.isMultiple)")
        alertController.addPrimaryButton(
            text: sendText, dismissCompletion: { [weak self] in
                guard let self = self,
                      let window = fromVC.view.window
                else { return }
                let hud = UDToast.showLoading(on: window)
                Tracker.post(TeaEvent("im_msg_send_confirm_click", params: getConfirmClickTrackParams()))
                // 转发执行时统一发富文本
                ForwardLogger.shared.info(module: .forwardAlert, event: "send message count: \(selectItems.count) chatID: \(chatId ?? "")")
                let attrText = contents.1?.attributedText ?? NSAttributedString(string: "")
                self.forwardExecuteQueue.async { [weak self] in
                    guard let self = self else { return }
                    let waitRes = self.forwardExecuteSemaphore.wait(timeout: .now() + 10)
                    switch waitRes {
                    case .success:
                        self.forwardExecuteInComponent(additionNote: attrText,
                                                       createGroupChatID: chatId,
                                                       hud: hud,
                                                       fromVC: fromVC)
                    case .timedOut:
                        hud.remove()
                        ForwardLogger.shared.error(module: .forwardAlert, event: "forwrad content loading timeout")
                    }
                }
            })
        Tracker.post(TeaEvent("im_msg_send_confirm_view",
                              params: ["scene": "msg_forward"]))
        currentAlertController = alertController
        self.forwardConfig.alertConfig.userResolver.navigator.present(alertController, from: self)
    }

    private func forwardExecuteInComponent(additionNote: NSAttributedString, createGroupChatID: String?, hud: UDToast, fromVC: UIViewController) {
        guard let forwardService = try? self.forwardConfig.alertConfig.userResolver.resolve(assert: ForwardService.self),
              let forwardContentParam = self.forwardContentParam
        else { return }
        ForwardLogger.shared.info(module: .forwardMessage, event: "forwrad content load successfully,start forwardExecution")
        let selectItems = self.picker.selected.compactMap { cast(option: $0) }
        let beforeSendTime = CACurrentMediaTime()
        let ids = forwardService.itemsToTargetIds(selectItems)
        forwardService.forwardMessageInComponent(selectItems: selectItems,
                                                 forwardContent: self.forwardConfig.alertConfig.content,
                                                 forwardParam: forwardContentParam,
                                                 additionNote: additionNote)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (results, filePermCheck) in
            guard let self = self,
                  let window = fromVC.view.window
            else { return }
            let chatIds = results.compactMap { $0 }.map { $0.chatID }
            self.trackAction(isMultiSelectMode: self.isMultiSelectMode,
                             selectRecordInfo: self.selectRecordInfos,
                             chatIds: chatIds)
            let forwardResults = ForwardResults.success(results)
            let forwardComponentResult: ForwardComponentResult = (forwardResults: forwardResults,
                                                                  chatIDs: Array(Set(ids.groupTargetIds + ids.threadTargets.map { $0.key })),
                                                                  userIDs: ids.userTargetIds,
                                                                  beforeSendTime: beforeSendTime)
            self.forwardConfig.commonConfig.forwardResultCallback?(forwardComponentResult)
            if let filePermCheck = filePermCheck {
                hud.showTips(with: filePermCheck.toast, on: window)
            } else if let successText = self.forwardConfig.commonConfig.forwardSuccessText {
                hud.showSuccess(with: successText, on: window)
            } else {
                hud.remove()
            }
            // 因为没有统一的转发接口，转发组件只能调用不同的接口去发消息
            // 单条/逐条/合并消息的转发接口入参是一组chatIDs，一次调用发送到多个目标，要成功就都成功
            // 其他走sendMessage接口的，入参是一个chatID，发多个目标时需要循环调接口，每次发送的成功与否是独立的，即使有一个发送失败也先catchErrorJustReturn
            // 当所有目标都发送失败时，才走错误处理逻辑
            let falseResultCount = results.compactMap { $0 }.filter { $0.isSuccess == false }.count
            if falseResultCount == selectItems.count {
                let error = NSError(domain: "lark.forward.send.error", code: 0)
                handleForwardError(error: error)
            }
            ForwardLogger.shared.info(module: .forwardMessage, event: "false forward result count: \(falseResultCount)")
            self.dismiss(with: createGroupChatID)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            ForwardLogger.shared.error(module: .forwardMessage, event: "fforwardExecute error: \(error)")
            handleForwardError(error: error)
            let forwardResults = ForwardResults.failure(error)
            let forwardComponentResult: ForwardComponentResult = (forwardResults: forwardResults,
                                                                  chatIDs: Array(Set(ids.groupTargetIds + ids.threadTargets.map { $0.key })),
                                                                  userIDs: ids.userTargetIds,
                                                                  beforeSendTime: beforeSendTime)
            self.forwardConfig.commonConfig.forwardResultCallback?(forwardComponentResult)
        }).disposed(by: self.disposeBag)
        func handleForwardError(error: Error) {
            if let error = error.underlyingError as? APIError,
               case .forwardThreadReachLimit(let message) = error.type {
                hud.remove()
                // 稍微延后，等上一个AlertController隐藏后再显示。
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
                    self?.showForwardThreadLimitAlert(additionNote: additionNote,
                                                      createGroupChatID: createGroupChatID,
                                                      hud: hud,
                                                      fromVC: fromVC,
                                                      with: message)
                })
                return
            } else {
                forwardComponentErrorHandler(userResolver: self.forwardConfig.alertConfig.userResolver,
                                             hud: hud,
                                             on: self,
                                             error: error)
            }
        }
    }

    private func dismiss(with newChatId: String?) {
        ForwardLogger.shared.info(module: .forwardMessage, event: "dismiss \(isOpenChatAfterCreateGroup) \(newChatId ?? "")")
        if isOpenChatAfterCreateGroup, let chatId = newChatId {
            // 创建群组并转发时，关闭转发面板并跳转到创建的新群
            self.pushToChat(chatId: chatId) { [ weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true,
                             completion: { [weak self] in
                    self?.forwardConfig.commonConfig.dismissAction?()
                })
            }
        } else {
            self.dismiss(animated: true,
                         completion: { [weak self] in
                self?.forwardConfig.commonConfig.dismissAction?()
            })
        }
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            completion?()
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
            self.forwardConfig.alertConfig.userResolver.navigator.showDetail(body: body, naviParams: params, from: splitVc) {_, _ in
                completion?()
            }
        } else if let nav = chatNav as? UINavigationController {
            self.forwardConfig.alertConfig.userResolver.navigator.push(body: body, naviParams: params, from: nav, animated: false) { _, _  in
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
            self.sureButton.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
            self.sureButton.isEnabled = true
        } else {
            self.sureButton.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .normal)
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
        let enabledConfigs = self.forwardConfig.targetConfig.enabledConfigs
        if let disabledBlock = self.forwardConfig.targetConfig.disadledBlock {
            let pickerItem = PickerItemFactory.shared.makeItem(forward: item)
            return disabledBlock(pickerItem)
        }
        return !ForwardConfigUtils.isForwardItemEnabled(item, enabledConfigs, forwardConfig.alertConfig.userResolver.userID)
    }

    public func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: sureButton.titleLabel?.text ?? BundleI18n.LarkForward.Lark_Legacy_Send,
            allowSelectNone: false,
            shouldDisplayCountTitle: false,
            targetPreview: self.picker.targetPreview,
            completion: { [weak self] fromVC in
                self?.currentAlertFromVC = fromVC
                self?.didTapSure()
            })
        self.forwardConfig.alertConfig.userResolver.navigator.push(body: body, from: self)
    }

    public func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        guard traceClick(item: item, selected: true) else { return false }
        if picker.isMultiple {
            let maxSelectCount = self.forwardConfig.chooseConfig.maxSelectCount
            if picker.selected.count >= maxSelectCount {
                let alertController = LarkAlertController()
                alertController.setContent(text: String(format: BundleI18n.LarkForward.Lark_Legacy_MaxChooseLimit, maxSelectCount))
                alertController.addPrimaryButton(text: BundleI18n.LarkForward.Lark_Legacy_Sure)
                self.forwardConfig.alertConfig.userResolver.navigator.present(alertController, from: self)
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

        if !picker.isMultiple {
            didTapSure()
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
                if let content = self.forwardConfig.alertConfig.content as? OpenShareContentAlertContent {
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
                if let content = self.forwardConfig.alertConfig.content as? OpenShareContentAlertContent {
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

    private func showForwardThreadLimitAlert(
        additionNote: NSAttributedString,
        createGroupChatID: String?,
        hud: UDToast,
        fromVC: UIViewController,
        with message: String
    ) {
        guard fromVC.view.window != nil else {
            assertionFailure()
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForward, alignment: .center)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorCancel, dismissCompletion: {
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorContinue, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.forwardExecuteQueue.async {
                self.forwardExecuteInComponent(additionNote: additionNote, createGroupChatID: createGroupChatID, hud: hud, fromVC: fromVC)
            }
        })
        self.forwardConfig.alertConfig.userResolver.navigator.present(alertController, from: fromVC)
    }
}
