// 
// Created by duanxiaochen.7 on 2020/7/1.
// Affiliated with SKCommon.
// 
// Description:

import Foundation
import HandyJSON

struct InsertBlockDataModel: HandyJSON {
    var title: String = ""
    var children: [BlockSectionModel] = []
    var callback: String = ""

    func contentHeight(uiConstant: InsertBlockUIConstant) -> CGFloat {
        guard children.count >= 1 else { return 0 }

        let sectionTotalHeight: CGFloat = children.reduce(0) { (res, section) -> CGFloat in res + section.rowHeight(uiConstant: uiConstant) }
        let gapTotalHeight: CGFloat = CGFloat(children.count - 1) * uiConstant.sectionSpacing
        return sectionTotalHeight + gapTotalHeight
    }
}

struct BlockSectionModel: HandyJSON {
    var subTitle: String?
    var data: [BlockModel] = []

    func cellMaxHeight(uiConstant: InsertBlockUIConstant) -> CGFloat {
        return ceil(data.reduce(0) { (res, block) -> CGFloat in max(res, block.cellHeight(uiConstant: uiConstant)) })
    }

    func rowHeight(uiConstant: InsertBlockUIConstant) -> CGFloat {
        let subTitleHeight: CGFloat = subTitle == nil ? 0 : uiConstant.sectionHeaderHeight
        return subTitleHeight + cellMaxHeight(uiConstant: uiConstant)
    }
}

struct BlockModel: HandyJSON {
    var id: String = "" // 定义见 BarButtonIdentifier
    var name: String?
    var showBadge: Bool?
    // admin限制，true置灰弹toast
    var adminLimit: Bool = false

    func cellHeight(uiConstant: InsertBlockUIConstant) -> CGFloat {
        if let name = name {
            let size = name.estimatedMultilineUILabelSize(in: UIFont.systemFont(ofSize: uiConstant.blockCellTextFontSize, weight: .regular),
                                                          maxWidth: uiConstant.blockCellIconEdge, expectLastLineFillPercentageAtLeast: nil)
            return uiConstant.blockCellIconTopSpace + uiConstant.blockCellIconEdge + uiConstant.blockCellIconTextSpacing + ceil(size.height)
        } else {
            return uiConstant.blockCellIconTopSpace + uiConstant.blockCellIconEdge
        }
    }
}
