//
//  EmailSearchTableViewCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation
import UIKit
import LarkCore
import SnapKit
import LarkUIKit
import LarkSearchCore
import LarkMessengerInterface
import LKCommonsLogging
import LarkSDKInterface
import LarkListItem
import LarkContainer
import UniverseDesignColor
import UniverseDesignIcon
import LarkTag
import LarkAccountInterface
import RustPB

final class EmailSearchTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    static let logger = Logger.log(EmailSearchTableViewCell.self, category: "Module.IM.Search")
    var viewModel: SearchCellViewModel?
    let containerGuide = UILayoutGuide()

    let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 4
        containerStackView.alignment = .leading
        containerStackView.distribution = .fill
        return containerStackView
    }()

    private let bgView = UIView()
    let titleContainer: UIView = UIView()
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return titleLabel
    }()
    let attachmentImageView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.attachmentOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 12, height: 12)))
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()
    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.ud.N500
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return timeLabel
    }()

    let secondaryTitleContainer: UIView = UIView()
    let secondaryTitleLabel: UILabel = {
        let secondaryTitleLabel = UILabel()
        secondaryTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        secondaryTitleLabel.textColor = UIColor.ud.textTitle
        secondaryTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        secondaryTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return secondaryTitleLabel
    }()
    let tagView: TagWrapperView = {
        let tagView = TagWrapperView()
        tagView.setContentCompressionResistancePriority(.required, for: .horizontal)
        tagView.setContentHuggingPriority(.required, for: .horizontal)
        tagView.isHidden = true
        return tagView
    }()

    let emailContentLabel: UILabel = {
        let emailContentLabel = UILabel()
        emailContentLabel.font = UIFont.systemFont(ofSize: 14)
        emailContentLabel.textColor = UIColor.ud.textPlaceholder
        emailContentLabel.isHidden = true
        return emailContentLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = SearchCellSelectedView()

        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        bgView.addSubview(containerStackView)

        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(attachmentImageView)
        titleContainer.addSubview(timeLabel)
        containerStackView.addArrangedSubview(titleContainer)

        secondaryTitleContainer.addSubview(secondaryTitleLabel)
        secondaryTitleContainer.addSubview(tagView)
        containerStackView.addArrangedSubview(secondaryTitleContainer)

        containerStackView.addArrangedSubview(emailContentLabel)

        titleContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        secondaryTitleContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(22)
        }
        emailContentLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        containerStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchCellViewModel, currentAccount: LarkAccountInterface.User?, searchText: String?) {
        guard let emailModel = viewModel as? EmailSearchViewModel, let searchResult = emailModel.searchResult as? Search.Result else {
            return
        }
        self.viewModel = emailModel
        // line 1
        titleLabel.attributedText = searchResult.title
        titleLabel.sizeToFit()
        var showAttachmentImage: Bool = false
        if let hasAttachment = emailModel.renderDataModel?.hasAttachment, hasAttachment {
            attachmentImageView.isHidden = false
            showAttachmentImage = true
        } else {
            attachmentImageView.isHidden = true
            attachmentImageView.snp.removeConstraints()
        }
        if let createTimeStamp = emailModel.renderDataModel?.createTimeStamp {
            timeLabel.text = Date.lf.getNiceDateString(TimeInterval(createTimeStamp))
            timeLabel.sizeToFit()
        }
        titleLabel.snp.remakeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(attachmentImageView.snp.leading).offset(-8)
        }
        attachmentImageView.snp.remakeConstraints { make in
            make.size.equalTo(showAttachmentImage ? CGSize(width: 12, height: 12) : CGSize.zero)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(timeLabel.snp.leading).offset(showAttachmentImage ? -6 : -8)
        }
        timeLabel.snp.remakeConstraints { make in
            make.trailing.centerY.equalToSuperview().priority(.required)
        }

        // line2
        if !searchResult.summary.string.isEmpty {
            secondaryTitleLabel.attributedText = searchResult.summary
        } else {
            secondaryTitleLabel.attributedText = NSAttributedString(string: BundleI18n.LarkSearch.Mail_ThreadList_TitleEmpty)
        }
        secondaryTitleLabel.sizeToFit()
        let customTags = searchResult.explanationTags.map {
            Tag(title: $0.text, style: SearchResultNameStatusView.getTagColor(withTagType: $0.tagType), type: .customTitleTag)
        }
        tagView.set(tags: customTags)
        secondaryTitleLabel.snp.remakeConstraints { make in
            make.leading.centerY.equalToSuperview()
            if customTags.isEmpty {
                make.trailing.equalToSuperview()
            } else {
                make.trailing.equalTo(tagView.snp.leading).offset(-8)
            }
        }
        tagView.snp.removeConstraints()
        if customTags.isEmpty {
            tagView.isHidden = true
        } else {
            tagView.isHidden = false
            tagView.snp.remakeConstraints { make in
                make.trailing.centerY.equalToSuperview().priority(.required)
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(secondaryTitleLabel.snp.trailing).offset(8)
            }
        }
        secondaryTitleContainer.isHidden = !(searchResult.summary.length > 0 || !customTags.isEmpty)

        //line3
        let extraAttributedString: NSAttributedString = Search_V2_ExtraInfoBlock.mergeExtraInfoBlocks(blocks: searchResult.extraInfos,
                                                                                                      separator: searchResult.extraInfoSeparator)
        if extraAttributedString.length > 0 {
            emailContentLabel.attributedText = extraAttributedString
            emailContentLabel.sizeToFit()
            emailContentLabel.isHidden = false
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
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        titleLabel.attributedText = nil
        titleLabel.textColor = UIColor.ud.textTitle
        attachmentImageView.isHidden = true
        timeLabel.text = nil
        secondaryTitleLabel.text = nil
        secondaryTitleLabel.attributedText = nil
        secondaryTitleLabel.textColor = UIColor.ud.textTitle
        tagView.clean()
        tagView.isHidden = true
        emailContentLabel.text = nil
        emailContentLabel.attributedText = nil
        emailContentLabel.isHidden = true
        emailContentLabel.textColor = UIColor.ud.textPlaceholder
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
