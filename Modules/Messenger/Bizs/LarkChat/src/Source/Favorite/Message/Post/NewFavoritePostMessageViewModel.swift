//
//  NewFavoritePostMessageViewModel.swift
//  LarkChat
//
//  Created by JackZhao on 2021/10/11.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import RichLabel
import LarkMessageCore
import TangramService
import ByteWebImage
import RustPB
import LKRichView
import EENavigator
import LarkMessengerInterface
import LarkRichTextCore
import LarkAccountInterface

// 使用新富文本渲染框架
final class NewFavoritePostMessageViewModel: FavoriteMessageViewModel {
    struct ParseProps {
        static let listMaxLines = 2
        static let listMaxChars = ParseProps.listMaxLines * FavoriteUtil.maxCharCountAtOneLine
        static let detailMaxLines = 0
        static let textFont = UIFont.ud.body0
    }

    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var passportUserService: PassportUserService?

    private var previewPostImage = PublishSubject<PreviewAssetActionMessage>()

    // MARK: 之前的实现，favoritelist与favoritedetail两个页面用了一个vm，同时又监听了vm的同一个信号，导致信号发射后，两个页面都会触发回调。目前detail页面的vm很难构造，临时只能单独再加一个信号，和之前的信号区分开，分别监听
    private var previewPostImageInDetail = PublishSubject<PreviewAssetActionMessage>()

    var title: String {
        return self.messageContent?.title ?? ""
    }

    private let iconColor = UIColor.ud.textLinkNormal

    weak var sourceView: UIView?

    private weak var targetElement: LKRichElement?

    private var textFont = NewFavoritePostMessageViewModel.ParseProps.textFont

    var messageContent: TextPostContent? {
        return TextPostContent.transform(from: self.message.content,
                                         currentUserId: self.passportUserService?.user.userID ?? "",
                                         currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
    }

    var previewPostImageDriver: Driver<PreviewAssetActionMessage> {
        return self.previewPostImage.asDriver(onErrorRecover: { _ in return Driver.empty() })
    }

    var previewPostImageInDetailDriver: Driver<PreviewAssetActionMessage> {
        return self.previewPostImageInDetail.asDriver(onErrorRecover: { _ in return Driver.empty() })
    }

    var detailRichElement: LKRichElement?
    var listRichElement: LKRichElement?
    var isDisplay: Bool = false
    // inlineRenderTrack的访问在一个串行队列里，保证了线程安全
    var inlineRenderTrack: InlinePreviewRenderTrack = .init()

    override public class var identifier: String {
        return String(describing: NewFavoritePostMessageViewModel.self)
    }

    override public var identifier: String {
        return NewFavoritePostMessageViewModel.identifier
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

        /// Parse the favorite list message and appropriate truncation.
        let size = (FavoriteUtil.imageMaxSize, FavoriteUtil.imageMinSize)
        guard let parseResult = self.parseRichText(maxLines: 2, attachMentSize: size, forDetail: false) else {
            return
        }
        self.listRichElement = parseResult
        self.listRichElement?.style.maxHeight(.point(FavoriteUtil.imageMaxSize.height * 2))

        let detailSize = (FavoriteUtil.imageDetailMaxSize, FavoriteUtil.imageMinSize)
        guard let richText = self.messageContent?.richText,
            let detailParseResult = self.parseRichText(maxLines: ParseProps.detailMaxLines, attachMentSize: detailSize, forDetail: true) else {
            return
        }
        self.detailRichElement = detailParseResult
        self.detailRichElement?.style.maxHeight(nil)
    }

    /// Parse post rich text
    ///
    /// - Parameter maxLines: Truncated post message into several lines.
    /// - Returns: Parsed result.
    func parseRichText(maxLines: Int = ParseProps.listMaxLines, attachMentSize: (max: CGSize, min: CGSize), forDetail: Bool) -> LKRichElement? {
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

        let result = RichViewAdaptor.parseRichTextToRichElement(
            richText: richText,
            isFromMe: false,
            isShowReadStatus: false,
            checkIsMe: self.dataProvider.checkIsMe,
            maxLines: maxLines,
            maxCharLine: FavoriteUtil.maxCharCountAtOneLine,
            abbreviationInfo: dataProvider.abbreviationEnable ? content.abbreviation : nil,
            imageAttachmentProvider: { [weak self] (property) in
                guard let `self` = self else {
                    return LKRichAttachmentImp(view: UIView())
                }
                let font = self.textFont
                if let docIcon = TextDocsViewModel.getDocIconRichAttachment(property: property, font: font, iconColor: self.iconColor) {
                    return docIcon
                }
                let permissionPreview = self.checkPermissionPreview()
                let originSize = CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight))
                let imageSize: CGSize = {
                    if permissionPreview.0 && self.dynamicAuthorityEnum.authorityAllowed { return originSize }
                    if forDetail { return CGSize(width: 200, height: 120) }
                    return CGSize(width: 80, height: 80)
                }()
                let size = ChatImageViewWrapper.calculateSize(originSize: imageSize, maxSize: attachMentSize.max, minSize: attachMentSize.min)
                var outerImageView: ChatImageViewWrapper?
                self.runInMain {
                    let imageView = ChatImageViewWrapper(maxSize: attachMentSize.max, minSize: attachMentSize.min)
                    outerImageView = imageView
                    imageView.tag = index
                    index += 1
                    imageView.backgroundColor = UIColor.clear
                    imageView.set(
                        isSmallPreview: forDetail ? false : true,
                        originSize: imageSize,
                        dynamicAuthorityEnum: self.dynamicAuthorityEnum,
                        permissionPreview: permissionPreview,
                        needLoading: true,
                        animatedDelegate: nil,
                        forceStartIndex: 0,
                        forceStartFrame: nil,
                        imageTappedCallback: { [weak self] view in
                            guard let self = self, let view = view as? ChatImageViewWrapper else { return }
                            // 没有接收权限时弹窗提示
                            if !self.dynamicAuthorityEnum.authorityAllowed {
                                self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                                           result: self.dynamicAuthorityEnum,
                                                                           from: view.window)
                                return
                            }
                            // 没有预览权限时弹窗提示
                            if !permissionPreview.0 {
                                guard let window = view.window else {
                                    assertionFailure()
                                    return
                                }
                                self.chatSecurity?.authorityErrorHandler(event: .localImagePreview, authResult: permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
                                return
                            }
                            // 有预览权限时判断点击事件发生在收藏界面还是detail界面
                            if forDetail {
                                self.imageViewInDetailTapped(view)
                            } else {
                                self.imageViewTapped(view)
                            }
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
            urlPreviewProvider: { [weak self] elementID in
                guard let self = self else { return nil }
                return self.dataProvider.inlinePreviewVM.getNodeSummerizeAndURL(elementID: elementID,
                                                                                message: self.message,
                                                                                font: UIFont.ud.body0,
                                                                                textColor: UIColor.ud.textLinkNormal,
                                                                                iconColor: self.iconColor,
                                                                                tagType: TagType.link)
            }
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
            source: .post(selectKey: selectKey, message: self.message),
            downloadFileScene: .favorite,
            extra: [
                FileBrowseFromWhere.FileFavoriteKey: self.favorite.id
            ]
        ))
    }

    fileprivate func imageViewInDetailTapped(_ view: ChatImageViewWrapper) {
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
        self.previewPostImageInDetail.onNext(PreviewAssetActionMessage(
            imageView: view.imageView,
            source: .post(selectKey: selectKey, message: self.message),
            downloadFileScene: .favorite,
            extra: [
                FileBrowseFromWhere.FileFavoriteKey: self.favorite.id
            ]
        ))
    }

    func trackURLParseClick(url: URL) {
        let entities = Array(MessageInlineViewModel.getInlinePreviewBody(message: message).values)
        let entity = entities.first(where: { $0.url?.tcURL == url.absoluteString })
        IMTracker.Chat.Main.Click.Msg.URLParseClick(message, "favorite", entity, url)
    }

    private func runInMain(_ callback: () -> Void) {
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.sync {
                callback()
            }
        }
    }

    override public var needAuthority: Bool {
        return true
    }
}

extension NewFavoritePostMessageViewModel: LKRichViewDelegate {
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
        navigator.present(body: CodeDetailBody(property: codeElement.property.codeBlockV2), from: window)
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
            navigator.push(body: body, from: window)
        } else {
            navigator.present(
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
            navigator.push(httpUrl, context: [
                "from": "collector",
                "scene": "messenger",
                "location": "messenger_favorite",
                "showTemporary": false
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
        navigator.open(body: OpenTelBody(number: phoneNumber), from: window)
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagSpanEvent(view: LKRichView, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        var chatId = ""
        if let abbreviationInfo = messageContent?.abbreviation,
           let abbres = abbreviationInfo[element.id],
           let text = messageContent?.richText.elements[element.id]?.property.text.content {
            if let messageContent = self.messageContent as? MessageFavoriteContent {
                chatId = messageContent.chat?.id ?? "未取到chatid"
            }
            (self.sourceView as? NewFavoritePostMessageCell)?.showEnterpriseEntityWordCard(abbres: abbres,
                                                                                           query: text,
                                                                                           chatId: chatId,
                                                                                           triggerView: view,
                                                                                           trigerLocation: event?.touches.first?.position)
            return false
        }
        return true
    }
}
