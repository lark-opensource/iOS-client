//
//  SearchDocInChatTableViewCell.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/23.
//

import Foundation
import UIKit
import RustPB
import LarkTag
import LarkCore
import LarkUIKit
import LarkAvatar
import LarkExtensions
import LarkSearchCore
import LarkSDKInterface
import LarkDocsIcon
import AvatarComponent

final class SearchDocInChatTableViewCell: BaseSearchInChatTableViewCell {
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
        goChatButton.hitTestEdgeInsets = .init(edges: -20)
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
        var config = AvatarComponentUIConfig()
        config.style = .square
        config.contentMode = .scaleAspectFit
        avatarView.setAvatarUIConfig(config)
               // 文档场景下头像内边距上下左右各2px
        let scale = (SearchResultDefaultView.searchAvatarImageDefaultSize - 4) / SearchResultDefaultView.searchAvatarImageDefaultSize
        avatarView.transform = CGAffineTransformMakeScale(scale, scale)

    }

    @objc
    func goChat() {
        self.viewModel?.gotoChat()
        trackResultClick()
    }

    private func trackResultClick() {
        let filters = viewModel?.context.clickInfo?().filters ?? []
        var isThreadGroup: Bool?
        if let chatId = viewModel?.context.chatId,
           let localChat = viewModel?.chatAPI.getLocalChat(by: chatId) {
            isThreadGroup = localChat.chatMode == .threadV2
        }
        SearchTrackUtil.trackSearchResultClick(viewModel: viewModel,
                                               sessionId: viewModel?.context.clickInfo?().sessionId ?? "",
                                               searchLocation: viewModel?.context.clickInfo?().searchLocation ?? "",
                                               isSmartSearch: false,
                                               isSuggested: false,
                                               query: viewModel?.context.clickInfo?().query ?? "",
                                               sceneType: "chat",
                                               filterStatus: filters.withNoFilter ? .none : .some(filters.convertToFilterStatusParam()),
                                               selectedRecFilter: filters.convertToSelectedRecommendFilterTrackingInfo(),
                                               imprID: viewModel?.context.clickInfo?().imprId ?? "",
                                               at: viewModel?.indexPath ?? IndexPath(row: 0, section: 0),
                                               in: viewModel?.context.clickInfo?().tableView ?? UITableView(),
                                               chatId: viewModel?.context.chatId,
                                               chatType: viewModel?.context.chatType,
                                               isThreadGroup: isThreadGroup,
                                               resultType: .doc,
                                               isEnterConversation: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        super.update(viewModel: viewModel, currentSearchText: currentSearchText)
        guard let searchResult = viewModel.data, let meta = viewModel.docMeta() else { return }

        var sourceType: Search_V2_ResultSourceType = .net
        if let result = viewModel.data as? Search.Result {
            sourceType = result.sourceType
        }

        let title = searchResult.title
        let avatarKey = searchResult.docAvatarKey(viewModel.enableDocCustomAvatar)
        if avatarKey.isEmpty {
            let containerInfo = ContainerInfo(isShortCut: meta.type == .shortcut, isShareFolder: meta.isShareFolder, isWikiRoot: false)
            self.avatarView.avatar.di.setDocsImage(iconInfo: meta.iconInfo, url: meta.url, shape: .SQUARE, container: containerInfo, userResolver: viewModel.userResolver)
        } else {
            avatarView.setAvatarByIdentifier(viewModel.chatId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
//        if viewModel.enableDocCustomAvatar {
//            avatarView.setMiniIcon(searchResult.meta?.miniIcon)
//        } else {
//            avatarView.setMiniIcon(nil)
//        }
        let summary = NSMutableAttributedString(attributedString: searchResult.summary)
        summary.append(NSAttributedString(string: " "))
        summary.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(meta.updateTime))))

        titleLabel.attributedText = title
        subtitleLabel.attributedText = summary

        if SearchFeatureGatingKey.searchDynamicTag.isEnabled,
           sourceType == .net {
            viewModel.showCustomTag(tagView: nameTag)
        } else {
            var tagTypes: [TagType] = []
            if meta.isCrossTenant {
                tagTypes.append(.external)
            }
            nameTag.setTags(tagTypes)
        }
    }
}
