//
//  RichTextToolbarItem.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/5.
//

import UIKit
import Foundation
import UniverseDesignIcon

final class ToolbarItem {
    var identifier: String
    var image: UIImage?
    var isSelected: Bool = false
    var isEnable: Bool = true
    var jsMethod: String = ""

    init(identifier: String, json: [String: Any], jsMethod: String = "") {
        self.jsMethod = jsMethod
        self.identifier = identifier
        self.isSelected = json["selected"] as? Bool ?? false
        self.isEnable = json["enable"] as? Bool ?? true
        self.image = ToolbarItem.loadImage(by: identifier)
    }

    init(identifier: String) {
        self.identifier = identifier
        self.image = ToolbarItem.loadImage(by: identifier)
    }

    // sdk特有名称使用sdk的资源，否则去拿Docs工程的
    class func loadImage(by identifier: String) -> UIImage? {
        guard let type = BarButtonIdentifier(rawValue: identifier) else {
            return nil
        }
        return imageMapping[type]
    }

    private class var imageMapping: [BarButtonIdentifier: UIImage] {
        return [
            .bold: UDIcon.getIconByKeyNoLimitSize(.boldOutlined),
            .italic: UDIcon.getIconByKeyNoLimitSize(.italicOutlined),
            .underline: UDIcon.getIconByKeyNoLimitSize(.underlineOutlined),
            .strikethrough: UDIcon.getIconByKeyNoLimitSize(.strikethroughOutlined),
            .unorderedlist: UDIcon.getIconByKeyNoLimitSize(.disordeListOutlined),
            .orderedlist: UDIcon.getIconByKeyNoLimitSize(.orderListOutlined),
            .separator: UDIcon.getIconByKeyNoLimitSize(.separateOutlined),
            .horizontalLine: UDIcon.getIconByKeyNoLimitSize(.dividerOutlined)
        ]
    }
}

extension ToolbarItem {

    enum BarButtonIdentifier: String {
        case bold = "bold"
        case italic = "italic"
        case underline = "underline"
        case strikethrough = "strikethrough"
        case unorderedlist = "unorderedList"
        case orderedlist = "orderedList"
        case separator = "insertSeparator"
        case horizontalLine = "horizontal-line"
    }
}
