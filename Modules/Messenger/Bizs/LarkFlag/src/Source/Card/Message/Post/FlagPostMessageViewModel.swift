//
//  FlagPostMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import LarkContainer
import RxSwift
import RichLabel
import LarkMessageCore
import TangramService
import ByteWebImage
import RustPB
import LKRichView
import EENavigator
import LarkMessengerInterface
import UIKit
import RxCocoa
import LarkRichTextCore
import LarkAccountInterface

// 使用新富文本渲染框架
final class FlagPostMessageViewModel: FlagMessageCellViewModel {
    struct ParseProps {
        static let listMaxLines = 2
        static let listMaxChars = ParseProps.listMaxLines * FlagUtility.maxCharCountAtOneLine
        static let detailMaxLines = 0
        static var textFont: UIFont { UIFont.ud.body0 }
    }

    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var passportUserService: PassportUserService?

    private var previewPostImage = PublishSubject<PreviewAssetActionMessage>()

    var title: String {
        return self.messageContent?.title ?? ""
    }

    private let iconColor = UIColor.ud.textLinkNormal

    weak var sourceView: UIView?

    private weak var targetElement: LKRichElement?

    private var textFont = FlagPostMessageViewModel.ParseProps.textFont

    var messageContent: TextPostContent? {
        return TextPostContent.transform(from: self.message.content,
                                         currentUserId: self.passportUserService?.user.userID ?? "",
                                         currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
    }

    var previewPostImageDriver: Driver<PreviewAssetActionMessage> {
        return self.previewPostImage.asDriver(onErrorRecover: { _ in return Driver.empty() })
    }

    var listRichElement: LKRichElement?
    var isDisplay: Bool = false
    // inlineRenderTrack的访问在一个串行队列里，保证了线程安全
    var inlineRenderTrack: InlinePreviewRenderTrack = .init()

    override public class var identifier: String {
        return String(describing: FlagPostMessageViewModel.self)
    }

    override public var identifier: String {
        return FlagPostMessageViewModel.identifier
    }

    override func willDisplay() {
        super.willDisplay()
        isDisplay = true
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        isDisplay = false
    }

    override func setupMessage() {
        super.setupMessage()

        /// Parse the flag list message and appropriate truncation.
        let size = (FlagUtility.imageMaxSize, FlagUtility.imageMinSize)
        guard let parseResult = self.parseRichText(maxLines: 2, attachMentSize: size) else {
            return
        }
        self.listRichElement = parseResult
        self.listRichElement?.style.maxHeight(.point(171))
    }

    /// Parse post rich text
    ///
    /// - Parameter maxLines: Truncated post message into several lines.
    /// - Returns: Parsed result.
    func parseRichText(maxLines: Int = ParseProps.listMaxLines, attachMentSize: (max: CGSize, min: CGSize)) -> LKRichElement? {
        guard let content = self.messageContent else {
            return nil
        }
        inlineRenderTrack.setStartTime(message: message)
        var index = 0
        let textDocsVMResult = TextDocsViewModel(
            userResolver: userResolver,
            richText: content.richText,
            docEntity: content.docEntity,
            hangPoint: message.urlPreviewHangPointMap
        )
        let richText = textDocsVMResult.richText
        // parseRichTextToRichElement做了二进制不兼容的变更，需要更新LarkFlag
        let result = RichViewAdaptor.parseRichTextToRichElement(
            richText: richText,
            isFromMe: false,
            isShowReadStatus: false,
            checkIsMe: self.dataDependency.checkIsMe,
            maxLines: maxLines,
            maxCharLine: FlagUtility.maxCharCountAtOneLine,
            abbreviationInfo: dataDependency.abbreviationEnable ? content.abbreviation : nil,
            imageAttachmentProvider: { [weak self] (property) in
                guard let `self` = self else {
                    return LKRichAttachmentImp(view: UIView())
                }
                let font = self.textFont
                if let docIcon = TextDocsViewModel.getDocIconRichAttachment(property: property, font: font, iconColor: self.iconColor) {
                    return docIcon
                }

                let originSize = CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight))
                let imageSize: CGSize = {
                    if self.permissionPreview.0 && self.dynamicAuthorityEnum.authorityAllowed { return originSize }
                    return CGSize(width: 200, height: 120)
                }()
                let size = ChatImageViewWrapper.calculateSize(originSize: imageSize, maxSize: attachMentSize.max, minSize: attachMentSize.min)

                var outerImageView: ChatImageViewWrapper?
                runInMain {
                    let imageView = ChatImageViewWrapper(maxSize: attachMentSize.max, minSize: attachMentSize.min)
                    outerImageView = imageView
                    imageView.backgroundColor = UIColor.clear
                    imageView.layer.cornerRadius = 4
                    imageView.clipsToBounds = true
                    imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    imageView.layer.borderWidth = 1 / UIScreen.main.scale

                    imageView.tag = index
                    index += 1
                    imageView.backgroundColor = UIColor.clear
                    imageView.set(
                        isSmallPreview: false,
                        originSize: imageSize,
                        dynamicAuthorityEnum: self.dynamicAuthorityEnum,
                        permissionPreview: self.permissionPreview,
                        needLoading: true,
                        animatedDelegate: nil,
                        forceStartIndex: 0,
                        forceStartFrame: nil,
                        imageTappedCallback: { [weak self] view in
                            // 没有预览权限时弹窗提示
                            guard let self = self, let view = view as? ChatImageViewWrapper else { return }
                            if !self.dynamicAuthorityEnum.authorityAllowed {
                                self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                                            result: self.dynamicAuthorityEnum,
                                                                            from: imageView.window)
                                return
                            }
                            if !self.permissionPreview.0 {
                                guard let window = view.window else {
                                    assertionFailure()
                                    return
                                }
                                self.chatSecurity?.authorityErrorHandler(event: .localImagePreview, authResult: self.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
                                return
                            }
                            // 有预览权限时处理点击事件
                            self.imageViewTapped(view)
                        },
                        setImageAction: { [weak self] (imageView, completion) in
                            let imageSet = ImageItemSet.transform(imageProperty: property)
                            let key = imageSet.generatePostMessageKey(forceOrigin: false)
                            let placeholder = imageSet.inlinePreview
                            let resource = LarkImageResource.default(key: key)
                            let metrics: [String: String] = ["message_id": self?.message.id ?? ""]
                            imageView.bt.setLarkImage(with: resource,
                                                      placeholder: placeholder,
                                                      trackStart: {
                                                          TrackInfo(scene: .Favorite,
                                                                    fromType: .post,
                                                                    metric: metrics)
                                                      },
                                                      completion: { result in
                                                          switch result {
                                                          case let .success(imageResult):
                                                              completion(imageResult.image, nil)
                                                          case let .failure(error):
                                                              completion(placeholder, error)
                                                          }
                                                      })
                        },
                        settingGifLoadConfig: self.userSetting?.gifLoadConfig
                    )
                    imageView.frame = CGRect(origin: .zero, size: size)
                }
                return LKAsyncRichAttachmentImp(
                    size: size,
                    viewProvider: { outerImageView ?? .init(maxSize: .zero, minSize: .zero) },
                    ascentProvider: { _ in return font.ascender },
                    verticalAlign: .baseline
                )
            },
            mediaAttachmentProvider: { [weak self] property in
                guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                return self.mediaViewRichAttachment(property: property)
            },
            urlPreviewProvider: { [weak self] elementID in
                guard let self = self else { return nil }
                return self.dataDependency.inlinePreviewVM.getNodeSummerizeAndURL(elementID: elementID,
                                                                                message: self.message,
                                                                                font: UIFont.ud.body0,
                                                                                textColor: UIColor.ud.textLinkNormal,
                                                                                iconColor: self.iconColor,
                                                                                tagType: TagType.link)
            },
            edited: message.isMultiEdited
        )

        if var content = self.messageContent {
            content.richText = richText
        }
        self.inlineRenderTrack.setEndTime(message: self.message, endTime: CACurrentMediaTime())
        if isDisplay {
            // 收藏页面没有接受消息push更新，需要每次重进刷新，暂时不在willDisplay处上报埋点，否则inlineRenderTrack还需要加锁
            self.inlineRenderTrack.trackRender(scene: "favorite")
        }
        return result
    }

    fileprivate func imageViewTapped(_ view: ChatImageViewWrapper) {
        guard let content = self.messageContent else {
            return
        }
        let richText = content.richText
        let images = richText.imageIds.compactMap { (id) -> RustPB.Basic_V1_RichTextElement.ImageProperty? in
            return richText.elements[id]?.property.image
        }
        var selectKey = ""
        if view.tag < images.count {
            selectKey = images[view.tag].originKey
        }
        self.previewPostImage.onNext(PreviewAssetActionMessage(
            imageView: view.imageView,
            source: .post(selectKey: selectKey, message: self.message)
        ))
    }

    fileprivate func mediaViewRichAttachment(property: Basic_V1_RichTextElement.MediaProperty) -> LKRichAttachment {
        let originSize = getPreviewSize(CGSize(width: CGFloat(property.image.thumbnail.width),
                                               height: CGFloat(property.image.thumbnail.height)
                                              ))
        let (size, _) = VideoImageView.calculateSizeAndContentMode(
            originSize: originSize,
            maxSize: CGSize(width: 100, height: 100),
            minSize: CGSize(width: 50, height: 50)
        )
        return LKAsyncRichAttachmentImp(size: size, viewProvider: { [weak self] in
            guard let self = self else { return UIView(frame: .zero) }
            return self.createMediaView(property: property, size: size, contentMode: .scaleAspectFill)
        }, ascentProvider: { mode in
            switch mode {
            case .horizontalTB: return size.height
            case .verticalLR, .verticalRL: return size.width
            @unknown default: return 0.0
            }
        })
    }

    func trackURLParseClick(url: URL) {
        let entities = Array(MessageInlineViewModel.getInlinePreviewBody(message: message).values)
        let entity = entities.first(where: { $0.url?.tcURL == url.absoluteString })
        IMTracker.Chat.Main.Click.Msg.URLParseClick(message, "favorite", entity, url)
    }

    fileprivate func createMediaView(property: Basic_V1_RichTextElement.MediaProperty,
                         size: CGSize,
                         contentMode: UIView.ContentMode) -> VideoImageViewWrapper {
        let videoView = VideoImageViewWrapper()
        let permissionPreview = self.checkPermissionPreview()
        videoView.handleAuthority(dynamicAuthorityEnum: dynamicAuthorityEnum, hasPermissionPreview: permissionPreview.0)
        videoView.status = self.message.localStatus == .success ? .normal : .notWork
        let imageSet = ImageItemSet.transform(imageSet: property.image)
        videoView.previewView.contentMode = contentMode
        videoView.setDuration(property.duration)
        let key = imageSet.getThumbKey()
        let resource = LarkImageResource.default(key: key)
        videoView.setVideoPreviewSize(originSize: size, authorityAllowed: permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed)
        videoView.previewView.bt.setLarkImage(
            with: resource,
            placeholder: imageSet.inlinePreview,
            trackStart: {
                TrackInfo(scene: .Chat, fromType: .media)
            },
            completion: { result in
                switch result {
                case .failure:
                    videoView.previewView.backgroundColor = UIColor.ud.N200
                case .success:
                    break
                }
            }
        )

        videoView.videoKey = property.key
        videoView.backgroundColor = UIColor.clear
        videoView.layer.cornerRadius = 4
        videoView.clipsToBounds = true

        videoView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        videoView.layer.borderWidth = 1 / UIScreen.main.scale

        videoView.tapAction = { [weak self] (videoImageViewWrapper, _) in
            self?.mediaImageViewTapped(videoImageViewWrapper)
        }

        videoView.frame = CGRect(origin: .zero, size: size)
        return videoView
    }

    fileprivate func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        if !(self.permissionPreview.0 && self.dynamicAuthorityEnum.authorityAllowed) {
            self.noPermissionVideoTappedAction(videoImageView: videoImageView)
            return
        }
        self.imageOrVideoTapped(visibleThumbnail: videoImageView.previewView) { () -> String in
            return videoImageView.videoKey ?? ""
        }
    }

    private func imageOrVideoTapped(visibleThumbnail: UIImageView?, selectKey: () -> String) {
        let selectKey = selectKey()
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: [message],
            selectedKey: selectKey,
            isMeSend: self.dataDependency.checkIsMe,
            checkPreviewPermission: { [weak self] message in
                guard let self = self, let chat = chat else { return .allow }
                return self.checkPreviewAndReceiveAuthority(chat: chat, message: message)
            }
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else {
            return
        }
        result.assets[index].visibleThumbnail = visibleThumbnail
        let body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .chat(chatId: message.channel.id, chatType: chat?.type, assetPositionMap: result.assetPositionMap),
            shouldDetectFile: chat?.shouldDetectFile ?? true,
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            showAddToSticker: true
        )
        /// 进入大图语言界面
        guard let window = visibleThumbnail?.window else {
            assertionFailure()
            return
        }
        userResolver.navigator.present(body: body, from: window)
    }

    fileprivate func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?) {
        return chatSecurity?.checkPermissionPreview(anonymousId: chat.anonymousId, message: message) ?? (false, nil)
    }
    fileprivate func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState {
        return chatSecurity?.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .receiveLoading
    }

    fileprivate func noPermissionVideoTappedAction(videoImageView: VideoImageViewWrapper) {
        guard let window = videoImageView.window else {
            assertionFailure()
            return
        }
        if !self.dynamicAuthorityEnum.authorityAllowed {
            //优先为动态鉴权弹窗
            self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                        result: dynamicAuthorityEnum,
                                                        from: window)
            return
        }
        self.chatSecurity?.authorityErrorHandler(event: .localVideoPreview, authResult: self.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
    }

    func getPreviewSize(_ size: CGSize) -> CGSize {
        guard permissionPreview.0,
              self.dynamicAuthorityEnum.authorityAllowed else { return CGSize(width: CGFloat(200), height: CGFloat(120)) }
        return size
    }

    override public var needAuthority: Bool {
        return true
    }
}

extension FlagPostMessageViewModel: LKRichViewDelegate {
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
    }

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        if targetElement !== event?.source { targetElement = nil }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }

        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID: needPropagation = handleTagAtEvent(element: element, event: event, view: view)
        case CodeTag.code.typeID: needPropagation = handleCodeEvent(isOrigin: true, element: element, event: event, view: view)
        case RichViewAdaptor.Tag.a.typeID: needPropagation = handleTagAEvent(element: element, event: event, view: view)
        case RichViewAdaptor.Tag.span.typeID: needPropagation = handleTagSpanEvent(view: view, element: element, event: event)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    /// Return - 事件是否需要继续冒泡
    private func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if anchor.classNames.contains(RichViewAdaptor.ClassName.phoneNumber) {
            handlePhoneNumberClick(phoneNumber: anchor.href ?? anchor.text, view: view)
            return false
        } else if let href = anchor.href, let url = URL(string: href) {
            handleURLClick(url: url, view: view)
            return false
        }
        return true
    }

    /// Return - 事件是否需要继续冒泡
    func handleCodeEvent(isOrigin: Bool, element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard let window = view.window else { return true }
        let content = self.messageContent
        guard let codeElement = content?.richText.elements[element.id] else { return true }
        userResolver.navigator.present(body: CodeDetailBody(property: codeElement.property.codeBlockV2), from: window)
        return false
    }

    // MARK: - Event Handler
    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        let content = self.messageContent
        guard let atElement = content?.richText.elements[element.id] else { return true }
        return handleAtClick(property: atElement.property.at, view: view)
    }

    private func handleAtClick(property: Basic_V1_RichTextElement.AtProperty, view: LKRichView) -> Bool {
        guard let window = view.window else {
            assertionFailure()
            return true
        }
        let body = PersonCardBody(chatterId: property.userID)
        if Display.phone {
            userResolver.navigator.push(body: body, from: window)
        } else {
            userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: window,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        return false
    }

    private func handleURLClick(url: URL, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        if let httpUrl = url.lf.toHttpUrl() {
            userResolver.navigator.push(httpUrl, context: [
                "from": "collector",
                "scene": "messenger",
                "location": "messenger_favorite"
            ], from: window)
        }
        self.chatSecurityAuditService?.auditEvent(.clickLink(url: url.absoluteString),
                                                 isSecretChat: false)
        trackURLParseClick(url: url)
    }

    private func handlePhoneNumberClick(phoneNumber: String, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        userResolver.navigator.open(body: OpenTelBody(number: phoneNumber), from: window)
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagSpanEvent(view: LKRichView, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        if let abbreviationInfo = messageContent?.abbreviation,
           let abbres = abbreviationInfo[element.id],
           let text = messageContent?.richText.elements[element.id]?.property.text.content {
            let chatId = self.chat?.id ?? "fetch chatid failed"
            (self.sourceView as? FlagPostMessageCell)?.showEnterpriseEntityWordCard(abbres: abbres,
                                                                                           query: text,
                                                                                           chatId: chatId,
                                                                                           triggerView: view,
                                                                                           trigerLocation: event?.touches.first?.position)
            return false
        }
        return true
    }
}

func runInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
