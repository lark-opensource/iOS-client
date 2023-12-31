//
//  ActivityRecordContentView.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/23.
//

import Foundation
import UniverseDesignColor
import LKRichView
import UniverseDesignBadge
import LarkBizAvatar
import LarkRichTextCore
import UniverseDesignFont
import LarkUIKit

struct ActivityRecordContentData {
    // 唯一id
    var guid: String

    var header: ActivityRecordContentHeaderData?

    var user: ReadableAvatarViewData
    // 内容
    var content: ActivityRecordMiddleContentData

    // 是否显示[展开]
    var showMore: Bool = true

    var footer: String

    // 元数据
    var metaData: Rust.ActivityRecord?
    // 缓存高度
    var itemHeight: CGFloat?
}

struct ActivityRecordImageData {
    var images = [Rust.ImageSet]()
    var imagesHeight: CGFloat?
}

struct ActivityRecordAttachmentData {
    var attachments = [DetailAttachmentContentCellData]()
    var attachmentFooter: DetailAttachmentFooterViewData?
    var attachmentsHeight: CGFloat?
}

extension ActivityRecordContentData {

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        var height = ActivityRecordContentView.Config.topPadding + ActivityRecordContentView.Config.bottomPadding
        if header != nil {
            // header 高度
            height += ActivityRecordContentView.Config.headerHeight
            // content top space
            height += ActivityRecordContentView.Config.largeSpace
        }
        // footer 高度
        height += ActivityRecordContentView.Config.middleSpace + ActivityRecordContentView.Config.footerHeight
        return height + displayContentHeight
    }

    var displayContentHeight: CGFloat {
        if showMore {
            return ActivityRecordContentView.Config.normalMaxHeight
        }
        return contentHeight
    }

    var shouldShowMore: Bool {
        return contentHeight > ActivityRecordContentView.Config.normalMaxHeight
    }

    var contentHeight: CGFloat {
        // 内容高度
        var contentHeight = 0.0
        // 高度
        contentHeight += content.text.preferredHeight
        // 九宫格图片高度
        if let imagesHeight = content.images.imagesHeight {
            contentHeight += ActivityRecordContentView.Config.middleSpace + imagesHeight
        }
        // 附件
        if let attachmentsHeight = content.attachments.attachmentsHeight {
            // 底部有space且DetailAttachment.bottomSpace 大于 Config.middleSpace 所以不需要额外添加
            contentHeight += attachmentsHeight
        }
        return ceil(contentHeight)
    }
}

/// 动态内容试图:
/// [
///   header
///   avtar middle
///   grid image
///   attach
///   footer
/// ]
final class ActivityRecordContentView: UIView {

    var viewData: ActivityRecordContentData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if let headerData = viewData.header {
                header.viewData = headerData
                header.isHidden = false
            } else {
                header.isHidden = true
            }
            user.viewData = viewData.user
            middle.viewData = viewData.content
            showMore.shouldShow = viewData.showMore
            footer.text = viewData.footer
            setNeedsLayout()
        }
    }

    private lazy var header = ActivityRecordContentHeader()
    private(set) lazy var user = ActivityRecordUserView()
    private(set) lazy var middle = ActivityRecordMiddleContentView()
    private(set) lazy var showMore = ActivityRecordShowMoreView()
    private lazy var footer = ActivityRecordContentFooter()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(header)
        addSubview(user)
        addSubview(middle)
        addSubview(showMore)
        addSubview(footer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxWidth = bounds.width - Config.leftPadding - Config.rightPadding
        if header.isHidden {
            header.frame = .zero
        } else {
            header.frame = CGRect(
                x: Config.leftPadding,
                y: Config.topPadding,
                width: maxWidth,
                height: Config.headerHeight
            )
        }
        user.frame = CGRect(
            x: Config.leftPadding,
            y: header.frame.maxY + Config.headerMiddleSpace,
            width: ActivityRecordUserView.Config.avatarSize.width,
            height: ActivityRecordUserView.Config.avatarSize.height
        )
        let maxMiddleWidth = maxWidth - ActivityRecordUserView.Config.avatarSize.width - Config.largeSpace
        let left = user.frame.maxX + Config.largeSpace
        var offsetY = header.isHidden ? Config.topPadding : header.frame.maxY + Config.largeSpace
        middle.frame = CGRect(
            x: left,
            y: offsetY,
            width: maxMiddleWidth,
            height: viewData?.displayContentHeight ?? 0
        )
        offsetY = middle.frame.maxY + Config.middleSpace

        if !showMore.isHidden {
            showMore.frame = CGRect(
                x: left,
                y: middle.frame.maxY - ActivityRecordShowMoreView.Config.height,
                width: maxMiddleWidth,
                height: ActivityRecordShowMoreView.Config.height
            )
        }

        footer.frame = CGRect(
            x: left,
            y: offsetY,
            width: maxMiddleWidth,
            height: Config.footerHeight
        )
    }
}

extension ActivityRecordContentView {

    struct Config {
        static let topPadding: CGFloat = 12.0
        static let bottomPadding: CGFloat = 12.0
        static let leftPadding: CGFloat = 16.0
        static let rightPadding: CGFloat = 16.0

        static let headerIconSize: CGSize = CGSize(width: 12.0, height: 12.0)
        static let headerIconTextSpace: CGFloat = 6.0
        static let headerHeight: CGFloat = 20.0

        static let headerMiddleSpace: CGFloat = 8.0

        static let largeSpace: CGFloat = 8.0
        static let middleSpace: CGFloat = 6.0

        static let footerHeight: CGFloat = 20.0

        // 显示showMore的最大高度
        static let normalMaxHeight: CGFloat = 300
    }

    static func configLabel(by textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.textColor = textColor
        label.font = UDFont.systemFont(ofSize: 14)
        label.backgroundColor = .clear
        return label
    }

}

struct ActivityRecordContentHeaderData {
    var icon: UIImage?
    var text: String?
}
/// header: [icon text]
final class ActivityRecordContentHeader: UIView {

    var viewData: ActivityRecordContentHeaderData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if let image = viewData.icon {
                icon.isHidden = false
                icon.image = image
            } else {
                icon.isHidden = true
            }
            label.text = viewData.text
        }
    }

    private lazy var icon = UIImageView()
    private lazy var label = ActivityRecordContentView.configLabel(by: UIColor.ud.textCaption)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(icon)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        typealias Config = ActivityRecordContentView.Config
        var offsetX: CGFloat = 0
        if icon.isHidden {
            icon.frame = .zero
        } else {
            icon.frame = CGRect(
                origin: CGPoint(x: 0, y: (Config.headerHeight - Config.headerIconSize.height) * 0.5),
                size: Config.headerIconSize
            )
            offsetX = icon.frame.maxX + Config.headerIconTextSpace
        }
        label.frame = CGRect(
            x: offsetX,
            y: 0,
            width: frame.width - offsetX,
            height: Config.headerHeight
        )
    }
}

/// Content: [
/// Text
/// Images
/// Attachment
/// ]
struct ActivityRecordMiddleContentData {
    // 文字区
    var text: ActivityRecordTextData
    // 图片
    var images = ActivityRecordImageData()
    // 附件
    var attachments = ActivityRecordAttachmentData()
}

final class ActivityRecordMiddleContentView: UIView {

    var viewData: ActivityRecordMiddleContentData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            text.viewData = viewData.text
            if !viewData.images.images.isEmpty {
                gridImage.isHidden = false
                gridImage.images = viewData.images.images
            } else {
                gridImage.isHidden = true
            }
            if !viewData.attachments.attachments.isEmpty {
                attachment.isHidden = false
                attachment.cellDatas = viewData.attachments.attachments
                attachment.footerData = viewData.attachments.attachmentFooter
            } else {
                attachment.isHidden = true
            }
            clipsToBounds = true
        }
    }

    private(set) lazy var text = ActivityRecordTextView()
    private(set) lazy var gridImage = ImageGridView()
    private(set) lazy var attachment = DetailAttachmentContentView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(text)
        addSubview(gridImage)
        addSubview(attachment)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        text.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: viewData?.text.preferredHeight ?? 0
        )
        var offsetY = text.frame.maxY + ActivityRecordContentView.Config.middleSpace

        if !gridImage.isHidden {
            gridImage.frame = CGRect(
                x: 0,
                y: offsetY,
                width: bounds.width,
                height: viewData?.images.imagesHeight ?? 0
            )
            offsetY = gridImage.frame.maxY + ActivityRecordContentView.Config.middleSpace
        }

        if !attachment.isHidden {
            attachment.frame = CGRect(
                x: 0,
                y: offsetY,
                width: bounds.width,
                height: viewData?.attachments.attachmentsHeight ?? 0
            )
        }
    }

}

struct ActivityRecordTextData {
    // 负责渲染
    var titleCore = LKRichViewCore()
    // 持有数据，为了响应事件
    var titleElement: LKRichElement?
    var titleSize: CGSize?

    var quoteText: String?

    var contentCore = LKRichViewCore()
    var contentSize: CGSize?
    var contentElement: LKRichElement?
    // content的数据来自富文本，为了点击At，记录的原始数据
    var contentAtElements: [String: String]?

    var preferredHeight: CGFloat {
        var height: CGFloat = 0
        if let titleSize = titleSize {
            height += titleSize.height
        }
        if quoteText != nil {
            height += ActivityRecordReplyView.Config.textHeight + ActivityRecordContentView.Config.middleSpace
        }
        if let contentSize = contentSize {
            height += ActivityRecordContentView.Config.middleSpace + contentSize.height
        }
        return height
    }
}
/// middle: [
///    text
///    reply
///    comment
/// ]
final class ActivityRecordTextView: UIView {

    var viewData: ActivityRecordTextData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            title.frame.size = viewData.titleSize ?? .zero
            title.setRichViewCore(viewData.titleCore)
            if let quoteText = viewData.quoteText {
                quote.isHidden = false
                quote.text = quoteText
            } else {
                quote.isHidden = true
            }
            content.frame.size = viewData.contentSize ?? .zero
            content.setRichViewCore(viewData.contentCore)
        }
    }

    private(set) lazy var title = LKRichView(frame: .zero)
    private lazy var quote = ActivityRecordReplyView()
    private(set) lazy var content = LKRichView(frame: .zero)

    private let selectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)]
    ]

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(title)
        title.bindEvent(selectorLists: selectors, isPropagation: true)
        addSubview(quote)
        addSubview(content)
        content.bindEvent(selectorLists: selectors, isPropagation: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !title.isHidden {
            title.frame.origin = .zero
        }

        var offsetY = title.frame.maxY + ActivityRecordContentView.Config.middleSpace
        if !quote.isHidden {
            quote.frame = CGRect(
                x: 0,
                y: offsetY,
                width: bounds.width,
                height: ActivityRecordReplyView.Config.textHeight
            )
            offsetY = quote.frame.maxY + ActivityRecordContentView.Config.middleSpace
        }

        if !content.isHidden {
            content.frame.origin = CGPoint(x: 0, y: offsetY)
        }
    }
}

/// user + badge
struct ReadableAvatarViewData {
    var avatar: AvatarSeed
    var isRead: Bool = true
}

final class ActivityRecordUserView: UIView {

    var onTap: ((String) -> Void)?

    var viewData: ReadableAvatarViewData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            avatar.setAvatarByIdentifier(
                viewData.avatar.avatarId,
                avatarKey: viewData.avatar.avatarKey,
                avatarViewParams: .init(sizeType: .size(Config.avatarSize.width), format: .webp)
            )
            let config = UDBadgeConfig(type: .dot, dotSize: .large)
            let badge = avatar.addBadge(config, anchor: .topRight, anchorType: .circle)
            if viewData.isRead {
                badge.removeFromSuperview()
            }
        }
    }

    private lazy var avatar = BizAvatar()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(avatar)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        avatar.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatar.frame = CGRect(origin: .zero, size: Config.avatarSize)
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let userId = viewData?.avatar.avatarId else {
            return
        }
        onTap?(userId)
    }

    struct Config {
        static let avatarSize = CGSize(width: 26.0, height: 26.0)
    }

}

/// reply: [line text]
final class ActivityRecordReplyView: UIView {

    var text: String? {
        didSet {
            guard let text = text else {
                isHidden = true
                return
            }
            isHidden = false
            textLabel.text = text
        }
    }

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.iconDisabled
        view.layer.cornerRadius = Config.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(lineView)
        addSubview(textLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lineView.frame = CGRect(origin: .zero, size: Config.lineSize)
        let maxWidth = bounds.width - Config.lineSize.width - Config.space
        textLabel.frame = CGRect(x: lineView.frame.maxX + Config.space, y: 0, width: maxWidth, height: Config.textHeight)
        lineView.center.y = textLabel.center.y
    }

    struct Config {
        static let cornerRadius: CGFloat = 2.0
        static let lineSize: CGSize = CGSize(width: 2.0, height: 12.0)
        static let textHeight: CGFloat = 20.0
        static let space: CGFloat = 4.0
    }

}

/// 九宫格图片
final class ImageGridView: UIView {

    var images = [Rust.ImageSet]() {
        didSet { reloadImages(images) }
    }
    var onItemTap: ((_ index: Int, _ sender: UIImageView) -> Void)?

    private var itemViews = [UIImageView]()

    private func reloadImages(_ images: [Rust.ImageSet]) {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()
        guard !images.isEmpty else { return }
        for (index, value) in images.enumerated() {
            let imageView = UIImageView()
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            imageView.addGestureRecognizer(tap)
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.4)
            imageView.layer.cornerRadius = Config.cornerRadius
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 0.5
            imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            itemViews.append(imageView)

            imageView.tag = index
            imageView.isHidden = false
            if imageView.superview != self {
                addSubview(imageView)
            }
            let key = value.downloadKey(forPriorityType: .thumbnail)
            imageView.bt.setLarkImage(with: .default(key: key), completion: { result in
                switch result {
                case .success(let imageResult):
                    if imageResult.image == nil {
                        V3Home.logger.error("load image failed. key: \(key)")
                    }
                case .failure(let error):
                    V3Home.logger.error("load image failed. err: \(error), key: \(key)")
                }
            })
        }
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sender = gesture.view as? UIImageView,
            let tag = gesture.view?.tag, tag >= 0 && tag < images.count else {
            return
        }
        onItemTap?(tag, sender)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let spaceWidth = CGFloat((Config.row - 1)) * Config.space
        let imageWidth = CGFloat((bounds.width - spaceWidth) / CGFloat(Config.row))
        for i in 0..<itemViews.count {
            let (row, col) = (CGFloat(i / Config.column), CGFloat(i % Config.row))
            itemViews[i].frame = CGRect(
                x: imageWidth * col + Config.space * col,
                y: imageWidth * row + Config.space * row,
                width: imageWidth,
                height: imageWidth
            )
        }
    }

    static func preferredHeight(by images: [Rust.ImageSet], and maxWidth: CGFloat) -> CGFloat {
        let lines = CGFloat((images.count + Config.offsetNum) / Int(Config.row))
        let spaceWidth = CGFloat((Config.row - 1)) * Config.space
        let imageHeight = CGFloat((maxWidth - spaceWidth) / CGFloat(Config.row))
        return lines * imageHeight + max(0, lines - 1) * Config.space
    }

    struct Config {
        static let offsetNum: Int = 2
        static let space: CGFloat = 8.0
        static let row = 3
        static let column = 3
        static let cornerRadius: CGFloat = 4.0
    }
}

final class ActivityRecordShowMoreView: UIView {

    var shouldShow: Bool = false {
        didSet {
            self.isHidden = !shouldShow
        }
    }

    var onShowTap: (() -> Void)?

    private lazy var button = ActivityRecordShowMoreBtn()

    private lazy var gradient: GradientView = {
        let gradient = GradientView()
        gradient.backgroundColor = UIColor.clear
        gradient.colors = [
            UIColor.ud.bgBody.withAlphaComponent(1.0),
            UIColor.ud.bgBody.withAlphaComponent(0.0)
        ]
        gradient.locations = [1.0, 0.0]
        gradient.direction = .vertical
        return gradient
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(gradient)
        addSubview(button)
        button.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        button.frame = CGRect(
            x: (bounds.width - Config.btnWidth) * 0.5,
            y: (bounds.height - Config.btnHeight) * 0.5,
            width: Config.btnWidth,
            height: Config.btnHeight
        )
    }

    @objc
    func clickBtn() {
        onShowTap?()
    }

    struct Config {
        static let font: UIFont = UDFont.systemFont(ofSize: 14.0)
        static let text: String = I18N.Lark_Legacy_ChatShowMore
        static let btnWidth: CGFloat = max(Config.text.lu.width(font: Config.font), 72.0) + hPadding * 2.0
        static let vPadding: CGFloat = 14.0
        static let hPadding: CGFloat = 8.0
        static let btnHeight: CGFloat = 32.0
        static let height: CGFloat = Config.btnHeight + vPadding * 2.0
    }

}

final class ActivityRecordShowMoreBtn: UIControl {

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = ActivityRecordShowMoreView.Config.text
        label.font = ActivityRecordShowMoreView.Config.font
        label.textAlignment = .center
        return label
    }()

    // 用于绘制阴影
    private var shadowView = UIView()
    private var shadowLayer = CALayer()

    // 用于切割圆角
    private var shapeView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(shadowView)
        shadowView.clipsToBounds = false
        shadowView.isUserInteractionEnabled = false

        shadowView.layer.addSublayer(shadowLayer)
        shadowLayer.shadowColor = UIColor.ud.shadowDefaultMd.cgColor
        shadowLayer.shadowOpacity = 1
        shadowLayer.shadowRadius = 10
        shadowLayer.shadowOffset = CGSize(width: 0, height: 5)

        addSubview(shapeView)
        shapeView.clipsToBounds = true
        shapeView.isUserInteractionEnabled = false

        shapeView.layer.backgroundColor = (UIColor.ud.bgFloat & UIColor.ud.bgFloatOverlay).cgColor

        addSubview(titleLabel)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds
        shadowView.frame = bounds
        shapeView.frame = bounds

        let shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 73)

        shadowLayer.shadowPath = shadowPath.cgPath
        shadowLayer.bounds = shadowView.bounds
        shadowLayer.position = shadowView.center

        let mask = CAShapeLayer()
        mask.path = shadowPath.cgPath
        shapeView.layer.mask = mask
    }
}


/// Footer: [text]
final class ActivityRecordContentFooter: UIView {

    var text: String? {
        didSet {
            guard let text = text else {
                isHidden = true
                return
            }
            isHidden = false
            label.text = text
        }
    }

    private lazy var label = ActivityRecordContentView.configLabel(by: UIColor.ud.textPlaceholder)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: ActivityRecordContentView.Config.footerHeight
        )
    }
}
