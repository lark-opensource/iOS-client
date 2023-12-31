//
//  MailTagModel.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/6.
//

import Foundation
import RxDataSources

enum MailTagSectionItem {
    case label(_ labelModel: MailFilterLabelCellModel)
    case folder(_ folderModel: MailFilterLabelCellModel)
}

struct MailTagSection {
    var header: String
    var items: [MailTagSectionItem]
}

extension MailTagSection: SectionModelType {
    typealias Item = MailTagSectionItem

    init(original: MailTagSection, items: [Item]) {
        self = original
        self.items = items
    }
}

// struct FolderModel {
//    var title = ""
//    var path = ""
//    var tipText = ""
//
//    static func defaultValue() -> FolderModel {
//        return FolderModel(title: "", path: "", tipText: "")
//    }
//
//    static func folderToCellModel(_ model: FolderModel) -> MailTagCellViewModel {
//        return MailTagCellViewModel(name: model.title, tagPath: model.path,
//                                    fontColorHex: "#fooo", tipText: model.tipText) // 传folder的黑色
//    }
// }
