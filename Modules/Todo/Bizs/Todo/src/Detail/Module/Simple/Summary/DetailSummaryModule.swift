//
//  DetailSummaryModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/26.
//

import EditTextView
import EENavigator
import RxSwift
import RxCocoa
import TodoInterface
import LarkContainer
import Foundation
import UniverseDesignDialog
import UniverseDesignActionPanel
import LarkKeyboardView
import LarkBaseKeyboard

/// Detail - Summary - Module

// nolint: magic number
final class DetailSummaryModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailSummaryViewModel

    private let disposeBag = DisposeBag()
    private let rootView = DetailSummaryView()
    private var inputDelegateSet: TextViewInputProtocolSet?
    private var atPlugin: InputAtPlugin?
    private var atContext: AtContext?
    private var inputController: InputController { viewModel.inputController }

    private var placeholder: String {
        return context.scene.isForSubTaskCreating ? I18N.Todo_AddSubTasks_Placeholder_Mobile : I18N.Todo_Task_AddTask
    }

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        setupView()
        bindInputAction()
        bindBusEvent()
        setupViewModel()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func setupViewModel() {
        viewModel.baseTextAttrs = rootView.baseAttributes
        viewModel.onCoreUpdate = { [weak self] core in
            self?.rootView.textView.attributedText = core.attrText
            self?.rootView.isEditable = core.isEditable
            self?.rootView.hasStrikethrough = core.hasStrikethrough
            self?.rootView.checkbox.viewData = {
                return CheckBoxViewData(checkState: core.checkBoxState, isRotated: core.isMilestone)
            }()
        }
        viewModel.onExtraUpdate = { [weak self] extra in
            guard let self = self else { return }
            if case .strikethrough(let hasStrikethrough) = extra.changed {
                self.rootView.hasStrikethrough = hasStrikethrough
            }
            let attrText = self.rootView.textView.attributedText ?? .init()
            self.rootView.textView.updateAttributedText(extra.transform(attrText),
                                                        in: self.rootView.textView.selectedRange)
        }
        viewModel.setup { [weak self] attrText in
            guard let self = self else { return }
            if let attrText = attrText {
                self.rootView.textView.attributedText = attrText
            } else {
                self.rootView.placeholder = self.placeholder
            }
        }
    }

    private func setupView() {
        rootView.textView.delegate = self
        rootView.textView.textDelegate = self
        rootView.textView.returnKeyType = context.scene.isForCreating ? .next : .done
        rootView.checkbox.delegate = self

        rootView.onUneditableTap = { [weak self] in
            guard let self = self, let window = self.view.window else { return }
            Utils.Toast.showWarning(with: self.viewModel.uneditableTapTip(), on: window)
        }

        // 新建场景，光标自动 focus
        if context.scene.isForCreating {
            // 唤起键盘时，textView 的权限还没有被放开（初始为无权限），这里先简单处理，后面从时序入手解决这个问题
            rootView.isEditable = true
            rootView.isCheckBoxHidden = true
            rootView.placeholder = placeholder
            rootView.textView.becomeFirstResponder()
        }
        // 粘贴emoji的时候不会出发didChange方法，所以用用rx
        rootView.textView.rx.attributedText.distinctUntilChanged()
            .map { $0 ?? AttrText() }
            .subscribe(onNext: { [weak self] attrText in
                self?.viewModel.handleEdit(attrText)
            })
            .disposed(by: disposeBag)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tap.delegate = self
        rootView.textView.addGestureRecognizer(tap)
    }

    private func bindBusEvent() {
        // 修复 view 的交互问题
        var fixed = false
        let fixInteraction = { [weak self] in
            guard !fixed, let self = self, let tableView = self.context.tableView else {
                return
            }
            fixed = true
            tableView.panGestureRecognizer.require(toFail: self.rootView.textView.panGestureRecognizer)
        }

        context.bus.subscribe { [weak self] action in
            switch action {
            case .hostLifeCycle(let lifeCycle):
                switch lifeCycle {
                case .didAppear:
                    fixInteraction()
                default:
                    break
                }
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func bindInputAction() {
        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).summaryLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let returnInputHandler = inputController.makeReturnInputHandler { [weak self] in
            guard let self = self else { return false }
            if self.context.scene.isForCreating {
                self.context.bus.post(.focusToNotes)
            } else {
                self.rootView.textView.resignFirstResponder()
            }
            return false
        }
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)
        inputDelegateSet = TextViewInputProtocolSet([limitInputHandler, returnInputHandler, spanInputHandler, anchorInputHandler,
                                                    emojiInputHandler])
        rootView.textView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-task-detail-summary-input")
        inputDelegateSet?.register(textView: rootView.textView)

        setupAtPlugin()
    }

}

// MARK: - Gesture Delegate

extension DetailSummaryModule: UIGestureRecognizerDelegate {

    @objc
    private func handleTapGesture() {
        // do nothing
    }

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard
            let containerVC = context.viewController,
            let tapItem = inputController.captureTapItem(with: gesture, in: rootView.textView)
        else {
            return false
        }
        inputController.handleTapAction(tapItem, from: containerVC)
        return false
    }

}

// MARK: - Input Delegate

extension DetailSummaryModule: UITextViewDelegate, EditTextViewTextDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        context.registerBottomInsetRelay(context.rxKeyboardHeight, forKey: "summary.input")
        viewModel.beginEditing()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        context.unregisterBottomInsetRelay(forKey: "summary.input")
        atPlugin?.reset()
        atContext?.unattachPicker()
        viewModel.endEditing(rootView.textView.attributedText ?? .init())
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
        if let delegateSet = inputDelegateSet {
            delegateSet.textViewDidChange(textView)
        }
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
        return false
    }

}

// MARK: - At Picker

extension DetailSummaryModule {

    fileprivate final class AtContext {
        weak var context: DetailModuleContext?
        var picker: AtPickerViewController
        private let textView: UITextView
        private var adjustAtPickerInsetDisposable: Disposable?

        /// 是否处于激活状态
        var isActive: Bool {
            guard let container = context?.viewController,
                  picker.parent == container || picker.view.superview == container.view else {
                return false
            }
            return true
        }

        var disposeBag = DisposeBag()

        init(context: DetailModuleContext, picker: AtPickerViewController, textView: UITextView) {
            self.context = context
            self.picker = picker
            self.textView = textView
        }

        func updateQuery(_ query: String) {
            guard isActive else {
                Detail.logger.info("picker is not active, update query failed")
                return
            }
            Detail.logger.info("picker is active, update query: \(query)")
            picker.updateQuery(query)
        }

        func attachPicker() {
            guard let containerVC = context?.viewController, !isActive else { return }

            adjustAtPickerInsetDisposable?.dispose()
            containerVC.addChild(picker)
            containerVC.view.addSubview(picker.view)
            picker.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            picker.didMove(toParent: containerVC)

            DispatchQueue.main.async {
                guard let context = self.context, let containerVC = self.context?.viewController else {
                    return
                }
                let alongside = self.picker.active()
                var lastInset = context.rxKeyboardHeight.value
                alongside(lastInset)
                self.adjustAtPickerInsetDisposable = context.rxKeyboardHeight.skip(1)
                    .subscribe(onNext: { [weak self] height in
                        guard let containerVC = self?.context?.viewController else {
                            return
                        }
                        var newInset = height
                        if newInset != lastInset {
                            lastInset = newInset
                            alongside(lastInset)
                        }
                    })
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let cursorOffset = self.textView.selectedTextRange?.start {
                    let rectInTextView = self.textView.caretRect(for: cursorOffset)
                    if let tableView = self.context?.tableView {
                        let rectInTableView = tableView.convert(rectInTextView, from: self.textView)
                        var targetOffset = tableView.contentOffset
                        if abs(targetOffset.y - rectInTableView.top) > 20 {
                            targetOffset.y = rectInTableView.top
                            tableView.setContentOffset(targetOffset, animated: true)
                        }
                    }
                }
            }
        }

        func unattachPicker() {
            guard isActive else { return }

            adjustAtPickerInsetDisposable?.dispose()
            picker.willMove(toParent: nil)
            picker.view.removeFromSuperview()
            picker.removeFromParent()
        }
    }

    private func setupAtPlugin() {
        atPlugin = InputAtPlugin(textView: rootView.textView)
        atPlugin?.onQueryChanged = { [weak self] atInfo in
            guard let self = self else { return }
            if self.atContext == nil {
                self.atContext = self.lazyInitAtContext()
            }
            self.atContext?.attachPicker()
            self.atContext?.updateQuery(atInfo.query)
        }
        atPlugin?.onQueryInvalid = { [weak self] in
            self?.atContext?.unattachPicker()
        }
    }

    private func lazyInitAtContext() -> AtContext? {
        guard let container = context.viewController else { return nil }
        let atPicker = AtPickerViewController(resolver: userResolver, chatId: context.scene.chatId)
        atPicker.dismissHandler = { [weak self] in
            Detail.logger.info("try to dismiss atPicker")
            self?.atPlugin?.reset()
            self?.atContext?.unattachPicker()
        }
        atPicker.selectHandler = { [weak self] user in
            Detail.logger.info("atPicker item selected")
            guard let self = self, let atInfo = self.atPlugin?.latestAtInfo else {
                return
            }
            self.atPlugin?.reset()
            self.atContext?.unattachPicker()

            let mutAttrText = MutAttrText(attributedString: self.rootView.textView.attributedText ?? .init())
            let attrs = self.rootView.baseAttributes
            guard let cursorLocation = self.inputController.insertAtAttrText(
                in: mutAttrText, for: user, with: attrs, in: atInfo.range
            ) else {
                Detail.logger.info("insert at attrText failed")
                return
            }
            self.rootView.textView.attributedText = mutAttrText
            self.rootView.textView.selectedRange = NSRange(location: cursorLocation, length: 0)
            self.rootView.textView.autoScrollToSelectionIfNeeded()
            self.viewModel.handleEdit(mutAttrText)
        }
        return AtContext(context: context, picker: atPicker, textView: rootView.textView)
    }

    /// 插入 at 信息
    private func insertAtAttrText(_ attrText: AttrText, in range: NSRange) -> Bool {
        var mutAttrText = MutAttrText(attributedString: rootView.textView.attributedText ?? .init())
        guard range.location >= 0 && NSMaxRange(range) <= mutAttrText.length else {
            return false
        }
        mutAttrText.replaceCharacters(in: range, with: attrText)
        rootView.textView.attributedText = mutAttrText
        viewModel.handleEdit(mutAttrText)
        return true
    }

}

// MARK: - CheckBox Delegate

extension DetailSummaryModule: CheckboxDelegate {

    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        return { }
    }

    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction {
        if let (role, items) = viewModel.completeActionSheetData() {
            if let role = role {
                return handleComplete(role: role)
            }
            if let items = items {
                return .needsAsk(
                    ask: { [weak self] (onYes, onNo) in
                        guard let self = self else { return }
                        let source = UDActionSheetSource(
                            sourceView: checkbox,
                            sourceRect: CGRect(x: checkbox.frame.width / 2, y: checkbox.frame.height, width: 0, height: 0),
                            arrowDirection: .unknown
                        )
                        let config = UDActionSheetUIConfig(popSource: source)
                        let actionSheet = UDActionSheet(config: config)
                        items.forEach { (role: CompleteRole, title: String) in
                            actionSheet.addItem(
                                UDActionSheetItem(
                                    title: title,
                                    titleColor: UIColor.ud.textTitle,
                                    action: { [weak self] in
                                        guard let self = self else { return }
                                        switch self.handleComplete(role: role) {
                                        case .immediate(let completion):
                                            completion()
                                            onNo()
                                        case .needsAsk(let ask, let completion):
                                            ask({
                                                completion()
                                                onYes()
                                            },
                                                onNo
                                            )
                                        }
                                    }
                                )
                            )
                        }
                        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
                        self.context.viewController?.present(actionSheet, animated: true, completion: nil)
                    },
                    completion: { }
                )
            }
            V3Home.assertionFailure("invalid")
            return .immediate { }
        } else {
            V3Home.assertionFailure("can not toggle complete")
            return .immediate { }
        }

    }

    private func handleComplete(role: CompleteRole) -> CheckboxEnabledAction {
        let completion = { }

        if let viewData = viewModel.checkDependent() {
            return .needsAsk(
                ask: { [weak self] (onYes, onNo) in
                    guard let self = self, let from = self.context.viewController  else { return }
                    let dialog = UDDialog()
                    dialog.setTitle(text: I18N.Todo_GanttView_CompleteBlockedBy_Title)
                    let customView = DetailDependentDialogCustomView()
                    customView.viewData = viewData
                    dialog.setContent(view: customView)
                    dialog.addCancelButton(dismissCompletion: onNo)
                    dialog.addPrimaryButton(text: I18N.Todo_GanttView_CompleteBlockedBy_MarkComplete_Button, dismissCompletion: onYes)
                    from.present(dialog, animated: true)
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    self.doToggleComplete(role: role)
                    completion()
                })
        }

        /// 自定义完成
        if let customComplete = viewModel.getCustomComplete() {
            return .needsAsk(
                ask: { [weak self] (_, onNo) in
                    guard let self = self, let from = self.context.viewController else { return }
                    customComplete.doAction(on: from)
                    onNo()
                },
                completion: completion
            )
        }

        if let doubleCheck = viewModel.doubleCheckBeforeToggleCompleteState(role: role) {
            return .needsAsk(
                ask: { [weak self] (onYes, onNo) in
                    guard let self = self, let from = self.context.viewController  else { return }
                    let dialog = UDDialog()
                    dialog.setTitle(text: doubleCheck.title)
                    dialog.setContent(text: doubleCheck.content)
                    dialog.addCancelButton(dismissCompletion: onNo)
                    dialog.addPrimaryButton(text: doubleCheck.confirm, dismissCompletion: onYes)
                    from.present(dialog, animated: true)
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    self.doToggleComplete(role: role)
                    completion()
                }
            )
        } else {
            return .immediate { [weak self] in
                guard let self = self else { return }
                self.doToggleComplete(role: role)
                completion()
            }
        }

    }

    private func doToggleComplete(role: CompleteRole) {
        viewModel.toggleComplete(
            role: role,
            completion: { [weak self] res in
                switch res {
                case .success(let t):
                    if let toast = t.toast, let window = self?.context.viewController?.view.window {
                        Utils.Toast.showSuccess(with: toast, on: window)
                    }
                case .failure(let err):
                    guard let window = self?.context.viewController?.view.window else { return }
                    Utils.Toast.showError(with: err.message, on: window)
                }
            }
        )
    }

}
