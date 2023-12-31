//
//  SheetTabInfo.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/2.
//

import Foundation
import SKFoundation
import SKUIKit

class SheetTabInfo {
    enum CustomIconType: Int {
        case url = 0
        case universal = 1
        case none = 9999
    }
    
    var index: Int
    var text: String
    var id: String
    var editable: Bool
    var isHidden: Bool
    var isLocked: Bool
    var isSelected: Bool
    var customIcon: [String: Any?]?
    var enabled: Bool
    
    var customIconType: CustomIconType {
        guard let customIcon = customIcon else {
            return .none
        }
        let typeValue: Int = customIcon["type"] as? Int ?? CustomIconType.none.rawValue
        return CustomIconType(rawValue: typeValue) ?? .none
    }
    
    var selectedUrl: String? {
        return customIcon?["selectedUrl"] as? String
    }
    
    var unselectedUrl: String? {
        return customIcon?["unselectedUrl"] as? String
    }

    init(index: Int = 0,
         text: String = "",
         id: String = "",
         editable: Bool = false,
         isHidden: Bool = false,
         isLocked: Bool = false,
         isSelected: Bool = false,
         customIcon: [String: Any]? = nil,
         enabled: Bool = true) {
        self.index = index
        self.text = text
        self.id = id
        self.editable = editable
        self.isHidden = isHidden
        self.isLocked = isLocked
        self.isSelected = isSelected
        self.customIcon = customIcon
        self.enabled = enabled  //默认可用
    }

    public func estimatedCellWidth(boundedByMaxWidth maxWidth: CGFloat) -> CGFloat {
        if isHidden { return 0 }
        let minWidth: CGFloat = 72

        let attachmentWidth: CGFloat = (isLocked ? 20 : 0) + (isSelected && editable ? 18 : 0) + (customIconType != .none ? 22 : 0)
        let leftRightMargin: CGFloat = 24
        let fullTextNeededWidth = text.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 13))

        let fullNeededWidth = leftRightMargin + attachmentWidth + fullTextNeededWidth

        if fullNeededWidth > maxWidth {
            return maxWidth
        } else if fullNeededWidth < minWidth {
            return minWidth
        } else {
            return fullNeededWidth
        }
    }
}
