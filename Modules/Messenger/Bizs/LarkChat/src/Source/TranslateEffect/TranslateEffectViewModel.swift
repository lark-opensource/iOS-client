//
//  TranslateEffectViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/5/31.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkCore
import LarkRichTextCore
import LarkModel
import RichLabel
import LarkMessageCore
import LarkUIKit
import EENavigator
import ByteWebImage
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import RustPB
import LarkContainer

/// 翻译对比vm
final class TranslateEffectViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()
    /// 会话信息
    private let chat: Chat
    /// 消息信息
    private let message: Message
    private let configurationAPI: ConfigurationAPI
    private let userGeneralSettings: UserGeneralSettings
    private let checkIsMe: (String) -> Bool
    private var imageViewWrappers: NSHashTable = NSHashTable<ChatImageViewWrapper>.weakObjects()
    private let refreshPublish: PublishSubject<Void> = PublishSubject<Void>()

    /// 数据源
    var dataSource: [(MessageTranslateInfo, ParseRichTextResult?)] = []
    /// 刷新表格视图
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }

    init(userResolver: UserResolver,
         chat: Chat,
         message: Message,
         configurationAPI: ConfigurationAPI,
         userGeneralSettings: UserGeneralSettings,
         checkIsMe: @escaping (String) -> Bool) {
        self.userResolver = userResolver
        self.chat = chat
        self.message = message
        self.configurationAPI = configurationAPI
        self.userGeneralSettings = userGeneralSettings
        self.checkIsMe = checkIsMe
        /// 从网络获取一次数据
        self.configurationAPI.fetchMessageTranslateInfos(messageId: self.message.id)
            .subscribe(onNext: { [weak self] (originTranslateInfo, translateInfos) in
                guard let `self` = self else { return }
                /// 组装原文
                var tempDataSources = [self.handleDataSource(originTranslateInfo: originTranslateInfo)]
                /// 组装译文
                tempDataSources.append(contentsOf: self.handleDataSource(translateInfos: translateInfos))
                self.dataSource = tempDataSources
                self.refreshPublish.onNext(())
            }).disposed(by: self.disposeBag)
    }

    /// 对原文进行处理，填充parseRichTextResult属性
    private func handleDataSource(originTranslateInfo: MessageTranslateInfo) -> (MessageTranslateInfo, ParseRichTextResult?) {
        var parseResult: ParseRichTextResult?
        switch originTranslateInfo.type {
        case .text:
            parseResult = self.createTextRichText(textContent: originTranslateInfo.content)
        case .post:
            parseResult = self.createPostRichText(postContent: originTranslateInfo.content)
        @unknown default:
            break
        }
        /// 原文固定展示"原文"
        var originTranslateInfo = originTranslateInfo
        originTranslateInfo.languageValue = BundleI18n.LarkChat.Lark_Chat_OriginalMessage
        return (originTranslateInfo, parseResult)
    }

    /// 对译文进行处理，填充parseRichTextResult属性
    private func handleDataSource(translateInfos: [MessageTranslateInfo]) -> [(MessageTranslateInfo, ParseRichTextResult?)] {
        return translateInfos.map { (info) -> (MessageTranslateInfo, ParseRichTextResult?) in
            var parseResult: ParseRichTextResult?
            switch info.type {
            case .text:
                parseResult = self.createTextRichText(textContent: info.content)
            case .post:
                parseResult = self.createPostRichText(postContent: info.content)
            @unknown default:
                break
            }
            var info = info
            /// 从本地获取key对应的value
            info.languageValue = self.getLanguageValue(language: info.languageValue)
            return (info, parseResult)
        }
    }

    /// 通过语言key得到显示值
    private func getLanguageValue(language: String) -> String {
        let translateSetting = self.userGeneralSettings.translateLanguageSetting
        guard let languageValue = translateSetting.supportedLanguages[language] else {
            return ""
        }
        return languageValue
    }

    /// 来自chat中的text显示逻辑
    private func createTextRichText(textContent: MessageContent) -> ParseRichTextResult? {
        guard let textContent = textContent as? TextContent else { return nil }

        let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: textContent.richText, docEntity: textContent.docEntity)
        let attributeElement = textDocsVM.parseRichText(
            isFromMe: true,
            isShowReadStatus: false,
            checkIsMe: self.checkIsMe,
            botIds: textContent.botIds,
            maxLines: 0,
            maxCharLine: LarkChatUtils.maxCharCountAtOneLine,
            customAttributes: [.foregroundColor: UIColor.ud.N900, .font: UIFont.systemFont(ofSize: 16)]
        )
        return attributeElement
    }

    /// 来自chat中的post显示逻辑
    private func createPostRichText(postContent: MessageContent) -> ParseRichTextResult? {
        guard let postContent = postContent as? PostContent else { return nil }

        let paragraph = NSMutableParagraphStyle()
        paragraph.maximumLineHeight = 18
        paragraph.minimumLineHeight = 18
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.systemFont(ofSize: 16),
            .paragraphStyle: paragraph
        ]
        var index = 0
        let parseResult = LarkCoreUtils.parseRichText(
            richText: postContent.richText,
            isFromMe: true,
            isShowReadStatus: false,
            checkIsMe: self.checkIsMe,
            botIds: postContent.botIds,
            maxLines: 0,
            maxCharLine: LarkChatUtils.maxCharCountAtOneLine,
            customAttributes: attributes,
            imageAttachmentViewProvider: { [weak self] (property, customFont) -> LKAttachment in
                guard let `self` = self else {
                    return LKAttachment(view: UIView(frame: .zero))
                }
                let originSize = CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight))
                var outerImageView: ChatImageViewWrapper?
                guardInMain {
                    let imageView = ChatImageViewWrapper(maxSize: LarkChatUtils.imageMaxSize, minSize: LarkChatUtils.imageMinSize)
                    outerImageView = imageView
                    if !self.imageViewWrappers.contains(imageView) {
                        self.imageViewWrappers.add(imageView)
                    }
                    imageView.tag = index
                    index += 1
                    imageView.backgroundColor = UIColor.clear
                    /// image需要支持点击预览
                    imageView.set(
                        originSize: originSize,
                        needLoading: true,
                        animatedDelegate: nil,
                        forceStartIndex: 0,
                        forceStartFrame: nil,
                        imageTappedCallback: { [weak self] view in
                            guard let `self` = self, let view = view as? ChatImageViewWrapper else { return }
                            self.imageViewTapped(view: view)
                        },
                        setImageAction: { (imageView, completion) in
                            let imageSet = ImageItemSet.transform(imageProperty: property)
                            let key = imageSet.generatePostMessageKey(forceOrigin: false)
                            let placeholder = imageSet.inlinePreview
                            let resource = LarkImageResource.default(key: key)
                            imageView.bt.setLarkImage(with: resource,
                                                      placeholder: placeholder,
                                                      trackStart: {
                                                          TrackInfo(scene: .Chat,
                                                                    fromType: .image)
                                                      },
                                                      completion: { result in
                                                          switch result {
                                                          case let .success(imageResult):
                                                              completion(imageResult.image, nil)
                                                          case let .failure(error):
                                                              completion(nil, error)
                                                          }
                                                      })
                        }
                    )
                    imageView.frame = CGRect(origin: .zero, size: imageView.intrinsicContentSize)
                    if postContent.isGroupAnnouncement {
                        imageView.imageView.contentMode = .scaleAspectFit
                        imageView.imageView.adaptiveContentModel = false
                    }
                }
                let attachMent = LKAttachment(view: outerImageView ?? .init(maxSize: .zero, minSize: .zero))
                attachMent.fontAscent = customFont.ascender
                attachMent.fontDescent = customFont.descender
                attachMent.margin = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
                return attachMent
            })
        return parseResult
    }

    private func imageViewTapped(view: ChatImageViewWrapper) {
        guard let window = view.window else {
            assertionFailure()
            return
        }

        /// 群公告消息直接跳push转
        if let postContent = self.message.content as? PostContent, postContent.isGroupAnnouncement {
            ChatTracker.trackOpenChatAnnouncement(from: .message, chatType: chat.type)
            let body = ChatAnnouncementBody(chatId: self.chat.id)
            navigator.push(body: body, from: window)
            return
        }

        /// 富文本内容直接取message的即可
        var contentRichText: RustPB.Basic_V1_RichText?
        if let textContent = self.message.content as? TextContent {
            contentRichText = textContent.richText
        } else if let postContent = self.message.content as? PostContent {
            contentRichText = postContent.richText
        }
        guard let richText = contentRichText else { return }

        /// 开启大图预览
        let images = richText.imageIds.compactMap { (id) -> RustPB.Basic_V1_RichTextElement.ImageProperty? in
            return richText.elements[id]?.property.image
        }
        var selectKey = ""
        if view.tag < images.count {
            selectKey = images[view.tag].originKey
        }
        self.previewImage(selectKey: selectKey, thumbnail: view.imageView, in: window)
    }

    private func previewImage(selectKey: String, thumbnail: UIImageView, in window: UIWindow) {
        let result = LKDisplayAsset.createAssetExceptForSticker(messages: [self.message], selectedKey: selectKey, isMeSend: checkIsMe)
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        /// push
        result.assets[index].visibleThumbnail = thumbnail
        let body = PreviewImagesBody(assets: result.assets.map({ $0.transform() }),
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
                                     trackInfo: PreviewImageTrackInfo(messageID: message.id),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInMessageScenesTranslateEnable)),
                                     translateEntityContext: (message.id, .message),
                                     canImageOCR: !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward))
        navigator.present(body: body, from: window)
    }
}

func guardInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
