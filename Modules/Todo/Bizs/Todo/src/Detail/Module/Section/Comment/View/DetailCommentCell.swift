//
//  DetailCommentCell.swift
//  Todo
//
//  Created by 张威 on 2021/2/26.
//

import LarkUIKit
import CTFoundation
import LarkBizAvatar
import RichLabel
import LarkFoundation
import LarkReactionView
import LarkEmotion
import UniverseDesignIcon
import UniverseDesignFont
import LarkContainer

/// Detail - Comment - Cell

typealias DetailCommentReactionInfo = LarkReactionView.ReactionInfo
typealias DetailCommentReactionUser = LarkReactionView.ReactionUser

protocol DetailCommentCellDataType {
    var commentId: String { get }
    /// 发送者头像
    var avatar: AvatarSeed { get }
    /// 发送者名字
    var name: String { get }
    /// 时间
    var timeStr: String { get }
    /// 文本内容
    var richContent: Rust.RichContent? { get }
    // var textContent: (attrText: AttrText, linkRanges: [NSRange])? { get }
    /// 附件（图片）
    var images: [Rust.ImageSet] { get }
    /// reactions
    var reactions: [DetailCommentReactionInfo] { get }
    /// 附件（文件）
    var attachments: [Rust.Attachment] { get }
    var attachmentCellDatas: [DetailAttachmentContentCellData] { get }
    var attachmentFooterData: DetailAttachmentFooterViewData? { get }

    var userResolver: UserResolver { get }
}

extension DetailCommentCellDataType {
    var attachmentHeight: CGFloat {
        let cellsHeight = attachmentCellDatas.reduce(0, { $0 + $1.cellHeight })
        return cellsHeight + (attachmentFooterData?.footerHeight ?? 0)
    }
}

private let layouts = (
    topPadding: CGFloat(12),
    bottomPadding: CGFloat(12),
    avatarSize: CGSize(width: 28, height: 28),
    nameHeight: CGFloat(20),        // nameLabel 的高度
    imageSpacing: CGFloat(8),       // 图片之间的间距
    labelSpacing: CGFloat(4),       // label 之间纵向的间距
    textImageSpacing: CGFloat(10),  // 文本和图片之间的间距
    attachmentSpacing: CGFloat(8),  // 图片和附件之间的间距
    reactionTopMargin: CGFloat(4)   // reaction top padding
)

protocol DetailCommentCellDelegate: AnyObject {
    func didTapRichLabel(with atItem: RichLabelContent.AtItem, from sender: DetailCommentCell)
    func didTapRichLabel(with anchorItem: RichLabelContent.AnchorItem, from sender: DetailCommentCell)
    func didTapImageItem(_ index: Int, imageView: UIImageView, sourceItems: [RichLabelContent.ImageItem], from sender: DetailCommentCell)
    func didTapMore(from sender: DetailCommentCell)
    func didTapAvatar(from sender: DetailCommentCell)
    func didTapImageView(_ imageView: UIImageView, at index: Int, from sender: DetailCommentCell)
    func didTapReactionIcon(with type: String, from sender: DetailCommentCell)
    func didTapReactionUser(with type: String, userId: String, from sender: DetailCommentCell)
    func didTapReactionMore(with type: String, from sender: DetailCommentCell)
    func didAnchorTitleFixed(from sender: DetailCommentCell)
    func didTapAttachment(from sender: DetailCommentCell, fileToken: String)
    func didExpandAttachment(from sender: DetailCommentCell)
}

final class DetailCommentCell: UITableViewCell, ViewDataConvertible {

    var viewData: DetailCommentCellDataType? {
        didSet { updateView() }
    }

    var cellWidth: CGFloat? {
        didSet {
            guard let width = cellWidth, width > 106 else { return }
            let contentMaxWidth = width - 40 - 54
            richLabel.preferredMaxLayoutWidth = contentMaxWidth
            reactionView.preferMaxLayoutWidth = contentMaxWidth
        }
    }

    weak var delegate: DetailCommentCellDelegate?

    // content 基础属性
    static private let basicContentAttrs: [AttrText.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        return [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UDFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle
        ]
    }()

    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let richLabel = {
        var label = RichContentLabel()
        label.lineSpacing = 4
        label.textVerticalAlignment = .top
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private let moreButton = UIButton()
    private let imageGridView = ImageGridView()
    private let attachmentView = DetailAttachmentContentView(hideHeader: true)
    private let bgColors = (highlighted: UIColor.ud.fillPressed, normal: UIColor.ud.bgBody)
    private let reactionView = ReactionView()
    private lazy var richRenderConfig: RichLabelContentBuildConfig = {
        let richLabelAttrs: [AttrText.Key: Any] = {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            return [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UDFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraphStyle
            ]
        }()
        return .init(
            baseAttrs: richLabelAttrs,
            anchorConfig: .init(foregroundColor: UIColor.ud.B700),
            atConfig: .init(
                normalForegroundColor: UIColor.ud.B700,
                outerForegroundColor: UIColor.ud.N500
            ),
            imageConfig: RichLabelContentBuildConfig.ImageConfig(width: richLabel.preferredMaxLayoutWidth)
        )
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = bgColors.normal
        contentView.backgroundColor = bgColors.normal
        selectionStyle = .none

        avatarView.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(handleTapAvatar))
        avatarView.addGestureRecognizer(avatarTap)
        contentView.addSubview(avatarView)

        let icon = UDIcon.getIconByKey(
            .moreOutlined,
            renderingMode: .automatic,
            iconColor: UIColor.ud.iconN2,
            size: CGSize(width: 20, height: 20)
        )
        moreButton.setImage(icon, for: .normal)
        moreButton.addTarget(self, action: #selector(handleMoreClick), for: .touchUpInside)
        contentView.addSubview(moreButton)

        nameLabel.font = UDFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(nameLabel)

        timeLabel.font = UDFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        contentView.addSubview(timeLabel)

        richLabel.onAtClick = { [weak self] atItem in
            guard let self = self else { return }
            self.delegate?.didTapRichLabel(with: atItem, from: self)
        }
        richLabel.onAnchorClick = { [weak self] anchorItem in
            guard let self = self else { return }
            self.delegate?.didTapRichLabel(with: anchorItem, from: self)
        }
        richLabel.onImageClick = { [weak self] (index, imageView, sourceItems) in
            guard let self = self else { return }
            self.delegate?.didTapImageItem(index, imageView: imageView, sourceItems: sourceItems, from: self)
        }
        richLabel.needsAutoUpdate = { [weak self] state in
            guard let self = self, case .needsUpdate = state else { return nil }
            self.delegate?.didAnchorTitleFixed(from: self)
            return nil
        }
        contentView.addSubview(richLabel)

        imageGridView.onItemTap = { [weak self] (index, sender) in
            guard let self = self else { return }
            self.delegate?.didTapImageView(sender, at: index, from: self)
        }
        contentView.addSubview(imageGridView)

        attachmentView.footerView.expandMoreClickHandler = { [weak self] in
            guard let self = self else { return }
            self.delegate?.didExpandAttachment(from: self)
        }
        attachmentView.actionDelegate = self
        contentView.addSubview(attachmentView)

        reactionView.delegate = self
        contentView.addSubview(reactionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? bgColors.highlighted : bgColors.normal
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.backgroundColor = selected ? bgColors.highlighted : bgColors.normal
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        avatarView.frame = CGRect(origin: .zero, size: layouts.avatarSize)
        avatarView.frame.left = 16
        avatarView.frame.top = 15

        moreButton.frame.size = CGSize(width: 24, height: 24)
        moreButton.frame.right = frame.width - 16
        moreButton.frame.top = 10

        nameLabel.sizeToFit()
        nameLabel.frame.size.height = 20
        nameLabel.frame.left = avatarView.frame.right + 10
        nameLabel.frame.top = 12

        timeLabel.frame.top = nameLabel.frame.top
        timeLabel.frame.left = nameLabel.frame.right + 6
        timeLabel.frame.size.height = nameLabel.frame.height
        timeLabel.frame.size.width = max(0, moreButton.frame.left - 10 - timeLabel.frame.left)

        let contentMaxWidth = bounds.width - 40 - nameLabel.frame.left
        let fitsRefSize = CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude)

        richLabel.frame.top = nameLabel.frame.maxY + layouts.labelSpacing
        richLabel.frame.left = nameLabel.frame.left
        richLabel.frame.size = richLabel.sizeThatFits(fitsRefSize)
        var contentBottom = richLabel.isHidden ? nameLabel.frame.bottom : richLabel.frame.bottom

        imageGridView.frame.top = contentBottom + layouts.textImageSpacing
        imageGridView.frame.left = nameLabel.frame.left
        let imageGridRefSize = CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude)
        imageGridView.frame.size = CGSize(width: contentMaxWidth, height: ImageGridView.preferredHeight(by: viewData?.images ?? [], and: contentMaxWidth))
        contentBottom = imageGridView.isHidden ? contentBottom : imageGridView.frame.bottom

        attachmentView.frame.top = contentBottom + layouts.attachmentSpacing
        attachmentView.frame.left = nameLabel.frame.left
        attachmentView.frame.size.width = contentMaxWidth
        attachmentView.frame.size.height = viewData?.attachmentHeight ?? 0
        contentBottom = attachmentView.isHidden ? contentBottom : attachmentView.frame.bottom

        reactionView.frame.top = contentBottom + layouts.reactionTopMargin
        reactionView.frame.left = nameLabel.frame.left
        reactionView.frame.size.width = contentMaxWidth
        reactionView.frame.size.height = bounds.height - layouts.bottomPadding - reactionView.frame.top
    }

    @objc
    func handleTapAvatar() {
        delegate?.didTapAvatar(from: self)
    }

    @objc
    private func handleMoreClick() {
        delegate?.didTapMore(from: self)
    }

    private func updateView() {
        richLabel.removeLKTextLink()
        guard let viewData = viewData else {
            textLabel?.attributedText = nil
            contentView.setNeedsLayout()
            return
        }

        avatarView.setAvatarByIdentifier(
            viewData.avatar.avatarId,
            avatarKey: viewData.avatar.avatarKey,
            avatarViewParams: .init(sizeType: .size(40), format: .webp)
        )
        nameLabel.text = viewData.name
        timeLabel.text = viewData.timeStr

        if let richContent = viewData.richContent {
            richLabel.updateRenderContent(
                userResolver: viewData.userResolver,
                with: richContent,
                sourceId: viewData.commentId,
                config: richRenderConfig
            )
            richLabel.isHidden = false
        } else {
            richLabel.clearRenderContent()
            richLabel.isHidden = true
        }
        imageGridView.images = viewData.images
        imageGridView.isHidden = viewData.images.isEmpty

        attachmentView.footerData = viewData.attachmentFooterData
        attachmentView.cellDatas = viewData.attachmentCellDatas

        reactionView.isHidden = viewData.reactions.isEmpty
        reactionView.reactions = viewData.reactions
        reactionView.layoutIfNeeded()

        contentView.setNeedsLayout()
    }

}

extension DetailCommentCell: ReactionViewDelegate {

    func reactionDidTapped(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        let type = reactionVM.reactionKey
        switch tapType {
        case .icon:
            delegate?.didTapReactionIcon(with: type, from: self)
        case .name(let id):
            delegate?.didTapReactionUser(with: type, userId: id, from: self)
        case .more:
            delegate?.didTapReactionMore(with: type, from: self)
        }
    }

    func reactionViewImage(_ reactionVM: ReactionInfo, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reactionVM.reactionKey) {
            callback(image)
        }
    }
}

extension DetailCommentCell: DetailAttachmentContentCellDelegate {
    func onClick(_ cell: DetailAttachmentContentCell) {
        guard let fileToken = cell.viewData?.fileToken,
              !fileToken.isEmpty else {
            return
        }
        delegate?.didTapAttachment(from: self, fileToken: fileToken)
    }

    func onRetryBtnClick(_ cell: DetailAttachmentContentCell) { }

    func onDeleteBtnClick(_ cell: DetailAttachmentContentCell) { }
}

extension DetailCommentCell {

    // 工具 cell，用于根据内容计算 height
    private static let toolCell = DetailCommentCell(style: .default, reuseIdentifier: nil)
    private static let greatestSize = CGSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
    )

    private static func imageGridHeight(for count: Int, with gridWidth: CGFloat) -> CGFloat {
        let lines = CGFloat((count + 2) / 3)
        var imageHeight = CGFloat(floor(gridWidth - 16) / 3)
        return lines * imageHeight + max(0, lines - 1) * 8
    }

    static func cellHeight(for viewData: ViewDataType, with displayWidth: CGFloat) -> CGFloat {
        toolCell.cellWidth = displayWidth
        toolCell.viewData = viewData
        let contentMaxWidth = displayWidth - 54 - 40
        let maxContentSize = CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude)
        var cellHeight = layouts.topPadding + layouts.nameHeight
        if !toolCell.richLabel.isHidden {
            let richLabelHeight = toolCell.richLabel.sizeThatFits(maxContentSize).height
            if richLabelHeight > 1.0 {
                cellHeight += layouts.labelSpacing
                cellHeight += richLabelHeight
            }
        }
        if !viewData.images.isEmpty {
            cellHeight += layouts.textImageSpacing
            cellHeight += ImageGridView.preferredHeight(by: viewData.images, and: maxContentSize.width)
        }

        if !viewData.attachmentCellDatas.isEmpty {
            cellHeight += viewData.attachmentHeight
        }

        if !viewData.reactions.isEmpty {
            cellHeight += layouts.reactionTopMargin
            let reactionHeight = toolCell.reactionView.systemLayoutSizeFitting(greatestSize).height
            cellHeight += reactionHeight
        }
        cellHeight += layouts.bottomPadding
        let minCellHeight: CGFloat = 15 + 40 + 12
        return max(cellHeight, minCellHeight)
    }

}
