//
//  StoreCardTableViewCell.swift
//  LarkSearch
//
//  Created by bytedance on 2021/8/9.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import Lynx
import LarkSearchCore
import UniverseDesignTheme
import LarkUIKit

// 华住门店卡片、通用数字卡片、服务卡片共用的cell
final class CustomizationCardTableViewCell: SearchCardTableViewCell {

    var preferredWidth: CGFloat?
    var currentTemplateName: String?
    var searchResultId: String?
    var currentSearchText: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        self.viewModel = viewModel
        let vm = self.viewModel as? StoreCardSearchViewModel
        if vm?.isContentChangeByJSB == true {
            vm?.isContentChangeByJSB = false
            return
        }
        let searchCardViewModel = self.viewModel as? SearchCardViewModel
        if case let .customization(meta) = viewModel.searchResult.meta {
            let data = LynxTemplateData(json: meta.renderContent)
            if let data = data {
                if let analysisParams = analysisParams {
                    let jsonData = try? JSONSerialization.data(withJSONObject: analysisParams)
                    guard let stringData = jsonData else { return }
                    guard let dataString = String(data: stringData, encoding: String.Encoding.utf8) else { return }
                    data.update(dataString, forKey: "analysisParams")
                }
            }
            let templateName = meta.templateName
            let id = viewModel.searchResult.id
            if self.lynxViewTemplate != nil, currentTemplateName == templateName, searchResultId == id, self.preferredWidth == searchCardViewModel?.preferredWidth, currentSearchText == searchText {
                self.lynxView?.updateData(with: data)
            } else {
                ASTemplateManager.loadTemplateWithData(templateName: templateName,
                                                       channel: ASTemplateManager.SearchChannel,
                                                       initData: data,
                                                       lynxView: self.lynxView) { [weak self] templateData in
                    self?.lynxViewTemplate = templateData
                    if templateData == nil {
                        self?.heightConstraint?.update(offset: 0)
                    }

                }
            }
            self.currentSearchText = searchText
            self.currentTemplateName = templateName
            self.searchResultId = id
            self.preferredWidth = searchCardViewModel?.preferredWidth
        }
    }
}
