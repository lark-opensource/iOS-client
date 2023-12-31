//
//  MomentsDetailKeyboard.swift
//  Moment
//
//  Created by bytedance on 2021/1/7.
//

import UIKit
import EENavigator
import Foundation
import LarkAssetsBrowser
import LarkContainer
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import EditTextView
import LarkEmotion
import LarkEmotionKeyboard
import LarkMessengerInterface
import LarkModel
import LarkSDKInterface
import LarkUIKit
import LKCommonsLogging
import Photos
import UniverseDesignToast
import RustPB
import RxCocoa
import RxSwift
import LarkMessageCore
import LarkAlertController
import TangramService
import ByteWebImage
import LarkFeatureGating
import LarkBaseKeyboard
import LarkSetting
import LarkSendMessage

/// 键盘代理
protocol MomentsKeyboardDelegate: AnyObject {
    func currentDisplayVC() -> UIViewController
    func handleKeyboardAppear()
    func keyboardFrameChange(frame: CGRect)
    func inputTextViewFrameChange(frame: CGRect)
    func getKeyboardStartupState() -> KeyboardStartupState
    func emojiClick()
    func pictureClick()
}

extension MomentsKeyboardDelegate {
    func emojiClick() {}
    func pictureClick() {}
}

final class MomentsKeyboard: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsKeyboard.self, category: "Module.Moments.MomentsKeyboard")

    private(set) var keyboardView: MomentsKeyboardView
    /// 键盘评论的数据
    var replyComment: RawData.CommentEntity?
    var pictureKeyboard: AssetPickerSuiteView?
    let viewModel: MomentsKeyboardViewModel
    let keyboardNewStyleEnable: Bool
    var emotionKeyboard: EmotionKeyboardProtocol?
    weak var delegate: MomentsKeyboardDelegate?
    /// 匿名相关
    /// 发帖身份展示视图
    private var identitySwitchView: IdentitySwitchBusinessView?
    /// 当前是否处于选择身份态，用来判断只弹出一次身份选择视图
    private var inBusinessPickStatus: Bool {
        return anonymousPickerView != nil
    }
    /// 发帖身份选择视图
    private var anonymousPickerView: AnonymousBusinessPickerView? {
        didSet {
            anonymousPickerView?.autoDismiss = !Display.pad
        }
    }
    private let imageChecker = MomentsImageChecker()
    let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var reactionAPI: ReactionAPI?
    @ScopedInjectedLazy private var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy private var docAPI: DocAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    @ScopedInjectedLazy var imageAPI: ImageAPI?

    init(userResolver: UserResolver,
         viewModel: MomentsKeyboardViewModel,
         delegate: MomentsKeyboardDelegate?,
         keyboardNewStyleEnable: Bool) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.keyboardNewStyleEnable = keyboardNewStyleEnable
        let keyboardView = MomentsKeyboardView(keyboardNewStyleEnable: keyboardNewStyleEnable)
        keyboardView.expandType = .hide
        self.keyboardView = keyboardView
        keyboardView.momentsKeyBoardDelegate = self
        self.delegate = delegate
        setupMomentsInputView()
        if keyboardNewStyleEnable {
            var items = self.viewModel.keyboardItems(keyboard: self)
            let sendKeyBoardItem = LarkKeyboard.buildSend { [weak self] () -> Bool in
                self?.keyboardView.sendNewMessage()
                return false
            }
            items.append(sendKeyBoardItem)
            self.keyboardView.items = items
        } else {
            self.keyboardView.items = self.viewModel.keyboardItems(keyboard: self)
        }
        self.keyboardView.inputPlaceHolder = BundleI18n.Moment.Lark_Community_ShareYourComment
        self.keyboardView.setSubViewsEnable(enable: true)
        self.addObserverForNickNameUpdate()
    }

    private weak var popoverVC: UIViewController?

    private func addOfficialUserInfoView() {
        let identitySwitchviewModel = MomentsIdentityInfoViewModel(userResolver: userResolver)
        setupIdentitySwitchBusinessView(viewModel: identitySwitchviewModel,
                                        switchable: false)
        identitySwitchView?.switchToReal()
    }

    private func addSelectAnonymousViewIfNeed() {
        guard identitySwitchView == nil,
              let config = self.viewModel.anonymousConfigService?.userCircleConfig else { return }
        // 添加发帖身份视图
        let userInfo = self.viewModel.anonymousConfigService?.anonymousAndNicknameUserInfoWithScene(.comment)
        let identitySwitchviewModel = MomentsAnonymousIdentitySwitchViewModel(userResolver: userResolver, anonymousUser: userInfo, type: config.anonymityPolicy.type)
        setupIdentitySwitchBusinessView(viewModel: identitySwitchviewModel,
                                        switchable: true)
        if self.viewModel.isAnonymous {
            identitySwitchView?.switchToAnonymous()
        } else {
            identitySwitchView?.switchToReal()
        }
        updateInputPlaceHolder()
        self.viewModel.onAnonymousStatusChangeBlock = { [weak self] _ in
            self?.updateInputPlaceHolder()
        }
    }

    private func setupIdentitySwitchBusinessView(viewModel: IdentitySwitchViewModel, switchable: Bool) {
        guard identitySwitchView == nil else { return }
        let view = IdentitySwitchBusinessView(viewModel: viewModel,
                                              switchable: switchable,
                                              leftRightMargin: 14)
        view.delegate = self
        keyboardView.inputStackView.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        identitySwitchView = view
    }

    private func setupMomentsInputView() {
        let atUserInputHandler = AtUserInputHandler()
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: false)
        let urlInputHandler: TextViewInputProtocol
        if TextViewCustomPasteConfig.useNewPasteFG {
            urlInputHandler = MomentsURLInputHander(urlPreviewAPI: urlPreviewAPI, psdaToken: "LARK-PSDA-moments-reply-comment-copy-permission")
        } else {
            urlInputHandler = URLInputHandler(urlPreviewAPI: urlPreviewAPI)
        }
        let returnInputHandler = ReturnInputHandler { [weak self] (_) -> Bool in
            if self?.keyboardNewStyleEnable ?? false {
                return true
            }
            self?.keyboardView.sendNewMessage()
            return false
        }
        returnInputHandler.newlineFunc = { (textView) -> Bool in
            // 搜狗换行会 先输入 \r\r 然后删除一个字符 所以这里需要输入两个 \n
            textView.insertText("\n\n")
            return false
        }

        let atPickerInputHandler = AtPickerInputHandler { [weak self] textView, range, _ in
            textView.resignFirstResponder()
            self?.inputTextViewInputAt(cancel: {
                textView.becomeFirstResponder()
            }, complete: { selectItems in
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()

                // 插入at标签
                selectItems.forEach { item in
                    switch item {
                    case .chatter(let item):
                        self?.keyboardView.insert(userName: item.name, actualName: item.actualName, userId: item.id, isOuter: item.isOuter)
                    case .doc(let url), .wiki(let url):
                        _ = url
                        assertionFailure("error entrance, current not support")
                    }
                }
            })
        }

        let textViewInputProtocolSet = TextViewInputProtocolSet([returnInputHandler, atPickerInputHandler, atUserInputHandler, emojiInputHandler, urlInputHandler])
        keyboardView.textViewInputProtocolSet = textViewInputProtocolSet
    }

    func updateReplayComment(_ comment: RawData.CommentEntity?) {
        if comment?.id != replyComment?.id {
            replyComment = comment
            updateInputPlaceHolder()
            updateKeyboardWithComment(comment)
        }
    }

    func updateAnonymousStatus(_ anonymous: Bool) {
        viewModel.isAnonymous = anonymous
        showSwitcherView()
        viewModel.refreshKeyBoardIdentitySwitcher = { [weak self] in
            self?.showSwitcherView()
        }
    }

    func updateEnable(_ value: Bool) {
        keyboardView.updateEnable(value)
    }

    private func updateInputPlaceHolder() {
        if viewModel.postEntity?.canCurrentAccountComment == false {
            return
        }
        if let replyComment = replyComment {
            keyboardView.inputPlaceHolder = BundleI18n.Moment.Lark_Community_ReplyToUsername("\(replyComment.userDisplayName)")
        } else {
            keyboardView.inputPlaceHolder = BundleI18n.Moment.Lark_Community_ShareYourComment
            /// 匿名的话 更新一下占位的文案
            if let config = viewModel.anonymousConfigService?.userCircleConfig, viewModel.isAnonymous {
                keyboardView.inputPlaceHolder = config.anonymityPolicy.tip
            }
        }
    }

    private func showUnSupportAtTipForAnonymous() {
        guard let config = viewModel.anonymousConfigService?.userCircleConfig,
              config.anonymityPolicy.enabled,
              let showView = self.delegate?.currentDisplayVC().view.window else {
            return
        }
        UDToast.showTips(with: BundleI18n.Moment.Moments_UnableToMentionOthersAnonymously_Toast, on: showView, delay: 1)
    }

    private func updateKeyboardWithComment(_ comment: RawData.CommentEntity?) {
        guard let userGeneralSettings, let fgService else { return }
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        let attr = MomentsDataConverter.convertCommentToAttributedStringWith(userResolver: userResolver,
                                                                             comment: comment,
                                                                             userGeneralSettings: userGeneralSettings,
                                                                             fgService: fgService,
                                                                             lineBreakMode: .byCharWrapping,
                                                                             ignoreTranslation: true)
        // swiftlint:enable ban_linebreak_byChar
        keyboardView.updateReplyBarWith(attributedString: attr)
    }

    private func clearKeyboardSelectedImageItem() {
        keyboardRemoveImageItemView(viewModel.selectedImage?.view)
        viewModel.selectedImage = nil
    }

    private func asyncTrans(attributedText: NSAttributedString, selectedImage: MomentsKeyboardSeletedImage?, finish: @escaping (RustPB.Basic_V1_RichText?, RawData.ImageInfo?) -> Void) {
        var richText: RustPB.Basic_V1_RichText?
        var imageInfo: RawData.ImageInfo?
        DispatchQueue.global(qos: .userInteractive).async {
            if !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                var attributedText = attributedText
                attributedText = RichTextTransformKit.preproccessSendAttributedStr(attributedText)
                richText = RichTextTransformKit.transformStringToRichText(string: attributedText)
            }
            if let seletedImage = selectedImage {
                var image = RawData.ImageInfo()
                image.token = seletedImage.token
                image.width = Int32(seletedImage.size.width)
                image.height = Int32(seletedImage.size.height)
                image.localPath = seletedImage.originKey
                imageInfo = image
            }
            finish(richText, imageInfo)
        }
    }

    private func addObserverForNickNameUpdate() {
        viewModel.circleConfigService?.rxUpdateNickNameNot.observeOn(MainScheduler.instance).subscribe(onNext: {  [weak self] (user) in
            guard let self = self else { return }
            if let switcherViewModel = self.identitySwitchView?.viewModel as? MomentsAnonymousIdentitySwitchViewModel {
                self.viewModel.anonymousConfigService?.userCircleConfig?.nicknameUser = user
                switcherViewModel.user?.nicknameUser = user
                if let hasQuota = self.viewModel.hasQuota, hasQuota, !self.keyboardView.attributedString.hasAtUser {
                    self.viewModel.isAnonymous = true
                    self.identitySwitchView?.switchToAnonymous()
                } else {
                    self.viewModel.isAnonymous = false
                    self.identitySwitchView?.switchToReal()
                }
            }
        }).disposed(by: disposeBag)
    }

    /**
     当前是否开启了匿名
     */
    private func showSwitcherView() {
        guard let postEntity = self.viewModel.postEntity else {
            return
        }
        if !postEntity.post.isAnonymous {
            viewModel.isAnonymous = false
        }
        if !postEntity.canCurrentAccountComment {
            return
        }
        if self.momentsAccountService?.getCurrentUserIsOfficialUser() ?? false {
            //官方号也要显示身份信息
            self.addOfficialUserInfoView()
        }
        /// 如果帖子为实名 不允许匿名
        if !postEntity.post.isAnonymous {
            return
        }
        viewModel.circleConfigService?.getUserCircleConfigWithFinsih({ [weak self] (config) in
            guard let self = self, let anonymousConfigService = self.viewModel.anonymousConfigService else { return }
            anonymousConfigService.userCircleConfig = config
            /// 如果草稿是匿名，但是还没有选择花名 无法直接使用 切为实名
            if self.viewModel.isAnonymous, anonymousConfigService.needConfigNickName() {
                self.viewModel.isAnonymous = false
            }
            if anonymousConfigService.canAnonymousForCategory(postEntity.category) {
                self.queryAnonymousQuota()
                self.addSelectAnonymousViewIfNeed()
            } else {
                /// 草稿获取到为匿名 给用户一个提示
                if self.viewModel.isAnonymous {
                    self.showToastForAnonymousCannotApplyForDraft()
                }
                self.viewModel.isAnonymous = false
            }
        }, onError: nil)
    }
    private func queryAnonymousQuota() {
        viewModel.queryAnonymousQuotaFinish { [weak self] (hasQuota) in
            if !hasQuota {
                if self?.viewModel.isAnonymous ?? false {
                    self?.showToastForAnonymousCannotApplyForDraft()
                }
                self?.viewModel.isAnonymous = false
                self?.identitySwitchView?.switchToReal()
            }
        }
    }

    private func showToastForAnonymousCannotApplyForDraft() {
        guard let vc = self.delegate?.currentDisplayVC() else {
            return
        }
        UDToast.showTips(with: BundleI18n.Moment.Lark_Community_UnableShareAnonymousToast, on: vc.view.window ?? vc.view)
    }

}

// MARK: - BaseKeyboardDelegate

extension MomentsKeyboard: MomentsKeyboardViewDelegate {
    func inputTextViewDidChange(input: OldBaseKeyboardView) {
        emotionKeyboard?.updateActionBarEnable()
    }

    /// 将要发送文案
    func inputTextViewWillSend() {
    }

    /// 要发送的富文本
    func inputTextViewSend(attributedText: NSAttributedString) {
        let limit = 5000
        if keyboardView.text.count > limit {
            UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_TheNumberOfWordsExceedsTheLimit("\(limit)"), on: delegate?.currentDisplayVC().view ?? UIView())
            return
        }
        if viewModel.isAnonymous, keyboardView.attributedString.hasAtUser {
            showUnSupportAtTipForAnonymous()
            return
        }
        asyncTrans(attributedText: attributedText, selectedImage: viewModel.selectedImage) { [weak self] richText, imageInfo in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.keyboardView.attributedString = NSAttributedString(string: "")
                // 没有输入任何文字和图片
                if richText == nil, imageInfo == nil {
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_ExpressAttitudeThenComment, on: self.delegate?.currentDisplayVC().view ?? UIView())
                    return
                }
                self.viewModel.delegate?.defaultInputSendTextMessage(richText, imageInfo: imageInfo, replyComment: self.replyComment, isAnonymous: self.viewModel.isAnonymous)
                // 发送后更新UI
                self.updateReplayComment(nil)
                self.clearKeyboardSelectedImageItem()
            }
        }
    }

    func keyboardframeChange(frame: CGRect) {
        delegate?.keyboardFrameChange(frame: frame)
    }

    func inputTextViewFrameChange(frame: CGRect) {
        delegate?.inputTextViewFrameChange(frame: frame)
    }

    func inputTextViewBeginEditing() {
        delegate?.handleKeyboardAppear()
    }

    func inputTextViewInputAt(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        guard let from = delegate?.currentDisplayVC() else {
            return
        }
        if viewModel.isAnonymous {
            showUnSupportAtTipForAnonymous()
            return
        }
        let vc = AtListViewController(userResolver: self.userResolver)
        vc.closeCallback = cancel
        vc.selectedCallback = { [weak self, weak vc] id in
            self?.transformIdsToSelectedItem(ids: [id]) { items in
                complete?(items.map { .chatter(.init(id: $0.id, name: $0.name, actualName: $0.actualName, isOuter: $0.isOuter)) })
            }
            vc?.dismiss(animated: true, completion: nil)
        }
        let nav = LkNavigationController(rootViewController: vc)
        userResolver.navigator.present(nav, from: from, prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() })
    }

    func transformIdsToSelectedItem(ids: [String], finish: (([AtPickerBody.SelectedItem]) -> Void)?) {
        let fgValue = (try? self.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "lark.chatter.name_with_another_name_p2") ?? false

        viewModel.chatterApi?.getChatters(ids: ids)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { chatterMap in
                let items = ids.compactMap { chatterMap[$0] }.map { (chatter) -> AtPickerBody.SelectedItem in
                    let name = fgValue ?
                    chatter.displayWithAnotherName : chatter.localizedName
                    return AtPickerBody.SelectedItem(id: chatter.id,
                                                     name: name,
                                                     actualName: "",
                                                     isOuter: false)
                }
                finish?(items)
            }, onError: { error in
                Self.logger.error("getChatters error \(error)")
            }).disposed(by: disposeBag)
    }

    func clickExpandButton() {
    }

    func closeKeyboardViewReplyTipView() {
        updateReplayComment(nil)
    }
}

// MARK: - EmojiEmotionInputDelegate

extension MomentsKeyboard: EmojiEmotionItemDelegate {
    // 点击表情
    func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        let emoji = "[\(emojiKey)]"
        keyboardView.insertEmoji(emoji)
        if let reactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: emojiKey) {
            reactionAPI?.updateRecentlyUsedReaction(reactionType: reactionKey).subscribe().disposed(by: disposeBag)
        }
    }

    // 点击撤退删除
    func emojiEmotionInputViewDidTapBackspace() {
        keyboardView.deleteBackward()
    }

    func emojiEmotionInputViewDidTapSend() {
        keyboardView.sendNewMessage()
    }

    func emojiEmotionActionEnable() -> Bool {
        return !keyboardView.text.isEmpty
    }

    func isKeyboardNewStyleEnable() -> Bool {
        return keyboardNewStyleEnable
    }

    public func supportSkinTones() -> Bool {
        return true
    }
}

// MARK: - AssetPickerSuiteViewDelegate

extension MomentsKeyboard: AssetPickerSuiteViewDelegate {
    func assetPickerSuiteShouldUpdateHeight(_ suiteView: AssetPickerSuiteView) {
        keyboardView.keyboardPanel.updateKeyboardHeightIfNeeded()
    }

    var mediaDiskUtil: MediaDiskUtil { .init(userResolver: userResolver) }
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 检测视频、图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard mediaDiskUtil.checkMediaSendEnable(assets: result.selectedAssets, on: self.delegate?.currentDisplayVC().view) else {
            return
        }
        pickedAssets(result.selectedAssets, useOriginal: result.isOriginal)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        // 检测图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard mediaDiskUtil.checkImageSendEnable(image: photo, on: self.delegate?.currentDisplayVC().view) else {
            return
        }
        let config = self.viewModel.imageCompressConfig
        let processor = AttachmentMomentProcessor(
            userResolver: userResolver,
            useOriginal: false,
            imageChecker: self.imageChecker,
            showFailedCallback: nil,
            insertCallback: { [weak self] selectItems, _ in
                return selectItems.compactMap { info -> SelectImageInfoItem? in
                    guard let image = info.imageSource?.image,
                            let key = self?.insertImageToKeyBoard(image: image, imageData: info.imageSource?.data, useOriginal: false)
                    else { return nil }
                    info.attachmentKey = key
                    return info
                }
            })
        let request = SendImageRequest(
            input: .image(photo),
            sendImageConfig: SendImageConfig(
                checkConfig: SendImageCheckConfig(
                    isOrigin: !self.viewModel.IsCompressCameraPhotoFG, scene: .Moments, biz: .Messenger, fromType: .post),
                compressConfig: SendImageCompressConfig(compressRate: config.targetQuality, destPixel: config.targetLength)),
            uploader: AttachmentImageUploader(encrypt: false, imageAPI: self.imageAPI))
        // upload内上传了埋点
        request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
        request.addProcessor(
            afterState: .compress,
            processor: processor,
            processorId: "moments.keyboard.afterCompress.processor")
        SendImageManager.shared.sendImage(request: request).subscribe(onNext: { [weak self] messageArray in
            messageArray.forEach { message in
                self?.viewModel.attachmentUploader.finishCustomUpload(key: message.key, result: message.result, data: message.data, error: message.error)
            }
        }, onError: { [weak self] error in
            guard case .noItemsResult = error as? AttachmentMomentSendImageError else { return }
            var tips = BundleI18n.Moment.Lark_Community_FailedToUploadPicture
            if let imageError = error as? LarkSendImageError,
                let compressError = imageError.error as? CompressError,
                let err = AttachmentImageError.getCompressError(error: compressError) {
                tips = err
            }
            DispatchQueue.main.async {
                UDToast.showFailure(with: tips, on: self?.delegate?.currentDisplayVC().view ?? UIView())
            }
        })
    }

    /// 目前业务不支持发送视频
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {}

    public func pickedAssets(_ assets: [PHAsset], useOriginal: Bool) {
        guard !assets.isEmpty,
              let asset = assets.first,
              asset.mediaType == .image else {
            return
        }
        // 当前业务只支持选取一张图片
        if assets.count != 1 {
            assertionFailure("选取图片逻辑出现问题，选取了多张图片")
            return
        }
        let config = self.viewModel.imageCompressConfig
        let processor = AttachmentMomentProcessor(
            userResolver: userResolver,
            useOriginal: useOriginal,
            imageChecker: self.imageChecker,
            showFailedCallback: { [weak self] tips in
                guard let tips = tips else { return }
                UDToast.showFailure(with: tips, on: self?.delegate?.currentDisplayVC().view ?? UIView())
            },
            insertCallback: { [weak self] selectItems, _ in
                return selectItems.compactMap { info -> SelectImageInfoItem? in
                    guard let image = info.imageSource?.image,
                            let key = self?.insertImageToKeyBoard(image: image, imageData: info.imageSource?.data, useOriginal: useOriginal)
                    else { return nil }
                    info.attachmentKey = key
                    return info
                }
            })
        let request = SendImageRequest(
            input: .asset(asset),
            sendImageConfig: SendImageConfig(
                checkConfig: SendImageCheckConfig(isOrigin: useOriginal, scene: .Moments, biz: .Messenger, fromType: .post),
                compressConfig: SendImageCompressConfig(compressRate: config.targetQuality, destPixel: config.targetLength)),
            uploader: AttachmentImageUploader(encrypt: false, imageAPI: self.imageAPI))
        // upload内上传了埋点
        request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
        request.addProcessor(afterState: .compress, processor: processor, processorId: "moment.keyboard.select.photo")
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            SendImageManager.shared.sendImage(request: request).subscribe(onNext: { [weak self] messageArray in
                messageArray.forEach { message in
                    self?.viewModel.attachmentUploader.finishCustomUpload(key: message.key, result: message.result, data: message.data, error: message.error)
                }
            }, onError: { error in
                guard case .noItemsResult = error as? AttachmentMomentSendImageError else { return }
                var tips = BundleI18n.Moment.Lark_Community_FailedToUploadPicture
                if let imageError = error as? LarkSendImageError,
                    let compressError = imageError.error as? CompressError,
                    let err = AttachmentImageError.getCompressError(error: compressError) {
                    tips = err
                }
                DispatchQueue.main.async { [weak self] in
                    UDToast.showFailure(with: tips, on: self?.delegate?.currentDisplayVC().view ?? UIView())
                }
            })
        }
    }

    @discardableResult
    func insertImageToKeyBoard(image: UIImage, imageData: Data?, useOriginal: Bool) -> String? {
        if viewModel.selectedImage != nil {
            return nil
        }
        let key = viewModel.upload(image: image, imageData: imageData, useOriginal: useOriginal)
        if let attachmentKey = key {
            viewModel.selectedImage = MomentsKeyboardSeletedImage()
            viewModel.selectedImage?.attachmentKey = attachmentKey
            viewModel.selectedImage?.size = image.size
            viewModel.refreshUIBlock = { [weak self] in
                self?.refreshKeyboardForInsertImage(image)
            }
            return attachmentKey
        }
        return nil
    }

    private func refreshKeyboardForInsertImage(_ image: UIImage) {
        let item = MomentsKeyBoardImageItemView(image: image) { [weak self] view in
            self?.viewModel.selectedImage = nil
            self?.keyboardRemoveImageItemView(view)
        } clickCallBack: { [weak self] in
            if let item = self?.viewModel.selectedImage,
               let delegate = self?.delegate {
                var coverImage = ImageSet()
                coverImage.origin.key = item.originKey
                var asset = Asset(sourceType: .image(coverImage))
                asset.key = item.originKey
                asset.originKey = item.originKey
                asset.forceLoadOrigin = true
                asset.isAutoLoadOrigin = true
                let assets = [asset]
                let body = MomentsPreviewImagesBody(postId: nil,
                                                    assets: assets,
                                             pageIndex: 0,
                                             canSaveImage: false,
                                             canEditImage: false,
                                             hideSavePhotoBut: true)
                self?.userResolver.navigator.present(body: body, from: delegate.currentDisplayVC())
            }
        }

        keyboardView.inputStackView.addArrangedSubview(item)
        item.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        viewModel.selectedImage?.view = item
        textViewBecomeFirstResponderIfNeed()
    }

    private func textViewBecomeFirstResponderIfNeed() {
        if !keyboardView.inputTextView.isFirstResponder {
            keyboardView.inputTextView.becomeFirstResponder()
        }
    }

    private func keyboardRemoveImageItemView(_ view: UIView?) {
        guard let view = view else {
            return
        }
        keyboardView.inputStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        keyboardView.controlContainer.layoutIfNeeded()
        textViewBecomeFirstResponderIfNeed()
    }
}

extension MomentsKeyboard: IdentitySwitchViewDelegate {
    func didSelect(businessView: IdentitySwitchBusinessView) {
        // 如果当前弹出了选择视图，则需要隐藏
        if inBusinessPickStatus {
            hidePickerView()
            return
        }
        // 为了简化逻辑，点击身份切换视图时，取消当前的编辑状态，收回键盘，取消键盘items的点击态（和头条圈一致）
        keyboardView.fold()
        showPickerView(businessView: businessView)
    }

    /// 隐藏身份选择视图
    private func hidePickerView() {
        anonymousPickerView?.hidePickerView()
        anonymousPickerView = nil
        // 退出选择态
        identitySwitchView?.exitSelectStatus()
    }

    /// 弹出身份选择视图
    private func showPickerView(businessView: IdentitySwitchBusinessView) {
        guard let switchView = self.identitySwitchView,
              let vc = delegate?.currentDisplayVC(),
              let hasQuota = viewModel.hasQuota else {
            return
        }
        // 创建选择视图 匿名回复 不需要限制次数 可以在所有的帖子下无限匿名回复
        let anonymousPicker = MomentsAnonymousPickerViewFactory.createPicker(hasAnonymousLeftCount: hasQuota,
                                                                             isAnonymous: viewModel.isAnonymous,
                                                                             showBottomLine: !Display.pad,
                                                                             viewModel: switchView.viewModel)
        anonymousPicker.delegate = self
        anonymousPicker.showPickerView()
        /// 区分IPad & 手机上的展示
        if !Display.pad {
            // 在导航控制器上添加视图，需要遮挡住导航栏
            vc.view.addSubview(anonymousPicker)
            anonymousPicker.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(switchView.snp.top)
            }
        } else {
            let size = CGSize(width: 375, height: anonymousPicker.containerHeight)
            popoverVC = MomentsIpadPopoverAdapter.popoverView(anonymousPicker,
                                                              fromVC: vc,
                                                              sourceView: businessView.nameLable,
                                                              preferredContentSize: size,
                                                              backgroundColor: UIColor.ud.bgBody,
                                                              permittedArrowDirections: .down,
                                                              deinitCallBack: { [weak self] in
                self?.identitySwitchView?.exitSelectStatus()
                self?.anonymousPickerView = nil
            })
        }
        // 进入选择态
        switchView.enterSelectStatus()
        anonymousPickerView = anonymousPicker
    }
}

extension MomentsKeyboard: AnonymousBusinessPickerViewDelegate {

    func pickViewDidSelectItem(pickView: AnonymousBusinessPickerView, selectedIndex: Int?, entityID: String?) {
        guard let index = selectedIndex, let vc = self.delegate?.currentDisplayVC() else { return }
        if index == MomentsAnonymousPickerViewFactory.anonymousNameIdx, keyboardView.attributedString.hasAtUser {
            showUnSupportAtTipForAnonymous()
            return
        }
        if index == MomentsAnonymousPickerViewFactory.anonymousNameIdx,
           (viewModel.anonymousConfigService?.needConfigNickName() ?? false) {
            let body = MomentsUserNickNameSelectBody(circleId: viewModel.anonymousConfigService?.userCircleConfig?.circleID ?? "",
                                                     completeBlock: nil)
            popoverVC?.dismiss(animated: false, completion: nil)
            userResolver.navigator.present(body: body, from: vc, prepare: {
                $0.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
            })
            return
        }
        viewModel.isAnonymous = index == MomentsAnonymousPickerViewFactory.anonymousNameIdx
        if index == MomentsAnonymousPickerViewFactory.realNameIdx {
            identitySwitchView?.switchToReal()
        } else {
            identitySwitchView?.switchToAnonymous()
        }

    }

    func pickViewWillDidReceiveUserInteraction(selectedIndex: Int?) {
        identitySwitchView?.exitSelectStatus()
        let anonymousPicker = self.anonymousPickerView
        /// 只有iPad上会有popoverVC，才会触发
        self.popoverVC?.dismiss(animated: true, completion: { [weak self] in
            self?.anonymousPickerView = nil
        })
        self.anonymousPickerView = nil
    }

    func pickViewWillDismiss(pickView: AnonymousBusinessPickerView) {
        identitySwitchView?.exitSelectStatus()
    }
}
