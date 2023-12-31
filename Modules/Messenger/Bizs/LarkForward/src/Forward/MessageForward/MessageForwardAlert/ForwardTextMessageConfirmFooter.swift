//
//  ForwardTextMessageConfirmFooter.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import Foundation
import LarkModel
import LarkCore
import ByteWebImage
import LarkMessengerInterface
import LarkAudio
import LarkAudioKit
import LarkAudioView
import LarkContainer
import SnapKit
import RxSwift
import LarkBizAvatar
import UniverseDesignColor
import RustPB
import UIKit
import LarkBaseKeyboard

// nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发内容预览能力组件内置时优化该逻辑
final class ForwardTextMessageConfirmFooter: BaseForwardConfirmFooter {
  var message: Message

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(message: Message, modelService: ModelService) {
    self.message = message
    super.init()

    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.numberOfLines = 4
    label.lineBreakMode = .byTruncatingTail
    self.addSubview(label)
    label.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }
    label.text = modelService.messageSummerize(message)
  }
}

final class ForwardCardMessageConfirmFooter: BaseTapForwardConfirmFooter {
    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message,
         previewFg: Bool = false) {
        self.message = message
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
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
        if let content = message.content as? CardContent {
            let title = "\(BundleI18n.LarkForward.Lark_Legacy_MessagePoCard) " + content.header.title
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

final class ForwardThreadMessageConfirmFooter: BaseTapForwardConfirmFooter {
    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message,
         mergeForwardContentService: MergeForwardContentService,
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
        if let content = message.content as? MergeForwardContent,
           content.isFromPrivateTopic {
            let title = "\(BundleI18n.LarkForward.Lark_IM_TopicWithBrackets_Text) " + mergeForwardContentService.getMergeForwardTitleFromContent(content)
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

final class ForwardThreadDetailConfirmFooter: BaseTapForwardConfirmFooter {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(posterName: String, previewFg: Bool = false) {
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
        let attributedString = NSMutableAttributedString(
            string: posterName,
            attributes: [.kern: 0.0])
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.ud.N900,
                                      range: NSRange(location: 0, length: attributedString.length))
        label.attributedText = attributedString
    }
}

final class ForwardUnknownMessageConfirmFooter: BaseForwardConfirmFooter {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init() {
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N600
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        let title = BundleI18n.LarkForward.Lark_IM_UnableToPreviewMessageTypeForwarding_Text
        label.text = title
    }
}

final class ForwardMessageBurnConfirmFooter: BaseForwardConfirmFooter {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init() {
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.N600
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        let title = BundleI18n.LarkForward.Lark_IM_UnablePreviewContentContainsMessageSelfDestruct_Toast
        label.text = title
    }
}

final class ForwardOldLocationMessageConfirmFooter: BaseForwardConfirmFooter {
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
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        if let content = message.content as? LocationContent {
            let title = BundleI18n.LarkForward.Lark_Chat_MessageReplyStatusLocation(content.location.name)
            let attributedString = NSMutableAttributedString(
                string: title,
                attributes: [.kern: 0.0])
            attributedString.addAttribute(
                .foregroundColor,
                value: UIColor.ud.colorfulBlue,
                range: NSRange(location: 0, length: (title.count - content.location.name.count))
            )
            label.attributedText = attributedString
        }
    }
}

final class ForwardImageMessageConfirmFooter: BaseForwardConfirmFooter {
    var message: Message
    let modelService: ModelService
    private let avatarSize: CGFloat = 64

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message,
         modelService: ModelService,
         image: UIImage?,
         hasPermissionPreview: Bool) {
        self.message = message
        self.modelService = modelService
        super.init()
        var imgView: UIImageView
        if !hasPermissionPreview {
            imgView = NoPermissonSmallView()
        } else {
            imgView = UIImageView()
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            setImage(imgView, image: image)
        }
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        if !hasPermissionPreview {
            label.numberOfLines = 3
            label.font = UIFont.systemFont(ofSize: 12)
            label.snp.makeConstraints { (make) in
                make.top.equalTo(imgView.snp.top).offset(4)
                make.left.equalTo(imgView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-10)
                make.bottom.lessThanOrEqualToSuperview().offset(-30)
            }
            let noPermissionLabel = UILabel()
            noPermissionLabel.text = BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button
            noPermissionLabel.font = UIFont.systemFont(ofSize: 12)
            noPermissionLabel.textColor = UIColor.ud.textPlaceholder
            noPermissionLabel.numberOfLines = 4
            noPermissionLabel.lineBreakMode = .byTruncatingTail
            self.addSubview(noPermissionLabel)
            noPermissionLabel.snp.makeConstraints { make in
                make.top.equalTo(label.snp.top).offset(40)
                make.left.equalTo(label.snp.left)
                make.right.equalTo(label.snp.right).offset(-10)
                make.bottom.lessThanOrEqualToSuperview().offset(-10)
            }
        } else {
            label.numberOfLines = 4
            label.font = UIFont.systemFont(ofSize: 14)
            label.snp.makeConstraints { (make) in
                make.top.equalTo(imgView.snp.top).offset(4)
                make.left.equalTo(imgView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-10)
                make.bottom.lessThanOrEqualToSuperview().offset(-10)
            }
        }
        setText(label)
    }

    func setText(_ label: UILabel) {
        if message.type == .image {
            label.text = BundleI18n.LarkForward.Lark_Legacy_ImageMessageHolder
        } else if message.type == .sticker {
            if let content = message.content as? StickerContent, content.transformToSticker().mode == .meme {
                label.text = content.transformToSticker().description_p
            } else {
                label.text = BundleI18n.LarkForward.Lark_Legacy_StickerHolder
            }
        } else {
            label.text = modelService.messageSummerize(message)
        }
    }

    func setImage(_ imgView: UIImageView, image: UIImage?) {
        // UIImage: view上贴的图片
        // ImageRequestResult: 请求key的结果
        let setImageCompletion: (UIImage?, ImageRequestResult) -> Void = { image, result in
            switch result {
            case .failure:
                if image == nil {
                    imgView.image = Resources.imageDownloadFailed
                    imgView.contentMode = .center
                    imgView.backgroundColor = .white
                }
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
                                    completion: { result in
                                        setImageCompletion(placeholder, result)
                                    })
        } else if let content = message.content as? ShareGroupChatContent, let avatarKey = content.chat?.avatarKey, let entityId = content.chat?.id {
            imgView.bt.setLarkImage(with: .avatar(key: avatarKey, entityID: entityId, params: .init(sizeType: .size(avatarSize))),
                                    trackStart: {
                                         TrackInfo(scene: .Chat, fromType: .avatar)
                                    })
        } else if let content = message.content as? StickerContent {
            imgView.bt.setLarkImage(with: .sticker(key: content.key,
                                                   stickerSetID:
                                                    content.stickerSetID),
                                    trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                    })
        }
    }
}

final class ForwardShareGroupConfirmFooter: BaseForwardConfirmFooter {
    var message: Message
    let modelService: ModelService
    private let avatarSize: CGFloat = 64

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
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
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
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
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

final class ForwardRawImageMessageConfirmFooter: BaseForwardConfirmFooter {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(image: UIImage) {
        super.init()

        let imgView = UIImageView(image: image)
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let label = UILabel()
        label.text = BundleI18n.LarkForward.Lark_Legacy_ImageMessageHolder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
    }
}

final class ForwardVideoMessageConfirmFooter: ForwardVideoConfirmFooter {
    var message: Message
    let modelService: ModelService
    var hasPermissionPreview: Bool
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, modelService: ModelService, hasPermissionPreview: Bool) {
        self.message = message
        self.modelService = modelService
        self.hasPermissionPreview = hasPermissionPreview
        super.init(length: 0, image: nil)
        if !hasPermissionPreview {
            let noPermisionLayer = NoPermissonSmallView()
            self.addSubview(noPermisionLayer)
            noPermisionLayer.snp.makeConstraints { make in
                make.edges.equalTo(self.imageView.snp.edges)
            }
            self.imageView.isHidden = true
            titleLabel.font = UIFont.systemFont(ofSize: 12)
            sizeLabel.text = BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button
        }
        if let content = message.content as? MediaContent {
            setImage(imageView, content: content)
            setSize(sizeLabel, content: content)
        }
    }

    private func setImage(_ imageView: UIImageView, content: MediaContent) {
        let imageSet = ImageItemSet.transform(imageSet: content.image)
        let key = imageSet.generateVideoMessageKey(forceOrigin: false)
        let placeholder = imageSet.inlinePreview
        imageView.bt.setLarkImage(with: .default(key: key), placeholder: placeholder, trackStart: {
            return TrackInfo(scene: .Chat, fromType: .media)
        })
    }

    private func setSize(_ label: UILabel, content: MediaContent) {
        var size = Double(content.size)
        let units = ["B", "KB", "MB", "GB"]
        var index = 0
        for i in 0..<units.count {
            if size > 1024 {
                size /= 1024
            } else {
                index = i
                break
            }
        }
        label.text = String(format: "%0.2f%@", size, units[index])
    }
}

class ForwardVideoConfirmFooter: BaseForwardConfirmFooter {
    let imageView = UIImageView()
    let sizeLabel = UILabel()
    let titleLabel = UILabel()
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(length: Int = 0, image: UIImage? = nil) {
        super.init()

        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let coverView = UIView()
        coverView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.1)
        imageView.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let iconImageView = UIImageView(image: Resources.small_video_icon)
        imageView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(12)
            maker.right.equalToSuperview().offset(-5)
            maker.bottom.equalToSuperview().offset(-3)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.numberOfLines = 4
        titleLabel.lineBreakMode = .byTruncatingTail
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.top).offset(4)
            make.left.equalTo(imageView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }

        sizeLabel.font = UIFont.systemFont(ofSize: 12)
        sizeLabel.textColor = UIColor.ud.N500
        self.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(58)
            maker.left.equalToSuperview().offset(84)
            maker.right.lessThanOrEqualToSuperview().offset(-10)
        }

        titleLabel.text = BundleI18n.LarkForward.Lark_Legacy_MediaMessageHolder
        setSize(sizeLabel, length: length)
    }

    private func setSize(_ label: UILabel, length: Int) {
        var size = Double(length)
        let units = ["B", "KB", "MB", "GB"]
        var index = 0
        for i in 0..<units.count {
            if size > 1024 {
                size /= 1024
            } else {
                index = i
                break
            }
        }
        label.text = String(format: "%0.2f%@", size, units[index])
    }
}

final class ForwardAudioMessageConfirmFooter: BaseForwardConfirmFooter, UserResolverWrapper {
    private var message: Message

    private var audioContent: AudioContent? {
        return message.content as? AudioContent
    }

    private var audioViewInset: Int = 10
    private let newStyle: Bool

    private var disposeBag: DisposeBag = DisposeBag()
    let userResolver: UserResolver

    @ScopedInjectedLazy var audioPlayer: AudioPlayMediator?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message,
         newStyle: Bool = false,
         userResolver: UserResolver) {
        self.message = message
        self.newStyle = newStyle
        self.userResolver = userResolver
        super.init()
        self.addSubview(self.audioView)
        let verticalInterval = newStyle ? 0 : audioViewInset
        self.audioView.snp.makeConstraints { (maker) in
            maker.top.left.equalTo(verticalInterval)
            maker.bottom.right.equalTo(-verticalInterval)
        }
        self.updateUI()
        self.observeAudioPlayStatus()
        if newStyle {
            self.backgroundColor = .clear
        }
    }

    deinit {
        self.audioPlayer?.stopPlayingAudio()
    }

    private lazy var audioView: AudioView = {
        let view = AudioView(frame: .zero)
        let background = newStyle ? UIColor.ud.N200 : UIColor.ud.N300
        view.colorConfig = AudioView.ColorConfig(
            panColorConfig: AudioView.PanColorConfig(
                background: UIColor.ud.primaryOnPrimaryFill,
                readyBorder: nil,
                playBorder: nil
            ),
            stateColorConfig: AudioView.StateColorConfig(
                background: UIColor.ud.N00 & UIColor.ud.N1000,
                foreground: UIColor.ud.N700 & UIColor.ud.N500
            ),
            background: background,
            lineBackground: UIColor.ud.N700.withAlphaComponent(0.3),
            processLineBackground: UIColor.ud.N700,
            timeLabelText: UIColor.ud.N700,
            invalidTimeLabelText: nil
        )
        view.newSkin = true
        view.clickStateBtnAction = { [weak self] in
            self?.stateButtonClicked()
        }
        view.panAction = { [weak self] (state, process) in
            guard let self = self else { return }
            guard let content = self.audioContent else {
                return
            }
            var status: AudioPlayMediatorStatus
            if state != .end {
                // 拖动中暂停播放
                status = .pause(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * process / 1000,
                    duration: TimeInterval(content.duration) / 1000)
                )
            } else {
                // 停止拖动播放
                status = .playing(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * process / 1000,
                    duration: TimeInterval(content.duration) / 1000)
                )
            }
            self.audioPlayer?.updateStatus(status)
        }
        return view
    }()

    private func stateButtonClicked() {
        guard let content = self.audioContent,
              let audioPlayer = self.audioPlayer
        else {
            return
        }
        let key = content.key
        if key.isEmpty {
            return
        }
        if audioPlayer.isPlaying(key: key) {
            audioPlayer.pausePlayingAudio()
        } else {
            audioPlayer.playAudioWith(keys: [.init(key, content.authToken)], downloadFileScene: .chat, from: self.window)
        }
    }

    private func updateUI() {
        guard let content = self.audioContent,
              let audioPlayer = self.audioPlayer
        else {
            return
        }
        let key = content.key
        var state: AudioView.State = .ready
        switch audioPlayer.status {
        case .default:
            break
        case let .pause(progress):
            if progress.key == key {
                if self.audioView.isDraging {
                    state = .draging((progress.key == key) ? progress.current : 0)
                } else {
                    state = .pause((progress.key == key) ? progress.current : 0)
                }
            }
        case let .playing(progress):
            if progress.key == key {
                state = .playing((progress.key == key) ? progress.current : 0)
            }
        case let .loading(audioKey):
            if audioKey == key {
                state = .loading(0)
            }
        @unknown default:
            break
        }

        let time = TimeInterval(content.duration) / 1000
        self.audioView.set(
            key: key,
            time: time,
            state: state,
            text: "",
            style: .dark,
            isAudioRecognizeFinish: true,
            isValid: true)
    }

    private func observeAudioPlayStatus() {
        guard let content = self.audioContent,
              let audioPlayer = self.audioPlayer,
              !content.key.isEmpty else {
            return
        }
        audioPlayer.statusSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.updateUI()
            }).disposed(by: self.disposeBag)
    }
}

final class ForwardFileAndFolderMessageConfirmFooter: BaseForwardConfirmFooter {
    private var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, hasPermissionPreview: Bool) {
        self.message = message
        super.init()
        let imgView = UIImageView()
        let noPermissionMsg = BundleI18n.LarkForward.Lark_IM_UnableToPreview_Button
        imgView.contentMode = .scaleAspectFit
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.equalTo((64))
            make.height.equalTo(64)
            make.left.top.equalTo(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        let nameAndSizeContainer: UIView = UIView()
        nameAndSizeContainer.backgroundColor = UIColor.clear
        self.addSubview(nameAndSizeContainer)
        if hasPermissionPreview {
            nameAndSizeContainer.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(imgView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-8)
            }
        } else {
            nameAndSizeContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(11)
                make.bottom.equalToSuperview().offset(-11)
                make.left.equalTo(imgView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-8)
            }
        }

        let nameLabel = UILabel()
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 14)
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
            let sizeString = hasPermissionPreview ? "(\(size))" : noPermissionMsg
            sizeLabel.text = sizeString
            return
        }

        if let content = message.content as? FolderContent {
            nameLabel.text = content.name
            imgView.image = Resources.imageForwardFolder
            let size = ByteCountFormatter.string(fromByteCount: content.size, countStyle: .binary)
            let sizeString = hasPermissionPreview ? "(\(size))" : noPermissionMsg
            sizeLabel.text = sizeString
            return
        }
    }
}

final class ForwardFileConfirmFooter: BaseTapForwardConfirmFooter {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(content: ForwardFileAlertContent) {
        super.init()
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.equalTo((64))
            make.height.equalTo(64)
            make.left.top.equalTo(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        let nameAndSizeContainer: UIView = UIView()
        nameAndSizeContainer.backgroundColor = UIColor.clear
        self.addSubview(nameAndSizeContainer)
        nameAndSizeContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(imgView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
        }

        let nameLabel = UILabel()
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 14)
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

        nameLabel.text = content.fileName
        imgView.image = LarkCoreUtils.fileLadderIcon(with: content.fileName)
        let size = ByteCountFormatter.string(fromByteCount: content.fileSize, countStyle: .binary)
        let sizeString = "(\(size))"
        sizeLabel.text = sizeString
    }
}

final class ForwardOldPostMessageConfirmFooter: BaseForwardConfirmFooter {
    var message: Message

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: Message, modelService: ModelService) {
        self.message = message
        super.init()
        let imgView = UIImageView()
        imgView.image = Resources.post_share
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }

        let makerTitleLabel: () -> UILabel = {
            let titleLabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            titleLabel.numberOfLines = 1
            titleLabel.lineBreakMode = .byTruncatingTail
            self.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(imgView.snp.top).offset(4)
                make.left.equalTo(imgView.snp.right).offset(6)
                make.right.equalToSuperview().offset(-10)
            }
            return titleLabel
        }

        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.numberOfLines = 2
        contentLabel.textColor = UIColor.ud.N500
        contentLabel.lineBreakMode = .byTruncatingTail
        self.addSubview(contentLabel)

        if let content = message.content as? PostContent {
            // 如果包含代码块
            if CodeInputHandler.richTextContainsCode(richText: content.richText) {
                // 把代码块替换为文本[代码块]
                var copyContent = content
                copyContent.richText = copyContent.richText.lc.convertText(tags: [.codeBlockV2])
                // copy一份message，用copyMessage获取摘要
                let copyMessage = message.copy()
                copyMessage.content = copyContent
                // 这里应该用content.richText.lc.summerize()，用copyMessageSummerize是为了和之前逻辑保持一致
                contentLabel.text = modelService.copyMessageSummerize(copyMessage, selectType: .all, copyType: .message)
            } else {
                contentLabel.text = modelService.copyMessageSummerize(message, selectType: .all, copyType: .message)
            }

            if content.isUntitledPost {
                contentLabel.snp.makeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.left.equalTo(imgView.snp.right).offset(6)
                    make.right.equalToSuperview().offset(-10)
                }
            } else {
                let titleLabel = makerTitleLabel()
                titleLabel.text = content.title

                contentLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(titleLabel.snp.bottom).offset(10)
                    make.left.equalTo(titleLabel)
                    make.right.equalTo(titleLabel)
                }
            }
        }
    }
}

final class ForwardChatChooseMessageConfirmFooter: BaseForwardConfirmFooter {
    var message: String
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init(message: String, modelService: ModelService) {
        self.message = message
        super.init()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        label.text = message
    }
}

final class ForwardUserCardMessageConfirmFooter: BaseForwardConfirmFooter {
    private let avatarSize: CGFloat = 64
    init(message: Message) {
        super.init()

        let avatarView = BizAvatar()
        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.top.left.bottom.equalToSuperview().inset(10)
        }

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 4
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.N900
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
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

final class ForwardVideoChatMessageConfirmFooter: BaseForwardConfirmFooter {
    private var content: VChatMeetingCardContent

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(content: VChatMeetingCardContent) {
        self.content = content
        super.init()

        let iconWrapper = UIView(frame: .zero)
        iconWrapper.backgroundColor = UIColor.ud.colorfulYellow
        self.addSubview(iconWrapper)
        iconWrapper.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.width.height.equalTo(64)
        }
        let icon = UIImageView(image: Resources.videoChat)
        icon.backgroundColor = .clear
        iconWrapper.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }

        let topicLabel = UILabel(frame: .zero)
        topicLabel.font = .systemFont(ofSize: 14)
        topicLabel.textColor = UIColor.ud.N900
        topicLabel.numberOfLines = 2
        self.addSubview(topicLabel)
        topicLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconWrapper)
            make.leading.equalTo(iconWrapper.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        let displayTopic = content.meetingSource == .cardFromInterview ? BundleI18n.LarkForward.Lark_View_VideoInterviewNameBraces(content.topic) : content.topic
        topicLabel.text = displayTopic.isEmpty ? BundleI18n.LarkForward.Lark_View_ServerNoTitle : displayTopic

        let meetingID = UILabel(frame: .zero)
        meetingID.font = .systemFont(ofSize: 14)
        meetingID.numberOfLines = 1
        meetingID.textColor = UIColor.ud.N500
        self.addSubview(meetingID)
        meetingID.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(topicLabel)
            make.top.equalTo(topicLabel.snp.bottom).offset(4)
        }
        meetingID.text = "\(BundleI18n.LarkForward.Lark_View_MeetingIdColon)\(formatMeetNumber(with: content.meetNumber))"
    }

    private func formatMeetNumber(with meetNumber: String) -> String {
        if meetNumber.count == 9 {
            return meetNumber.substring(to: 3)
                + " " + meetNumber.substring(from: 3).substring(to: 3)
                + " " + meetNumber.substring(from: 6).substring(to: 3)
        } else {
            return meetNumber
        }
    }
}

final class NoPermissonSmallView: UIImageView {
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
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
}
