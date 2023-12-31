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
import SwiftyJSON

final class QACardSearchTableViewCell: SearchCardTableViewCell {

    var currentId: String?
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
        let vm = viewModel as? SearchCardViewModel
        if vm?.isContentChangeByJSB == true {
            vm?.isContentChangeByJSB = false
            return
        }
        if case let .qaCard(meta) = viewModel.searchResult.meta {
            let data = LynxTemplateData(json: meta.qaRenderMeta)
            if let lynxViewTemplate {
                if self.currentId == meta.id, self.preferredWidth == vm?.preferredWidth {
                    self.lynxView?.updateData(with: data)
                } else {
                    self.preferredWidth = vm?.preferredWidth
                    self.lynxView?.loadTemplate(lynxViewTemplate, withURL: "", initData: data)
                }
            } else {
                ASTemplateManager.loadTemplateWithData(templateName: "card-service-precise/template.js",
                                                       channel: ASTemplateManager.SearchChannel,
                                                       initData: data,
                                                       lynxView: self.lynxView) { [weak self] templateData in
                    self?.lynxViewTemplate = templateData
                }
            }
            self.currentId = meta.id
        }
    }
}
