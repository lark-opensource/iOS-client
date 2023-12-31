//
//  MomentSendPostViewController.swift
//  Moment
//
//  Created by bytedance on 2021/1/4.
//
import Foundation
import UIKit
import Photos
import RxCocoa
import RxSwift
import SnapKit
import LarkUIKit
import LarkGuide
import LarkGuideUI
import EditTextView
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import EENavigator
import UniverseDesignToast
import LarkAlertController
import LarkMessengerInterface
import LarkMessageCore
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkContainer
import RustPB
import ByteWebImage
import TangramService
import LarkFeatureGating
import LarkSendMessage
import LarkBaseKeyboard
import LarkSetting

final class MomentSendPostViewController: BaseUIViewController,
                                          PostNavigationBarDelegate,
                                          UITextViewDelegate,
                                          UITextPasteDelegate,
                                          UIGestureRecognizerDelegate,
                                          PadLargeModalDelegate,
                                          UserResolverWrapper {
    let userResolver: UserResolver
    static let fgKeyBindCategory = "moments.publish.bind_category"

    static let logger = Logger.log(MomentSendPostViewController.self, category: "Module.Moments.MomentSendPostViewController")
    let tracker: MomentsCommonTracker = MomentsCommonTracker()

    // UI相关
    private weak var popoverVC: UIViewController?
    private let scrollView: UIScrollView = UIScrollView()
    private let centerContainer: UIView = UIView()
    private var hashTagListView: MomentsHashTagListView?

    /// 发帖身份展示视图
    private var identitySwitcher: IdentitySwitchBusinessView?
    /// 发帖身份选择视图
    private var anonymousPickerView: AnonymousBusinessPickerView? {
        didSet {
            if viewModel.shouldShowNickNameGuide {
                anonymousPickerView?.autoDismiss = false
            } else {
                anonymousPickerView?.autoDismiss = !Display.pad
            }
        }
    }
    /// 当前是否处于选择身份态，用来判断只弹出一次身份选择视图
    private var inAnonymousPickStatus: Bool {
        return anonymousPickerView != nil
    }
    private var categoryListRefreshNotice: Driver<[RawData.PostCategory]> { return _categoryListRefreshNotice.asDriver(onErrorJustReturn: ([])) }
    private var _categoryListRefreshNotice = PublishSubject<[RawData.PostCategory]>()
    @ScopedInjectedLazy var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    @ScopedInjectedLazy var imageAPI: ImageAPI?

    let photoContainerView: UIView = UIView()

    // 发资源类消息管理类
    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: userResolver, isCrypto: false)
    }()

    private lazy var featureGatingBindCategory: Bool = {
        (try? self.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: .init(stringLiteral: Self.fgKeyBindCategory)) ?? false
    }()

    //当FG "moments.publish.bind_category" 为false时使用
    private lazy var categoriesView: PostCategoriesDisplayView = {
        let view = PostCategoriesDisplayView(items: []) { [weak self] in
            guard let self = self else { return }
            self.showPostCategoriesListViewContrller(sourceView: self.categoriesView.allView)
        } selectItemCallBack: { [weak self] in
            self?.updateIdentitySwitcherOnSeletedCategoryChange()
        }
        return view
    }()

    //当FG "moments.publish.bind_category" 为true时使用
    private lazy var newCategoriesView: PostCategoriesView = {
        let view = PostCategoriesView(frame: .zero)
        view.onTapped = { [weak self] in
            guard let self = self else { return }
            self.showPostCategoriesListViewContrller(sourceView: self.newCategoriesView)
        }
        return view
    }()

    lazy var hashTagRecognizer: MomentsHashTagRecognizer = {
        return MomentsHashTagRecognizer(ignoreAttributedKeys: [AtTransformer.UserIdAttributedKey, LinkTransformer.TagAttributedKey, LinkTransformer.LinkAttributedKey]) {  [weak self] (input) in
            if let input = input {
                self?.showHashTagListViewWithInput(input)
            } else {
                self?.removeHashTagListView()
            }
        }
    }()

    lazy var contentTextView: LarkEditTextView = {
        let textView = LarkEditTextView()
        textView.backgroundColor = UIColor.ud.bgBody
        textView.maxHeight = 0
        textView.forceScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholder = BundleI18n.Moment.Lark_Community_SaySomething
        textView.placeholderTextColor = UIColor.ud.N500
        let edgeInset: CGFloat = featureGatingBindCategory ? 16 : 15
        textView.textContainerInset = UIEdgeInsets(top: edgeInset, left: edgeInset, bottom: edgeInset, right: edgeInset)
        textView.textColor = UIColor.ud.textTitle
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.linkTextAttributes = [:]
        textView.delegate = self
        textView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-moments-send-post-copy-permission")
        textView.pasteDelegate = self
        return textView
    }()

    lazy var contentTextViewWarpper: UIView = {
        let warpper = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(wrapperViewClick))
        warpper.addGestureRecognizer(tap)
        return warpper
    }()

    private var viewDidAppeaded: Bool = false
    private var finishedApplyDraft: Bool = false
    lazy var keyboardPanel: KeyboardPanel = {
        let panel = KeyboardPanel()
        panel.backgroundColor = UIColor.ud.bgBody
        panel.delegate = self
        return panel
    }()

    let photoGalleryMaxWith: CGFloat = 3 * 90 + 2 * 6
    lazy var photoGalleryManager: PhotoGalleryManager = {
        let config = PhotoGalleryConfig(columnCount: 3, rowSpace: 6, columnSpace: 6, itemCornerRadius: 4, maxWidth: photoGalleryMaxWith, superView: self.photoContainerView)
        let manager = PhotoGalleryManager(config: config)
        manager.delegate = self
        return manager
    }()

    // 键盘相关
    var keyboardViewCache: [Int: UIView] = [:]
    var textViewInputProtocolSet = TextViewInputProtocolSet()

    var keyboardItems: [InputKeyboardItem] = [] {
        didSet {
            self.keyboardViewCache.removeAll()
            self.keyboardPanel.reloadPanel()
        }
    }

    private var showPlaceholder = true

    // 从 willBegin 开始到 didEndEditing
    var contentIsEditing: Bool = false

    private var hasGuideView: Bool = false
    private var refrshUIOnUploadSuccess: (() -> Void)?
    var viewWillClosed: (() -> Void)?
    var hudView: UDToast?

    // VM
    let viewModel: MomentSendPostViewModel
    let sendPostCallBack: ((String?, Bool, RustPB.Basic_V1_RichText?, [PostImageMediaInfo]?) -> Void)
    let imageChecker = MomentsImageChecker()
    let disposeBag = DisposeBag()
    @ScopedInjectedLazy var reactionAPI: ReactionAPI?
    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy var docAPI: DocAPI?

    init(userResolver: UserResolver,
         viewModel: MomentSendPostViewModel,
         sendPostCallBack: @escaping ((String?, Bool, RustPB.Basic_V1_RichText?, [PostImageMediaInfo]?) -> Void)) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.sendPostCallBack = sendPostCallBack
        super.init(nibName: nil, bundle: nil)
        let item = MomentsSendPostPageItem(biz: .Moments,
                                       scene: .MoPost,
                                       event: .momentsShowPublishPage,
                                       page: "publish")
        self.tracker.startTrackWithItem(item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 上传完成置空
    deinit {
        self.viewModel.attachmentUploader.defaultCallback = nil
        self.viewModel.attachmentUploader.allFinishedCallback = nil
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubview()
        self.initInputHandler()
        self.viewModel.attachmentUploader.defaultCallback = { [weak self] (_, attachmentKey, token, data, error) in
            guard let `self` = self else { return }
            if let imageData = data,
                let token = token,
                let image = try? ByteImage(imageData) {
                let originKey = self.viewModel.resourceAPI?.computeResourceKey(key: token, isOrigin: true) ?? ""
                self.viewModel.uploadingItems.forEach { (item) in
                    if item.attachmentKey == attachmentKey {
                        item.localImageKey = originKey
                        item.token = token
                    }
                }
                self.storeImageToCacheFromDraft(image: image, imageData: imageData, originKey: originKey)
            }

            if let apiError = error?.underlyingError as? APIError {
                switch apiError.type {
                case .cloudDiskFull:
                    let alertController = LarkAlertController()
                    alertController.showCloudDiskFullAlert(from: self, nav: self.navigator)
                case .securityControlDeny(let message):
                    self.viewModel.chatSecurityControlService?.authorityErrorHandler(event: .sendImage,
                                                                                    authResult: nil,
                                                                          from: self,
                                                                          errorMessage: message)
                default: break
                }
            }
        }

        self.viewModel.attachmentUploader.allFinishedCallback = { [weak self] (_) in
            guard let self = self, !self.viewModel.uploadingItems.isEmpty else {
                return
            }
            let allUploadFailedIds = self.viewModel.attachmentUploader.failedTasks.map({ (task) -> String in
                return task.key
            })
            let attachmentIds = self.viewModel.getAllEffectiveAttachmentIds()
            let uploadFailedIdsInPost = allUploadFailedIds.filter({ attachmentIds.contains($0) })
            // 存在图片上传失败的情况
            if uploadFailedIdsInPost.isEmpty {
                self.refrshUIOnUploadSuccess?()
            } else {
                self.removeUploadHUD()
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUploadPicture, on: self.view)
            }
            self.viewModel.uploadingItems = []
            self.refrshUIOnUploadSuccess = nil
            self.adjustScrollviewToBottom()
        }

        self.viewModel.getCategoriesListCallBack = (succeed: { [weak self] data in
            self?.setupCategoriesList(data)
        }, fail: { [weak self] in
            if self?.featureGatingBindCategory == false {
                self?.updateCategoriesViewLayoutIfNeed()
            }
            self?.getUserCircleConfigForAnonymous()
        })

        self.contentTextView.rx.value.asDriver().drive(onNext: { [weak self] (value) in
            self?.textChanged(isEmpty: value?.isEmpty ?? true)
        }).disposed(by: self.disposeBag)
        self.viewModel.onAnonymousStatusChangeBlock = { [weak self] _ in
            self?.updatePlaceholderText()
        }
        if let source = self.viewModel.source {
            Tracer.trackCommunitySendPostPageView(source: source)
        }
        self.addObserverForNickNameUpdate()
        let item = self.tracker.getItemWithEvent(.momentsShowPublishPage) as? MomentsSendPostPageItem
        self.applyDraftWithFinish { [weak self] in
            item?.startGetCategory()
            self?.viewModel.getCategoriesListLocalFirst()
            self?.finishedApplyDraft = true
        }
        NotificationCenter.default.rx.notification(UIApplication.willTerminateNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.saveDraft()
        }).disposed(by: disposeBag)
    }

    private func storeImageToCacheFromDraft(image: UIImage, imageData: Data, originKey: String) {
        // store image to cache from draft cache
        if !LarkImageService.shared.isCached(resource: .default(key: originKey)) {
            LarkImageService.shared.cacheImage(image: image,
                                               data: imageData,
                                               resource: .default(key: originKey))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 防止键盘多次弹出
        if !viewDidAppeaded {
            viewDidAppeaded = true
            self.contentTextView.becomeFirstResponder()
        }
        /// 在当前页面出现的时候 刷新一下HUD，防止选择图片页面展示时候 loading无法展示的问题
        if self.hudView != nil {
            self.removeUploadHUD()
            self.showLoadingHudForUpload()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.contentTextView.resignFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// C视图下
        if self.popoverVC != nil, traitCollection.horizontalSizeClass == .compact {
            self.view.endEditing(true)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if hasGuideView {
            self.viewModel.guideManager?.closeCurrentGuideUIIfNeeded()
        }
    }

    fileprivate func initInputHandler() {
        let atUserInputHandler = AtUserInputHandler()
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: false)
        let urlInputHandler: TextViewInputProtocol
        if TextViewCustomPasteConfig.useNewPasteFG {
            urlInputHandler = MomentsURLInputHander(urlPreviewAPI: urlPreviewAPI, psdaToken: "LARK-PSDA-moments-send-post-copy-permission")
        } else {
            urlInputHandler = URLInputHandler(urlPreviewAPI: urlPreviewAPI)
        }
        let returnInputHandler = ReturnInputHandler { [weak self] (textView) -> Bool in
            guard let `self` = self else { return true }
            if textView == self.contentTextView { return true }
            self.contentTextView.becomeFirstResponder()
            return false
        }

        let atPickerInputHandler = AtPickerInputHandler { [weak self] (textView, range, _) in
            guard let `self` = self else { return }
            textView.resignFirstResponder()
            self.chatInputViewInputAt(cancel: {
                textView.becomeFirstResponder()
            }, complete: { (selectItems) in
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()
                // 插入at标签
                selectItems.forEach { (item) in
                    self.insert(userName: item.name,
                                actualName: item.actualName,
                                userId: item.id,
                                isOuter: item.isOuter)
                }
            })
        }
        let hashTagHandler = HashTagInputHandler(showHashTagListCallBack: nil) { [weak self] in
            guard let self = self else { return }
            self.hashTagRecognizer.onTextDidChangeFor(textView: self.contentTextView)
        }
        let textViewInputProtocolSet = TextViewInputProtocolSet([returnInputHandler, atPickerInputHandler, atUserInputHandler, emojiInputHandler, urlInputHandler, hashTagHandler])
        self.textViewInputProtocolSet = textViewInputProtocolSet
        self.textViewInputProtocolSet.register(textView: self.contentTextView)
    }

    func setupSubview() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.isNavigationBarHidden = true
        let navBar = MomentsPostNavigationBar(backImage: Resources.momentsNavBarClose.ud.withTintColor(UIColor.ud.iconN1), delegate: self)
        self.view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(MomentsPostNavigationBar.navigationBarHeight)
        }

        self.view.addSubview(keyboardPanel)
        keyboardPanel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        keyboardPanel.layout = .custom(MomentPostKeyboardFactory.postKeyboardLayout())
        self.keyboardItems = MomentPostKeyboardFactory.postKeyboardItems(context: self)
        if featureGatingBindCategory {
            self.view.addSubview(self.newCategoriesView)
            self.newCategoriesView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.height.equalTo(36)
                make.top.equalTo(navBar.snp.bottom).offset(16)
            }
            self.view.addSubview(scrollView)
            self.view.addSubview(centerContainer)
            scrollView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.width.equalToSuperview()
                make.top.equalTo(newCategoriesView.snp.bottom)
                make.bottom.equalTo(centerContainer.snp.top)
            }
        } else {
            self.view.addSubview(self.categoriesView)
            self.categoriesView.isHidden = true
            self.categoriesView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(0)
                make.top.equalTo(navBar.snp.bottom)
            }
            self.view.addSubview(scrollView)
            self.view.addSubview(centerContainer)
            scrollView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.width.equalToSuperview()
                make.top.equalTo(categoriesView.snp.bottom)
                make.bottom.equalTo(centerContainer.snp.top)
            }
        }
        centerContainer.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(keyboardPanel.snp.top)
        }
        scrollView.addSubview(contentTextViewWarpper)
        contentTextViewWarpper.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(124)
            make.bottom.lessThanOrEqualTo(contentTextViewWarpper)
        }

        contentTextViewWarpper.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(124)
        }
        scrollView.addSubview(photoContainerView)
        photoContainerView.backgroundColor = UIColor.ud.bgBody
        photoContainerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(photoGalleryMaxWith)
            make.top.equalTo(contentTextViewWarpper.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }

    func MomentsNavigationViewOnRightButtonTapped(_ view: MomentsPostNavigationBar) {
        //do nothing
    }
    func MomentsNavigationViewOnClose(_ view: MomentsPostNavigationBar) {
        self.saveDraft()
        self.viewWillClosed?()
        self.dismiss(animated: true, completion: nil)
    }
    //点击了背景，将要dismiss
    func padLargeModalViewControllerBackgroundClicked() {
        self.saveDraft()
        self.viewWillClosed?()
    }
    func titleViewForNavigation() -> UIView? {
        let label = UILabel()
        label.text = BundleI18n.Moment.Lark_Community_PostNewNews
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }

    func textChanged(isEmpty: Bool) {
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
        if showPlaceholder != isEmpty {
            showPlaceholder = isEmpty
            self.contentTextView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(showPlaceholder ? 124 : 20)
            }
        }
    }

    // 发送帖子
    func sendPost() {
        if featureGatingBindCategory,
           self.newCategoriesView.getCategoryId() == nil {
            showPostCategoriesListViewContrller(sourceView: self.newCategoriesView)
            return
        }
        if !self.sendPostEnable() {
            return
        }
        MomentsTracer.trackMomentsEditPageClickWith(circleId: viewModel.circleId)
        let limit = 20_000
        if self.checkInputTextIsOutOf(limit: limit) {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_TheNumberOfWordsExceedsTheLimit("\(limit)"), on: self.view)
            return
        }
        if viewModel.isAnonymous, contentTextView.attributedText.hasAtUser {
            showUnSupportAtTipForAnonymous()
            return
        }
        var richText: RustPB.Basic_V1_RichText?
        var imageList: [PostImageMediaInfo]?
        if !self.contentTextIsEmpty() {
            richText = richTextFromContent(needPreproccess: true)
        }
        if !self.viewModel.selectedImagesModel.selectedItems.isEmpty {
            imageList = self.viewModel.getAllPostImageMediaInfoItems()
        }
        self.sendPostCallBack(getSelectedCategoryId(), viewModel.isAnonymous, richText, imageList)
        self.viewModel.clearDraft()
        Tracer.trackCommunitySendPost()
    }

    func showPostCategoriesListViewContrller(sourceView: UIView) {
        self.contentTextView.resignFirstResponder()
        let categoryItems = self.viewModel.categoryItems.map({ item in
            PostCategoryDataItem(item, userSelected: item.category.categoryID == getSelectedCategoryId())
        })
        let vc = PostCategoriesListViewContrller(categoryItems: categoryItems,
                                                 categoryListRefreshNotice: self.categoryListRefreshNotice) {(item) in
            if let item = item {
                self.updateCategoriesForItem(item)
            }
            self.updateIdentitySwitcherOnSeletedCategoryChange()
        }
        if Display.pad {
            vc.popoverPresentationController?.backgroundColor = .ud.bgBody
            MomentsIpadPopoverAdapter.popoverVC(vc,
                                                fromVC: self,
                                                sourceView: sourceView,
                                                preferredContentSize: CGSize(width: 375, height: 600),
                                                permittedArrowDirections: .up)
        } else {
            userResolver.navigator.present(vc, from: self)
        }
    }

    func richTextFromContent(needPreproccess: Bool) -> RustPB.Basic_V1_RichText? {
        var contentAttributedText = self.contentTextView.attributedText ?? NSAttributedString(string: "")
        if needPreproccess {
            contentAttributedText = RichTextTransformKit.preproccessSendAttributedStr(contentAttributedText)
        }
        return RichTextTransformKit.transformStringToRichText(string: contentAttributedText)
    }
    /// 是否可以发送帖子
    func sendPostEnable() -> Bool {
        return !self.contentTextIsEmpty() || !self.viewModel.selectedImagesModel.selectedItems.isEmpty
    }

    func contentTextIsEmpty() -> Bool {
        let content = self.contentTextView.text?.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail) ?? ""
        return content.isEmpty
    }

    func chatInputViewInputAt(cancel: (() -> Void)?, complete: AtPickerBody.AtPickerSureCallBack?) {
        if viewModel.isAnonymous {
            showUnSupportAtTipForAnonymous()
            return
        }
        let vc = AtListViewController(userResolver: self.userResolver)
        vc.selectedCallback = { [weak self, weak vc] id in
            self?.transformIdsToSelectedItem(ids: [id]) { (items) in
                complete?(items)
            }
            vc?.dismiss(animated: true, completion: nil)
        }
        let nav = LkNavigationController(rootViewController: vc)
        userResolver.navigator.present(nav, from: self, prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() })
    }

    private func transformIdsToSelectedItem(ids: [String], finish: (([AtPickerBody.SelectedItem]) -> Void)?) {
        self.viewModel.chatterAPI?.getChatters(ids: ids)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMap) in
                let items = ids.compactMap { chatterMap[$0] }.map { (chatter) -> AtPickerBody.SelectedItem in
                    let fgValue = (try? self.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "lark.chatter.name_with_another_name_p2") ?? false

                    let name = fgValue ? chatter.displayWithAnotherName : chatter.localizedName
                    return AtPickerBody.SelectedItem(id: chatter.id,
                                                     name: name,
                                                     actualName: "",
                                                     isOuter: false)
                }
                finish?(items)
            }, onError: { (error) in
                Self.logger.error("getChatters error \(error)")
            }).disposed(by: self.disposeBag)
    }

    func showLoadingHudForUpload() {
        hudView = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_Uploading, on: self.view.window ?? self.view, disableUserInteraction: true)
    }

    func removeUploadHUD() {
        self.hudView?.remove()
        self.hudView = nil
    }

    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !self.keyboardPanel.observeKeyboard {
            self.keyboardPanel.resetContentHeight()
        }
        self.keyboardPanel.observeKeyboard = true
        if textView == self.contentTextView {
            self.contentIsEditing = true
        }
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.at.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.emotion.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.picture.rawValue)
    }

    func textViewDidChange(_ textView: UITextView) {
        self.textViewInputProtocolSet.textViewDidChange(textView)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        hashTagRecognizer.onChangeSelectionForTextView(contentTextView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {

        if textView == self.contentTextView {
            self.contentIsEditing = false
        }

        if !self.contentIsEditing {
            self.keyboardPanel.observeKeyboard = false
            if self.keyboardPanel.selectIndex == nil {
                self.keyboardPanel.closeKeyboardPanel(animation: true)
            }
        }
    }

    // MARK: - UITextPasteDelegate
     func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
        guard let string = itemStrings.first else {
            return NSAttributedString()
        }
        let mutableString = NSMutableAttributedString(attributedString: string)
        let attributes = self.contentTextView.defaultTypingAttributes
        let range = NSRange(location: 0, length: string.length)
        mutableString.fixAttributes(in: range)
        mutableString.addAttributes(attributes, range: range)
        return mutableString
    }

    func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        shouldAnimatePasteOf attributedString: NSAttributedString,
        to textRange: UITextRange) -> Bool {
        return false
    }

    func checkInputTextIsOutOf(limit: Int) -> Bool {
        if contentTextView.text.count > limit {
            return true
        }
        return false
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - 草稿相关
    /// 保存草稿
    func saveDraft() {
        var richText: RustPB.Basic_V1_RichText?
        if !contentTextIsEmpty() {
            richText = richTextFromContent(needPreproccess: false)
        }
        self.viewModel.saveDraftWithRichText(richText, categoryID: getSelectedCategoryId())
    }

    /// 应用草稿
    func applyDraftWithFinish(_ finish: (() -> Void)?) {
        let item = self.tracker.getItemWithEvent(.momentsShowPublishPage) as? MomentsSendPostPageItem
        item?.startGetDraft()
        self.viewModel.getDraftWithAttributes(contentTextView.defaultTypingAttributes) { [weak self] (data) in
            item?.endGetDraft()
            /// 没有草稿的时候
            guard let data = data else {
                if let content = self?.viewModel.selectedHashTagContent {
                    let attr = NSAttributedString(string: "\(content) ",
                                       attributes: self?.contentTextView.defaultTypingAttributes)
                    self?.contentTextView.attributedText = attr
                    self?.hashTagRecognizer.onTextDidChangeFor(textView: self?.contentTextView)
                }
                finish?()
                return
            }
            item?.startRenderDraft()
            var isEffectiveDraft = false
            if let attr = data.attr {
                self?.contentTextView.attributedText = attr
                isEffectiveDraft = true
                self?.hashTagRecognizer.onTextDidChangeFor(textView: self?.contentTextView)
            }

            if let hashTagContent = self?.viewModel.selectedHashTagContent, !(self?.hashTagRecognizer.hasHashTag(hashTagContent, textView: self?.contentTextView) ?? false),
               let attr = self?.contentTextView.attributedText {
                /// 这里需要添加一个空格 保证用户继续编辑hashag
                let muAttr = NSMutableAttributedString(string: "\(hashTagContent) ", attributes: self?.contentTextView.defaultTypingAttributes)
                muAttr.append(attr)
                self?.contentTextView.attributedText = muAttr
                self?.hashTagRecognizer.onTextDidChangeFor(textView: self?.contentTextView)
            }

            if !data.items.isEmpty {
                self?.photoGalleryManager.addItems(data.items)
                isEffectiveDraft = true
            }
            if isEffectiveDraft {
                self?.viewModel.isAnonymous = data.anonymous
            }
            /// 草稿不为空
            if !data.categoryID.isEmpty, isEffectiveDraft {
                self?.viewModel.selectedCategoryID = data.categoryID
            }
            item?.endRenderDraft()
            finish?()
        }
    }
    // MARK: - 版块列表
    private func setupCategoriesList(_ data: [RawData.PostCategory]) {
        let item = self.tracker.getItemWithEvent(.momentsShowPublishPage) as? MomentsSendPostPageItem
        item?.endGetCategory()
        if data.isEmpty {
            return
        }
        /// 筛出去名字为空的
        let effectiveData = data.filter { (category) -> Bool in
            return !category.category.name.isEmpty && category.category.canCreatePost
        }
        self.viewModel.categoryItems = effectiveData
        if self.featureGatingBindCategory {
            if let category = self.viewModel.categoryItems.first(where: { $0.category.categoryID == self.viewModel.selectedCategoryID }) {
                self.newCategoriesView.update(title: category.category.name,
                                               iconKey: category.category.iconKey,
                                               id: category.category.categoryID)
            }
        } else {
            self.categoriesView.items = self.viewModel.getDisplayItemsWithData(effectiveData) ?? []
            self.updateCategoriesViewLayoutIfNeed()
        }
        self.getUserCircleConfigForAnonymous()
    }
    //这个方法只在FG "moments.publish.bind_category" 为false时会用到
    func updateCategoriesViewLayoutIfNeed() {
        let showCategoriesView = !self.categoriesView.items.isEmpty
        self.categoriesView.snp.updateConstraints { (make) in
            make.height.equalTo(showCategoriesView ? 48 : 0)
        }
        self.categoriesView.isHidden = self.categoriesView.items.isEmpty
    }

    func updateCategoriesForItem(_ item: RawData.PostCategory) {
        if featureGatingBindCategory {
            newCategoriesView.update(title: item.category.name, iconKey: item.category.iconKey, id: item.category.categoryID)
        } else {
            viewModel.selectCategoryAndMoveToFirst(item)
            let newItem = PostCategoryItem(id: item.category.categoryID, title: item.category.name, selected: true, iconKey: item.category.iconKey)
            self.categoriesView.insertItem(newItem)
        }
    }

    // MARK: - 当选中的板块变化的时候，调用 决定隐藏或者展示身份切换器
    private func getUserCircleConfigForAnonymous() {
        let item = self.tracker.getItemWithEvent(.momentsShowPublishPage) as? MomentsSendPostPageItem
        item?.startGetPolicy()
        viewModel.circleConfigService?.getUserCircleConfigWithFinsih({ [weak self] (config) in
            item?.endGetPolicy()
            guard let self = self, let anonymousConfigService = self.viewModel.anonymousConfigService else { return }
            self.viewModel.circleId = config.circleID
            anonymousConfigService.userCircleConfig = config
            MomentsTracer.trackMomentsEditPageViewWith(circleId: config.circleID)

            if let momentsAccountService = self.momentsAccountService, (momentsAccountService.getCurrentUserIsOfficialUser() ?? false) {
                //官方号身份要展示身份信息，且不允许切换匿名
                self.configOfficialUserInfoView()
                return
            }
            /// 可以匿名的话 查询匿名次数
            if self.viewModel.anonymityEnabled {
                self.configIdentitySwitcherWithType(config.anonymityPolicy.type)
                /// 如果草稿是匿名，但是还没有选择花名 无法直接使用 切为实名
                if self.viewModel.isAnonymous, (self.viewModel.anonymousConfigService?.needConfigNickName() ?? false) {
                    self.viewModel.isAnonymous = false
                }
                self.updateIdentitySwitcherOnSeletedCategoryChange(careDraft: true)
                item?.startGetQuota()
                self.viewModel.queryAnonymousQuotaFinish { [weak self] (hasQuota) in
                    item?.endGetQuota()
                    /// 如果当前没有匿名的额度了切换为实名,发送为实名
                    if !hasQuota {
                        if self?.viewModel.isAnonymous ?? false {
                            self?.showToastForAnonymousCannotApplyForDraft()
                        }
                        self?.viewModel.isAnonymous = false
                        self?.identitySwitcher?.switchToReal()
                    }
                    self?.tracker.endTrackWithItem(item)
                }
            } else {
                if self.viewModel.isAnonymous {
                    self.showToastForAnonymousCannotApplyForDraft()
                }
                /// 隐藏centerView
                self.viewModel.isAnonymous = false
                self.centerContainer.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(self.keyboardPanel.snp.top)
                    make.height.equalTo(0)
                }
                self.tracker.endTrackWithItem(item)
            }
        }, onError: nil)
    }

    private func addObserverForNickNameUpdate() {
        viewModel.circleConfigService?.rxUpdateNickNameNot
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (user) in
                guard let self = self else { return }
                if let switcherViewModel = self.identitySwitcher?.viewModel as? MomentsAnonymousIdentitySwitchViewModel {
                    self.viewModel.anonymousConfigService?.userCircleConfig?.nicknameUser = user
                    switcherViewModel.user?.nicknameUser = user
                    /// 选择完身份之后 如果还有匿名额度 直接选择匿名
                    if let hasQuota = self.viewModel.hasQuota, hasQuota, !self.contentTextView.attributedText.hasAtUser {
                        self.viewModel.isAnonymous = true
                    } else {
                        /// 选择完身份之后 如果没有匿名额度，选择实名
                        self.viewModel.isAnonymous = false
                    }
                    self.switchToCurrentIdentity()
                }
            }).disposed(by: self.disposeBag)
    }

    private func configIdentitySwitcherWithType(_ type: RawData.AnonymityPolicy.AnonymousType) {
        if let identitySwitcher = identitySwitcher {
            (identitySwitcher.viewModel as? MomentsAnonymousIdentitySwitchViewModel)?.type = type
        } else {
            let switchViewModel = MomentsAnonymousIdentitySwitchViewModel(userResolver: userResolver,
                                                                          anonymousUser: viewModel.anonymousConfigService?.anonymousAndNicknameUserInfoWithScene(.post),
                                                                 type: type)

            setupIdentitySwitcher(viewModel: switchViewModel, switchable: true)
            identitySwitcher?.isHidden = true
        }
        switchToCurrentIdentity()
        updatePlaceholderText()
    }

    private func configOfficialUserInfoView() {
        let switchViewModel = MomentsIdentityInfoViewModel(userResolver: userResolver)
        setupIdentitySwitcher(viewModel: switchViewModel, switchable: false)
        identitySwitcher?.switchToReal()
    }

    private func setupIdentitySwitcher(viewModel: IdentitySwitchViewModel,
                                       switchable: Bool) {
        guard identitySwitcher == nil else { return }
        // 添加发帖身份视图
        let switchView = IdentitySwitchBusinessView(viewModel: viewModel,
                                                    switchable: switchable,
                                                    leftRightMargin: 16)
        switchView.delegate = self
        centerContainer.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        identitySwitcher = switchView
    }

    private func updateIdentitySwitcherOnSeletedCategoryChange(careDraft: Bool = false) {
        //官方号身份时 不会随板块更改 匿名身份切换信息
        guard !(momentsAccountService?.getCurrentUserIsOfficialUser() ?? false) else { return }
        var currentCategory: RawData.PostCategory?
        if let itemId = getSelectedCategoryId(),
           let category = viewModel.categoryItems.first(where: { $0.category.categoryID == itemId }) {
            currentCategory = category
        }
        let canAnonymous = (self.viewModel.anonymousConfigService?.canAnonymousForCategory(currentCategory) ?? false)
        if canAnonymous {
            showIdentitySwitcher()
        } else {
            if careDraft, viewModel.isAnonymous {
                showToastForAnonymousCannotApplyForDraft()
            }
            hideIdentitySwitcher()
        }
    }

    private func switchToCurrentIdentity() {
        if viewModel.isAnonymous {
            identitySwitcher?.switchToAnonymous()
        } else {
            identitySwitcher?.switchToReal()
        }
    }

    /// 展示身份选择器
    private func showIdentitySwitcher() {
        identitySwitcher?.isHidden = false
        identitySwitcher?.snp.remakeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        switchToCurrentIdentity()
    }
    /// 隐藏身份选择器
    private func hideIdentitySwitcher() {
        /// 需要隐藏
        if let switcher = identitySwitcher,
           !switcher.isHidden,
           viewModel.isAnonymous {
            let toastText = viewModel.anonymousConfigService?.userCircleConfig?.anonymityPolicy.type == .nickname ?
            BundleI18n.Moment.Moments_NoNicknameUseTrueIdentity : BundleI18n.Moment.Lark_Community_NoAnonymousInCategoryDesc
            UDToast.showTips(with: toastText, on: self.view.window ?? self.view, delay: 1.5)
        }
        viewModel.isAnonymous = false
        identitySwitcher?.isHidden = true
        identitySwitcher?.snp.remakeConstraints({ (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        })
    }
    private func updatePlaceholderText() {
        guard let config = viewModel.anonymousConfigService?.userCircleConfig else {
            return
        }
        self.contentTextView.placeholder = viewModel.isAnonymous ? config.anonymityPolicy.tip : BundleI18n.Moment.Lark_Community_SaySomething
    }

    private func showToastForAnonymousCannotApplyForDraft() {
        UDToast.showTips(with: BundleI18n.Moment.Lark_Community_UnableShareAnonymousToast, on: self.view.window ?? self.view)
    }

    private func showUnSupportAtTipForAnonymous() {
        guard let config = viewModel.anonymousConfigService?.userCircleConfig,
              config.anonymityPolicy.enabled, let showView = self.view.window else {
            return
        }
        UDToast.showTips(with: BundleI18n.Moment.Moments_UnableToMentionOthersAnonymously_Toast, on: showView, delay: 1)
    }

    @objc
    func wrapperViewClick() {
        contentTextView.becomeFirstResponder()
    }

    func isUrlItemBeforeSelectedRange() -> Bool {
        let range = contentTextView.selectedRange
        if range.location == 0 {
            return false
        }
        let content = contentTextView.attributedText.string as NSString
        if range.location - 1 < content.length {
            let subStr = content.substring(with: NSRange(location: range.location - 1, length: 1))
            return subStr.isUrlChar()
        }
        return false
    }

}

// MARK: - 插入表情 & @ & 插入图片
extension MomentSendPostViewController {
    func insert(userName: String, actualName: String, userId: String = "", isOuter: Bool = false) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId, name: userName, isOuter: isOuter, actualName: actualName)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: self.contentTextView.defaultTypingAttributes)
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: self.contentTextView.defaultTypingAttributes))
            self.contentTextView.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            self.contentTextView.insertText(userName)
        }
        self.contentTextView.becomeFirstResponder()
    }

    /// 拍照 或者 选取图片
    @discardableResult
    func userDidSelectImages(_ items: [SelectImageInfoItem], unSupportTip: String?) -> [SelectImageInfoItem] {
        let items = self.viewModel.uploadImageItems(items)
        self.viewModel.uploadingItems = items
        refrshUIOnUploadSuccess = { [weak self] in
            guard let self = self else {
                return
            }
            self.removeUploadHUD()
            var photoInfoArray: [PhotoInfoItem] = []
            for item in items {
                let photoInfo = PhotoInfoItem(image: item.imageSource?.image ?? UIImage(), isVideo: false)
                item.photoItem = photoInfo
                photoInfoArray.append(photoInfo)
            }
            self.viewModel.selectedImagesModel.selectedItems.append(contentsOf: items)
            self.photoGalleryManager.addItems(photoInfoArray)
            self.updateKeyboardIfNeed()
            self.showFailureWithUnSupportTip(unSupportTip)
        }
        return items
    }

    /// 视频 或者发送视频
    func userDidSelectVideo(item: SelectImageInfoItem) {
        guard let videoInfo = item.videoInfo, let key = self.viewModel.upload(videoInfo: videoInfo) else {
            return
        }
        let trackerItem = self.tracker.getItemWithEvent(.momentsUploadVideo) as? MomentsUploadVideoItem
        trackerItem?.startUploadVideo = CACurrentMediaTime()
        item.attachmentKey = key
        self.viewModel.uploadingItems = [item]
        refrshUIOnUploadSuccess = { [weak self] in
            guard let self = self else {
                return
            }
            trackerItem?.endUploadCover()
            trackerItem?.startUploadVideo = CACurrentMediaTime()
            self.uploadVideoWith(item: item, videoInfo: videoInfo)
        }
    }

    private func uploadVideoWith(item: SelectImageInfoItem, videoInfo: VideoParseInfo) {
        let trackerItem = self.tracker.getItemWithEvent(.momentsUploadVideo) as? MomentsUploadVideoItem
        self.viewModel.uploadVideoToSDK(videoInfo: videoInfo, item: item) { [weak self] (success) in
            guard let self = self else {
                return
            }
            self.removeUploadHUD()
            if success {
                // 视频第一帧图像
                let image = videoInfo.preview
                let photoInfo = PhotoInfoItem(image: image, isVideo: true)
                item.photoItem = photoInfo
                self.photoGalleryManager.addItems([photoInfo])
                self.updateKeyboardIfNeed()
                trackerItem?.endUploadVideo()
            } else {
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_VideoUploadFailed, on: self.view)
                /// 这里drive没有回调错误，给个默认的
                let error = APIError(code: 0, errorCode: 0, status: 0, displayMessage: "", serverMessage: "", debugMessage: "")
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoPost, event: .momentsUploadVideo, page: "publish")
            }
        }
    }

    func updateKeyboardIfNeed() {
        /// 关闭图片选择键盘 改用文字键盘
        if !self.contentTextView.isFirstResponder {
            self.keyboardPanel.closeKeyboardPanel(animation: true)
            self.contentTextView.becomeFirstResponder()
        }
    }

    /// 插入图片的时候，调整滚到底部
    func adjustScrollviewToBottom() {
        self.scrollView.layoutIfNeeded()
        if self.scrollView.contentSize.height <= self.scrollView.frame.height {
            return
        }
        self.scrollView.setContentOffset(CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.frame.height), animated: true)
    }

    func showFailureWithUnSupportTip(_ unSupportTip: String?) {
        guard let unSupportTip = unSupportTip else {
            return
        }
        UDToast.showFailure(with: unSupportTip,
                            on: self.view.window ?? self.view, delay: 2)
    }
}

extension MomentSendPostViewController: PhotoGalleryManagerDelegate {

    func photoGalleryDidClick(photoItem: PhotoInfoItem) {
        var assets: [Asset] = []
        var pageIndex: Int = 0
        if !photoItem.isVideo {
            assets = self.viewModel.getCustomSelectedAssets()
            pageIndex = self.photoGalleryManager.getItemIndex(item: photoItem) ?? 0
        } else {
            if let item = self.viewModel.selectedImagesModel.selectedItems.first,
               let videoInfo = item.videoInfo {
                var coverImage = ImageSet()
                coverImage.origin.key = item.localImageKey
                let mediaInfoItem = MediaInfoItem(key: "",
                                                  videoKey: "",
                                                  coverImage: coverImage,
                                                  url: "",
                                                  videoCoverUrl: "",
                                                  localPath: "",
                                                  size: Float(videoInfo.filesize),
                                                  messageId: "",
                                                  channelId: "",
                                                  sourceId: "",
                                                  sourceType: .typeFromUnkonwn,
                                                  downloadFileScene: nil,
                                                  duration: Int32(videoInfo.duration),
                                                  isPCOriginVideo: false)
                var asset = Asset(sourceType: .video(mediaInfoItem))
                asset.isLocalVideoUrl = true
                asset.isVideo = true
                asset.videoUrl = videoInfo.compressPath
                asset.duration = mediaInfoItem.duration
                assets = [asset]
            }
        }

        if assets.isEmpty {
            return
        }
        let body = MomentsPreviewImagesBody(postId: nil,
                                            assets: assets,
                                     pageIndex: pageIndex,
                                     canSaveImage: false,
                                     canEditImage: false,
                                     hideSavePhotoBut: true)
        userResolver.navigator.present(body: body, from: self)
    }

    func photoGalleryDidClickAddItem() {
        let model = self.viewModel.selectedImagesModel
        let assetType = model.photoPickerAssetType()
        // 隐藏选择原图按钮，希望可以发送非原图照片
        let picker = ImagePickerViewController(assetType: model.convertPhotoTypeToImageType(assetType),
                                               isOriginal: false,
                                               isOriginButtonHidden: true,
                                               sendButtonTitle: BundleI18n.Moment.Lark_Community_Confirm)
        picker.reachMaxCountTipBlock = { (type) in
            return MomentPostKeyboardFactory.reachMaxCountTipForType(type: type)
        }
        picker.showMultiSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in
            picker.dismiss(animated: true, completion: nil)
            self?.assetPickerSuiteDidSelected(assets: result.selectedAssets, isOriginal: result.isOriginal)
        }
        picker.modalPresentationStyle = .fullScreen
        userResolver.navigator.present(picker, from: self, animated: true, completion: nil)
    }

    func photoGalleryDidRemove(photoItem: PhotoInfoItem) {
        self.viewModel.selectedImagesModel.selectedItems.removeAll { (item) -> Bool in
            return item.photoItem == photoItem
        }
        self.updateKeyboardIfNeed()
    }

    func photoGalleryItemCountDidChangeTo(count: Int?) {
        guard let value = count else {
            return
        }
        // 当删图片选择器选择的图片为0之后 隐藏
        if value > 0 {
            // 这里还有些问题
            self.photoGalleryManager.photoGalleryView.isHidden = false
        } else {
            self.photoGalleryManager.adjustContentToMin()
            self.photoGalleryManager.photoGalleryView.isHidden = true
        }
        // 插入图片的时候 也需要更新一下发送按钮是否可用
        self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
    }
}

extension MomentSendPostViewController: IdentitySwitchViewDelegate, AnonymousBusinessPickerViewDelegate {

    func didSelect(businessView: IdentitySwitchBusinessView) {
        /// 如果当前还没有查询是否有匿名余额 则不允许点击
        guard let hasQuota = viewModel.hasQuota else {
            return
        }
        /// 当前已经弹出身份选择页面
        if inAnonymousPickStatus {
            anonymousPickerView?.hidePickerView()
            anonymousPickerView = nil
            businessView.exitSelectStatus()
        } else {
            let pickerView = MomentsAnonymousPickerViewFactory.createPicker(hasAnonymousLeftCount: hasQuota,
                                                                            isAnonymous: viewModel.isAnonymous,
                                                                            showBottomLine: !Display.pad,
                                                                            viewModel: businessView.viewModel)
            pickerView.showPickerView()
            pickerView.delegate = self
            /// 区分IPad & 手机上的展示
            if !Display.pad {
                view.addSubview(pickerView)
                pickerView.snp.makeConstraints { (make) in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalTo(centerContainer.snp.top)
                }
            } else {
                let size = CGSize(width: 375, height: pickerView.containerHeight)
                self.popoverVC = MomentsIpadPopoverAdapter.popoverView(pickerView,
                                                                       fromVC: self,
                                                                       sourceView: businessView.nameLable,
                                                                       preferredContentSize: size,
                                                                       backgroundColor: UIColor.ud.bgBody,
                                                                       permittedArrowDirections: .down,
                                                                       deinitCallBack: { [weak self] in
                    self?.identitySwitcher?.exitSelectStatus()
                    self?.anonymousPickerView = nil
                })
            }
            anonymousPickerView = pickerView
            businessView.enterSelectStatus()
        }

    }

    func pickViewDidSelectItem(pickView: AnonymousBusinessPickerView, selectedIndex: Int?, entityID: String?) {
        guard let idx = selectedIndex else {
            return
        }
        /// 切换到匿名模式
        if  MomentsAnonymousPickerViewFactory.anonymousNameIdx == idx, self.contentTextView.attributedText.hasAtUser {
            showUnSupportAtTipForAnonymous()
            return
        }
        if MomentsAnonymousPickerViewFactory.anonymousNameIdx == idx,
           (viewModel.anonymousConfigService?.needConfigNickName() ?? false) {
            let body = MomentsUserNickNameSelectBody(circleId: viewModel.anonymousConfigService?.userCircleConfig?.circleID ?? "",
                                                     completeBlock: nil)
            if Display.pad {
                self.popoverVC?.dismiss(animated: true, completion: nil)
            }
            userResolver.navigator.present(body: body, from: self, prepare: {
                $0.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
            })
            return
        }
        viewModel.isAnonymous = idx == MomentsAnonymousPickerViewFactory.anonymousNameIdx
        if idx == MomentsAnonymousPickerViewFactory.realNameIdx {
            identitySwitcher?.switchToReal()
        } else {
            /// TODO: 李洛斌 是否有花名的逻辑 & 测试一下花名第一次的逻辑
            identitySwitcher?.switchToAnonymous()
        }
    }

    func pickViewWillDismiss(pickView: AnonymousBusinessPickerView) {
        identitySwitcher?.exitSelectStatus()
    }

    func pickViewWillDidReceiveUserInteraction(selectedIndex: Int?) {
        if self.viewModel.shouldShowNickNameGuide,
           let selectedIndex = selectedIndex,
           selectedIndex == MomentsAnonymousPickerViewFactory.anonymousNameIdx,
           let vm = self.identitySwitcher?.viewModel as? MomentsAnonymousIdentitySwitchViewModel,
            vm.type == .nickname {
            let userID = vm.user?.nicknameUser?.userID ?? ""
            if userID.isEmpty {
                self.viewModel.guideManager?.didShowedGuide(guideKey: viewModel.nickNameGuideKey)
                self.removeAnonymousPickerView()
            } else {
                /// 弹出引导会收起键盘 如果当前键盘收起的直接弹出 如果不是收起的 等待键盘收起弹出
                var time = 0.01
                if self.contentTextView.isFirstResponder {
                    self.view.endEditing(true)
                    time = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                    self.showGuideIfNeedToView(self.anonymousPickerView?.selectedSubview())
                }
            }

        } else {
            self.removeAnonymousPickerView()
        }
    }

    private func removeAnonymousPickerView() {
        /// 如果手机上 需要
        if !Display.pad {
            anonymousPickerView?.hidePickerView()
        }
        identitySwitcher?.exitSelectStatus()
        self.anonymousPickerView = nil
        /// 只有iPad上会有popoverVC，才会触发
        self.popoverVC?.dismiss(animated: true)
    }

    /// 点击引导上的查看花名页面按钮 跳转到花名页面
    private func pushToNickNameVC() {
        identitySwitcher?.switchToAnonymous()
        if let user = viewModel.anonymousConfigService?.userCircleConfig?.nicknameUser {
            MomentsNavigator.pushNickNameAvatarWith(userResolver: userResolver,
                                                    userID: user.userID,
                                                    userInfo: (user.displayName, user.avatarKey),
                                                    from: self,
                                                    selectPostTab: false)
        } else {
            assertionFailure("error to entry pushToNickNameVC")
        }
    }

    private func showGuideIfNeedToView(_ targetView: UIView?) {
        guard let targetView = targetView else {
            return
        }
        let item = BubbleItemConfig(guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView), offset: -50, targetRectType: .circle),
                                    textConfig: TextInfoConfig(title: BundleI18n.Moment.Moments_NicknameProfile_Title_Onboarding,
                                                               detail: BundleI18n.Moment.Moments_NicknameProfile_Desc_Onboarding),
                                    bottomConfig: BottomConfig(leftBtnInfo: ButtonInfo(title: BundleI18n.Moment.Moments_NicknameProfile_ViewMyNicknameProfile_Button_Onboarding),
                                                               rightBtnInfo: ButtonInfo(title: BundleI18n.Moment.Moments_NicknameProfile_GotIt_Button_Onboarding)))
        // 创建单个气泡的配置, 如果不需要代理，就不需要delegate参数
        let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: item)
        let bubbleType = BubbleType.single(singleBubbleConfig)
        self.hasGuideView = true
        self.viewModel.guideManager?.showBubbleGuideIfNeeded(guideKey: viewModel.nickNameGuideKey,
                                                            bubbleType: bubbleType, dismissHandler: nil)
    }
}

extension MomentSendPostViewController: GuideSingleBubbleDelegate {

    func didClickLeftButton(bubbleView: GuideBubbleView) {
        self.viewModel.guideManager?.closeCurrentGuideUIIfNeeded()
        self.removeAnonymousPickerView()
        self.pushToNickNameVC()
        self.hasGuideView = false
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        self.viewModel.guideManager?.closeCurrentGuideUIIfNeeded()
        self.removeAnonymousPickerView()
        identitySwitcher?.switchToAnonymous()
        self.hasGuideView = false
    }

    func didTapBubbleView(bubbleView: LarkGuideUI.GuideBubbleView) {}
}
/// hastTag处理  输入hashTag 或者删除至
extension MomentSendPostViewController: MomentsHashTagListViewDelegate {
    func showHashTagListViewWithInput(_ input: String) {
        /// 当前界面还没展示出来，丢弃展示
        if !finishedApplyDraft {
            return
        }
        /// 当前如果输入的是空字符串 需要获取历史展示
        if input.isEmpty, hashTagListView == nil {
            viewModel.getHistroyHashtag { [weak self] data in
                guard let self = self else { return }
                if self.hashTagListView == nil,
                   self.hashTagRecognizer.isBeginEditingHashTagFor(textView: self.contentTextView) {
                    self.showHashTagListImmediately()
                    self.hashTagListView?.viewModel.updateData(data)
                }
            }
        } else {
            showHashTagListImmediately()
            hashTagListView?.viewModel.updateUserInput(input)
        }
    }

    func showHashTagListImmediately() {
        guard hashTagListView == nil  else {
            return
        }
        let hashTagListView = createHashTagListView()
        hashTagListView.delegate = self
        view.addSubview(hashTagListView)
        ///198 为hashTag列表的最小高度
        let offset = keyboardPanel.panelTopBarHeight - 198
        scrollView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(featureGatingBindCategory ? newCategoriesView.snp.bottom : categoriesView.snp.bottom)
            make.bottom.equalTo(keyboardPanel.snp.top).offset(offset)
        }
        self.hashTagListView = hashTagListView
        view.layoutIfNeeded()
        adjustSelectedRangeToVisible()
        /// 当前内容超出屏幕
        if scrollView.contentSize.height > scrollView.frame.height {
            hashTagListView.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(scrollView.snp.bottom)
                make.bottom.equalTo(keyboardPanel.snp.top).offset(40)
            })
        } else {
            hashTagListView.snp.makeConstraints({ (make) in
                make.top.equalTo(contentTextView.snp.bottom).offset(9)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(keyboardPanel.snp.top).offset(40)
            })
        }
    }

    func removeHashTagListView() {
        guard let hashTagListView = self.hashTagListView else {
            return
        }
        hashTagListView.removeFromSuperview()
        self.hashTagListView = nil
        scrollView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(featureGatingBindCategory ? newCategoriesView.snp.bottom : categoriesView.snp.bottom)
            make.bottom.equalTo(centerContainer.snp.top)
        }
    }
    func createHashTagListView() -> MomentsHashTagListView {
        let hashTagListView = MomentsHashTagListView(userResolver: userResolver)
        return hashTagListView
    }

    /// 调整scrollView的偏移量
    func adjustSelectedRangeToVisible() {
        /// 调整偏移
        var offsetY: CGFloat = 0
        if let frame = hashTagRecognizer.getSelectedRangeRect(contentTextView) {
            if frame.maxY > scrollView.frame.height {
                offsetY = frame.maxY - scrollView.frame.height
            }
        } else {
            if contentTextView.frame.height - scrollView.frame.height > 0 {
                offsetY = contentTextView.frame.height - scrollView.frame.height
            }
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
    }

    func didSelectedItem(_ item: String) {
        removeHashTagListView()
        if !item.isEmpty, let range = hashTagRecognizer.editingHashTagForTextView(contentTextView) {
            let info = HashTagInfo(content: item)
            let hashTagString = HashTagTransformer.transformAttributeStringFor(tagInfo: info, attributes: contentTextView.defaultTypingAttributes)
            let mutableHashTagString = NSMutableAttributedString(attributedString: hashTagString)
            mutableHashTagString.append(NSMutableAttributedString(string: " ", attributes: contentTextView.defaultTypingAttributes))
            let targetAttributeString = NSMutableAttributedString(attributedString: contentTextView.attributedText)
            targetAttributeString.replaceCharacters(in: range, with: mutableHashTagString)
            contentTextView.replace(targetAttributeString, useDefaultAttributes: false)
            let newSelectedRange = NSRange(location: range.location + mutableHashTagString.length, length: 0)
            contentTextView.selectedRange = newSelectedRange
            hashTagRecognizer.onTextDidChangeFor(textView: contentTextView)
        }
        contentTextView.becomeFirstResponder()
    }

    private func getSelectedCategoryId() -> String? {
        return featureGatingBindCategory ? newCategoriesView.getCategoryId() : categoriesView.selectedItem?.id
    }
}
