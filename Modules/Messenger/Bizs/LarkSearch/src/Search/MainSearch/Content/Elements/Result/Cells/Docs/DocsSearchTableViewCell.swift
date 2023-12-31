//
//  DocsSearchTableViewCell.swift
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
import LarkMessengerInterface
import LarkAvatar
import RustPB
import LarkSearchCore
import LarkSDKInterface
import UniverseDesignIcon
import AvatarComponent
import LarkBizAvatar
import LarkDocsIcon

final class DocsSearchNewTableViewCell: SearchNewDefaultTableViewCell {
    private static let extraInfosRatios: [CGFloat] = [2, 3]
    let extraInfosView: SearchExtraInfosView = SearchExtraInfosView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        infoView.extraView.addSubview(extraInfosView)
        extraInfosView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        var config = AvatarComponentUIConfig()
        config.style = .square
        config.contentMode = .scaleAspectFit
        infoView.avatarView.setAvatarUIConfig(config)
        // 文档场景下头像内边距上下左右各2px
        let scale = (SearchResultDefaultView.searchAvatarImageDefaultSize - 4) / SearchResultDefaultView.searchAvatarImageDefaultSize
        infoView.avatarView.transform = CGAffineTransformMakeScale(scale, scale)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        infoView.extraView.isHidden = true
        extraInfosView.prepareForReuse()
    }

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        guard let currentAccount = currentAccount, let docsViewModel = viewModel as? DocsSearchViewModel else { return }
        let docMeta: SearchMetaDocType
        switch docsViewModel.searchResult.meta {
        case .doc(let v):
            docMeta = v
        case .wiki(let v):
            docMeta = v.docMetaType
        default: return
        }
        setupAvatarWith(viewModel: docsViewModel, docMeta: docMeta)
        setupInfoViewWith(viewModel: docsViewModel, docMeta: docMeta, account: currentAccount)
    }

    private func setupAvatarWith(viewModel: DocsSearchViewModel, docMeta: SearchMetaDocType) {
        let searchResult = viewModel.searchResult
        let enableDocCustomIcon = viewModel.enableDocCustomAvatar
        let avatarKey: String
        if enableDocCustomIcon, let icon = searchResult.icon, icon.type == .image {
            avatarKey = icon.value
        } else {
            avatarKey = searchResult.avatarKey
        }
        infoView.avatarView.setMiniIcon(nil)
        if avatarKey.isEmpty {
            let containerInfo = ContainerInfo(isShortCut: docMeta.type == .shortcut, isShareFolder: docMeta.isShareFolder, isWikiRoot: false)
            self.infoView.avatarView.avatar.di.setDocsImage(iconInfo: docMeta.iconInfo, url: docMeta.url, shape: .SQUARE, container: containerInfo, userResolver: viewModel.userResolver)
        } else {
            infoView.avatarView.setAvatarByIdentifier(docMeta.id, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(SearchResultDefaultView.searchAvatarImageDefaultSize)))
        }
    }

    private func setupInfoViewWith(viewModel: DocsSearchViewModel, docMeta: SearchMetaDocType, account: User) {
        let searchResult = viewModel.searchResult
        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        var sourceType: Search_V2_ResultSourceType = .net
        nameStatusConfig.nameAttributedText = searchResult.title
        if let result = searchResult as? Search.Result {
            sourceType = result.sourceType
            if SearchFeatureGatingKey.searchDynamicTag.isEnabled && sourceType == .net {
                nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
            }
        }
        if !SearchFeatureGatingKey.searchDynamicTag.isEnabled || sourceType != .net {
            var tagTypes: [TagType] = []
            if docMeta.isCrossTenant {
                if case .standard = account.type {
                    tagTypes.append(.external)
                }
            }
            nameStatusConfig.tags = tagTypes.map({ tagType in
                Tag(type: tagType)
            })
        }

        infoView.nameStatusView.updateContent(content: nameStatusConfig)

        let extraInfos = viewModel.searchResult.extraInfos
        if SearchFeatureGatingKey.enableExtraInfoUpdate.isUserEnabled(userResolver: viewModel.userResolver) && !extraInfos.isEmpty {
            extraInfosView.updateExtraInfos(extraInfos: Array(extraInfos.prefix(2)),
                                            extraInfoSeparator: viewModel.searchResult.extraInfoSeparator,
                                            ratios: Self.extraInfosRatios)
        } else {
            var extraInfoBlockSegment = RustPB.Search_V2_ExtraInfoBlockSegment()
            extraInfoBlockSegment.type = .text
            extraInfoBlockSegment.textHighlighted = BundleI18n.LarkSearch.Lark_ASL_EntryLastUpdated(Date.lf.getNiceDateString(TimeInterval(docMeta.updateTime)))
            var extraInfo = RustPB.Search_V2_ExtraInfoBlock()
            extraInfo.blockSegments = [extraInfoBlockSegment]
            extraInfosView.updateExtraInfos(extraInfos: [extraInfo], extraInfoSeparator: "")
        }
        infoView.extraView.isHidden = false
    }

    override func cellWillDisplay() {
        guard let userResolver = (viewModel as? DocsSearchViewModel)?.userResolver,
              SearchFeatureGatingKey.enableExtraInfoUpdate.isUserEnabled(userResolver: userResolver),
              !(viewModel?.searchResult.extraInfos.isEmpty ?? true) else {
            return
        }
        // avatar + space = 89
        extraInfosView.updateTotalWidth(totalWidth: self.frame.width - 89)
    }
}
