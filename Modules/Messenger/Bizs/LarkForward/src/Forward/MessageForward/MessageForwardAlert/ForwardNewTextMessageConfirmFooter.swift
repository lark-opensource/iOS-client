//
//  ForwardNewTextMessageConfirmFooter.swift
//  LarkForward
//
//  Created by ByteDance on 2022/8/11.
//
import Foundation
import LarkModel
import LarkCore
import ByteWebImage
import LarkMessengerInterface
import LarkAudio
import LarkAudioKit
import LarkRichTextCore
import LarkBaseKeyboard
import LarkAudioView
import LarkContainer
import SnapKit
import RxSwift
import LarkBizAvatar
import UniverseDesignColor
import RustPB
import UIKit

// nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发内容预览能力组件内置时优化该逻辑
struct ImageCons {
    static var maxWidth: CGFloat = 263
    static var maxHeight: CGFloat = 146
    static var minSize: CGFloat = 80
    static var longImageJudgeWHRatio: CGFloat = 1 / 3
    static var longImageJudgeWidth: CGFloat = 200
    static var longImageDisplaySize = CGSize(width: 80, height: 240)
    static var cornerRadius: CGFloat = 6

    static func calculateImgViewSize(size: CGSize) -> CGSize {
        let maxSize = CGSize(width: maxWidth, height: maxHeight)
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return size
        }
        let widthScaleRatio: CGFloat = min(1, maxSize.width / size.width)
        let heightScaleRatio: CGFloat = min(1, maxSize.height / size.height)
        let scaleRatio = min(widthScaleRatio, heightScaleRatio)
        if Self.showStripeImage(originSize: size) {
            ///长图逻辑
            return CGSize(width: Self.longImageDisplaySize.width,
                          height: Self.maxHeight)
        } else {
            return CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        }
    }

    static func showStripeImage(originSize: CGSize) -> Bool {
        return originSize.width >= Self.longImageJudgeWidth &&
        originSize.width / originSize.height < Self.longImageJudgeWHRatio
    }
}

struct ForwardTextCons {
    static func processing(text: String,
                           inlinePreviewEntities: [String: InlinePreviewEntity],
                           urlPreviewEntities: [String: URLPreviewEntity],
                           previewHangPointValues: [RustPB.Basic_V1_UrlPreviewHangPoint] = []) -> String {
        if urlPreviewEntities.isEmpty { return text }
        let prefixTitle = "\(BundleI18n.LarkForward.Lark_Legacy_WebMessageHolder)"
        var resultText = text
        urlPreviewEntities.keys.forEach({ inlineEntityKey in
            if let inlinePreviewEntitie = inlinePreviewEntities[inlineEntityKey],
               let inlineUrl = inlinePreviewEntitie.url,
               let inlineTitle = inlinePreviewEntitie.title {
                let showTitle = prefixTitle + inlineTitle
                var inlineLink = inlineUrl.url
                if !previewHangPointValues.isEmpty, !resultText.contains(inlineLink) {
                    if let previewHangPoint = previewHangPointValues.first(where: { $0.previewID == inlinePreviewEntitie.previewID }) {
                        inlineLink = previewHangPoint.url
                    }
                }
                resultText = resultText.replacingOccurrences(of: inlineLink, with: showTitle)
            } else {
                if let messageURLPreviewEntity = urlPreviewEntities[inlineEntityKey],
                   let localPreviewBody = messageURLPreviewEntity.localPreviewBody,
                   let url = localPreviewBody.cardURL?.url,
                   !localPreviewBody.title.isEmpty {
                    let showTitle = prefixTitle + localPreviewBody.title
                    resultText = resultText.replacingOccurrences(of: url, with: showTitle)
                }
            }
        })
        return resultText
    }
}

final class ForwardNewTextMessageConfirmFooter: BaseTapForwardConfirmFooter {

    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, modelService: ModelService,
         previewFg: Bool = false) {
        self.message = message
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N900
        self.addSubview(label)
        if previewFg {
            self.addSubview(nextImageView)
            nextImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.width.equalTo(7)
                make.height.equalTo(12)
            }
        }
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: previewFg ? 32 : 10))
        }
        let isPreviewUrls = !((message.content as? TextContent)?.previewUrls.isEmpty ?? true)
        if !message.urlPreviewEntities.isEmpty || isPreviewUrls {
            guard let textContent = message.content as? TextContent else { return }
            let previewHangPointValues = [RustPB.Basic_V1_UrlPreviewHangPoint](message.urlPreviewHangPointMap.values)
            let prefixTitle = "\(BundleI18n.LarkForward.Lark_Legacy_WebMessageHolder) "
            let originText = modelService.messageSummerize(message)
            let resultText = ForwardTextCons.processing(text: originText,
                                                        inlinePreviewEntities: textContent.inlinePreviewEntities,
                                                        urlPreviewEntities: message.urlPreviewEntities,
                                                        previewHangPointValues: previewHangPointValues)
            label.text = resultText
        } else {
            label.text = modelService.messageSummerize(message)
        }
    }
}

final class ForwardNewPostMessageConfirmFooter: BaseTapForwardConfirmFooter {

    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, modelService: ModelService,
         previewFg: Bool = false) {
        self.message = message
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N900
        self.addSubview(label)
        if previewFg {
            self.addSubview(nextImageView)
            nextImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.width.equalTo(7)
                make.height.equalTo(12)
            }
        }
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: previewFg ? 32 : 10))
        }
        guard let content = message.content as? PostContent else { return }

        let originText: String
        // 如果包含代码块
        if CodeInputHandler.richTextContainsCode(richText: content.richText) {
            // 把代码块替换为文本[代码块]
            var copyContent = content
            copyContent.richText = copyContent.richText.lc.convertText(tags: [.codeBlockV2])
            // copy一份message，用copyMessage获取摘要
            let copyMessage = message.copy()
            copyMessage.content = copyContent
            // 这里应该用content.richText.lc.summerize()，用copyMessageSummerize是为了和之前逻辑保持一致
            originText = modelService.copyMessageSummerize(copyMessage, selectType: .all, copyType: .message)
        } else {
            originText = modelService.copyMessageSummerize(message, selectType: .all, copyType: .message)
        }
        let title = content.title.isEmpty ? "" : "[\(content.title)] "
        label.text = title + ForwardTextCons.processing(text: originText,
                                                        inlinePreviewEntities: content.inlinePreviewEntities,
                                                        urlPreviewEntities: message.urlPreviewEntities)
    }
}

final class ForwardNewImageMessageConfirmFooter: BaseTapForwardConfirmFooter {
    var message: Message
    var image: UIImage?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var imgView: ByteImageView = {
        let imgView = ByteImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = ImageCons.cornerRadius
        imgView.layer.masksToBounds = true
        return imgView
    }()

    private lazy var noPermissionPreviewLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N600
        let title = "\(BundleI18n.LarkForward.Lark_Legacy_ImageMessageHolder) \(BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button)"
        label.text = title
        return label
    }()

    private lazy var tipView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        label.layer.cornerRadius = 2
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    init(message: Message,
         image: UIImage?,
         hasPermissionPreview: Bool) {
        self.message = message
        self.image = image
        super.init()
        if !hasPermissionPreview {
            self.backgroundColor = UIColor.ud.bgFloatOverlay
            self.layer.cornerRadius = 5
            self.addSubview(noPermissionPreviewLable)
            noPermissionPreviewLable.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            }
        } else {
            self.backgroundColor = .clear
            self.layer.cornerRadius = 0
            self.addSubview(imgView)
            setImage(imgView, image: image)
            var imageSize = CGSize.zero
            if let imageContent = message.content as? ImageContent {
                imageSize = imageContent.image.intactSize
            } else if let stickerContent = message.content as? StickerContent {
                imageSize = CGSize(width: Double(stickerContent.width), height: Double(stickerContent.height))
            }
            let size = ImageCons.calculateImgViewSize(size: imageSize)
            self.updateImageConstraints(size: size)
            if ImageCons.showStripeImage(originSize: imageSize) {
                showTip(BundleI18n.LarkForward.Lark_Groups_PostPhotostrip)
            }
        }
    }

    func showTip(_ tip: String) {
        tipView.text = tip
        let paddingSize = CGSize(width: 6 * 2, height: 2 * 2)
        let sizeToFit = CGSize(width: imgView.bounds.size.width - paddingSize.width,
                      height: imgView.bounds.size.height - paddingSize.height)
        let tipViewFitSize = tipView.sizeThatFits(sizeToFit)
        let sizeWithPadding = CGSize(width: tipViewFitSize.width + paddingSize.width,
               height: tipViewFitSize.height + paddingSize.height)
        let boundsWithPadding = CGRect(origin: .zero, size: sizeWithPadding)
        let path = UIBezierPath(roundedRect: boundsWithPadding,
                                byRoundingCorners: .topLeft,
                                cornerRadii: CGSize(width: 2, height: 2))
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = boundsWithPadding
        shapeLayer.path = path.cgPath
        tipView.layer.mask = shapeLayer
        imgView.addSubview(tipView)
        tipView.snp.remakeConstraints({ (make) in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(sizeWithPadding.width)
            make.height.equalTo(sizeWithPadding.height)
        })
    }

    func updateImageConstraints(size: CGSize) {
        if size.width < (ImageCons.cornerRadius * 2) || size.height < (ImageCons.cornerRadius * 2) {
            imgView.layer.cornerRadius = 0
        }
        imgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    func setImage(_ imgView: UIImageView, image: UIImage?) {
        let setImageCompletion: ImageRequestCompletion = { [weak self, weak imgView] result in
            guard let imgView = imgView else { return }
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                if let image = self.image {
                    return
                }
                guard let resultImage = imageResult.image else { return }
                print("Image width: \(resultImage.size.width),height: \(resultImage.size.height)")
            case .failure:
                imgView.image = Resources.imageDownloadFailed
                imgView.contentMode = .center
                imgView.backgroundColor = .white
            default:
                break
            }
        }
        if let content = message.content as? ImageContent {
            if let image = image {
                /// 如果有 UIImage 会优先使用，不再从网络/缓存中取
                imgView.bt.setLarkImage(with: .default(key: ""), placeholder: image)
                return
            }
            let imageSet = ImageItemSet.transform(imageSet: content.image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            let useOrigin = imageSet.isOriginKey(key: key)
            imgView.bt.setLarkImage(with: .default(key: key),
                                    placeholder: placeholder,
                                    trackStart: {
                                        TrackInfo(scene: .Chat, isOrigin: useOrigin, fromType: .image)
                                    },
                                    completion: setImageCompletion)
        } else if let content = message.content as? StickerContent {
            imgView.bt.setLarkImage(with: .sticker(key: content.key,
                                                   stickerSetID:
                                                    content.stickerSetID),
                                    trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                    },
                                    completion: setImageCompletion)
        }
    }
}

final class ForwardNewVideoConfirmFooter: BaseTapForwardConfirmFooter {
    var message: Message
    var hasPermissionPreview: Bool
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var imgView: ByteImageView = {
        let imgView = ByteImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = ImageCons.cornerRadius
        imgView.layer.masksToBounds = true
        return imgView
    }()

    private lazy var noPermissionPreviewLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N600
        let title = "\(BundleI18n.LarkForward.Lark_Legacy_MediaMessageHolder) \(BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button)"
        label.text = title
        return label
    }()

    private lazy var playView: UIImageView = {
        let imageView = UIImageView(image: Resources.forwardPlay)
        return imageView
    }()

    private lazy var timeView: ForwardVideoTimeView = {
        let timeView = ForwardVideoTimeView()
        return timeView
    }()

    init(message: Message,
         hasPermissionPreview: Bool) {
        self.message = message
        self.hasPermissionPreview = hasPermissionPreview
        super.init()
        if !hasPermissionPreview {
            self.backgroundColor = UIColor.ud.bgFloatOverlay
            self.layer.cornerRadius = 5
            self.addSubview(noPermissionPreviewLable)
            noPermissionPreviewLable.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            }
        } else {
            self.backgroundColor = .clear
            self.layer.cornerRadius = 0
            self.addSubview(imgView)
            imgView.addSubview(playView)
            imgView.addSubview(timeView)
            playView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 36, height: 36))
            }
            timeView.snp.makeConstraints { (maker) in
                maker.height.equalTo(18)
                maker.right.bottom.equalToSuperview().offset(-8)
            }
            if let content = message.content as? MediaContent {
                setImage(imgView, content: content)
                timeView.setDuration(content.duration)
            }
            guard let mediaContent = message.content as? MediaContent else { return }
            let size = ImageCons.calculateImgViewSize(size: mediaContent.image.intactSize)
            self.updateImageConstraints(size: size)
        }
    }

    func updateImageConstraints(size: CGSize) {
        if size.width < ImageCons.cornerRadius || size.height < ImageCons.cornerRadius {
            imgView.layer.cornerRadius = 0
        }
        imgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    private func setImage(_ imageView: UIImageView, content: MediaContent) {
        let setImageCompletion: ImageRequestCompletion = { [weak self, weak imgView] result in
            guard let imgView = imgView else { return }
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                guard let resultImage = imageResult.image else { return }
                print("Media width: \(resultImage.size.width),height: \(resultImage.size.height)")
            case .failure:
                imgView.image = Resources.imageDownloadFailed
                imgView.contentMode = .center
                imgView.backgroundColor = .white
            default:
                break
            }
        }
        let imageSet = ImageItemSet.transform(imageSet: content.image)
        let key = imageSet.generateVideoMessageKey(forceOrigin: false)
        let placeholder = imageSet.inlinePreview
        imageView.bt.setLarkImage(with: .default(key: key), placeholder: placeholder, trackStart: {
            return TrackInfo(scene: .Chat, fromType: .media)
        }, completion: setImageCompletion)
    }
}

final class ForwardNewLocationMessageConfirmFooter: BaseTapForwardConfirmFooter {
    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, modelService: ModelService,
         previewFg: Bool = false) {
        self.message = message
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        if previewFg {
            self.addSubview(nextImageView)
            nextImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.width.equalTo(7)
                make.height.equalTo(12)
            }
        }
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: previewFg ? 32 : 10))
        }
        if let content = message.content as? LocationContent {
            let title = BundleI18n.LarkForward.Lark_Chat_MessageReplyStatusLocation(content.location.name)
            let attributedString = NSMutableAttributedString(
                string: title,
                attributes: [.kern: 0.0])
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.N900,
                                          range: NSRange(location: 0, length: attributedString.length))
            label.attributedText = attributedString
        }
    }
}

final class ForwardNewFileAndFolderMessageConfirmFooter: BaseTapForwardConfirmFooter {
    private var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, hasPermissionPreview: Bool) {
        self.message = message
        super.init()

        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        let imgView = UIImageView()
        let noPermissionMsg = BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button
        imgView.contentMode = .scaleAspectFit
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.left.top.equalTo(10)
            make.width.equalTo((40))
            make.height.equalTo(40)
        }

        let nameAndSizeContainer: UIView = UIView()
        nameAndSizeContainer.backgroundColor = UIColor.clear
        self.addSubview(nameAndSizeContainer)
        if hasPermissionPreview {
            nameAndSizeContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalTo(imgView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-10)
                make.bottom.equalToSuperview().offset(-10)
            }
        } else {
            nameAndSizeContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(11)
                make.bottom.equalToSuperview().offset(-11)
                make.left.equalTo(imgView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-10)
            }
        }

        let nameLabel = UILabel()
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.N900
        nameAndSizeContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        let sizeLabel = UILabel()
        sizeLabel.numberOfLines = 1
        sizeLabel.font = UIFont.systemFont(ofSize: 12)
        sizeLabel.textColor = UIColor.ud.N500
        nameAndSizeContainer.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        if let content = message.content as? FileContent {
            nameLabel.text = content.name
            imgView.image = LarkCoreUtils.fileLadderIcon(with: content.name)
            let size = ByteCountFormatter.string(fromByteCount: content.size, countStyle: .binary)
            let sizeString = hasPermissionPreview ? "\(size)" : noPermissionMsg
            sizeLabel.text = sizeString
            return
        }

        if let content = message.content as? FolderContent {
            nameLabel.text = content.name
            imgView.image = Resources.imageForwardFolder
            let size = ByteCountFormatter.string(fromByteCount: content.size, countStyle: .binary)
            let sizeString = hasPermissionPreview ? "\(size)" : noPermissionMsg
            sizeLabel.text = sizeString
            return
        }
    }
}

final class ForwardNewUserCardMessageConfirmFooter: NewBaseForwardConfirmFooter {
    private let avatarSize: CGFloat = 40
    private lazy var avatarView: BizAvatar = {
        let avatarView = BizAvatar()
        return avatarView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.N900
        return titleLabel
    }()

    init(message: Message) {
        super.init()
        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }

        if let content = message.content as? ShareUserCardContent, let chatter = content.chatter {
            avatarView.setAvatarByIdentifier(chatter.id, avatarKey: chatter.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
            titleLabel.text = BundleI18n.LarkForward.Lark_Legacy_PreviewUserCard(chatter.localizedName)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ForwardNewShareGroupConfirmFooter: NewBaseForwardConfirmFooter {
    var message: Message
    let modelService: ModelService
    private let avatarSize: CGFloat = 40

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var avatarView: BizAvatar = {
        let imgView = BizAvatar()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        return imgView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N900
        return label
    }()

    init(message: Message, modelService: ModelService) {
        self.message = message
        self.modelService = modelService
        super.init()

        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }

        setImage(avatarView)
        setText(nameLabel)
    }

    func setText(_ label: UILabel) {
        label.text = modelService.messageSummerize(message)
    }

    func setImage(_ imgView: BizAvatar) {
       if let content = message.content as? ShareGroupChatContent, let avatarKey = content.chat?.avatarKey, let entityId = content.chat?.id {
           imgView.setAvatarByIdentifier(entityId, avatarKey: avatarKey, scene: .Chat, avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
    }
}

public final class ForwardVideoTimeView: UIView {
    private let videoIcon = UIImageView()
    private let timeLabel = UILabel()

    public init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.7)
        self.layer.cornerRadius = 9

        videoIcon.image = Resources.small_video_icon
        self.addSubview(videoIcon)
        videoIcon.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(4)
            maker.width.height.equalTo(10)
        }

        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(videoIcon.snp.right).offset(3)
            maker.right.equalToSuperview().offset(-4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setDuration(_ duration: Int32) {
        // 服务器返回的是毫秒，所以先除以1000
        var time = duration / 1000
        let second = time % 60
        time /= 60
        let minute = time % 60
        time /= 60
        let value: String
        if time > 0 {
            value = String(format: "%02d:%02d:%02d", time, minute, second)
        } else {
            value = String(format: "%02d:%02d", minute, second)
        }
        self.timeLabel.text = value
    }
}
