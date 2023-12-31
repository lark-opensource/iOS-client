//
//  ChatTranslationDetailViewModel.swift
//  LarkMessageCore
//
//  Created by bytedance on 3/31/22.
//

import UIKit
import Foundation
import RustPB
import LKRichView
import LarkModel
import UniverseDesignColor
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkAttachmentUploader
import LarkRichTextCore
import ByteWebImage
import LarkCore
import LarkUIKit
import UniverseDesignTheme
import EditTextView
import LarkMessengerInterface
import LarkContainer
import LarkBaseKeyboard
import LarkSDKInterface
import LarkSetting

final class ChatTranslationDetailViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    private static let logger = Logger.log(ChatTranslationDetailViewModel.self, category: "LarkMessageCore")
    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var userSetting: UserGeneralSettings?
    @ScopedInjectedLazy var fgService: FeatureGatingService?
    let chat: Chat?
    private let title: String?
    private let content: Basic_V1_RichText?
    var useTranslationCallBack: (() -> Void)?
    private var attributes: [NSAttributedString.Key: Any]
    private let imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)]
    private let videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)]

    lazy var styleSheets: [CSSStyleSheet] = {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: UIFont.systemFont(ofSize: 26),
                                                                                atColor: AtColor()))
    }()

    let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.p)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)]
    ]

    public var tiledCache: LKTiledCache?
    private weak var targetElement: LKRichElement?
    private var touchStartTime: TimeInterval?

    var eventDriver: Driver<RichElementTouchedEvent?> { eventPublish.asDriver(onErrorJustReturn: (nil)) }
    private var eventPublish = PublishSubject<RichElementTouchedEvent?>()

    private var imageMaxSize: CGSize = CGSize(width: 300, height: 300)
    private var imageMinSize: CGSize = CGSize(width: 10, height: 10)

    init(chat: Chat?,
         title: String?,
         content: Basic_V1_RichText?,
         attributes: [NSAttributedString.Key: Any],
         imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)],
         videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)],
         useTranslationCallBack: (() -> Void)?,
         userResolver: UserResolver) {
        self.chat = chat
        self.title = title
        self.content = content
        self.attributes = attributes
        self.imageAttachments = imageAttachments
        self.videoAttachments = videoAttachments
        self.useTranslationCallBack = useTranslationCallBack
        self.userResolver = userResolver
    }

    func getAttributeString() -> NSAttributedString {
        let titleString: String
        if let title = title {
            titleString = title + "\n"
        } else {
            titleString = ""
        }
        var attrString = NSMutableAttributedString(string: titleString, attributes: attributes)
        if let content = content {
            let contentAttrString = self.modelService?.copyStringAttr(richText: content,
                                                                      docEntity: nil,
                                                                      selectType: .all,
                                                                      urlPreviewProvider: nil,
                                                                      hangPoint: [:],
                                                                      copyValueProvider: nil,
                                                                      userResolver: self.userResolver) ?? NSAttributedString(string: "")
            attrString.append(contentAttrString)
        }
        return attrString
    }

    func getRichElement() -> LKRichElement {
        var titleElement: LKRichElement?
        if let title = title,
           !title.isEmpty {
            titleElement = LKBlockElement(tagName: RichViewAdaptor.Tag.p).children([
                LKTextElement(
                    classNames: [RichViewAdaptor.ClassName.text],
                    text: title
                )
            ])
            titleElement?.style.font(.ud.title3).color(.ud.textTitle).lineHeight(.em(1.3)).margin(top: nil, right: nil, bottom: .point(26), left: nil)
        }
        var contentElement: LKRichElement?
        if let content = content {
            let needParserContents = PhoneNumberAndLinkParser.getNeedParserContent(richText: content)
            let phoneNumberResult = PhoneNumberAndLinkParser.syncParser(contents: needParserContents, detector: .phoneNumberAndLink)
            // 翻译详情，代码块宽度固定，并且不适配"字体放大"需求
            var codeParseConfig = CodeParseConfig()
            codeParseConfig.fixedWidth = 260
            codeParseConfig.adjustFontScale = false
            contentElement = RichViewAdaptor.parseRichTextToRichElement(richText: content,
                                                                        isFromMe: true,
                                                                        isShowReadStatus: false,
                                                                        checkIsMe: nil,
                                                                        botIDs: [],
                                                                        readAtUserIDs: [],
                                                                        defaultTextColor: .ud.textTitle,
                                                                        abbreviationInfo: nil,
                                                                        mentions: nil,
                                                                        imageAttachmentProvider: { [weak self] property in
                          guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                return self.getImageViewRichAttachment(property: property, imageMaxSize: self.imageMaxSize, imageMinSize: self.imageMinSize)
                      },
                                                                        mediaAttachmentProvider: { [weak self] property in
                          guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                          return self.getMediaViewRichAttachment(property: property, imageMaxSize: self.imageMaxSize, imageMinSize: self.imageMinSize)
                      },
                                                                        urlPreviewProvider: nil,
                                                                        hashTagProvider: nil,
                                                                        phoneNumberAndLinkProvider: { elementID, _ in
                return phoneNumberResult[elementID] ?? []
            },
                                                                        codeParseConfig: codeParseConfig)
        }

        let children = [titleElement, contentElement].compactMap { $0 }
        let document = LKBlockElement(tagName: RichViewAdaptor.Tag.p)
        document.children(children)
        return document
    }
}

extension ChatTranslationDetailViewModel {
    public func getImageViewRichAttachment(property: Basic_V1_RichTextElement.ImageProperty,
                                           imageMaxSize: CGSize,
                                           imageMinSize: CGSize,
                                           font: UIFont = UIFont.ud.body0,
                                           iconColor: UIColor = UIColor.ud.textLinkNormal
    ) -> LKRichAttachment {
        if let docIcon = TextDocsViewModel.getDocIconRichAttachment(property: property, font: font, iconColor: iconColor) {
            return docIcon
        }
        let imageTransformInfo = imageAttachments[property.originKey]?.1
        var useLocal = imageAttachments[property.originKey]?.1.localKey != nil
        let originSize = useLocal ? (imageTransformInfo?.imageSize ?? .zero)
        : CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight))
        let size = ChatImageViewWrapper.calculateSize(originSize: originSize, maxSize: imageMaxSize, minSize: imageMinSize)
        let attachment = LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: { [weak self] in
                guard let self = self else { return UIView(frame: .zero) }
                return self.createImageView(property: property,
                                            useLocal: useLocal,
                                            originSize: originSize,
                                            size: size,
                                            imageMaxSize: imageMaxSize,
                                            imageMinSize: imageMinSize)
            },
            ascentProvider: { _ in return font.ascender },
            verticalAlign: .baseline
        )
        return attachment
    }

    private func createImageView(property: Basic_V1_RichTextElement.ImageProperty,
                                 useLocal: Bool,
                                 originSize: CGSize,
                                 size: CGSize,
                                 imageMaxSize: CGSize,
                                 imageMinSize: CGSize) -> ChatImageViewWrapper {
        let imageView = ChatImageViewWrapper(maxSize: imageMaxSize, minSize: imageMinSize)
        imageView.imageKey = property.originKey

        if useLocal {
            if let image = (self.imageAttachments[property.originKey]?.0.customView as? AttachmentPreviewableView)?.previewImage() {
                imageView.set(
                    originSize: originSize,
                    dynamicAuthorityEnum: .allow,
                    needLoading: false,
                    animatedDelegate: nil,
                    forceStartIndex: 0,
                    forceStartFrame: nil,
                    imageTappedCallback: { [weak self] _ in
                        self?.eventPublish.onNext(.imageCLick(image: image))
                    },
                    setImageAction: { (imageView, completion) in
                        imageView.image = image
                        completion(image, nil)
                    },
                    settingGifLoadConfig: self.userSetting?.gifLoadConfig
                )
            }
        } else {
            let imageSet = ImageItemSet.transform(imageProperty: property)
            let key = imageSet.getThumbKey()
            let resource = LarkImageResource.default(key: key)
            imageView.set(
                originSize: originSize,
                dynamicAuthorityEnum: .allow,
                needLoading: true,
                animatedDelegate: nil,
                forceStartIndex: 0,
                forceStartFrame: nil,
                imageTappedCallback: { [weak self] _ in
                    self?.eventPublish.onNext(.imageClick(property: property))
                },
                setImageAction: { (imageView, completion) in
                    imageView.bt.setLarkImage(
                        with: resource,
                        placeholder: imageSet.inlinePreview,
                        trackStart: nil,
                        completion: { result in
                            switch result {
                            case .success(let imageResult):
                                completion(imageResult.image, nil)
                            case .failure(let error):
                                completion(nil, error)
                            }
                        }
                    )
                },
                settingGifLoadConfig: self.userSetting?.gifLoadConfig
            )
        }

        imageView.frame = CGRect(origin: .zero, size: size)
        return imageView
    }

    public func getMediaViewRichAttachment(property: Basic_V1_RichTextElement.MediaProperty,
                                           imageMaxSize: CGSize,
                                           imageMinSize: CGSize,
                                           font: UIFont = UIFont.ud.body0) -> LKRichAttachment {
        let videoTransformInfo = videoAttachments[property.image.key]?.1
        let originSize = videoTransformInfo?.imageSize ?? .zero
        let (size, contentMode) = VideoImageView.calculateSizeAndContentMode(
            originSize: originSize,
            maxSize: imageMaxSize,
            minSize: imageMinSize
        )

        return LKAsyncRichAttachmentImp(size: size, viewProvider: { [weak self] in
            guard let self = self else { return UIView(frame: .zero) }
            return self.createMediaView(property: property, size: size, contentMode: contentMode)
        }, ascentProvider: { mode in
            switch mode {
            case .horizontalTB: return size.height
            case .verticalLR, .verticalRL: return size.width
            }
        })
    }

    private func createMediaView(property: Basic_V1_RichTextElement.MediaProperty,
                                 size: CGSize,
                                 contentMode: UIView.ContentMode) -> VideoImageViewWrapper {
        let videoView = VideoImageViewWrapper()

        videoView.status = .normal
        videoView.previewView.contentMode = contentMode
        videoView.setDuration(property.duration)
        videoView.setOriginSize(size)
        videoView.previewView.image = (videoAttachments[property.image.key]?.0.customView as? AttachmentPreviewableView)?.previewImage()
        videoView.tapAction = { [weak self] (_, _) in
            guard let self = self else { return }
            if let videoTransformInfo = self.videoAttachments[property.image.key]?.1 {
                self.eventPublish.onNext(.videoClick(videoTransformInfo: videoTransformInfo))
            }
        }
        videoView.videoKey = property.key
        videoView.backgroundColor = UIColor.clear

        videoView.frame = CGRect(origin: .zero, size: size)
        return videoView
    }
}

extension ChatTranslationDetailViewModel: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
        guard cache.checksum.isTiledCacheValid else { return }
        self.tiledCache = cache
    }

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return self.tiledCache
    }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
        touchStartTime = event?.timestamp
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard let event = event,
              let touchStartTime = touchStartTime else {
            targetElement = nil
            return
        }
        if targetElement !== event.source { targetElement = nil }
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }
        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID:
            needPropagation = handleTagAtEvent(element: element, event: event)
        case RichViewAdaptor.Tag.a.typeID:
            needPropagation = handleTagAEvent(element: element, event: event)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let atElement = content?.elements[element.id] else { return true }
        handleAtClick(property: atElement.property.at)
        return false
    }
    func handleAtClick(property: Basic_V1_RichTextElement.AtProperty) {
        // 非匿名用户 & 非艾特全体才有点击事件和跳转
        guard !property.isAnonymous, property.userID != "all" else { return }
        self.eventPublish.onNext(.atClick(userID: property.userID))
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if anchor.classNames.contains(RichViewAdaptor.ClassName.phoneNumber) {
            handlePhoneNumberClick(phoneNumber: anchor.href ?? anchor.text)
            return false
        } else if let href = anchor.href {
            do {
                let url = try URL.forceCreateURL(string: href)
                handleURLClick(url: url)
            } catch {
                Self.logger.error(logId: "url_parse", "Error: \(error.localizedDescription), SpecURL: \(href)")
            }
            return false
        }
        return true
    }

    func handlePhoneNumberClick(phoneNumber: String) {
        self.eventPublish.onNext(.phoneNumberClick(phoneNumber: phoneNumber))
    }

    func handleURLClick(url: URL) {
        self.eventPublish.onNext(.URLClick(url: url))
    }
}

enum RichElementTouchedEvent {
    case atClick(userID: String)
    case imageClick(property: Basic_V1_RichTextElement.ImageProperty)
    case imageCLick(image: UIImage)
    case phoneNumberClick(phoneNumber: String)
    case URLClick(url: URL)
    case videoClick(videoTransformInfo: VideoTransformInfo)
}
