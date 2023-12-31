//
//  DetailNotesInputModule.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import RxSwift
import RxCocoa
import LarkUIKit
import EditTextView
import EENavigator
import TodoInterface
import LarkContainer
import LarkKeyboardView
import LarkBaseKeyboard

/// Detail - NotesInput - Module
/// 详情页编辑场景的 notes 模块

// nolint: magic number
final class DetailNotesInputModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailNotesInputViewModel

    private let notesView = DetailNotesInputView()
    private let disposeBag = DisposeBag()
    private var inputDelegateSet: TextViewInputProtocolSet?
    private var atPlugin: InputAtPlugin?
    private var atContext: AtContext?
    private var inputController: InputController { viewModel.inputController }

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        guard context.scene.isForCreating else {
            assertionFailure("just for creating")
            return
        }

        setupView()
        setupViewModel()
        bindBusEvent()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(notesView)
        notesView.snp.makeConstraints { $0.edges.equalToSuperview() }
        notesView.textView.delegate = self
        notesView.textView.textDelegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tap.delegate = self
        notesView.textView.addGestureRecognizer(tap)
    }

    private func setupViewModel() {
        viewModel.baseTextAttrs = notesView.textView.defaultTypingAttributes
        viewModel.setup()
            .drive(onNext: { [weak self] attrText in
                self?.setupInput(with: attrText)
            })
            .disposed(by: disposeBag)
    }

    private func setupInput(with initialAttrText: AttrText) {
        notesView.textView.isEditable = true
        notesView.textView.attributedText = initialAttrText

        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).notesLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let returnInputHandler = inputController.makeReturnInputHandler {
            // 返回 true，允许用户输入 enter 换行
            return true
        }
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)

        inputDelegateSet = TextViewInputProtocolSet([limitInputHandler, spanInputHandler, anchorInputHandler,
                                                     returnInputHandler, emojiInputHandler])
        notesView.textView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-task-create-note-input")
        inputDelegateSet?.register(textView: notesView.textView)
        setupAtPlugin()

        notesView.textView.rx.attributedText
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] attrText in
                self?.viewModel.notesDidChange(attrText ?? .init())
            })
            .disposed(by: disposeBag)

        let textView = notesView.textView
        inputController.rxActiveChatters
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self, weak textView] _ in
                guard let self = self, let textView = textView else { return }
                let mutAttrText = MutAttrText(attributedString: textView.attributedText)
                self.inputController.resetAtInfo(in: mutAttrText)
                textView.attributedText = mutAttrText
            })
            .disposed(by: disposeBag)
    }

    private func bindBusEvent() {
        // 修复 textView 的交互问题：和 tableView 的手势冲突
        var fixed = false
        let fixInteraction = { [weak self] in
            guard !fixed, let self = self, let tableView = self.context.tableView else {
                return
            }
            fixed = true
            let textViewGesture = self.notesView.textView.panGestureRecognizer
            tableView.panGestureRecognizer.require(toFail: textViewGesture)
        }

        context.bus.subscribe { [weak self] action in
            switch action {
            case .hostLifeCycle(let lifeCycle):
                if case .didAppear = lifeCycle {
                    fixInteraction()
                }
            case .focusToNotes:
                self?.notesView.textView.becomeFirstResponder()
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

}

// MARK: - Gesture Recognizer

extension DetailNotesInputModule: UIGestureRecognizerDelegate {

    @objc
    private func handleTapGesture() {
        // do nothing
    }

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard
            let containerVC = context.viewController,
            let tapItem = inputController.captureTapItem(with: gesture, in: notesView.textView)
        else {
            return false
        }
        inputController.handleTapAction(tapItem, from: containerVC)
        return false
    }

}

// MARK: - Input Delegate

extension DetailNotesInputModule: UITextViewDelegate, EditTextViewTextDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        context.registerBottomInsetRelay(context.rxKeyboardHeight, forKey: "notes.input")
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        context.unregisterBottomInsetRelay(forKey: "notes.input")
        atPlugin?.reset()
        atContext?.unattachPicker()
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

}

// MARK: - At Picker

extension DetailNotesInputModule {

    fileprivate final class AtContext {
        weak var context: DetailModuleContext?
        var picker: AtPickerViewController
        private let textView: UITextView
        private var adjustAtPickerInsetDisposable: Disposable?

        /// 是否处于激活状态
        var isActive: Bool {
            guard
                let container = context?.viewController,
                picker.parent == container || picker.view.superview == container.view
            else {
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
                guard let context = self.context, let containerVC = context.viewController else {
                    return
                }
                let alongside = self.picker.active()
                var lastInset = context.rxKeyboardHeight.value
                alongside(lastInset)
                self.adjustAtPickerInsetDisposable = context.rxKeyboardHeight.skip(1)
                    .subscribe(onNext: { [weak self] height in
                        guard let containerVC = self?.context?.viewController else { return }
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
                        targetOffset.y = rectInTableView.top
                        tableView.setContentOffset(targetOffset, animated: true)
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
        atPlugin = InputAtPlugin(textView: notesView.textView)
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
            let mutAttrText = MutAttrText(attributedString: self.notesView.textView.attributedText)
            let attrs = self.notesView.textView.defaultTypingAttributes
            guard let cursorLocation = self.inputController.insertAtAttrText(
                in: mutAttrText, for: user, with: attrs, in: atInfo.range
            ) else {
                Detail.logger.info("insert at attrText failed")
                return
            }
            self.notesView.textView.attributedText = mutAttrText
            self.notesView.textView.selectedRange = NSRange(location: cursorLocation, length: 0)
            self.notesView.textView.autoScrollToSelectionIfNeeded()
        }
        return AtContext(context: self.context, picker: atPicker, textView: notesView.textView)
    }

}
