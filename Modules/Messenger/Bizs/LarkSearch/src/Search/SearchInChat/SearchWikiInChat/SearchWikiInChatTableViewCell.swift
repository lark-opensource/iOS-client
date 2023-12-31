//
//  SearchWikiInChatTableViewCell.swift
//  LarkSearch
//
//  Created by Fangzhou Liu on 2019/8/15.
//

import Foundation
import UIKit
import RustPB
import LarkUIKit
import LarkTag
import LarkCore
import LarkSearchCore
import LarkExtensions
import LarkSDKInterface

final class SearchWikiInChatTableViewCell: BaseSearchInChatTableViewCell {
    private let tagLabel: PaddingUILabel
    private let nameTag = TagWrapperView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        tagLabel = PaddingUILabel()
        tagLabel.color = UIColor.clear
        tagLabel.paddingLeft = 5
        tagLabel.paddingRight = 5
        tagLabel.isHidden = true
        tagLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        tagLabel.layer.cornerRadius = 4
        tagLabel.layer.borderWidth = 0
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.textColor = UIColor.ud.colorfulRed
        tagLabel.color = UIColor.ud.R100

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle

        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.ud.textPlaceholder

        let goChatButton: UIButton = UIButton(type: .custom)
        goChatButton.setImage(Resources.goDoc.withRenderingMode(.alwaysTemplate), for: .normal)
        goChatButton.tintColor = UIColor.ud.iconN2
        goChatButton.addTarget(self, action: #selector(goChat), for: .touchUpInside)
        self.contentView.addSubview(goChatButton)
        goChatButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        textWarrperView.snp.remakeConstraints({ (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView)
            make.right.lessThanOrEqualTo(goChatButton.snp.left).offset(-31)
        })

        self.contentView.addSubview(nameTag)
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        nameTag.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.titleLabel)
            make.height.equalTo(16)
            make.right.lessThanOrEqualTo(goChatButton.snp.left).offset(-4)
            make.left.equalTo(self.titleLabel.snp.right).offset(6)
        }
    }

    @objc
    func goChat() {
        self.viewModel?.gotoChat()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        super.update(viewModel: viewModel, currentSearchText: currentSearchText)
        guard let searchResult = viewModel.data, case .wiki(let meta) = searchResult.meta else { return }

        var sourceType: Search_V2_ResultSourceType = .net
        if let result = searchResult as? Search.Result {
            sourceType = result.sourceType
        }

        let title = searchResult.title

        let avatarKey = searchResult.docAvatarKey(viewModel.enableDocCustomAvatar)
        if avatarKey.isEmpty {
            avatarView.image = LarkCoreUtils.wikiIconColorful(
                docType: meta.docMetaType.type,
                fileName: title.string
            )
        } else {
            avatarView.setAvatarByIdentifier(viewModel.chatId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        }

        let summary = NSMutableAttributedString(attributedString: searchResult.summary)
        summary.append(NSAttributedString(string: " "))
        summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(meta.docMetaType.updateTime))))

        titleLabel.attributedText = title
        subtitleLabel.attributedText = summary

        if SearchFeatureGatingKey.searchDynamicTag.isEnabled,
           sourceType == .net {
            viewModel.showCustomTag(tagView: nameTag)
        } else {
            var tagTypes: [TagType] = []
            if meta.docMetaType.isCrossTenant {
                tagTypes.append(.external)
            }
            nameTag.setTags(tagTypes)
        }
    }
}
