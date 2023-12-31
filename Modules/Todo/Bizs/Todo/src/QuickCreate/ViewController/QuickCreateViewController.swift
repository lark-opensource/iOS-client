//
//  QuickCreateViewController.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/17.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LarkNavigator
import LarkUIKit
import LarkExtensions
import LarkContainer
import UniverseDesignToast
import UniverseDesignDialog
import TodoInterface
import LarkBaseKeyboard

/// QuickCreate - ViewController

final class QuickCreateViewController: BaseUIViewController, UITextViewDelegate, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var viewModel: QuickCreateViewModel

    private var observeKeyboard: Bool = false
    private var lastKeyboardY: CGFloat = 0
    private lazy var containerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
            cornerSize: CGSize(width: 12, height: 12)
        )
        return view
    }()
    private lazy var containerView: StackView = {
        let containerView = StackView()
        containerView.axis = .vertical
        containerView.spacing = 16
        containerView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerView.isLayoutMarginsRelativeArrangement = true
        return containerView
    }()
    private lazy var bottomPaddingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    private lazy var topSeparateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()
    private lazy var hideControl: UIControl = {
        let control = UIControl()
        control.addTarget(self, action: #selector(onTapCloseControl), for: .touchUpInside)
        return control
    }()
    private let disposeBag = DisposeBag()
    private lazy var headerView = QuickCreateHeaderView()
    private lazy var middleView = QuickCreateMiddleView()
    private lazy var bottomView = QuickCreateBottomView()
    private var inputController: InputController { viewModel.inputController }
    private var inputDelegateSet: TextViewInputProtocolSet?
    private var atPlugin: InputAtPlugin?
    private var atPickerContext = (
        picker: AtPickerViewController?.none,
        attachDisposable: Disposable?.none,
        alongside: AtPickerViewController.BottomInsetAlongside?.none,
        rxVisibleRect: BehaviorRelay<CGRect?>(value: nil)
    )
    // 可见区域
    private var visibleRect = (
        rxValue: BehaviorRelay(value: CGRect?.none),
        observations: [NSKeyValueObservation]()  // visibleRect 相关监听
    )
    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    @ScopedInjectedLazy private var todoService: TodoService?

    // 退出状态
    private var exitStatus = ExitStatus.idle

    init(resolver: UserResolver, source: TodoCreateSource, callbacks: TodoCreateCallbacks) {
        self.userResolver = resolver
        self.viewModel = QuickCreateViewModel(resolver: resolver, source: source, callbacks: callbacks)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isFirstAppear: Bool = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defer { isFirstAppear = false }
        observeKeyboard = true
        // 从二级页返回，这样弹出键盘更快.目前用于iOS13以下, iOS13以上调用formsheet不会触发这里
        if !isFirstAppear, exitStatus == .idle {
            headerView.textView.becomeFirstResponder()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observeKeyboard = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 第一次弹出为了输入框跟随键盘。目前用于iOS13以下, iOS13以上调用formsheet不会触发这里
        guard exitStatus == .idle else { return }
        if #available(iOS 15.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                self?.headerView.textView.becomeFirstResponder()
            }
        } else {
            headerView.textView.becomeFirstResponder()
        }
    }

    override func loadView() {
        super.loadView()
        let customView = PassthroungView(frame: UIScreen.main.bounds)
        customView.eventFilter = { [weak self] (point, _) -> Bool in
            guard let self = self else { return false }
            if point.y <= self.containerView.frame.minY && !self.headerView.textView.isFirstResponder {
                self.onClose(reason: .cancelEdit, animated: false)
                return false
            }
            return true
        }
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        setupViewModel()
        addKeyboardObserver()
        QuickCreate.Track.viewQuickCreate()
    }

    deinit {
        visibleRect.observations.forEach { $0.invalidate() }
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        view.backgroundColor = .clear
        isNavigationBarHidden = true
        view.addSubview(bottomPaddingView)
        view.addSubview(topSeparateLine)
        view.addSubview(containerView)
        view.addSubview(hideControl)
        let topView: UIView = UIView()
        containerView.addArrangedSubview(topView)
        containerView.addArrangedSubview(headerView)
        containerView.addArrangedSubview(middleView)
        containerView.addArrangedSubview(bottomView)

        containerView.insertSubview(containerBgView, at: 0)
        containerBgView.snp.makeConstraints { $0.edges.equalToSuperview() }

        topView.snp.makeConstraints { make in
            make.height.equalTo(4)
        }
        topSeparateLine.snp.makeConstraints { make in
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalTo(containerView.snp.top)
        }
        middleView.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(view.frame.height)
        }
        hideControl.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
            make.bottom.equalTo(topSeparateLine.snp.top)
        }
        bottomPaddingView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(lastKeyboardY)
            make.bottom.equalToSuperview()
        }
        headerView.textView.delegate = self
        headerView.textView.returnKeyType = viewModel.isInLineScene ? .next : .done
        headerView.placeholder = viewModel.headerPlaceholder()

        // setup visible rect
        let updateVisibleRect = { [weak self] in
            guard let self = self else { return }
            var targetVisibleRect = self.view.bounds
            targetVisibleRect.top = self.topSeparateLine.frame.top
            targetVisibleRect.size.height = self.view.bounds.height - targetVisibleRect.top
            if self.visibleRect.rxValue.value != targetVisibleRect {
                self.visibleRect.rxValue.accept(targetVisibleRect)
            }
        }
        updateVisibleRect()
        let obv1 = topSeparateLine.observe(\.frame, options: .new) { (_, _) in updateVisibleRect() }
        let obv2 = topSeparateLine.observe(\.bounds, options: .new) { (_, _) in updateVisibleRect() }
        let obv3 = topSeparateLine.observe(\.center, options: .new) { (_, _) in updateVisibleRect() }
        let obv4 = topSeparateLine.observe(\.transform, options: .new) { (_, _) in updateVisibleRect() }
        visibleRect.observations = [obv1, obv2, obv3, obv4]
    }

    private func bindViewData() {
        viewModel.rxOwnerViewData.bind(to: middleView.ownerContentView).disposed(by: disposeBag)
        viewModel.rxTimeViewData.bind(to: middleView.timeContentView).disposed(by: disposeBag)
        viewModel.rxDueTimePickViewData.bind(to: middleView.dueTimePickView).disposed(by: disposeBag)
        viewModel.rxBottomViewData.bind(to: bottomView).disposed(by: disposeBag)
    }

    private func setupViewModel() {
        headerView.textView.isEditable = false
        viewModel.setup().drive(onNext: { [weak self] in
            guard let self = self else { return }

            // reset inputText
            self.headerView.textView.isEditable = true
            self.headerView.textView.attributedText = self.inputController.makeAttrText(
                from: self.viewModel.todoData.richSummary,
                with: self.headerView.textView.defaultTypingAttributes
            )
            self.setupInputHandler()
            self.headerView.expandButton.isHidden = self.viewModel.displayHeaderExpand

            // bind view action
            self.bindHeaderAction()
            self.bindMiddleAction()
            self.bindBottomAction()
        }).disposed(by: disposeBag)
    }

    // MARK: UITextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !observeKeyboard || lastKeyboardY > 0 {
            // reset bottom
            containerView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-self.lastKeyboardY)
            }
            view.backgroundColor = UIColor.ud.bgMask
        }
        observeKeyboard = true
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        observeKeyboard = false
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let atPlugin = { [weak self] in
            self?.atPlugin?.captureReplacementText(text, in: range)
        }
        guard let delegateSet = inputDelegateSet else {
            atPlugin()
            return true
        }
        let shouldChanged = delegateSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
        if shouldChanged {
            atPlugin()
        }
        return shouldChanged
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let delegateSet = inputDelegateSet else { return }
        delegateSet.textViewDidChange(textView)
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        return false
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    // MARK: - Input Handler
    private func setupInputHandler() {
        atPlugin = .init(textView: headerView.textView)
        if viewModel.isFromChat {
            atPlugin?.onTiggered = { [weak self] atRange in
                guard let self = self else { return }
                var routeParams = RouteParams(from: self)
                routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
                routeParams.wrap = LkNavigationController.self
                self.routeDependency?.showAtPicker(
                    title: I18N.Todo_AddCollaborator_Tooltip,
                    chatId: self.viewModel.sourceChatId ?? "",
                    onSelect: { [weak self] (controller, seletedId) in
                        controller?.dismiss(animated: true)
                        guard let self = self else { return }
                        self.atPlugin?.reset()

                        self.viewModel.fetchTodoUsers(with: [seletedId]) { [weak self] todoUsers in
                            guard let self = self, let user = todoUsers.first else { return }
                            let mutAttrText = MutAttrText(attributedString: self.headerView.textView.attributedText)
                            let attrs = self.headerView.textView.defaultTypingAttributes
                            guard let cursorLocation = self.inputController.insertAtAttrText(
                                in: mutAttrText, for: user, with: attrs, in: atRange
                            ) else {
                                QuickCreate.logger.info("insert at attrText failed")
                                return
                            }
                            self.headerView.textView.attributedText = mutAttrText
                            self.headerView.textView.selectedRange = NSRange(location: cursorLocation, length: 0)
                            self.headerView.textView.autoScrollToSelectionIfNeeded()
                        }
                    },
                    onCancel: { },
                    params: routeParams
                )
            }
        } else {
            atPlugin?.onQueryChanged = { [weak self] atInfo in
                guard let self = self else { return }
                self.attachAtPicker()
                self.updateAtQuery(atInfo.query)
            }
            atPlugin?.onQueryInvalid = { [weak self] in
                self?.unattachAtPicker()
            }
        }

        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).summaryLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let window = self.view.window
        let returnInputHandler = inputController.makeReturnInputHandler { [weak self] () -> Bool in
            guard let self = self else { return false }
            guard let bottomViewData = self.viewModel.rxBottomViewData.value, bottomViewData.sendAction.isEnabled else {
                // 和发送按钮保持一致逻辑
                return false
            }
            QuickCreate.logger.info("tap keyboard return type")
            self.viewModel.save().subscribe(
                onSuccess: { [weak self] todo in
                    guard let self = self else { return }
                    self.viewModel.shareAfterSave(todoId: todo.guid) { shareResult in
                        var bottomInset: CGFloat?
                        if let superview = self.containerView.superview, let window = window {
                            let rectInScreen = superview.convert(self.containerView.frame, to: nil)
                            bottomInset = 20 + window.bounds.height - rectInScreen.top
                        }
                        Self.handleShareResult(shareResult, window: window, bottomInset: bottomInset)
                    }
                    let willDismiss = self.viewModel.closeAfterReturnType
                    if willDismiss {
                        self.onClose(reason: .saveSucceed)
                    } else {
                        self.viewModel.reset()
                    }
                    // reset以后会重置view高度，导致计算toast偏移的时候有问题。加个延迟
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.showCreateSucessToast(todo, willDismiss: willDismiss)
                    }
                    self.headerView.textView.attributedText = .init()
                },
                onError: { [weak self] err in
                    self?.onClose(reason: .saveFailed)
                    self?.showCreateErrorToast(err)
                }
            ).disposed(by: self.disposeBag)
            return false
        }
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)
        inputDelegateSet = TextViewInputProtocolSet([limitInputHandler, spanInputHandler, anchorInputHandler,
                                                     returnInputHandler, emojiInputHandler])
        headerView.textView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-task-quickcreate-input")
        inputDelegateSet?.register(textView: headerView.textView)
    }

    private static func handleShareResult(_ result: ShareToLarkResult, window: UIWindow?, bottomInset: CGFloat? = nil) {
        guard let window = window else { return }

        switch result {
        case .success(_, let blockAlert):
            if let blockAlert = blockAlert {
                Utils.Toast.showError(with: blockAlert.message, on: window)
                if let bottomInset = bottomInset {
                    UDToast.setCustomBottomMargin(bottomInset, view: window)
                }
            }
        case .failure(let message):
            Utils.Toast.showError(with: message, on: window)
            if let bottomInset = bottomInset {
                UDToast.setCustomBottomMargin(bottomInset, view: window)
            }
        }
    }

    // MARK: - View Action: Header
    private func bindHeaderAction() {
        headerView.onExpand = { [weak self] in
            guard let self = self else { return }
            let (todo, subTasks, source) = (self.viewModel.todoData, self.viewModel.subTasksData, self.viewModel.source)
            let (relatedTaskLists, sectionRefResult, ownedSection) = (self.viewModel.relatedTaskLists, self.viewModel.sectionRefResult, self.viewModel.ownedContainerSection)
            let callbacks = TodoCreateCallbacks(
                createHandler: { [weak self] res in
                    guard let self = self else { return }
                    self.viewModel.callbacks.createHandler?(res)
                    self.viewModel.deleteDraft()
                },
                cancelHandler: { [weak self] todo, subTasks, taskLists, sections, ownedSection in
                    guard let self = self  else { return }
                    self.viewModel.callbacks.cancelHandler?(todo, nil, nil, nil, nil)
                    self.viewModel.reset(with: todo, subTasks: subTasks, tasklists: taskLists, sections: sections, ownedSection: ownedSection)
                    self.headerView.textView.attributedText = self.inputController.makeAttrText(
                        from: self.viewModel.todoData.richSummary,
                        with: self.headerView.textView.defaultTypingAttributes
                    )
                    self.viewModel.trackUnexpand()
                },
                successToastHandler: { [self] todo in
                    // 这里需要强持有下self, 不然会被释放掉，没法执行
                    self.viewModel.callbacks.successToastHandler?(todo)
                }
            )
            QuickCreate.Track.clickExpand()
            let detailVC = DetailViewController(
                resolver: self.userResolver,
                input: .quickExpand(
                    todo: todo,
                    subTasks: subTasks,
                    relatedTaskLists: relatedTaskLists,
                    sectionRefResult: sectionRefResult,
                    ownedSection: ownedSection,
                    source: source,
                    callbacks: callbacks
                )
            )
            detailVC.onNeedsExit = { [weak self, weak detailVC] reason in
                guard [.create, .cancel].contains(reason) else { return false }
                self?.exitStatus = .will
                detailVC?.dismiss(animated: true)
                let exitReason: ExitReason
                switch reason {
                case .cancel:
                    exitReason = .cancelEdit
                default:
                    exitReason = .saveSucceed
                }
                self?.onClose(reason: exitReason, animated: true)
                return true
            }
            self.userResolver.navigator.present(
                detailVC,
                wrap: LkNavigationController.self,
                from: self,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
            self.viewModel.trackExpand()
        }

        headerView.textView.rx.attributedText.distinctUntilChanged()
            .map { $0 ?? AttrText() }
            .subscribe(onNext: { [weak self] attrText in
                self?.viewModel.updateSummaryInput(attrText)
            })
            .disposed(by: disposeBag)

        inputController.rxActiveChatters
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let mutAttrText = MutAttrText(attributedString: self.headerView.textView.attributedText ?? .init())
                self.inputController.resetAtInfo(in: mutAttrText)
                self.headerView.textView.updateAttributedText(mutAttrText,
                                                              in: self.headerView.textView.selectedRange)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - View Action: Middle
    private func bindMiddleAction() {
        // 点击今天
        middleView.dueTimePickView.onTodaySelect = { [weak self] in
            self?.viewModel.setTodayDueTime()
            self?.viewModel.trackPickTime(type: "today")
        }
        // 点击明天
        middleView.dueTimePickView.onTomorrowSelect = { [weak self] in
            self?.viewModel.setTomorrowDueTime()
            self?.viewModel.trackPickTime(type: "tomorrow")
        }
        // 点击其他
        middleView.dueTimePickView.onOtherSelect = { [weak self] in
            guard let self = self else { return }
            self.showTimePickerVC()
            self.viewModel.trackPickTime(type: "others")
        }

        // 点击删除时间
        middleView.timeContentView.onCloseTap = { [weak self] in
            guard let self = self else { return }
            self.viewModel.clearTimeComponents()
        }
        // 点击时间内容
        middleView.timeContentView.onContentTap = { [weak self] in
            guard let self = self else { return }
            self.showTimePickerVC()
        }

        // 点击删除
        middleView.ownerContentView.onClearHandler = { [weak self] in
            self?.viewModel.removeOwner()
        }
        // 点击内容
        middleView.ownerContentView.onContentHandler = { [weak self] in
            guard let self = self else { return }
            if FeatureGating(resolver: self.userResolver).boolValue(for: .multiAssignee) {
                self.showMemeberList()
            } else {
                self.showOwnerPicker()
            }
        }
    }

    private func showOwnerPicker() {
        guard viewModel.checkOwnerPickerInSubTask else {
            if let window = view.window, let superView = containerView.superview {
                let rectInScreen = superView.convert(containerView.frame, to: nil)
                let bottomInset = 20 + window.bounds.height - rectInScreen.top
                UDToast.showToast(with: UDToastConfig(
                     toastType: .warning,
                     text: I18N.Todo_PleaseEnterTaskTitle_Toast,
                     operation: nil
                 ), on: window)
                 UDToast.setCustomBottomMargin(bottomInset, view: window)
            }
            return
        }
        let result = viewModel.getSingleSubTaskReq()
        let ancestorGuid = result?.ancestorGuid ?? ""
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showOwnerPicker(
            title: I18N.Todo_TaskDetails_AddAnOwner_Button,
            chatId: viewModel.sourceChatId,
            selectedChatterIds: viewModel.selectedAssigneeIds,
            supportbatchAdd: viewModel.isFromSubTask,
            disableBatchAdd: false,
            batchHandler: { [weak self] fromVC in
                guard let self = self else { return }
                OwnerPicker.Track.multiSelectClick(with: ancestorGuid, isEdit: (result?.ancestorIsSubTask ?? false), isSubTask: true)
                self.showBatchOwnerPicker(fromVC, createSubTask: true)
            },
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                guard let self = self, let chatterId = chatterIds.first else { return }
                QuickCreate.logger.info("selected owner, id:\(chatterId)")
                self.viewModel.addOwners(with: [chatterId])
            },
            params: routeParams
        )
        OwnerPicker.Track.view(with: ancestorGuid,
                               isSubTask: !ancestorGuid.isEmpty,
                               isEdit: (result?.ancestorIsSubTask ?? false)
        )
    }

    private func showBatchOwnerPicker(_ fromVC: UIViewController, createSubTask: Bool) {
        if !createSubTask, !viewModel.checkOwnerPickerInSubTask {
            if let window = view.window, let superView = containerView.superview {
                let rectInScreen = superView.convert(containerView.frame, to: nil)
                let bottomInset = 20 + window.bounds.height - rectInScreen.top
                UDToast.showToast(with: UDToastConfig(
                     toastType: .warning,
                     text: I18N.Todo_PleaseEnterTaskTitle_Toast,
                     operation: nil
                 ), on: window)
                 UDToast.setCustomBottomMargin(bottomInset, view: window)
            }
            return
        }
        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let title = createSubTask ? I18N.Todo_MultiselectMembersToAssignTasks_Title : I18N.Todo_TaskDetails_AddAnOwner_Button
        // selectedChatterIds 批量指派应该是一个独立操作，不然会选不中已选的一个
        let selectedChatterIds = createSubTask ? [] : viewModel.selectedAssigneeIds
        let result = viewModel.getSingleSubTaskReq()
        routeDependency?.showChatterPicker(
            title:  title,
            chatId: viewModel.sourceChatId,
            isAssignee: true,
            selectedChatterIds: selectedChatterIds,
            selectedCallback: { [weak self] controller, chatterIds in
                guard let self = self else { return }
                if createSubTask {
                    OwnerPicker.Track.confirmClick(with: result?.ancestorGuid ?? "", isEdit: (result?.ancestorIsSubTask ?? false), isSubTask: true)
                    // 需要先把最底层的dissmiss掉
                    self.dismiss(animated: true)
                    self.onClose(reason: .saveSucceed, animated: true)
                    self.viewModel.createSubTasks(chatterIds)
                } else {
                    OwnerPicker.Track.finalAddClick(with: result?.ancestorGuid ?? "", isEdit: (result?.ancestorIsSubTask ?? false), isSubTask: true)
                    controller?.dismiss(animated: true, completion: nil)
                    self.viewModel.addOwners(with: chatterIds)
                }
            },
            params: routeParams
        )
        let ancestorGuid = result?.ancestorGuid ?? ""
        OwnerPicker.Track.view(
            with: ancestorGuid,
            isSubTask: !ancestorGuid.isEmpty,
            isEdit: (result?.ancestorIsSubTask ?? false)
        )
    }

    private func showMemeberList() {
        let vm = MemberListViewModel(resolver: userResolver, input: viewModel.memberListInput, dependency: viewModel)
        let vc = MemberListViewController(resolver: userResolver, viewModel: vm)
        vc.onNeedsExit = { [weak vc] in
            let theVC = vc?.navigationController ?? vc
            theVC?.dismiss(animated: true)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    // 新时间选择器
    private func showTimePickerVC() {
        let vm = TimePickerViewModel(resolver: userResolver, tuple: viewModel.getDueRemindTuple())
        let vc = TimePickerViewController(resolver: userResolver, viewModel: vm)
        vc.saveHandler = { [weak self] (tuple) in
            self?.viewModel.setTimeComponents(tuple)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    // MARK: - View Action: Bottom
    private func bindBottomAction() {
        bottomView.onIconTapped = { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .assignee:
                if FeatureGating(resolver: self.userResolver).boolValue(for: .multiAssignee) {
                    self.showBatchOwnerPicker(self, createSubTask: false)
                } else {
                    self.showOwnerPicker()
                }
            case .time:
                if self.viewModel.respondsToBottomTimeAction() == false {
                    self.showTimePickerVC()
                }
            }
        }

        bottomView.onSendTapped = { [weak self] in
            QuickCreate.logger.info("tap bottom send button")
            guard let self = self else { return }
            self.doSend()
        }
    }

    private func doSend() {
        let window = self.view.window
        viewModel.save().subscribe(
            onSuccess: { [weak self] todo in
                guard let self = self else { return }
                self.viewModel.shareAfterSave(todoId: todo.guid) { shareResult in
                    Self.handleShareResult(shareResult, window: window)
                }
                self.onClose(reason: .saveSucceed)
                self.showCreateSucessToast(todo, willDismiss: true)
                self.headerView.textView.attributedText = .init()
            },
            onError: { [weak self] err in
                self?.onClose(reason: .saveFailed)
                self?.showCreateErrorToast(err)
            }
        ).disposed(by: disposeBag)
    }

    // MARK: - Keyboard

    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChanged(with:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChanged(with:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc
    private func handleKeyboardFrameChanged(with noti: Notification) {
        QuickCreate.logger.info("response keyboard will changed, name: \(noti.name)")

        guard let userInfo = noti.userInfo else { return }
        let height = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0
        let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 0
        let curve = UIView.AnimationCurve(rawValue: curveValue)!

        var isKeyboardShown = false
        if noti.name == UIResponder.keyboardWillShowNotification {
            isKeyboardShown = true
            lastKeyboardY = height
        } else if noti.name == UIResponder.keyboardWillHideNotification {
            lastKeyboardY = 0
        } else {
            return
        }

        bottomPaddingView.snp.updateConstraints { make in
            make.height.equalTo(lastKeyboardY)
        }
        guard observeKeyboard else {
            QuickCreate.logger.info("not subscribe key board event")
            return
        }

        if isKeyboardShown {
            containerView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-lastKeyboardY)
            }
        } else {
            containerView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(view.frame.height)
            }
        }

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: { [weak self] in
                guard let self = self else { return }
                UIView.setAnimationCurve(curve)
                self.view.backgroundColor = isKeyboardShown ? UIColor.ud.bgMask : .clear
                self.view?.layoutIfNeeded()
            },
            completion: nil)

    }

    // MARK: - Close
    @objc
    private func onTapCloseControl() {
        viewModel.suspendCreateTrack()
        onClose(reason: .cancelEdit)
    }

    /// 描述退出原因
    private enum ExitReason {
        /// 取消编辑
        case cancelEdit
        /// 创建成功
        case saveSucceed
        /// 创建失败
        case saveFailed
    }

    /// 描述退出状态
    private enum ExitStatus: Int {
        case idle
        case will
        case did
    }

    private func onClose(reason: ExitReason, animated: Bool = false) {
        guard exitStatus != .did else { return }
        exitStatus = .will
        defer { exitStatus = .did }

        switch reason {
        case .cancelEdit, .saveFailed:
            viewModel.saveDraft()
        case .saveSucceed:
            break
        }
        if headerView.textView.isFirstResponder {
            headerView.textView.resignFirstResponder()
        }
        dismiss(animated: animated, completion: nil)
    }

}

// MARK: - Toast

extension QuickCreateViewController {

    private func showCreateSucessToast(_ todo: Rust.Todo, willDismiss: Bool) {
        if let window = self.view.window {
            let bottomInset: CGFloat
            if let superView = containerView.superview, !willDismiss {
                let rectInScreen = superView.convert(containerView.frame, to: nil)
                bottomInset = 20 + window.bounds.height - rectInScreen.top
            } else {
                bottomInset = Utils.Toast.standardBottomInset
            }

            if viewModel.isFromChat,
               let todoService = todoService,
               todoService.shouldDisplayGuideToastInChat(),
               case .chat(let chatContext) = viewModel.source,
               let handler = chatContext.chatGuideHandler {
                handler(bottomInset)
            } else {
                var operation: UDToastOperationConfig
                if !viewModel.isInLineScene {
                    UDToast.showToast(with: UDToastConfig(
                         toastType: .success,
                         text: I18N.Todo_common_CreatedSuccessfully,
                         operation: nil
                     ), on: window, delay: 2)
                     UDToast.setCustomBottomMargin(bottomInset, view: window)
                } else {
                    var operation = UDToastOperationConfig(
                        text: I18N.Todo_ViewDetails_New,
                        displayType: .auto
                    )
                    operation.textAlignment = .left
                    let config = UDToastConfig(
                        toastType: .success,
                        text: I18N.Todo_common_CreatedSuccessfully,
                        operation: operation
                    )
                    UDToast.showToast(with: config, on: window, delay: 7) { [self] _ in
                        // 这里需要强持有下self, 不然会被释放掉
                        if !willDismiss {
                            self.onClose(reason: .saveSucceed)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                self.viewModel.callbacks.successToastHandler?(todo)
                            }
                        } else {
                            self.viewModel.callbacks.successToastHandler?(todo)
                        }
                    }
                    UDToast.setCustomBottomMargin(bottomInset, view: window)
                }
            }
        }
    }

    private func showCreateErrorToast(_ err: Error) {
        var text = I18N.Todo_common_ActionFailedTryAgainLater
        switch Rust.makeUserError(from: err).bizCode() {
        case .assigneeLimit:
            text = I18N.Todo_UnableToAddMoreThanNumCollabs_Toast(SettingConfig(resolver: userResolver).getAssingeeLimit)
        case .followerLimit:
            text = I18N.Todo_Task_FollowerLimitToast(SettingConfig(resolver: userResolver).getFollowerLimit)
        default:
            break
        }
        if let window = view.window {
            Utils.Toast.showError(with: text, on: window)
        }
    }

}

// MARK: - At Picker

extension QuickCreateViewController {

    private var isAtPickerActive: Bool {
        guard let atPicker = atPickerContext.picker,
              atPicker.parent == self || atPicker.view.superview == view else {
            return false
        }
        return true
    }

    private func lazyInitAtPicker() -> AtPickerViewController {
        let atPicker = AtPickerViewController(resolver: userResolver, chatId: self.viewModel.sourceChatId)
        atPicker.dismissHandler = { [weak self] in
            QuickCreate.logger.info("try to dismiss atPicker")
            self?.atPlugin?.reset()
            self?.unattachAtPicker()
        }
        atPicker.selectHandler = { [weak self] user in
            QuickCreate.logger.info("atPicker item selected")
            guard let self = self, let atInfo = self.atPlugin?.latestAtInfo else { return }
            self.atPlugin?.reset()
            self.unattachAtPicker()

            let mutAttrText = MutAttrText(attributedString: self.headerView.textView.attributedText)
            let attrs = self.headerView.textView.defaultTypingAttributes
            guard let cursorLocation = self.inputController.insertAtAttrText(
                in: mutAttrText, for: user, with: attrs, in: atInfo.range
            ) else {
                QuickCreate.logger.info("insert at attrText failed")
                return
            }
            self.headerView.textView.attributedText = mutAttrText
            self.headerView.textView.selectedRange = NSRange(location: cursorLocation, length: 0)
            self.headerView.textView.autoScrollToSelectionIfNeeded()
        }
        return atPicker
    }

    // 更新 atPicker 搜索词
    private func updateAtQuery(_ query: String) {
        guard isAtPickerActive else {
            QuickCreate.logger.info("picker is not active, update query failed")
            return
        }
        QuickCreate.logger.info("picker is active, update query: \(query)")
        atPickerContext.picker?.updateQuery(query)
    }

    // 启用 atPicker
    private func attachAtPicker() {
        guard !isAtPickerActive else { return }
        if atPickerContext.picker == nil {
            atPickerContext.picker = lazyInitAtPicker()
        }
        guard let atPicker = atPickerContext.picker else { return }

        atPickerContext.attachDisposable?.dispose()
        addChild(atPicker)
        view.addSubview(atPicker.view)
        atPicker.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        atPicker.didMove(toParent: self)

        changeTopCorner(hasCorner: false)

        DispatchQueue.main.async {
            let alongside = atPicker.active()
            self.atPickerContext.alongside = alongside
            var lastInset: CGFloat = 0
            if let visibleRect = self.visibleRect.rxValue.value {
                lastInset = self.view.bounds.height - visibleRect.top
            }
            self.atPickerContext.alongside?(lastInset)
            self.atPickerContext.attachDisposable = self.visibleRect.rxValue
                .compactMap { $0 }
                .skip(1)
                .subscribe(onNext: { [weak self] rect in
                    guard let self = self else { return }
                    let newInset = self.view.bounds.height - rect.top
                    if newInset != lastInset {
                        lastInset = newInset
                        alongside(lastInset)
                    }
                })
        }
    }

    // 关闭 atPicker
    private func unattachAtPicker() {
        atPickerContext.attachDisposable?.dispose()
        atPickerContext.alongside = nil
        atPickerContext.rxVisibleRect.accept(nil)

        guard isAtPickerActive else { return }
        guard let atPicker = atPickerContext.picker else { return }

        changeTopCorner(hasCorner: true)

        atPicker.willMove(toParent: nil)
        atPicker.view.removeFromSuperview()
        atPicker.removeFromParent()
    }

    /// 顶部圆角处理
    private func changeTopCorner(hasCorner: Bool) {
        containerBgView.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
            cornerSize: hasCorner ? CGSize(width: 12, height: 12) : .zero
        )
        if hasCorner {
            topSeparateLine.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(12)
                make.right.equalToSuperview().offset(-12)
            }
        } else {
            topSeparateLine.snp.updateConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
    }

}
