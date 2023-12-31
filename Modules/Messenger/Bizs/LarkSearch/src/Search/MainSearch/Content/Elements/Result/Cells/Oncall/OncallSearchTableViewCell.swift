//
//  OncallTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkTag
import LarkAccountInterface
import LarkSearchCore
import RustPB
import LarkSDKInterface

final class OncallSearchNewTableViewCell: SearchNewDefaultTableViewCell {

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        guard currentAccount != nil else { return }

        setupInfoViewWith(viewModel: viewModel)
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult

        if case let .oncall(oncall) = viewModel.searchResult.meta {
            let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
            nameStatusConfig.nameAttributedText = searchResult.title
            var finalTags: [Tag] = []
            var sourceType: Search_V2_ResultSourceType = .net
            if let result = searchResult as? Search.Result {
                sourceType = result.sourceType
                if SearchFeatureGatingKey.searchDynamicTag.isEnabled && sourceType == .net {
                    finalTags = SearchResultNameStatusView.customTagsWith(result: result)
                }
            }
            if !SearchFeatureGatingKey.searchDynamicTag.isEnabled || sourceType != .net {
                if oncall.isOfficialOncall {
                    finalTags.append(.init(type: .officialOncall))
                } else {
                    if oncall.tagsV1.contains(.oncallOffline) {
                        finalTags.append(.init(type: .oncallOffline))
                    } else {
                        finalTags.append(.init(type: .oncall))
                    }
                }
                if oncall.hasCrossTagInfo, !oncall.crossTagInfo.isEmpty {
                    finalTags.append(.init(title: oncall.crossTagInfo, style: .red, type: .external))
                }
            }
            nameStatusConfig.tags = finalTags

            let faqTitle = oncall.faqTitle
            if !faqTitle.isEmpty {
                let content = NSMutableAttributedString()
                content.append(NSAttributedString(string: BundleI18n.LarkSearch.Lark_Search_QuickLink))
                content.append(NSAttributedString(string: ": "))
                content.append(NSAttributedString(string: faqTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal]))
                infoView.secondDescriptionLabel.attributedText = content
                infoView.secondDescriptionLabel.isHidden = false
            }
            infoView.nameStatusView.updateContent(content: nameStatusConfig)
        }
    }
}
