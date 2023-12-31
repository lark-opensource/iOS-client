//
//  GenericAvatarView.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/9.
//

import UIKit
import FigmaKit
import LarkBizAvatar
import AvatarComponent
import RustPB
import ByteWebImage
import UniverseDesignColor
import LKCommonsLogging
import LarkBaseKeyboard

enum VariousAvatarType {
    case angularGradient(UInt32, UInt32, String, NSAttributedString?, String) // startColor, endColor, key, content, fsUnit
    case border(UInt32, UInt32, NSAttributedString?)
    case image(UIImage)
    case upload(UIImage) /// TODO: 李洛斌 这个枚举是否合适
    case avatarKey(entityId: String, key: String)
    case jointImage(UIImage)
    func canCustomText() -> Bool {
        switch self {
        case .angularGradient(_, _, _, _, _):
            return true
        case .border(_, _, _):
            return true
        case .image, .upload, .avatarKey, .jointImage:
            return false
        }
    }
    func getTextColor() -> UIColor? {
        switch self {
        case .angularGradient(_, _, _, _, _):
            return UIColor.ud.primaryOnPrimaryFill
        case .border(let start, let end, _):
            return ColorCalculator.middleColorForm(UIColor.ud.rgb(start), to: UIColor.ud.rgb(end))
        case .image, .upload, .avatarKey, .jointImage:
            return nil
        }
    }
    func updateText(withText text: NSAttributedString?) -> VariousAvatarType {
        switch self {
        case .angularGradient(let startColor, let endColor, let key, _, let fsUnit):
            return .angularGradient(startColor, endColor, key, text, fsUnit)
        case .border(let startColor, let endColor, _):
            return .border(startColor, endColor, text)
        default:
            return self
        }
    }
}

// 展示头像的基类view
class GenericAvatarView: UIView {
    private let logger = Logger.log(GenericAvatarView.self, category: "LarkSetting.groupAvatar.GenericAvatarView")
    static let defaultAvatarSize: CGSize = CGSize(width: 120, height: 120)
    lazy var imageManager: AvatarImageCacheManager = AvatarImageCacheManager()
    let imageView = BizAvatar()
    /// 默认图片
    let defaultImage: UIImage
    /// 文字展示
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    lazy var angularGradientView: ByteImageView = {
        let gradientView = ByteImageView()
        gradientView.layer.masksToBounds = true
        return gradientView
    }()

    lazy var borderGradientView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: self.avatarSize.width, height: self.avatarSize.height)
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        view.layer.cornerRadius = self.avatarSize.width / 2.0
        view.layer.borderWidth = 2
        view.layer.masksToBounds = true
        return view
    }()

    /// 头像数据
    var avatarType: VariousAvatarType?
    var avatarSize: CGSize
    init(defaultImage: UIImage = Resources.newStyle_color_icon, avatarSize: CGSize = GenericAvatarView.defaultAvatarSize) {
        self.defaultImage = defaultImage
        self.avatarSize = avatarSize
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.layer.cornerRadius = self.avatarSize.width / 2.0
        self.addSubview(angularGradientView)
        self.addSubview(borderGradientView)
        self.addSubview(imageView)
        self.backgroundColor = .clear
        imageView.addSubview(textLabel)

        self.angularGradientView.isHidden = true
        self.borderGradientView.isHidden = true
        // 展示头像
        imageView.avatar.layer.masksToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.avatar.ud.removeMaskView()

        imageView.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview()
            maker.size.equalTo(self.avatarSize)
        }

        angularGradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        borderGradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.lessThanOrEqualToSuperview()
        }
    }

    func setAvatar(_ type: VariousAvatarType) {
        self.avatarType = type
        switch type {
        case .angularGradient(_, _, let key, let text, let fsUnit):
            self.angularGradientView.layer.cornerRadius = self.avatarSize.width / 2.0
            self.angularGradientView.image = nil
            var passThrough = ImagePassThrough()
            passThrough.key = key
            passThrough.fsUnit = fsUnit
            self.angularGradientView.bt.setLarkImage(.default(key: key), passThrough: passThrough, completion: { [weak self] imageResult in
                if case .failure(let error) = imageResult {
                    self?.logger.error("angularGradientView.bt.setLarkImage error item.key \(key)", error: error)
                }
            })
            self.angularGradientView.isHidden = false
            self.borderGradientView.isHidden = true
            self.updateToDefaultImageIfNeed(UIColor.ud.primaryOnPrimaryFill, text: text)
            self.textLabel.attributedText = text
        case .border(let startColor, let endColor, let text):
            let color: UIColor? = .fromGradientWithDirection(.leftToRight,
                                                             frame: CGRect(origin: .zero, size: self.avatarSize),
                                                             colors: [UIColor.ud.rgb(startColor), UIColor.ud.rgb(endColor)])

            self.borderGradientView.layer.borderColor = color?.cgColor
            self.angularGradientView.isHidden = true
            self.borderGradientView.isHidden = false
            self.updateToDefaultImageIfNeed(type.getTextColor() ?? UIColor.ud.rgb(startColor), text: text)
            self.textLabel.attributedText = text
        case .image(let image):
            self.imageView.setCustomLocalImage(image)
            self.clearColorAndText()
        case .upload(let image):
            self.imageView.setCustomLocalImage(image)
            self.clearColorAndText()
        case .jointImage(let image):
            self.imageView.setCustomLocalImage(image)
            self.clearColorAndText()
        case .avatarKey(entityId: let entityId, key: let key):
            self.imageView.setCustomRemoteKey(entityId, key: key)
            self.clearColorAndText()
        }
    }

    private func updateToDefaultImageIfNeed(_ color: UIColor, text: NSAttributedString?) {
        if let str = text, str.length > 0 {
            self.imageView.setCustomLocalImage(nil)
            return
        }
        let image = self.imageManager.getColorImageFor(originImage: defaultImage, color: color)
        self.imageView.setCustomLocalImage(image,
                                           mode: .center)
    }

    func clearColorAndText() {
        self.angularGradientView.isHidden = true
        self.borderGradientView.isHidden = true
        self.textLabel.attributedText = NSAttributedString(string: "")
    }

    func updateText(_ text: NSAttributedString) {
        guard let type = avatarType, type.canCustomText() else {
            self.textLabel.attributedText = NSAttributedString(string: "")
            return
        }
        self.textLabel.attributedText = text
        if let avatar = self.avatarType?.updateText(withText: text) {
            self.avatarType = avatar
        }
        if text.length == 0, let color = type.getTextColor() {
            self.updateToDefaultImageIfNeed(color, text: text)
        } else {
            self.imageView.setCustomLocalImage(nil)
        }
    }

    func displayText() -> NSAttributedString {
        return self.textLabel.attributedText ?? NSAttributedString(string: "")
    }

    /// 获取当前用户设置的群meta信息
    func avatarMeta() -> RustPB.Basic_V1_AvatarMeta {
        var meta = RustPB.Basic_V1_AvatarMeta()
        guard let type = self.avatarType else {
            assertionFailure("error to get current avatarType")
            return meta
        }
        func updateMeta(styleType: RustPB.Basic_V1_AvatarMeta.AvatarStyleType,
                        startColor: UInt32,
                        endColor: UInt32,
                        attributedText: NSAttributedString) {
            meta.type = attributedText.length == 0 ? .random : .words
            meta.styleType = styleType
            meta.startColor = Int32(startColor)
            meta.endColor = Int32(endColor)
            meta.text = EmotionTransformer.retransformContentToString(attributedText).subStrToCount(14).string
            if attributedText.length != 0, let richText = RichTextTransformKit.transformStringToRichText(string: attributedText) {
                meta.richText = richText
            }
        }
        switch type {
        case .angularGradient(let uIColor, let uIColor2, _, _, _):
            updateMeta(styleType: .fill, startColor: uIColor, endColor: uIColor2, attributedText: self.displayText())
        case .border(let uIColor, let uIColor2, _):
            updateMeta(styleType: .border, startColor: uIColor, endColor: uIColor2, attributedText: self.displayText())
        case .upload(_):
            meta.type = .upload
        case .image(_):
            break
        case .avatarKey(_, _):
            break
        case .jointImage(_):
            meta.type = .collage
        }
        return meta
    }

    func getAvatarImage() -> UIImage {
        if case .image(let image) = avatarType {
            return image
        } else if case .upload(let image) = avatarType {
            return image
        } else if case .jointImage(let image) = avatarType {
            return image
        } else {
            return self.lu.screenshot() ?? UIImage()
        }
    }

}

internal extension BizAvatar {
    func setCustomLocalImage(_ image: UIImage?,
                             mode: UIView.ContentMode = .scaleAspectFit,
                             backgroundColor: UIColor = UIColor.clear) {
        var config = AvatarComponentUIConfig(backgroundColor: backgroundColor)
        config.contentMode = mode
        self.setAvatarByIdentifier("", avatarKey: "")
        self.image = image
        self.setAvatarUIConfig(config)
    }

    func setCustomRemoteKey(_ id: String, key: String) {
        self.image = nil
        var config = AvatarComponentUIConfig(backgroundColor: UIColor.clear)
        config.contentMode = .scaleAspectFill
        self.setAvatarByIdentifier(id, avatarKey: key)
        self.setAvatarUIConfig(config)
    }
}
