//
//  DetailNotesViewController.swift
//  Todo
//
//  Created by 张威 on 2021/3/12.
//

import SnapKit
import RxSwift
import RxCocoa
import LarkUIKit
import EditTextView
import CTFoundation
import TodoInterface
import EENavigator
import LarkContainer
import UniverseDesignIcon
import LarkKeyboardView
import LarkBaseKeyboard
import UniverseDesignFont
import LarkChatOpenKeyboard

/// DetailNotes - ViewController
/// 任务备注编辑器

final class DetailNotesViewController: BaseUIViewController, UserResolverWrapper,
    UIGestureRecognizerDelegate,
    UITextViewDelegate,
    EditTextViewTextDelegate,
    UIAdaptivePresentationControllerDelegate {

    enum Scene {
        case note
        case customFiled
    }

    var onSave: ((_ result: Rust.RichContent) -> Void)?
    var userResolver: LarkContainer.UserResolver
    var naviTitle: String? = I18N.Todo_Task_TaskNotes
    var scene: Scene = .note

    var isForceActive: Bool { scene == .customFiled }

    private lazy var keyboard = Keyboard()
    private lazy var rxKeyboardHeight = BehaviorRelay<CGFloat>(value: 0)
    private let disposeBag = DisposeBag()
    private var atPlugin: InputAtPlugin?
    private var atPickerContext = (
        picker: AtPickerViewController?.none,
        attachDisposable: Disposable?.none,
        alongside: AtPickerViewController.BottomInsetAlongside?.none,
        rxVisibleRect: BehaviorRelay<CGRect?>(value: nil)
    )

    private var inputTextView = LarkEditTextView()
    private var inputDelegateSet: TextViewInputProtocolSet?
    private var inputBaseAttrs: [AttrText.Key: Any] = [
        .font: UDFont.systemFont(ofSize: 16),
        .foregroundColor: UIColor.ud.textTitle,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            return paragraphStyle
        }()
    ]

    private let richContent: Rust.RichContent
    private let isEditable: Bool
    private let inputController: InputController

    init(
        resolver: UserResolver,
        richContent: Rust.RichContent,
        isEditable: Bool,
        inputController: InputController
    ) {
        self.userResolver = resolver
        self.richContent = richContent
        self.isEditable = isEditable
        self.inputController = inputController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = naviTitle
        setupView()
        bindInputAction()
        setupNaviItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if inputTextView.isEditable {
            // 为了修复在at，anchor, image为结尾的时候，在点击最后会响应这些事件
            if inputController.needsEndEmptyChar(in: inputTextView.attributedText) {
                let mutAttrText = MutAttrText(attributedString: inputTextView.attributedText)
                inputController.appendEndEmptyChar(in: mutAttrText, with: inputBaseAttrs)
                inputTextView.attributedText = mutAttrText
            }
        }
        if inputTextView.isEditable && inputTextView.attributedText.length == 0 {
            inputTextView.becomeFirstResponder()
        }

        registerKeyboardNotification()
    }

    private func registerKeyboardNotification() {
        if !keyboard.isListening {
            keyboard.on(events: Keyboard.KeyboardEvent.allCases) { [weak self] options in
                guard let self = self else { return }
                if Display.pad,
                   case .formSheet = self.navigationController?.modalPresentationStyle,
                   let superView = self.view.superview, let window = self.view.window {
                    let rectInWindow = superView.convert(self.view.frame, to: window)
                    let offsetY = window.bounds.height - rectInWindow.maxY
                    let fixedHeight = max(0, options.endFrame.height - offsetY)
                    self.rxKeyboardHeight.accept(fixedHeight)
                } else {
                    self.rxKeyboardHeight.accept(options.endFrame.height)
                }
            }
            keyboard.start()

            rxKeyboardHeight.observeOn(MainScheduler.instance)
                .skip(1)
                .subscribe(onNext: { [weak self] bottomInset in
                    self?.handleBottomInsetUpdate(bottomInset)
                })
            .disposed(by: disposeBag)
        }
    }

    private func handleBottomInsetUpdate(_ bottomInset: CGFloat) {
        var contentInset = inputTextView.contentInset
        guard contentInset.bottom != bottomInset else { return }
        contentInset.bottom = bottomInset
        inputTextView.contentInset = contentInset
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody
        navigationController?.presentationController?.delegate = self

        inputTextView.gestureRecognizeSimultaneously = false
        inputTextView.textDragInteraction?.isEnabled = false
        inputTextView.defaultTypingAttributes = inputBaseAttrs
        inputTextView.textAlignment = .left
        inputTextView.maxHeight = 0
        inputTextView.keyboardDismissMode = .onDrag
        inputTextView.delegate = self
        inputTextView.showsVerticalScrollIndicator = false
        inputTextView.linkTextAttributes = [:]
        inputTextView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-task-detail-note-input")
        view.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
        inputTextView.backgroundColor = UIColor.ud.bgBody
        inputTextView.isEditable = isEditable
        inputTextView.attributedText = inputController.makeAttrText(from: richContent, with: inputBaseAttrs, isAtForceActive: isForceActive)
        observeActiveChatters(for: inputTextView)
        addGestureToTextView()
    }

    private func bindInputAction() {
        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).notesLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let returnInputHandler = inputController.makeReturnInputHandler { true }
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)

        inputDelegateSet = TextViewInputProtocolSet([limitInputHandler, spanInputHandler, anchorInputHandler,
                                                     returnInputHandler, emojiInputHandler])
        inputDelegateSet?.register(textView: inputTextView)

        atPlugin = .init(textView: inputTextView)
        atPlugin?.onQueryChanged = { [weak self] atInfo in
            guard let self = self else { return }
            self.attachAtPicker()
            self.updateAtQuery(atInfo.query)
        }
        atPlugin?.onQueryInvalid = { [weak self] in
            self?.unattachAtPicker()
        }
    }

    private func setupNaviItem() {
        let exitItem = LKBarButtonItem(image: nil, title: I18N.Todo_Common_Cancel, fontStyle: .medium)
        exitItem.button.titleLabel?.textColor = UIColor.ud.textTitle
        exitItem.button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        navigationItem.leftBarButtonItem = exitItem

        if isEditable {
            let saveItem = LKBarButtonItem(image: nil, title: I18N.Todo_common_Save, fontStyle: .medium)
            saveItem.button.tintColor = UIColor.ud.primaryContentDefault
            saveItem.button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
            navigationItem.rightBarButtonItem = saveItem
        }
    }

    @objc
    private func handleClose() {
        closeBtnTapped()
    }

    @objc
    private func handleSave() {
        let attrText = inputTextView.attributedText ?? .init()
        let richContent = inputController.makeRichContent(from: attrText)
        onSave?(richContent)
        closeBtnTapped()
    }

    private func observeActiveChatters(for textView: LarkEditTextView) {
        inputController.rxActiveChatters
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self, weak textView] _ in
                guard let self = self, let textView = textView else { return }
                let mutAttrText = MutAttrText(attributedString: textView.attributedText)
                self.inputController.resetAtInfo(in: mutAttrText, isForceActive: self.isForceActive)
                textView.attributedText = mutAttrText
            })
            .disposed(by: disposeBag)
    }

    // MAKR: Handle Tap

    private func addGestureToTextView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tap.delegate = self
        inputTextView.addGestureRecognizer(tap)
    }

    @objc
    private func handleTapGesture() {
        // do nothing
    }

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard let tapItem = inputController.captureTapItem(with: gesture, in: inputTextView) else {
            return false
        }
        inputController.handleTapAction(tapItem, from: self)
        return false
    }

    // MARK: Presentation Delegate

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard inputTextView.isEditable else { return true }
        guard inputTextView.attributedText.length == 0 else { return false }
        return true
    }

    // MARK: Input Delegate

    func textViewDidEndEditing(_ textView: UITextView) {
        atPlugin?.reset()
        unattachAtPicker()
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

extension DetailNotesViewController {

    private var isAtPickerActive: Bool {
        guard let atPicker = atPickerContext.picker,
              atPicker.parent == self || atPicker.view.superview == view else {
            return false
        }
        return true
    }

    private func lazyInitAtPicker() -> AtPickerViewController {
        let atPicker = AtPickerViewController(resolver: userResolver, chatId: nil)
        atPicker.dismissHandler = { [weak self] in
            Detail.logger.info("try to dismiss atPicker")
            self?.atPlugin?.reset()
            self?.unattachAtPicker()
        }
        atPicker.selectHandler = { [weak self] user in
            Detail.logger.info("atPicker item selected")
            guard let self = self, let atInfo = self.atPlugin?.latestAtInfo else { return }
            self.atPlugin?.reset()
            self.unattachAtPicker()
            let mutAttrText = MutAttrText(attributedString: self.inputTextView.attributedText)
            let attrs = self.inputBaseAttrs
            guard let cursorLocation = self.inputController.insertAtAttrText(
                in: mutAttrText, for: user, with: attrs, in: atInfo.range, isForceActive: self.isForceActive
            ) else {
                Detail.logger.info("insert at attrText failed")
                return
            }
            self.inputTextView.attributedText = mutAttrText
            self.inputTextView.selectedRange = NSRange(location: cursorLocation, length: 0)
            self.inputTextView.autoScrollToSelectionIfNeeded()
        }
        return atPicker
    }

    // 更新 atPicker 搜索词
    private func updateAtQuery(_ query: String) {
        guard isAtPickerActive else {
            Detail.logger.info("picker is not active, update query failed")
            return
        }
        Detail.logger.info("picker is active, update query: \(query)")
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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alongside = atPicker.active()
            self.atPickerContext.alongside = alongside
            var lastInset = self.rxKeyboardHeight.value
            self.atPickerContext.alongside?(lastInset)
            self.atPickerContext.attachDisposable = self.rxKeyboardHeight.skip(1)
                .subscribe(onNext: { height in
                    var newInset = height
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

        atPicker.willMove(toParent: nil)
        atPicker.view.removeFromSuperview()
        atPicker.removeFromParent()
    }

    /// 插入 at 信息
    private func insertAtAttrText(_ attrText: AttrText, in range: NSRange) -> Bool {
        let mutAttrText = MutAttrText(attributedString: inputTextView.attributedText)
        guard range.location >= 0 && NSMaxRange(range) <= mutAttrText.length else {
            return false
        }
        mutAttrText.replaceCharacters(in: range, with: attrText)
        inputTextView.attributedText = mutAttrText
        return true
    }

}
