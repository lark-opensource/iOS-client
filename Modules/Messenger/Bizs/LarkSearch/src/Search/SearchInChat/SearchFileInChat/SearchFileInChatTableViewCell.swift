//
//  SearchFileInChatTableViewCell.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/23.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkExtensions
import LarkListItem
import LarkSearchCore
import AvatarComponent
import RustPB

final class SearchFileInChatTableViewCell: UITableViewCell, BaseSearchInChatTableViewCellProtocol {
    private let containerGuide = UILayoutGuide()
    private let stackView = UIStackView()
    private let personInfoView = ListItem()
    private let goToMessageButton = UIButton()
    private var hasFilePermission: Bool = false
    // 局域网传输icon
    private lazy var lanTransIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = Resources.lan_Trans_Icon
        return imageView
    }()

    private(set) var viewModel: SearchInChatCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }

        stackView.spacing = 20
        stackView.axis = .horizontal
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(-16)
        }

        personInfoView.rightMarginConstraint.update(offset: 0)
        var config = AvatarComponentUIConfig()
        config.style = .square
        personInfoView.avatarView.setAvatarUIConfig(config)
        personInfoView.checkBox.isHidden = true
        personInfoView.additionalIcon.isHidden = true
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.infoLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
        }
        stackView.addArrangedSubview(personInfoView)

        goToMessageButton.setImage(Resources.goDoc.withRenderingMode(.alwaysTemplate), for: .normal)
        goToMessageButton.tintColor = UIColor.ud.iconN2
        goToMessageButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 900), for: .horizontal)
        goToMessageButton.hitTestEdgeInsets = .init(edges: -20)
        stackView.addArrangedSubview(goToMessageButton)
        goToMessageButton.addTarget(self, action: #selector(gotoMessageButtonDidClick), for: .touchUpInside)
        contentView.addSubview(lanTransIcon)
        lanTransIcon.snp.makeConstraints { (make) in
            make.right.equalTo(personInfoView.avatarView.snp.right).offset(4)
            make.bottom.equalTo(personInfoView.avatarView.snp.bottom).offset(6)
            make.size.equalTo(24)
        }
        lanTransIcon.isHidden = true
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    private func clearStatus() {
        personInfoView.avatarView.image = nil
        personInfoView.nameLabel.text = ""
        personInfoView.nameTag.clean()
        personInfoView.nameTag.isHidden = true
        personInfoView.setDescription(NSAttributedString(string: ""), descriptionType: ListItem.DescriptionType.onDefault)
        personInfoView.infoLabel.text = ""
        personInfoView.additionalIcon.clean()
        personInfoView.additionalIcon.isHidden = true
    }

    func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        clearStatus()

        self.viewModel = viewModel

        if SearchFeatureGatingKey.enableSearchSubFile.isEnabled {
            updateFileItem(currentSearchText: currentSearchText)
        } else {
            updateMessageItem(currentSearchText: currentSearchText)
        }

    }

    func updateMessageItem(currentSearchText: String) {
        guard let searchResult = viewModel?.data, case let .message(messageMeta) = searchResult.meta else { return }
        self.hasFilePermission = messageMeta.isFileAccessAuth

        if self.hasFilePermission {
            // 有权限正常展示
            // nameLabel
            personInfoView.nameLabel.attributedText = searchResult.title
            // infoLable
            let summary = NSMutableAttributedString(attributedString: searchResult.summary)
            summary.append(NSAttributedString(string: " "))
            summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(messageMeta.updateTime))))
            personInfoView.infoLabel.attributedText = summary
        } else {
            // 无权限
            let titleString = NSMutableAttributedString(attributedString: searchResult.title)
            titleString.addAttribute(.foregroundColor, value: UIColor.ud.textPlaceholder, range: NSRange(location: 0, length: titleString.length))

            let summary = NSAttributedString(
                string: BundleI18n.LarkSearch.Lark_IM_UnableToPreview_Button,
                attributes: [
                    .foregroundColor: UIColor.ud.textPlaceholder
                ]
            )
            personInfoView.nameLabel.attributedText = titleString
            personInfoView.infoLabel.attributedText = summary
        }

        if messageMeta.contentType == .folder {
            personInfoView.avatarView.image = Resources.icon_file_folder_colorful
            lanTransIcon.isHidden = !messageMeta.hasFileMeta || messageMeta.fileMeta.extra.source != .lanTrans
        } else if messageMeta.hasFileMeta, !messageMeta.fileMeta.name.isEmpty {
            // 头像
            let image = LarkCoreUtils.fileIconColorful(with: messageMeta.fileMeta.name, size: CGSize(width: 40, height: 40))
            personInfoView.avatarView.image = image
            // 局域网文件显示特定icon
            lanTransIcon.isHidden = messageMeta.fileMeta.extra.source != .lanTrans
        } else {
            assertionFailure("unknown meta data")
        }
    }
    func updateFileItem(currentSearchText: String) {
        guard let searchResult = viewModel?.data, case let .messageFile(messageFileMeta) = searchResult.meta else { return }
        self.hasFilePermission = messageFileMeta.isFileAccessAuth

        if self.hasFilePermission {
            // 有权限正常展示
            // nameLabel
            personInfoView.nameLabel.attributedText = searchResult.title
            // infoLable
            let summary = NSMutableAttributedString(attributedString: searchResult.summary)
            summary.append(NSAttributedString(string: " "))
            summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(messageFileMeta.createTime))))
            personInfoView.infoLabel.attributedText = summary
        } else {
            // 无权限
            let titleString = NSMutableAttributedString(attributedString: searchResult.title)
            titleString.addAttribute(.foregroundColor, value: UIColor.ud.textPlaceholder, range: NSRange(location: 0, length: titleString.length))

            let summary = NSAttributedString(
                string: BundleI18n.LarkSearch.Lark_IM_UnableToPreview_Button,
                attributes: [
                    .foregroundColor: UIColor.ud.textPlaceholder
                ]
            )
            personInfoView.nameLabel.attributedText = titleString
            personInfoView.infoLabel.attributedText = summary
        }

        if messageFileMeta.fileType == .folder {
            personInfoView.avatarView.image = Resources.icon_file_folder_colorful
            lanTransIcon.isHidden = !messageFileMeta.hasFileMeta || messageFileMeta.fileMeta.source != .lanTrans
        } else if messageFileMeta.hasFileMeta, !messageFileMeta.fileMeta.name.isEmpty {
            // 头像
            let image = LarkCoreUtils.fileIconColorful(with: messageFileMeta.fileMeta.name, size: CGSize(width: 40, height: 40))
            personInfoView.avatarView.image = image
            // 局域网文件显示特定icon
            lanTransIcon.isHidden = messageFileMeta.fileMeta.source != .lanTrans
        } else {
            assertionFailure("unknown meta data")
        }
    }
    @objc
    private func gotoMessageButtonDidClick() {
        viewModel?.gotoChat()
    }
}
