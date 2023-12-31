//
//  UrgentConfirmMessageView.swift
//  Action
//
//  Created by shane on 2019/3/14.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import ByteWebImage
import LarkSDKInterface
import LarkMessengerInterface
import RichLabel
import RustPB
import LarkRustClient
import LarkContainer

private let urgentConfirmViewHeight: CGFloat = 150.0

protocol UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum { get }

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView
    func messageViewBackgorundColor() -> UIColor
    func heightOfView(message: Message?, modelService: ModelService?) -> CGFloat
    func invalidSpaceWidth() -> CGFloat
    func needUpdateRichLabelMaxLayoutWidth() -> Bool
    func getRichLabelMaxLayoutWidth() -> CGFloat
    func updateRichLabelMaxLayoutWidth(maxLayoutWidth: CGFloat)

}

extension UrgentConfirmMessageViewProtocol {

    func heightOfView(message: Message?, modelService: ModelService?) -> CGFloat {
        return urgentConfirmViewHeight
    }

    func messageViewBackgorundColor() -> UIColor {
        return UIColor.ud.N100
    }

    func needUpdateRichLabelMaxLayoutWidth() -> Bool {
        return false
    }

    func getRichLabelMaxLayoutWidth() -> CGFloat {
        return -1
    }

    func updateRichLabelMaxLayoutWidth(maxLayoutWidth: CGFloat) {

    }

    func invalidSpaceWidth() -> CGFloat {
        return 30
    }

}

// MARK: 默认实现
struct UrgentConfirmMessageViewEmpty: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .unknown

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()
        return messageView
    }
}

// 富文本属性构造
struct UrgentConfirmTextAttributes {
    static func textAttributesWith(font: UIFont, foregroundColor: UIColor) -> [NSAttributedString.Key: Any] {
          let attributes: [NSAttributedString.Key: Any] = [
              .foregroundColor: foregroundColor,
              .font: font
          ]
          return attributes
    }
}
//场景：发送文本消息 文本输入框
final class UrgentConfirmTextMessageView: UrgentConfirmMessageViewProtocol {
    let userResolver: UserResolver

    var type: Message.TypeEnum = .text
    let label: LKLabel = LKLabel()

    init(userResolver: UserResolver, rustService: RustService) {
        self.userResolver = userResolver
        self.rustClient = rustService
    }

    private let rustClient: RustService

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.autoDetectLinks = false
        label.backgroundColor = .clear
        label.lineSpacing = 2.0
        let lineHeight: CGFloat = label.font.lineHeight + label.lineSpacing
        //当前label的展示高度为 父容器 - 上下边距(15 *2 ) 即：urgentConfirmViewHeight - 30
        label.numberOfLines = Int((urgentConfirmViewHeight - 30) / lineHeight)

        label.activeLinkAttributes = [:]

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        let setAttributeStr: (TextContent?) -> Void = { [weak self, userResolver] textContent in
            guard let content = textContent else {
                return
            }
            let attributes = UrgentConfirmTextAttributes.textAttributesWith(font: UIFont.systemFont(ofSize: 14), foregroundColor: UIColor.ud.N500)
            let docsViewModel: TextDocsViewModel = TextDocsViewModel(userResolver: userResolver, richText: content.richText,
                                                                     docEntity: content.docEntity)
            let result = docsViewModel.parseRichText(checkIsMe: nil, customAttributes: attributes)
            self?.label.linkAttributes = UrgentConfirmTextAttributes.textAttributesWith(font: UIFont.systemFont(ofSize: 14), foregroundColor: UIColor.ud.colorfulBlue)
            result.textUrlRangeMap.forEach { (key: NSRange, _: String) in
                let textLink = LKTextLink(range: key, type: .link)
                self?.label.addLKTextLink(link: textLink)
            }
            self?.label.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
            self?.label.attributedText = result.attriubuteText
        }
        if message.type == .text {
            if message.cryptoToken.isEmpty {
                let content: TextContent? = message.content as? TextContent
                setAttributeStr(content)
            } else {
                DispatchQueue.global(qos: .userInteractive).async {
                    let content: TextContent? = try? self.getRealContent(token: message.cryptoToken)
                    DispatchQueue.main.async {
                        setAttributeStr(content)
                    }
                }
            }
        }
        return messageView
    }

    func needUpdateRichLabelMaxLayoutWidth() -> Bool {
        return true
    }

    func getRichLabelMaxLayoutWidth() -> CGFloat {
        return label.preferredMaxLayoutWidth
    }

    func updateRichLabelMaxLayoutWidth(maxLayoutWidth: CGFloat) {
        if maxLayoutWidth != label.preferredMaxLayoutWidth {
            self.label.preferredMaxLayoutWidth = maxLayoutWidth
            self.label.invalidateIntrinsicContentSize()
        }
    }

    private func getRealContent(token: String) throws -> TextContent? {
        var request = RustPB.Im_V1_GetDecryptedContentRequest()
        request.decryptedTokens = [token]
        let res: RustPB.Im_V1_GetDecryptedContentResponse = try self.rustClient.sendSyncRequest(request)
        if let content = res.contents[token] {
            let textContent = TextContent(
                text: content.text,
                previewUrls: content.previewUrls,
                richText: content.richText,
                docEntity: nil,
                abbreviation: nil,
                typedElementRefs: nil
            )
            return textContent
        }
        return nil
    }
}

//场景：发送图片
struct UrgentConfirmImageMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .image

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        messageView.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(120)
            make.center.equalToSuperview()
        }

        let setImageCompletion: ImageRequestCompletion = { result in
            switch result {
            case .success:
                break
            case .failure:
                imgView.image = Resources.imageDownloadFailed
                imgView.contentMode = .center
                imgView.backgroundColor = .white
            }
        }
        if let content = message.content as? ImageContent {
            let imageSet = ImageItemSet.transform(imageSet: content.image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            let resource = LarkImageResource.default(key: key)
            imgView.bt.setLarkImage(with: resource,
                                    placeholder: placeholder,
                                    trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .image)
                                    },
                                    completion: setImageCompletion)
        } else if let content = message.content as? StickerContent {
            let resource = LarkImageResource.sticker(key: content.key, stickerSetID: content.stickerSetID)
            imgView.bt.setLarkImage(with: resource,
                                    trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                    },
                                    completion: setImageCompletion)
        }

        return messageView
    }
}

//场景：发送定位
struct UrgentConfirmLocationMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .location

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }
        return messageView
    }
}

//场景：发送视频
struct UrgentConfirmMediaMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .media

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        messageView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(120)
            make.center.equalToSuperview()
        }

        let coverView = UIView()
        coverView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.1)
        imageView.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let iconImageView = UIImageView(image: Resources.smallVideoIcon)
        imageView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-5)
            maker.bottom.equalToSuperview().offset(-4)
            maker.width.height.equalTo(12)
        }

        if let content = message.content as? MediaContent {
            let imageSet = ImageItemSet.transform(imageSet: content.image)
            let placeholder = imageSet.inlinePreview
            let key = imageSet.generateVideoMessageKey(forceOrigin: false)
            let resource = LarkImageResource.default(key: key)
            imageView.bt.setLarkImage(with: resource,
                                      placeholder: placeholder,
                                      trackStart: {
                                          return TrackInfo(scene: .Chat, fromType: .media)
                                      })
        }

        return messageView
    }
}

//场景：使用富文本编辑框发送的消息
struct UrgentConfirmPostMessageView: UrgentConfirmMessageViewProtocol {
    let userResolver: UserResolver
    var type: Message.TypeEnum = .post
    let contentLabel: LKLabel = LKLabel()
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let title = UILabel()
        title.font = UIFont.boldSystemFont(ofSize: 14)
        title.textColor = UIColor.ud.N700
        title.lineBreakMode = .byTruncatingTail
        title.numberOfLines = 1
        //title标题的高度 = 文字的行高 + 5的上下边距 满足UI需求
        var titleLabelHeight = title.font.lineHeight + 5.0
        var titleTopSpace: CGFloat = 15

        //无标题的帖子 高度为0
        if let content = message.content as? PostContent {
            // 无标题帖子不展示标题
            if content.isUntitledPost {
                title.text = nil
                titleTopSpace = 0
                titleLabelHeight = 0
            } else {
                title.text = content.title
            }

        }

        messageView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(titleTopSpace)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(titleLabelHeight)
        }

        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.textColor = UIColor.ud.N500
        contentLabel.lineSpacing = 2.0

        /**
         如果当前的post消息没有标题
         contentLabel的高度 urgentConfirmViewHeight - 上边距10 - 下边距15
         如果当前的post消息有标题
         contentLabel的高度 urgentConfirmViewHeight - 上边距15 -titleLabelHeight - 上边距10 - 下边距15
         */
        var contentHeight: CGFloat = 0
        if titleLabelHeight == 0 {
            contentHeight = urgentConfirmViewHeight - 25
        } else {
            contentHeight = urgentConfirmViewHeight - 40 - titleLabelHeight
        }

        let lineHeight: CGFloat = contentLabel.font.lineHeight + contentLabel.lineSpacing

        //这里采用numberofLine 来限制contentLabel的内容高度 不在约束上对label的大小加以限制
        contentLabel.numberOfLines = Int(contentHeight / lineHeight)
        contentLabel.backgroundColor = .clear
        contentLabel.activeLinkAttributes = [:]
        //加急这里链接不需要点击
        contentLabel.autoDetectLinks = false
        messageView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }

        if let content = message.content as? PostContent {
            let attributes = UrgentConfirmTextAttributes.textAttributesWith(font: UIFont.systemFont(ofSize: 14), foregroundColor: UIColor.ud.N500)
            let richTextWithTextImage = content.richText.lc.convertText(tags: [.img])
            let docsViewModel = TextDocsViewModel(userResolver: userResolver, richText: richTextWithTextImage, docEntity: content.docEntity)
            let result = docsViewModel.parseRichText(checkIsMe: nil, customAttributes: attributes)
            //这里 addLKTextLink和linkAttributes 需要在attributedText
            contentLabel.linkAttributes = UrgentConfirmTextAttributes.textAttributesWith(font: UIFont.systemFont(ofSize: 14), foregroundColor: UIColor.ud.colorfulBlue)

            result.textUrlRangeMap.forEach { (key: NSRange, _: String) in
                let textLink = LKTextLink(range: key, type: .link)
                contentLabel.addLKTextLink(link: textLink)
            }

            contentLabel.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
            contentLabel.attributedText = result.attriubuteText
        }
        return messageView
    }

    func needUpdateRichLabelMaxLayoutWidth() -> Bool {
        return true
    }

    func getRichLabelMaxLayoutWidth() -> CGFloat {
        return contentLabel.preferredMaxLayoutWidth
    }

    func updateRichLabelMaxLayoutWidth(maxLayoutWidth: CGFloat) {
        if maxLayoutWidth != contentLabel.preferredMaxLayoutWidth {
            self.contentLabel.preferredMaxLayoutWidth = maxLayoutWidth
            self.contentLabel.invalidateIntrinsicContentSize()
        }
    }

}

//场景：发送的录音消息
struct UrgentConfirmAudioMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .audio

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N500
        label.lineBreakMode = .byTruncatingTail
        messageView.addSubview(label)

        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let content = message.content as? AudioContent {
            let durationStr = formatedDuration(content: content, minuteSuffix: BundleI18n.LarkUrgent.Lark_Legacy_Minute, secondSuffix: BundleI18n.LarkUrgent.Lark_Legacy_Second)
            label.text = "[\(BundleI18n.LarkUrgent.Lark_Legacy_Voice):\(durationStr)]"
        }

        return messageView
    }

    func formatedDuration(
        content: AudioContent,
        minuteSuffix: String,
        secondSuffix: String,
        zeroPrefix: Bool = false
        ) -> String {
        // 5分钟限制
        let maxLength: Int32 = 5 * 60 * 1000
        let duration: Int32 = content.duration > maxLength ? maxLength : content.duration

        var formatedStr = ""

        var seconds = Int(duration / 1000)
        let minutes = seconds / 60
        seconds -= minutes * 60

        if minutes > 0 {
            formatedStr += "\(minutes)\(minuteSuffix)"
        }

        if zeroPrefix && seconds < 10 {
            formatedStr += "0"
        }

        formatedStr += "\(seconds)\(secondSuffix)"

        return formatedStr
    }
}

//场景：消息合并转发的类型
struct UrgentConfirmMergeForwardMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .mergeForward

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let content = message.content as? MergeForwardContent {
            label.text = content.title
        }

        return messageView
    }
}

//场景：卡片消息
struct UrgentConfirmCardMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .card

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        label.text = BundleI18n.LarkUrgent.Lark_Legacy_TextCardContentHolder

        return messageView
    }
}

//场景：用户表情里面的自定义表情
struct UrgentConfirmStickerMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .sticker

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        let stickerContent = message.content as? StickerContent
        let sticker = stickerContent?.transformToSticker()
        if sticker?.mode == .meme, let desc = sticker?.description_p, !desc.isEmpty {
            label.text = "[" + desc + "]"
        } else {
            label.text = BundleI18n.LarkUrgent.Lark_Legacy_StickerHolder
        }
        return messageView
    }
}

//场景：分享用户名片
struct UrgentConfirmShareUserCardMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .shareUserCard

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }
        return messageView
    }
}

// 场景：文件
struct UrgentConfirmFileMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .file

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：文件夹
struct UrgentConfirmFolderMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .folder

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：视频会议
struct UrgentConfirmVideoChatMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .videoChat

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：红包
struct UrgentConfirmHongbaoMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .hongbao

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：红包
struct UrgentConfirmCommercializedHongbaoMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .commercializedHongbao

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：日程消息
struct UrgentConfirmShareCalendarEventMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .shareCalendarEvent

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}

// 场景：任务
struct UrgentConfirmTodoMessageView: UrgentConfirmMessageViewProtocol {
    var type: Message.TypeEnum = .todo

    func fetchMessageView(message: Message, modelService: ModelService?) -> UIView {
        let messageView = UIView()
        messageView.backgroundColor = messageViewBackgorundColor()

        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0

        messageView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }

        if let modelService = modelService {
            label.text = modelService.messageSummerize(message)
        }

        return messageView
    }
}
