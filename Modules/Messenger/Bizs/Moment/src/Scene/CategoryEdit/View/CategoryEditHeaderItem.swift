//
//  CategoryEditHeaderViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/5/19.
//

import Foundation
import UIKit
enum CategoryEditHeaderStyle {
    case single
    case multiline(_ desHeight: CGFloat)
    static func == (lhs: CategoryEditHeaderStyle, rhs: CategoryEditHeaderStyle) -> Bool {
        switch (lhs, rhs) {
        case (.single, .single): return true
        case (.multiline, .multiline): return true
        default: return false
        }
    }
}
final class CategoryEditHeaderItem {
    let title: String
    let des: String
    let showEditBtn: Bool
    let maxWidth: CGFloat
    var style: CategoryEditHeaderStyle = .single
    var loadingTab = false
    var settingTab = false
    var hadEditItems = true
    var suggestHeight: CGFloat {
        switch style {
        case .single:
            return 40
        case .multiline(let desHeight):
            return 40 + 8 + desHeight
        }
    }
    init(title: String, des: String, showEditBtn: Bool, maxWidth: CGFloat) {
        self.title = title
        self.des = des
        self.showEditBtn = showEditBtn
        self.maxWidth = maxWidth
        style = calculateStyle()
    }
    private func calculateStyle() -> CategoryEditHeaderStyle {
        let titleWidth = MomentsDataConverter.widthForString(title, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        let desWidth = MomentsDataConverter.widthForString(des, font: UIFont.systemFont(ofSize: 14))
        let editBtnWidth = showEditBtn ? MomentsDataConverter.widthForString(BundleI18n.Moment.Lark_Community_Done, font: UIFont.systemFont(ofSize: 14)) : 0
        return titleWidth + desWidth + editBtnWidth + 16 > maxWidth ? .multiline(MomentsDataConverter.heightForString(des, onWidth: maxWidth, font: UIFont.systemFont(ofSize: 16))) : .single
    }
}
