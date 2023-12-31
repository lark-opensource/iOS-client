//
//  MessageSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import Foundation
import UIKit
import LarkCore
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkUIKit
import LarkTag
import Swinject
import LarkAccountInterface
import LarkExtensions
import EETroubleKiller
import LarkBizAvatar
import LarkInteraction
import LarkSDKInterface
import LarkSearchCore
import UniverseDesignIcon
import RustPB
import LarkListItem
import ByteWebImage

final class MessageSearchTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    private(set) var viewModel: SearchCellViewModel?

    private let CellHeightForMobile = 67
    private let CellHeightForPad = 79
    private let bgView = UIView()
    private let avatarView = BizAvatar()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let titleTimeContainerView = UIView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let nameInfoContainerView = UIView()
    private let titleAndInfoStackView = UIStackView()
    private let baseMessageContainerView = UIView()
    private let containerGuide = UILayoutGuide()
    private lazy var urlAttachmentView = MessageAttachmentView(superCell: self)
    private var webImageDownloader: SearchWebImagesDownloader?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        contentView.addLayoutGuide(containerGuide)

        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        baseMessageContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
        bgView.addSubview(baseMessageContainerView)
        baseMessageContainerView.addSubview(avatarView)
        baseMessageContainerView.addSubview(titleAndInfoStackView)
        if SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            urlAttachmentView.setContentCompressionResistancePriority(.required, for: .vertical)
            bgView.addSubview(urlAttachmentView)
            urlAttachmentView.isHidden = true
            baseMessageContainerView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(12)
            }
            urlAttachmentView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.top.equalTo(baseMessageContainerView.snp.bottom).offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }
        } else {
            baseMessageContainerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        titleAndInfoStackView.addArrangedSubview(titleTimeContainerView)
        titleAndInfoStackView.addArrangedSubview(nameInfoContainerView)

        titleTimeContainerView.addSubview(titleLabel)
        titleTimeContainerView.addSubview(timeLabel)

        nameInfoContainerView.addSubview(nameLabel)
        nameInfoContainerView.addSubview(infoLabel)

        if SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            containerGuide.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            containerGuide.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.height.equalTo(67).priority(.high)
            }
        }

        avatarView.avatar.ud.setMaskView()
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: SearchResultDefaultView.searchAvatarImageDefaultSize, height: SearchResultDefaultView.searchAvatarImageDefaultSize))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        titleAndInfoStackView.axis = .vertical
        titleAndInfoStackView.spacing = 7
        titleAndInfoStackView.alignment = .fill
        titleAndInfoStackView.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(16)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
        }

        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
        }

        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
        }

        infoLabel.textColor = UIColor.ud.textPlaceholder
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        infoLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.height.lessThanOrEqualToSuperview() // nameLabel可能为空，这时用这个height保证推断的container高度正常
        }

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        webImageDownloader = nil
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        self.viewModel = viewModel
        webImageDownloader = nil
        let searchResult = viewModel.searchResult
        guard case .message(let meta) = viewModel.searchResult.meta else { return }
        avatarView.setAvatarByIdentifier(viewModel.avatarID,
                                         avatarKey: searchResult.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(SearchResultDefaultView.searchAvatarImageDefaultSize)))
        titleLabel.attributedText = searchResult.title

        timeLabel.text = Date.lf.getNiceDateString(TimeInterval(meta.createTime))

        let summary = searchResult.summary
        if summary.length == 0 {
            nameInfoContainerView.isHidden = true
        } else {
            nameInfoContainerView.isHidden = false
            nameLabel.text = meta.fromName.isEmpty ? "" : meta.fromName + BundleI18n.LarkSearch.Lark_Legacy_Colon

            if !meta.docExtraInfosType.isEmpty {
                infoLabel.attributedText = Utils.replaceUrl(
                    meta: meta, subtitle: summary, font: infoLabel.font)
            } else {
                infoLabel.attributedText = summary
            }
            if let _summary = infoLabel.attributedText, SearchFeatureGatingKey.enableSupportURLIconInline.isEnabled {
                var mutableSummary = NSMutableAttributedString(attributedString: _summary)
                let imageKeys = mutableSummary.searchWebImageKeysInAttachment
                if !imageKeys.isEmpty {
                    webImageDownloader = SearchWebImagesDownloader(with: imageKeys)
                    webImageDownloader?.download(completion: { [weak self] result in
                        guard let self = self else { return }
                        mutableSummary = mutableSummary.updateSearchWebImageView(withImageResource: result, font: UIFont.systemFont(ofSize: 14))
                        if Thread.current.isMainThread {
                            self.infoLabel.attributedText = mutableSummary
                        } else {
                            DispatchQueue.main.async {
                                self.infoLabel.attributedText = mutableSummary
                            }
                        }
                    })
                }
            }
        }
        if SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            if urlAttachmentView.checkAndSetViewIfNeeded(viewModel: viewModel) {
                urlAttachmentView.isHidden = false
                baseMessageContainerView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalToSuperview().offset(12)
                }
                urlAttachmentView.snp.remakeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview().offset(-16)
                    make.top.equalTo(baseMessageContainerView.snp.bottom).offset(12)
                    make.bottom.equalToSuperview().offset(-12)
                }
            } else {
                urlAttachmentView.isHidden = true
                baseMessageContainerView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(67).priority(.high)
                }
            }
        } else {
            baseMessageContainerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
        }
        // 和setup中的代码对齐
        if !SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            containerGuide.snp.updateConstraints { (make) in
                make.height.equalTo(CellHeightForPad).priority(.high)
            }
        }
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview()
        }
        if !SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
            containerGuide.snp.updateConstraints { (make) in
                make.height.equalTo(CellHeightForMobile).priority(.high)
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellState(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellState(animated: animated)
    }

    private func updateCellState(animated: Bool) {
        updateCellStyle(animated: animated)
        if needShowDividerStyle() {
            self.selectedBackgroundView?.backgroundColor = UIColor.clear
            updateCellStyleForPad(animated: animated, view: bgView)
        }
    }

    override func layoutSubviews() {
        var bottom = 1
        if needShowDividerStyle() {
            bottom = 13
        }
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: CGFloat(bottom), right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }
}

// MARK: - EETroubleKiller
extension MessageSearchTableViewCell: CaptureProtocol & DomainProtocol {

    public var isLeaf: Bool {
        return true
    }

    public var domainKey: [String: String] {
        var tkDescription: [String: String] = [:]
        tkDescription["id"] = "\(self.viewModel?.searchResult.id ?? "")"
        tkDescription["type"] = "\(self.viewModel?.searchResult.type ?? .unknown)"
        tkDescription["cid"] = "\(self.viewModel?.searchResult.contextID ?? "")"
        return tkDescription
    }
}

final class MessageAttachmentView: UIView {
    static let searchMessageURLAttachmentShowMaxCount: Int32 = 2
    let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.backgroundColor = .clear
        containerStackView.axis = .vertical
        containerStackView.alignment = .leading
        containerStackView.spacing = 8
        return containerStackView
    }()

    let remindMoreLabel: UILabel = {
        let remindMoreLabel = UILabel()
        remindMoreLabel.backgroundColor = .clear
        remindMoreLabel.font = UIFont.systemFont(ofSize: 14)
        remindMoreLabel.textColor = UIColor.ud.textPlaceholder
        remindMoreLabel.isHidden = true
        return remindMoreLabel
    }()

    var viewModel: MessageSearchViewModel?
    weak var superCell: MessageSearchTableViewCell?

    init(superCell: MessageSearchTableViewCell) {
        self.superCell = superCell
        super.init(frame: .zero)
        addSubview(containerStackView)
        addSubview(remindMoreLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func checkAndSetViewIfNeeded(viewModel: SearchCellViewModel) -> Bool {
        guard let messageVM = viewModel as? MessageSearchViewModel,
              case .message(let meta) = viewModel.searchResult.meta,
              let messageMeta = meta as? Search_V2_MessageMeta, messageMeta.attachmentCount > 0,
              !messageMeta.attachments.isEmpty
        else {
            self.viewModel = nil
            return false
        }
        let urlAttachments = messageMeta.attachments.filter { attachment in
            return attachment.attachmentType == .attachmentLink && attachment.attachmentRenderType == .card
        }
        if urlAttachments.isEmpty {
            self.viewModel = nil
            return false
        }
        self.viewModel = messageVM

        containerStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        var count = 0
        for attachment in urlAttachments {
            let urlCardView = MessageURLAttachmentCardView(attachment: attachment) { [weak self] urlStr in
                guard let self = self, let vc = self.superCell?.controller else { return }
                self.viewModel?.didSelectURLAttachmentCard(withURL: urlStr, fromVC: vc)
            }
            containerStackView.addArrangedSubview(urlCardView)
            urlCardView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
            }
            count += 1
            if count >= Self.searchMessageURLAttachmentShowMaxCount {
                break
            }
        }

        let residualCount = Int(messageMeta.attachmentCount - Self.searchMessageURLAttachmentShowMaxCount)
        if residualCount > 0 {
            remindMoreLabel.isHidden = false
            remindMoreLabel.text = BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_LinkResultsDisplayIncomplete_ShowTheRestClickable(residualCount)
            containerStackView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
            }
            remindMoreLabel.snp.remakeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(containerStackView.snp.bottom).offset(8)
            }
        } else {
            remindMoreLabel.isHidden = true
            remindMoreLabel.snp.removeConstraints()
            containerStackView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }

        return true
    }
}

final class MessageURLAttachmentCardView: UIView {
    class SearchAttachmentBaseButton: UIButton {
        override var isHighlighted: Bool {
            didSet {
                updateBackgroundColor()
            }
        }
        override var isSelected: Bool {
            didSet {
                updateBackgroundColor()
            }
        }
        private func updateBackgroundColor() {
            switch (isHighlighted, isSelected) {
            case (_, true):
                backgroundColor = UIColor.ud.fillActive
            case (true, false):
                backgroundColor = UIColor.ud.fillFocus
            default:
                backgroundColor = UIColor.ud.bgBody
            }
        }
    }

    let attachment: Search_V2_MessageAttachment
    let redirectWithURL: ((String) -> Void)?
    init(attachment: Search_V2_MessageAttachment, redirectWithURL: ((String) -> Void)? = nil) {
        self.attachment = attachment
        self.redirectWithURL = redirectWithURL
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        layer.cornerRadius = 8
        layer.borderColor = UIColor.ud.lineDividerDefault.cgColor
        layer.borderWidth = 1
        layer.masksToBounds = true
        let backgroundButton = SearchAttachmentBaseButton()
        backgroundButton.backgroundColor = UIColor.ud.bgBody
        backgroundButton.addTarget(self, action: #selector(tapACtion), for: UIControl.Event.touchUpInside)
        addSubview(backgroundButton)
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let iconImageView = UIImageView()
        iconImageView.backgroundColor = .clear
        addSubview(iconImageView)
        let iconSize = CGSize(width: 16, height: 16)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(12)
        }

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.leading.equalTo(iconImageView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-12)
        }

        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(iconImageView.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-12)
        }

        let defaultTintColor = UIColor.ud.textLinkNormal
        let defaultIconImage = UDIcon.getIconByKey(.globalLinkOutlined, size: iconSize).ud.withTintColor(defaultTintColor)
        // 目前 UD 和 ImageSet server只下发了key，无颜色相关数据，需客户端自行染色
        if attachment.urlMeta.udIcon.hasKey {
            let image = UDIcon.getIconByString(attachment.urlMeta.udIcon.key, iconColor: defaultTintColor, size: iconSize) ?? defaultIconImage
            iconImageView.bt.setImage(image)
        } else if attachment.urlMeta.imageIcon.hasKey {
            let imageSet = attachment.urlMeta.imageIcon
            iconImageView.bt.setLarkImage(with: .default(key: imageSet.key), placeholder: nil, completion: { [weak iconImageView] imageResult in
                guard let imageView = iconImageView else { return }
                if case .success(let res) = imageResult, let image = res.image {
                    imageView.bt.setImage(image.ud.withTintColor(defaultTintColor))
                } else {
                    imageView.bt.setImage(defaultIconImage)
                }
            })
        } else if !attachment.urlMeta.iconURL.isEmpty, let iconImageURL = URL(string: attachment.urlMeta.iconURL) {
            iconImageView.bt.setImage(iconImageURL, placeholder: defaultIconImage)
        } else {
            iconImageView.bt.setImage(defaultIconImage)
        }

        let titleHighlighted = attachment.titleHighlighted.replacingOccurrences(of: "\n", with: " ", options: .caseInsensitive, range: nil)
        if !titleHighlighted.isEmpty {
            titleLabel.attributedText = SearchAttributeString(searchHighlightedString: titleHighlighted).attributeText
        } else {
            titleLabel.text = attachment.title
        }
        let summaryHighlighted = attachment.summaryHighlighted.replacingOccurrences(of: "\n", with: " ", options: .caseInsensitive, range: nil)
        if !summaryHighlighted.isEmpty {
            descriptionLabel.attributedText = SearchAttributeString(searchHighlightedString: summaryHighlighted).attributeText
        } else {
            descriptionLabel.text = attachment.summary
        }
    }

    @objc
    private func tapACtion() {
        if let _redirectWithURL = redirectWithURL, !attachment.urlMeta.url.isEmpty {
            _redirectWithURL(attachment.urlMeta.url)
        }
    }
}
