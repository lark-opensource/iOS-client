//
//  CommentInputViewController.swift
//  Todo
//
//  Created by 张威 on 2021/3/6.
//

import RxSwift
import RxCocoa
import SnapKit
import LarkUIKit
import EditTextView
import LarkContainer
import LarkExtensions
import LarkAccountInterface
import LarkAssetsBrowser
import LarkKeyboardView
import UniverseDesignToast
import UIKit
import UniverseDesignIcon
import TodoInterface
import LarkBaseKeyboard

/// Comment - Input - ViewController
/// 任务评论

class CommentInputViewController: BaseViewController, HasViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    /// Delegates
    /// send 被点击时触发
    var onSend = Delegate<(), Void>()
    /// 需要隐藏时触发
    var onHidden = Delegate<(), Void>()

    /// 可见区域
    let rxVisibleRect = BehaviorRelay(value: CGRect.zero)

    let rxKeyboardVisibleRect = BehaviorRelay(value: CGRect?.none)

    let viewModel: CommentInputViewModel
    private var atPlugin: InputAtPlugin?
    private var atPickerContext = (
        picker: AtPickerViewController?.none,
        attachDisposable: Disposable?.none,
        alongside: AtPickerViewController.BottomInsetAlongside?.none,
        rxVisibleRect: BehaviorRelay<CGRect?>(value: nil)
    )
    private(set) lazy var keyboardView = DetailCommentKeyboardView(frame: .zero, pasteboardToken: "LARK-PSDA-task-detail-comment-input")
    private lazy var keyboardItems = lazyInitKeyboardItems()
    private var keyboardViewCache = [Int: UIView]()
    private var inputTextView: LarkEditTextView { keyboardView.inputTextView }
    private let disposeBag = DisposeBag()
    private lazy var imageGalleryView = CommentInputImageGalleryView()
    private(set) lazy var attachmentView = DetailAttachmentContentView(
        edgeInsets: .init(top: 8, left: 16, bottom: 8, right: 16),
        hideHeader: true,
        hideFooter: true
    )
    private let inputController: InputController
    // chatId 用于 at 人搜索场景
    private let chatId: String?
    @ScopedInjectedLazy private var attachmentService: AttachmentService?
    @ScopedInjectedLazy private var driveDependency: DriveDependency?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    private var currentUserId: String { userResolver.userID }

    private var isAtPickerActive: Bool = false

    // 用于附件，某些正在本地处理中的任务，比如选择一个很大的图片作为附件
    private var processingFileIds = Set<String>()

    /// Initializer
    ///
    /// - Parameters:
    ///   - inputController: 处理 text 输入
    ///   - todoId: todo id（用于埋点）
    ///   - chatId: 会话 id（用于 at 人搜索）
    init(resolver: UserResolver, inputController: InputController, todoId: String, chatId: String?) {
        self.userResolver = resolver
        self.inputController = inputController
        self.viewModel = ViewModel(resolver: userResolver, todoId: todoId)
        self.chatId = chatId
        super.init(nibName: nil, bundle: nil)

        self.viewModel.errorToastCallback = { [weak self] (errMsg) in
            if let view = self?.view, let inset = self?.rxKeyboardVisibleRect.value?.height {
                Utils.Toast.showError(with: errMsg, on: view)
                UDToast.setCustomBottomMargin(inset, view: view)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupInputAction()
        bindTexInput()
        bindImageInput()
        bindKeyboardPanel()
        bindAttachment()
    }

    override func loadView() {
        super.loadView()
        view = PassthroungView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardView.viewControllerDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardView.viewControllerWillDisappear()
    }

    /// 是否有有效内容
    func hasVisibleContent() -> Bool {
        return !inputTextView.attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !viewModel.rxImageStates.value.isEmpty
    }

    private enum HiddenSource {
        case fromTap
        case fromKeyboardWillHideNoti(noti: Notification)
    }

    private var hidenSource: HiddenSource?

    private func setHidden(with source: HiddenSource) {
        guard hidenSource == nil else { return }
        hidenSource = source
        keyboardView.fold()
        onHidden()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            // 会很快时间调用两次，拦截一次
            self?.hidenSource = nil
        }
    }

    func resetContent(_ content: CommentInputContent?, insertWhiteSpace: Bool = false) {
        if let richContent = content?.richContent {
            // 只要进入评论输入框，所有的 at 全部置为蓝色
            let attrText = inputController.makeAttrText(from: richContent, with: keyboardView.baseAttributes, isAtForceActive: true)
            if insertWhiteSpace {
                inputController.insertWhiteSpaceAfterFirstAt(in: attrText)
            }
            inputTextView.attributedText = attrText
        } else {
            inputTextView.attributedText = .init()
        }

        let imagesStates = (content?.attachments ?? []).compactMap { attachment -> ViewModel.ImageState? in
            guard case .image = attachment.type, attachment.hasImageSet else { return nil }
            return .rustMeta(attachment.imageSet, extra: attachment)
        }
        viewModel.resetImageStates(with: imagesStates)
        viewModel.resetFileAttachments(content?.fileAttachments ?? [])
    }

    func inputContent() -> CommentInputContent {
        // 1. reset at info in attrText
        let mutAttrText = MutAttrText(attributedString: inputTextView.attributedText ?? .init())
        inputController.resetAtInfo(in: mutAttrText)
        // 2. make richContent from attrText
        let richContent = inputController.makeRichContent(from: mutAttrText)

        let attachments = viewModel.makeAttachments()
        let fileAttachments = viewModel.makeFileAttachments()
        return (richContent, attachments, fileAttachments)
    }

    func focusInputTextViewIfNeeded() {
        if !inputTextView.isFirstResponder {
            inputTextView.becomeFirstResponder()
        }
    }

    private func setupView() {
        view.backgroundColor = .clear
        view.addSubview(keyboardView)
        inputTextView.backgroundColor = UIColor.ud.bgBody
        keyboardView.inputTextView.returnKeyType = .default
        keyboardView.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        keyboardView.keyboardPanel.delegate = self
        keyboardView.delegate = self
        keyboardView.backgroundColor = UIColor.ud.bgBody

        imageGalleryView.isHidden = true
        keyboardView.containerStackView.insertArrangedSubview(imageGalleryView, at: 1)
        imageGalleryView.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }

        attachmentView.isHidden = true
        keyboardView.containerStackView.insertArrangedSubview(attachmentView, at: 2)
        attachmentView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
        }
        attachmentView.actionDelegate = self

        if let passthroungView = view as? PassthroungView {
            passthroungView.eventFilter = { [weak self] (point, _) in
                guard let self = self else { return false }
                let keboardAttachHeight = self.attachmentView.frame.height
                if self.keyboardView.inputViewIsFirstResponder() == false,
                   self.keyboardView.frame.height <= Detail.commentKeyboardEstimateHeight + keboardAttachHeight {
                    // 这里会调用两次，第二次已经不是第一响应了，但键盘依然弹起，取320是一个经验值
                    let pointInKeyboard = self.view.convert(point, to: self.keyboardView)
                    let flag = self.keyboardView.bounds.contains(pointInKeyboard)
                    return flag
                }
                if UIMenuController.shared.isMenuVisible {
                    // 如果 point 坐落在 menuFrame，不处理
                    let menuFrameInScreen = UIMenuController.shared.menuFrame
                    let pointInScreen = self.view.convert(point, to: nil)
                    if menuFrameInScreen.contains(pointInScreen) {
                        return true
                    }
                }
                if point.y < self.keyboardView.frame.minY {
                    self.setHidden(with: .fromTap)
                }
                return true
            }
        }
    }

    private func bindTexInput() {
        // 绑定 textView 输入：inputTextView.text -> viewModel
        inputTextView.rx.attributedText.distinctUntilChanged()
            .map { $0 ?? AttrText() }
            .bind(to: viewModel.rxInputText)
            .disposed(by: disposeBag)
    }

    private func bindImageInput() {
        imageGalleryView.onItemDelete = { [weak self] index in
            self?.viewModel.deleteImage(at: index)
        }
        imageGalleryView.onItemTap = { _ in
            // 查看大图，暂不支持
        }
        viewModel.rxImageStates.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] imageStates in
            self?.imageGalleryView.isHidden = imageStates.isEmpty
            self?.imageGalleryView.items = imageStates.map(\.imageItem)
        }).disposed(by: disposeBag)
    }

    private func bindKeyboardPanel() {
        Observable<Void>.merge(
            inputTextView.rx.didBeginEditing.asObservable(),
            inputTextView.rx.didEndEditing.asObservable()
        ).observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] _ in
            self?.keyboardView.keyboardPanel.reloadPanel()
        }).disposed(by: disposeBag)

        viewModel.rxSendEnable.distinctUntilChanged().observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] _ in
            self?.keyboardView.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
        }).disposed(by: disposeBag)

        viewModel.rxPictureEnable.distinctUntilChanged().observeOn(MainScheduler.asyncInstance).subscribe(onNext: { [weak self] _ in
            self?.keyboardView.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.picture.rawValue)
        }).disposed(by: disposeBag)
    }

    private class AtPluginWrapper: TextViewInputProtocol {
        let plugin: InputAtPlugin

        init(plugin: InputAtPlugin) {
            self.plugin = plugin
        }

        func register(textView: UITextView) { }

        func textViewDidChange(_ textView: UITextView) { }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            plugin.captureReplacementText(text, in: range)
            return true
        }
    }

    private func bindAttachment() {
        viewModel.reloadAttachmentNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                self?.attachmentView.cellDatas = self?.viewModel.rxAttachmentCellDatas.value
            })
            .disposed(by: disposeBag)
        viewModel.rxAttachmentHeight
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                let edgeInsets = self.attachmentView.edgeInsets
                self.attachmentView.snp.updateConstraints {
                    $0.height.equalTo(height + edgeInsets.top + edgeInsets.bottom)
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxAttachmentIsHidden
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] isHidden in
                self?.attachmentView.isHidden = isHidden
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Attachment Cell Action

extension CommentInputViewController: DetailAttachmentContentCellDelegate {
    func onClick(_ cell: DetailAttachmentContentCell) {
        guard let fileToken = cell.viewData?.fileToken,
              !fileToken.isEmpty else {
            return
        }
        driveDependency?.previewFile(from: self, fileToken: fileToken)
    }

    func onRetryBtnClick(_ cell: DetailAttachmentContentCell) {
        guard case .attachmentService(let info) = cell.viewData?.source,
              let uploadKey = info.uploadInfo.uploadKey else {
            return
        }
        attachmentService?.resumeUpload(scene: viewModel.attachmentScene, key: uploadKey)
    }

    func onDeleteBtnClick(_ cell: DetailAttachmentContentCell) {
        guard let data = cell.viewData else { return }
        viewModel.doDeleteAttachment(with: data)
    }
}

extension CommentInputViewController: OldBaseKeyboardDelegate {
    func clickExpandButton() { }
    func inputTextViewWillSend() {}
    func inputTextViewSend(attributedText: NSAttributedString) {}

    func inputTextViewInputAt(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        atPlugin?.detectAtQuery()
    }

    func inputTextViewBeginEditing() {}

    func keyboardframeChange(frame: CGRect) {
        /// keyboardframeChange 是基于监听 `bounds` 的回调，frame 不会立马生效，因此做 `async` 处理
        DispatchQueue.main.async {
            self.rxKeyboardVisibleRect.accept(self.keyboardView.frame)
        }
    }
    func inputTextViewFrameChange(frame: CGRect) {}
    func inputTextViewDidChange(input: OldBaseKeyboardView) {}
    func inputTextViewCheckLimit() -> Bool {
        let limitInputHandler = self.inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).commentLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        return limitInputHandler.textView(self.inputTextView,
                                          shouldChangeTextIn: NSRange(location: self.inputTextView.attributedText.length, length: 0),
                                          replacementText: "@")
    }
}

extension CommentInputViewController {

    private func lazyInitKeyboardItems() -> [InputKeyboardItem] {
        let atItem = LarkKeyboardBuilder.buildAt(iconColor: UIColor.ud.textCaption) { [weak self] in
            self?.insertAtSymbol()
            DispatchQueue.main.async {
                self?.atPlugin?.reset()
                self?.atPlugin?.detectAtQuery()
            }
            return false
        }

        // 选择图片
        let photoPickerBlock = { [weak self] () -> UIView in
            guard let self = self else { return UIView() }
            let pickView = AssetPickerSuiteView(
                assetType: .imageOnly(maxCount: self.viewModel.seletableImageCount()),
                cameraType: .custom(true),
                sendButtonTitle: I18N.Todo_Task_Confirm
            )
            pickView.updateBottomOffset(0)
            pickView.delegate = self
            return pickView
        }
        let photoPickerInfo = PhotoPickView.keyboard(iconColor: UIColor.ud.textCaption)
        ///  PhotoPickView的height是动态变化的 (没有权限的时候) 所以改为Block传入
        let piturecItem = InputKeyboardItem(
            key: KeyboardItemKey.picture.rawValue,
            keyboardViewBlock: photoPickerBlock,
            keyboardHeightBlock: { PhotoPickView.keyboard(iconColor: UIColor.ud.textCaption).height },
            keyboardIcon: photoPickerInfo.icons,
            selectedAction: { true }
        )

        let sendItem = LarkKeyboardBuilder.buildSend { true }

        return [atItem, piturecItem, initAttachmentItem(), sendItem]
    }

    private func initAttachmentItem() -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: UDIcon.attachmentOutlined,
            selectedIcon: UDIcon.attachmentOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault),
            tintColor: UIColor.ud.textCaption
        )
        let selectedAction = { [weak self] () -> Bool in
            guard let self = self,
                  let sourceView = self.keyboardView.keyboardPanel.getButton(KeyboardItemKey.file.rawValue) else {
                return false
            }
            let remainingCount = self.viewModel.getRemainingCount() - self.processingFileIds.count
            DetailAttachment.logger.info("comment select. rc: \(remainingCount), sc: \(self.processingFileIds.count)")
            if remainingCount <= 0 {
                if let window = self.view.window {
                    Utils.Toast.showWarning(
                        with: I18N.Todo_Task_FileExceeds100NumberToast(DetailAttachment.CommentLimit),
                        on: window
                    )
                }
            } else {
                let callbacks = SelectLocalFilesCallbacks(
                    selectCallback: { [weak self] ids in
                        guard let self = self else { return }
                        DetailAttachment.logger.info("comment select. select ids: \(ids)")
                        self.processingFileIds = self.processingFileIds.union(ids)
                    },
                    finishCallback: { [weak self] tuples in
                        guard let self = self else { return }
                        let ids = tuples.map { $0.0 }
                        DetailAttachment.logger.info("comment select. finish ids: \(ids)")
                        self.processingFileIds = self.processingFileIds.subtracting(ids)
                        self.viewModel.doSelectedFiles(tuples.compactMap { $0.1 })
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, !Display.pad else { return }
                            self.inputTextView.becomeFirstResponder()
                        }
                    },
                    cancelCallback: { [weak self] in
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, !Display.pad else { return }
                            self.inputTextView.becomeFirstResponder()
                        }
                    }
                )
                self.attachmentService?.selectLocalFiles(
                    vc: self,
                    sourceView: sourceView,
                    sourceRect: CGRect(x: sourceView.frame.width / 2, y: 0, width: 0, height: 0),
                    enableCount: remainingCount,
                    callbacks: callbacks
                )
            }
            return false
        }
        return InputKeyboardItem(
            key: KeyboardItemKey.file.rawValue,
            keyboardViewBlock: { UIView() },
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            selectedAction: selectedAction
        )
    }
}

// MARK: - AssetPicker

extension CommentInputViewController: AssetPickerSuiteViewDelegate {

    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        viewModel.appendSelectedPhotos(result.selectedAssets, isOriginal: result.isOriginal)
        suiteView.reset()
        inputTextView.becomeFirstResponder()
    }

    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        viewModel.appendTakenPhoto(photo)
        suiteView.reset()
        inputTextView.becomeFirstResponder()
    }

    // 目前业务不支持发送视频
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        suiteView.reset()
        inputTextView.becomeFirstResponder()
    }

}

// MARK: - KeyboardPanel

extension CommentInputViewController: KeyboardPanelDelegate {

    func numberOfKeyboard() -> Int {
        return keyboardItems.count
    }

    func keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) {
        return keyboardItems[index].keyboardIcon
    }

    func keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType {
        return .none
    }

    func keyboardItemKey(index: Int) -> String {
        return keyboardItems[index].key
    }

    func keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void {
        return keyboardItems[index].onTapped
    }

    func keyboardSelectEnable(index: Int, key: String) -> Bool {
        switch key {
        case KeyboardItemKey.send.rawValue:
            return viewModel.rxSendEnable.value
        case KeyboardItemKey.picture.rawValue:
            return viewModel.rxPictureEnable.value
        default:
            return true
        }
    }

    func willSelected(index: Int, key: String) -> Bool {
        return keyboardItems[index].selectedAction?() ?? true
    }

    func didSelected(index: Int, key: String) {
        inputTextView.resignFirstResponder()
        if key == KeyboardItemKey.send.rawValue {
            DispatchQueue.main.async {
                self.onSend()
            }
        }
    }

    func keyboardView(index: Int, key: String) -> (UIView, Float) {
        let item = keyboardItems[index]
        if let view = keyboardViewCache[index] {
            return (view, item.keyboardHeightBlock())
        }
        let keyboardView = item.keyboardViewBlock()
        // 将 keyboardView 给持有起来，避免收起时被释放，导致回调异常（主要选择图片场景）
        keyboardViewCache[index] = keyboardView
        return (keyboardView, item.keyboardHeightBlock())
    }

    func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return keyboardItems[index].coverSafeArea
    }

    func keyboardContentHeightWillChange(_ height: Float) { }
    func keyboardContentHeightDidChange(_ height: Float) { }
    func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView) {}
    func systemKeyboardPopup() {}

}

// MARK: - AtPicker

extension CommentInputViewController {

    private func setupInputAction() {
        atPlugin = .init(textView: inputTextView)
        atPlugin?.onQueryChanged = { [weak self] atInfo in
            guard let self = self, !self.isAtPickerActive else { return }
            self.isAtPickerActive = true
            self.showAtPicker(atInfo.range)
        }
        atPlugin?.onQueryInvalid = { [weak self] in
            self?.isAtPickerActive = false
        }

        let limitInputHandler = inputController.makeLimitInputHandler(SettingConfig(resolver: userResolver).commentLimit) { [weak self] in
            guard let self = self, let window = self.view.window else {
                return nil
            }
            return window
        }
        let spanInputHandler = inputController.makeSpanInputHandler()
        let anchorInputHandler = inputController.makeAnchorInputHandler()
        let returnInputHandler = inputController.makeReturnInputHandler { () -> Bool in
            // 返回 true，允许用户输入 enter 换行
            return true
        }
        let atPluginWrapper = AtPluginWrapper(plugin: atPlugin!)
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: true)
        let protocols: [TextViewInputProtocol] = [limitInputHandler, spanInputHandler, anchorInputHandler,
                                                  returnInputHandler, atPluginWrapper, emojiInputHandler]
        keyboardView.textViewInputProtocolSet = TextViewInputProtocolSet(protocols)

        inputTextView.rx.didEndEditing.subscribe(onNext: { [weak self] in
            self?.atPlugin?.reset()
        }).disposed(by: disposeBag)

        inputTextView.rx.didBeginEditing.take(1)
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                // 监听键盘的 willHide
                NotificationCenter.default.rx
                    .notification(UIResponder.keyboardWillHideNotification)
                    .delay(.milliseconds(10), scheduler: MainScheduler.instance)
                    .filter { [weak self] _ in
                        guard
                            let self = self,
                            self.parent != nil,
                            self.parent?.presentedViewController == nil
                        else {
                            return false
                        }
                        return self.keyboardView.keyboardPanel.selectIndex == nil
                    }
                    .take(1)
                    .asSingle()
                    .subscribe(onSuccess: { [weak self] noti in
                        self?.setHidden(with: .fromKeyboardWillHideNoti(noti: noti))
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    private func showAtPicker(_ atRange: NSRange) {
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showAtPicker(
            title: I18N.Todo_Task_ProbabilityAtPersonHint,
            chatId: "",
            onSelect: { [weak self] (controller, seletedId) in
                controller?.dismiss(animated: true)
                guard let self = self else { return }
                self.atPlugin?.reset()

                self.viewModel.fetchTodoUser(with: seletedId) { [weak self] user in
                    guard let self = self else { return }
                    let mutAttrText = MutAttrText(attributedString: self.inputTextView.attributedText)
                    let attrs = self.keyboardView.baseAttributes
                    guard let cursorLocation = self.inputController.insertAtAttrText(
                        in: mutAttrText, for: user, with: attrs, in: atRange
                    ) else {
                        Detail.logger.info("insert at attrText failed")
                        return
                    }
                    self.inputTextView.attributedText = mutAttrText
                    self.inputTextView.selectedRange = NSRange(location: cursorLocation, length: 0)
                    self.inputTextView.autoScrollToSelectionIfNeeded()
                }
            },
            onCancel: { },
            params: routeParams
        )
    }

    /// 插入
    private func insertAtSymbol() {
        guard inputTextViewCheckLimit() else { return }
        inputTextView.insertText("@")
        if !inputTextView.isFirstResponder {
            inputTextView.becomeFirstResponder()
        }
    }

}
