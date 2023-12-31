//
//  DetailSubTaskCellInputController.swift
//  Todo
//
//  Created by baiyantao on 2022/8/1.
//

import Foundation
import RxSwift
import RxCocoa
import EditTextView
import LarkKeyboardView
import LarkContainer
import LarkBaseKeyboard

final class DetailSubTaskCellInputController: NSObject, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var returnHandler: (() -> Void)?
    var emptyBackspaceHandler: (() -> Void)?
    var beginEditingHandler: (() -> Void)?
    var endEditingHandler: (() -> Void)?

    private var inputDelegateSet: TextViewInputProtocolSet?
    private var atPlugin: InputAtPlugin?
    private var atContext: AtContext?

    private let disposeBag = DisposeBag()

    private let context: DetailModuleContext
    private let summaryView: DetailSubTaskCellSummaryView
    private(set) lazy var inputController = InputController(resolver: userResolver, sourceId: nil)

    init(resolver: UserResolver, context: DetailModuleContext, summaryView: DetailSubTaskCellSummaryView) {
        self.userResolver = resolver
        self.context = context
        self.summaryView = summaryView
    }

    func setup() {
        summaryView.textView.delegate = self
        summaryView.textView.textDelegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tap.delegate = self
        summaryView.textView.addGestureRecognizer(tap)

        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).summaryLimit) { [weak self] in
            guard let self = self, let window = self.context.tableView?.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let returnInputHandler = inputController.makeReturnInputHandler { [weak self] in
            self?.returnHandler?()
            return false
        }
        let emptyBackspaceInputHandler = inputController.makeEmptyBackspaceInputHandler { [weak self] in
            self?.emptyBackspaceHandler?()
        }
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)

        inputDelegateSet = TextViewInputProtocolSet([
            limitInputHandler, spanInputHandler, anchorInputHandler,
            returnInputHandler, emptyBackspaceInputHandler, emojiInputHandler
        ])
        summaryView.textView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-task-create-subtask-input")
        inputDelegateSet?.register(textView: summaryView.textView)
        setupAtPlugin()

        inputController.rxActiveChatters
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let textView = self.summaryView.textView
                let mutAttrText = MutAttrText(attributedString: textView.attributedText)
                self.inputController.resetAtInfo(in: mutAttrText)
                textView.attributedText = mutAttrText
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Gesture Delegate

extension DetailSubTaskCellInputController: UIGestureRecognizerDelegate {

    @objc
    private func handleTapGesture() {
        // do nothing
    }

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard
            let containerVC = context.viewController,
            let tapItem = inputController.captureTapItem(with: gesture, in: summaryView.textView)
        else {
            return false
        }
        inputController.handleTapAction(tapItem, from: containerVC)
        return false
    }

}

// MARK: - Input Delegate

extension DetailSubTaskCellInputController: UITextViewDelegate, EditTextViewTextDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        context.registerBottomInsetRelay(context.rxKeyboardHeight, forKey: "subTask.input")
        beginEditingHandler?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        context.unregisterBottomInsetRelay(forKey: "subTask.input")
        atPlugin?.reset()
        atContext?.unattachPicker()
        endEditingHandler?()
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

extension DetailSubTaskCellInputController {

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
                DetailSubTask.logger.info("picker is not active, update query failed")
                return
            }
            DetailSubTask.logger.info("picker is active, update query: \(query)")
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
        atPlugin = InputAtPlugin(textView: summaryView.textView)
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
            DetailSubTask.logger.info("try to dismiss atPicker")
            self?.atPlugin?.reset()
            self?.atContext?.unattachPicker()
        }
        atPicker.selectHandler = { [weak self] user in
            DetailSubTask.logger.info("atPicker item selected")
            guard let self = self, let atInfo = self.atPlugin?.latestAtInfo else {
                return
            }
            self.atPlugin?.reset()
            self.atContext?.unattachPicker()

            let mutAttrText = MutAttrText(attributedString: self.summaryView.textView.attributedText ?? .init())
            let attrs = DetailSubTaskCellSummaryView.baseAttributes
            guard let cursorLocation = self.inputController.insertAtAttrText(
                in: mutAttrText, for: user, with: attrs, in: atInfo.range
            ) else {
                DetailSubTask.logger.info("insert at attrText failed")
                return
            }
            self.summaryView.textView.attributedText = mutAttrText
            self.summaryView.textView.selectedRange = NSRange(location: cursorLocation, length: 0)
            self.summaryView.textView.autoScrollToSelectionIfNeeded()
        }
        return AtContext(context: context, picker: atPicker, textView: summaryView.textView)
    }
}
