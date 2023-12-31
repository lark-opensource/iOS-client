//
//  BoxTableViewCell.swift
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
import RustPB
import LarkSDKInterface
import LarkSearchCore

final class BoxSearchNewTableViewCell: SearchNewDefaultTableViewCell {
    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        let searchResult = viewModel.searchResult
        infoView.avatarView.image = Resources.box_avatar

        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        nameStatusConfig.nameAttributedText = searchResult.title
        if let result = searchResult as? Search.Result, result.sourceType == .net {
            nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
        }
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }
}
