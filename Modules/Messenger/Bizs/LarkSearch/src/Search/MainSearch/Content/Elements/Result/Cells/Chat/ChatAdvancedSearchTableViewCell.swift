//
//  ChatAdvancedSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 9/12/19.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import RxSwift
import LarkSearchCore
import RustPB
import LarkSDKInterface
import LarkContainer

final class ChatAdvancedSearchNewTableViewCell: SearchNewDefaultTableViewCell {
    private static let extraInfosRatios: [CGFloat] = [3, 2]
    let extraInfosView: SearchExtraInfosView = SearchExtraInfosView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        infoView.extraView.addSubview(extraInfosView)
        extraInfosView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        infoView.avatarView.topBadge.setMaxNumber(to: 999)
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
        setupInfoViewWith(viewModel: viewModel, currentAccount: currentAccount)
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel, currentAccount: User?) {
        guard let account = currentAccount else { return }
        guard let userResolver = (viewModel as? ChatSearchViewModel)?.userResolver else { return }
        guard case .chat(let meta) = viewModel.searchResult.meta else { return }

        let searchResult = viewModel.searchResult

        let extraInfos = viewModel.searchResult.extraInfos

        if SearchFeatureGatingKey.enableExtraInfoUpdate.isUserEnabled(userResolver: userResolver) && !extraInfos.isEmpty {
            extraInfosView.updateExtraInfos(extraInfos: Array(extraInfos.prefix(2)),
                                            extraInfoSeparator: viewModel.searchResult.extraInfoSeparator,
                                            ratios: Self.extraInfosRatios)
            infoView.extraView.isHidden = false
            infoView.firstDescriptionLabel.isHidden = true
        }

        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        nameStatusConfig.nameAttributedText = searchResult.title
        var sourceType: Search_V2_ResultSourceType = .net
        if let result = searchResult as? Search.Result {
            sourceType = result.sourceType
            if SearchFeatureGatingKey.searchDynamicTag.isUserEnabled(userResolver: userResolver) && sourceType == .net {
                nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
            }
        }
        if !SearchFeatureGatingKey.searchDynamicTag.isUserEnabled(userResolver: userResolver) || sourceType != .net {
            var tagTypes: [TagType] = []
            // code_block_start tag CryptChat
            if meta.isCrypto {
                tagTypes.append(.crypto)
            }
            if meta.isShield {
                tagTypes.append(.isPrivateMode)
            }
            // code_block_end
            if meta.isOfficialOncall || meta.tags.contains(.official) {
                tagTypes.append(.officialOncall)
            } else {
                if !meta.oncallID.isEmpty, meta.oncallID != "0" {
                    if meta.tags.contains(.oncallOffline) {
                        tagTypes.append(.oncallOffline)
                    } else {
                        tagTypes.append(.oncall)
                    }
                }
                if meta.isCrossWithKa {
                    if case .standard = account.type {
                        tagTypes.append(.connect)
                    }
                } else if meta.isCrossTenant {
                    if case .standard = account.type {
                        tagTypes.append(.external)
                    }
                } else if meta.isPublicV2 {
                    tagTypes.append(.public)
                }
            }
            if meta.isDepartment {
                tagTypes.append(.team)
            }
            if meta.isTenant {
                tagTypes.append(.allStaff)
            }
            nameStatusConfig.tags = tagTypes.map({ tagType in
                Tag(type: tagType)
            })
        }
        if viewModel.searchResult.isSpotlight && SearchFeatureGatingKey.enableSpotlightLocalTag.isUserEnabled(userResolver: userResolver) {
            nameStatusConfig.shouldAddLocalTag = true
        }
        nameStatusConfig.countText = meta.userCountTextMayBeInvisible
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }

    override func cellWillDisplay() {
        guard let userResolver = (viewModel as? ChatSearchViewModel)?.userResolver,
              SearchFeatureGatingKey.enableExtraInfoUpdate.isUserEnabled(userResolver: userResolver),
              !(viewModel?.searchResult.extraInfos.isEmpty ?? true) else {
            return
        }
        // 89 = avatarSize + 前后间隔
        extraInfosView.updateTotalWidth(totalWidth: self.frame.width - 89)
    }
}
