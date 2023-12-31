//
//  ChatSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import RxSwift
import LarkBizAvatar
import RustPB
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

final class ChatSearchNewTableViewCell: SearchNewDefaultTableViewCell {

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        guard let _currentAccount = currentAccount else { return }
        setupAvatarWith(viewModel: viewModel)
        setupInfoViewWith(viewModel: viewModel, account: _currentAccount)
    }

    private func setupAvatarWith(viewModel: SearchCellViewModel) {
        infoView.avatarView.topBadge.setMaxNumber(to: 999)
        if case let .chat(meta) = viewModel.searchResult.meta {
            let enableThreadMiniIcon = (viewModel as? ChatSearchViewModel)?.enableThreadMiniIcon ?? false && meta.type == .topicGroup
            infoView.avatarView.setMiniIcon(enableThreadMiniIcon ? MiniIconProps(.thread) : nil)
        }
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel, account: User) {
        guard let userResolver = try? Container.shared.getUserResolver(userID: account.userID) else { return }
        let searchResult = viewModel.searchResult

        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()

        nameStatusConfig.nameAttributedText = searchResult.title

        if case let .chat(meta) = searchResult.meta {
            var sourceType: Search_V2_ResultSourceType = .net
            if let result = searchResult as? Search.Result {
                sourceType = result.sourceType
                if sourceType == .net {
                    nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
                }
            }

            if sourceType != .net {
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
            nameStatusConfig.countText = meta.userCountTextMayBeInvisible
        }
        if viewModel.searchResult.isSpotlight && SearchFeatureGatingKey.enableSpotlightLocalTag.isUserEnabled(userResolver: userResolver) {
            nameStatusConfig.shouldAddLocalTag = true
        }
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }
}
