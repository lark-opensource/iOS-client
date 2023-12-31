//
//  ThreadSearchTableViewCell.swift
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
import LarkBizAvatar
import LarkSDKInterface
import LarkSearchCore

final class TopicSearchNewTableViewCell: SearchNewDefaultTableViewCell {
    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        let searchResult = viewModel.searchResult

        if let topicVM = viewModel as? TopicSearchViewModel, topicVM.enableDocCustomIcon {
            infoView.avatarView.setMiniIcon(MiniIconProps(.topic))
        } else {
            infoView.avatarView.setMiniIcon(MiniIconProps(.dynamicIcon(LarkCore.Resources.thread_topic)))
        }

        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        nameStatusConfig.nameAttributedText = searchResult.title
        if let result = searchResult as? Search.Result, result.sourceType == .net {
            nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
        }
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }
}
