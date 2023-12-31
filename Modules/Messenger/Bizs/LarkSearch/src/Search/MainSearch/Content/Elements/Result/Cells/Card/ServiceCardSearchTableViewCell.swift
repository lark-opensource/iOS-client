//
//  QACardSearchTableViewCell.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/7/14.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import Lynx
import LarkSearchCore
import UniverseDesignTheme

final class ServiceCardSearchTableViewCell: SearchCardTableViewCell {

    var preferredWidth: CGFloat?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        self.viewModel = viewModel
        guard let card = viewModel.searchResult.card else {
            return
        }
        let vm = viewModel as? SearchCardViewModel
        let data = LynxTemplateData(json: card.renderContent)
        if self.lynxViewTemplate != nil, self.preferredWidth == vm?.preferredWidth {
            self.lynxView?.updateData(with: data)
        } else {
            self.preferredWidth = vm?.preferredWidth
            ASTemplateManager.loadTemplateWithData(templateName: "card-service-blur/template.js",
                                                   channel: ASTemplateManager.SearchChannel,
                                                   initData: data,
                                                   lynxView: self.lynxView) { [weak self] templateData in
                self?.lynxViewTemplate = templateData
            }
        }
    }
}
