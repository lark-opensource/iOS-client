//
//  ReplyComponentViewModel.swift
//  Action
//
//  Created by KT on 2019/5/29.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RichLabel
import RxSwift
import LarkSetting
import EENavigator
import LarkMessageBase
import LarkContainer
import LarkSDKInterface
import LarkCore
import ByteWebImage
import LarkMessengerInterface
import UniverseDesignColor
import UniverseDesignCardHeader
import LarkAlertController
import LKCommonsLogging

private let logger = Logger.log(LarkMessageBase.ViewModelContext.self, category: "ImageContentViewModel")

public protocol ReplyViewModelContext: PageContext, ColorConfigContext {
    func isBurned(message: Message) -> Bool
    func getReplyMessageSummerize(message: Message, chat: Chat, textColor: UIColor, partialReplyInfo: PartialReplyInfo?) -> NSAttributedString
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    var scene: ContextScene { get }
    var userGeneralSettings: UserGeneralSettings? { get }
}

extension CardContent.CardHeader {
    public var backgroundColors: [UIColor] {
        var colors = [UIColor]()
        if let startColor = Self.parseColor(
            colorKey: "startColor",
            style: style) {
            colors.append(startColor)
        }
        if let endColor = Self.parseColor(
            colorKey: "endColor",
            style: style) {
            colors.append(endColor)
        }
        return colors
    }
    /// 从style dictionary中解析颜色配置
    public static func parseColor(colorKey: String, style: [String: String]) -> UIColor? {
        if let tokenColorKey = style[(colorKey + "Token")],
           let tokenColor = UDColor.getValueByKey(UDColor.Name(tokenColorKey)) {
            return tokenColor
        }
        if let lightColorKey = style[colorKey] {
            if let darkColorKey = style[(colorKey + "DarkMode")] {
                return UIColor.ud.css(lightColorKey) & UIColor.ud.css(darkColorKey)
            }
            return UIColor.ud.css(lightColorKey)
        }
        return nil
    }

    fileprivate struct HeaderThemeConfig {
        static var colorHueDic: [String: UDCardHeaderHue] = [
            "blue": .blue,
            "wathet": .wathet,
            "turquoise": .turquoise,
            "green": .green,
            "lime": .lime,
            "yellow": .yellow,
            "orange": .orange,
            "red": .red,
            "carmine": .carmine,
            "violet": .violet,
            "purple": .purple,
            "indigo": .indigo,
            "neutral": .neural,
            "grey": .neural
        ]
    }

    var colorHue: UDCardHeaderHue? {
        if !self.theme.isEmpty {
            return HeaderThemeConfig.colorHueDic[self.theme]
        }
        return nil
    }
}

public class ReplyComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReplyViewModelContext>: NewAuthenticationMessageSubViewModel<M, D, C> {
    let font: UIFont = UIFont.ud.body2

    var attributedText: NSMutableAttributedString = NSMutableAttributedString(string: "")

    var outOfRangeText: NSAttributedString?

    var isMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    public var colorHue: UDCardHeaderHue? {
        if let content = message.content as? CardContent {
            return content.header.colorHue
        }
        return nil
    }

    public var backgroundColors: [UIColor] {
        if let content = message.content as? CardContent {
            return content.header.backgroundColors
        }
        return []
    }

    public var replyViewTapped: ((_ replyMessage: Message?, _ chat: Chat) -> Void)?
    public var replyImageTapped: ((_ imageView: UIImageView,
                                   _ replyMessage: Message,
                                   _ chat: Chat,
                                   _ messageID: String,
                                   _ permissionPreview: (Bool, ValidateResult?),
                                   _ dynamicAuthorityEnum: DynamicAuthorityEnum) -> Void)?

    private var isCardContent: Bool {
        return (message.content as? CardContent) != nil
    }

    var parentMessage: Message? {
        return message.parentMessage
    }

    override public var authorityMessage: Message? {
        guard let parentMessage = parentMessage else {
            assertionFailure("no parentMessage")
            return nil
        }
        return parentMessage
    }

    private var permissionPreview: (Bool, ValidateResult?) {
        guard let message = parentMessage else { return (true, nil) }
        let context = self.context
        return context.checkPermissionPreview(chat: metaModel.getChat(), message: message)
    }

    private var cardContentHasColorBackground: Bool {
        if let cardcontent = message.content as? CardContent {
            let styleDic = cardcontent.header.style
            let existStartColor = styleDic["startColor"] != nil
            let existEndColor = styleDic["endColor"] != nil
            if existStartColor && existEndColor {
                return true
            }
        }
        return false
    }

    /// 文本颜色
    lazy var textColor: UIColor = {
        if let colorHue = self.colorHue { return colorHue.textColor }
        var key: ColorKey = .Message_Reply_Foreground
        if cardContentHasColorBackground {
            key = .Message_Reply_Card_Custom_Foreground
        } else if isCardContent {
            key = .Message_Reply_Card_Foreground
        }
        return self.context.getColor(for: key, type: self.isMe ? .mine : .other)
    }()

    /// 竖线颜色
    lazy var lineColor: UIColor = {
        if let colorHue = self.colorHue { return colorHue.textColor }
        var key: ColorKey = .Message_Reply_SplitLine
        if cardContentHasColorBackground {
            key = .Message_Reply_Card_Custom_SplitLine
        } else if isCardContent {
            key = .Message_Reply_Card_SplitLine
        }
        return self.context.getColor(for: key, type: self.isMe ? .mine : .other)
    }()

    private weak var imgView: ByteImageView?

    private lazy var fetchKeyWithCrypto: Bool = {
        return self.context.getStaticFeatureGating("messenger.image.resource_not_found")
    }()

    func getReplyMessageSummerize() {
        setupAttributedText()
        setupAttachment()
    }

    // 文本
    func setupAttributedText() {
        guard let replyMessage = parentMessage else { return }
        var partialReplyInfo: PartialReplyInfo?
        /// FG关的时候，按照全部引用
        if context.userResolver.fg.dynamicFeatureGatingValue(with: "im.messenger.part_reply") {
            partialReplyInfo = metaModel.message.partialReplyInfo
        }

        attributedText = NSMutableAttributedString(attributedString: context.getReplyMessageSummerize(message: replyMessage,
                                                                                                      chat: metaModel.getChat(),
                                                                                                      textColor: textColor,
                                                                                                      partialReplyInfo: partialReplyInfo))
        attributedText.mutableString.replaceOccurrences(
            of: "\n",
            with: " ",
            options: [],
            range: NSRange(location: 0, length: attributedText.length)
        )
        attributedText.addAttributes(
            [.font: font, .foregroundColor: textColor],
            range: NSRange(location: 0, length: attributedText.length)
        )
        outOfRangeText = NSAttributedString(
            string: "\u{2026}",
            attributes: [.font: font, .foregroundColor: textColor]
        )
        /// 有局部回复的信息的时候 不展示二次编辑的标记
        if replyMessage.isMultiEdited, partialReplyInfo == nil {
            attributedText.append(.init(string: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_Edited_Label,
                                        attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                     .foregroundColor: UIColor.ud.textCaption]))
        }

        let width: CGFloat = 2
        /// 分割线
        let lineAttachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let self = self else { return UIView() }
                let lineView = UIView()
                lineView.layer.cornerRadius = width / 2.0
                lineView.backgroundColor = self.lineColor
                return lineView
            },
            size: CGSize(width: width, height: UIFont.ud.body2.pointSize)
        )
        lineAttachment.fontDescent = font.descender
        lineAttachment.fontAscent = font.ascender
        lineAttachment.margin.right = 4
        attributedText.insert(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: lineAttachment]
            ),
            at: 0)
    }

    // 附件
    private func setupAttachment() {
        guard let replyMessage = parentMessage else {
            return
        }
        let content = replyMessage.content

        guard content is ImageContent || content is StickerContent || content is HongbaoContent else {
            return
        }
        // code_next_line tag CryptChat
        guard !context.isBurned(message: replyMessage)
            && !replyMessage.isRecalled
            && !replyMessage.isDeleted else {
            return
        }
        var size = CGSize(width: 44, height: 44)
        if content is HongbaoContent {
            let height: CGFloat = UIFont.ud.body2.rowHeight
            size = CGSize(width: height / 16 * 11, height: height)
        }
        let attachment = LKAsyncAttachment(
            viewProvider: { [weak self] () -> UIView in
                guard let `self` = self else { return UIView() }
                if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
                    let imgView = NoPermissonPreviewSmallLayerView()
                    imgView.tapAction = { [weak self] _ in
                        guard let self = self else { return }
                        self.context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: self.dynamicAuthorityEnum,
                                                                            previewAuthResult: self.permissionPreview.1,
                                                                            resourceType: .image)
                    }
                    return imgView
                }
                let imgView = ByteImageView()
                imgView.animateRunLoopMode = .default
                imgView.isUserInteractionEnabled = true
                imgView.contentMode = .scaleAspectFill
                imgView.clipsToBounds = true
                imgView.lu.addTapGestureRecognizer(action: #selector(self.imageTapped(gesture:)), target: self)
                imgView.layer.borderWidth = 1
                imgView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
                imgView.layer.cornerRadius = 4
                imgView.backgroundColor = .white

                // UIImage: 指placeholder图
                // ImageRequestResult: 指图片请求结果
                let completion: (UIImage?, ImageRequestResult) -> Void = { [weak self, weak imgView] inlineImage, result in
                    guard let imgView = imgView else { return }
                    switch result {
                    case .success(let imageResult):
                        // 对齐 ChatImageViewWrapper，大 GIF 不自动播放
                        if let image = imageResult.image as? ByteImage, image.bt.isAnimatedImage, let config = self?.context.userGeneralSettings?.gifLoadConfig {
                            let dataCount = image.bt.dataCount
                            let imagePixels = CGFloat(image.bt.destPixelSize.width * image.bt.destPixelSize.height)
                            let configPixels = CGFloat(config.width * config.height)
                            if config.size != 0 && dataCount > config.size ||
                                configPixels != 0 && imagePixels > configPixels {
                                imgView.autoPlayAnimatedImage = false
                                imgView.stopAnimating()
                            }
                        }
                        imgView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
                    case .failure:
                        if inlineImage != nil { return }
                        imgView.image = Resources.imageDownloadFailedReply
                        imgView.contentMode = .center
                        imgView.isUserInteractionEnabled = false
                        imgView.backgroundColor = UIColor.ud.N200
                    }
                }
                if let imgContent = content as? ImageContent {
                    let imageSet = ImageItemSet.transform(imageSet: imgContent.image)
                    let resource: LarkImageResource
                    if self.fetchKeyWithCrypto {
                        if let cacheItem = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .messageReplay, originSize: Int(imgContent.originFileSize)) {
                            resource = cacheItem.imageResource()
                        } else {
                            resource = imageSet.getThumbResource()
                        }
                    } else {
                        if let cacheKey = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .messageReplay, originSize: Int(imgContent.originFileSize))?.key {
                            resource = .default(key: cacheKey)
                        } else {
                            resource = .default(key: imageSet.getThumbKey())
                        }
                    }
                    let placeholder = imageSet.inlinePreview
                    imgView.bt.setLarkImage(
                        with: resource,
                        placeholder: placeholder,
                        trackStart: {
                            TrackInfo(biz: .Messenger, scene: .Chat, fromType: .image)
                        },
                        completion: { result in
                            completion(placeholder, result)
                        }
                    )
                } else if let stickerContent = content as? StickerContent {
                    let resource = LarkImageResource.sticker(key: stickerContent.key, stickerSetID: stickerContent.stickerSetID)
                    imgView.bt.setLarkImage(
                        with: resource,
                        trackStart: {
                            TrackInfo(biz: .Messenger, scene: .Chat, fromType: .sticker)
                        },
                        completion: { result in
                            completion(nil, result)
                        }
                    )
                } else if content is HongbaoContent {
                    imgView.contentMode = .scaleAspectFit
                    imgView.layer.cornerRadius = 3
                    imgView.image = BundleResources.hongbao_rectangleCopy
                }

                self.imgView = imgView

                return imgView
            },
            size: size
        )

        // update height

        attachment.fontDescent = font.descender
        attachment.fontAscent = font.ascender
        attachment.verticalAlignment = .top

        attributedText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                                 attributes: [LKAttachmentAttributeName: attachment]))

        let outOfRangeText = NSMutableAttributedString(
            string: "\u{2026} ",
            attributes: [.font: font, .foregroundColor: textColor]
        )
        outOfRangeText.append(NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [LKAttachmentAttributeName: attachment]
        ))
        self.outOfRangeText = outOfRangeText
    }

    @objc
    private func imageTapped(gesture: UIGestureRecognizer) {
        guard gesture.state == .ended,
            let imgView = gesture.view as? UIImageView,
            let replyMessage = parentMessage else {
            return
        }
        if replyMessage.content is HongbaoContent {
            // 红包图片点击进入详情页
            self.replyViewTapped?(message, metaModel.getChat())
        } else {
            self.replyImageTapped?(imgView, replyMessage, metaModel.getChat(), message.id, permissionPreview, dynamicAuthorityEnum)
        }
    }

    public override func willDisplay() {
        super.willDisplay()
        guard let imgView = imgView, imgView.autoPlayAnimatedImage else { return }
        self.imgView?.startAnimating()
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.imgView?.stopAnimating()
    }
}

final class NoPermissonPreviewSmallLayerView: UIView {
    var tapAction: ((_ gesture: UIGestureRecognizer) -> Void)?
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.lu.addTapGestureRecognizer(action: #selector(onTapped(gesture:)), target: self)
    }

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.bgFloatOverlay
        imageView.image = Resources.no_preview_permission
        imageView.contentMode = .center
        return imageView
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTapped(gesture: UIGestureRecognizer) {
        if let tapAction = self.tapAction {
            tapAction(gesture)
        }
    }
}
