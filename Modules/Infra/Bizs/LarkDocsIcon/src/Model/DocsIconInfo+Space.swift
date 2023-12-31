//
//  DocsIconInfo+Space.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/12/15.
//  从wiki知识库下沉下来的代码 by majie

import Foundation
import UniverseDesignColor

extension DocsIconInfo {
    
    // icon的背景色选取：通过取spaceId的后四位与颜色总数相模，取结果作为数组下标取准确的颜色
    // 设计稿：https://www.figma.com/file/G00Tn2sKlxdoIUCtCBVm4n/
    private static let colorArray: [UIColor] = [
        UDColor.O400,
        UDColor.R400,
        UDColor.C400,
        UDColor.V400,
        UDColor.P400,
        UDColor.B400,
        UDColor.I400,
        UDColor.W400,
        UDColor.T400,
        UDColor.G400
    ]
    // 处理icon的颜色展示
    public static func getIconColor(spaceId: String) -> UIColor {
        // 颜色选择
        var colorIndex: Int = 0
        let maxSubSpaceIdCount: Int = 4
        if spaceId.isEmpty || spaceId.count < maxSubSpaceIdCount {
            // spaceId不满足从数组中取色的规则，则默认取数组中第一个颜色
            colorIndex = 0
        } else {
            // 取spaceId后四位与0xFFF，与颜色总数相模
            let subSpaceId = spaceId.suffix(maxSubSpaceIdCount)
            if let subSpaceIdInt = Int(subSpaceId) {
                colorIndex = (subSpaceIdInt & 0xFFF) % colorArray.count
            } else {
                colorIndex = 0
            }
        }
        return colorArray[colorIndex]
    }
    
    // 处理icon的内容展示
    public static func getIconWord(spaceName: String) -> String {
        var text: String
        let string = spaceName.trim().capitalized
        let firstCharacter = string.first
        if let firstCharacter {
            text = String(firstCharacter)
        } else {
            // 知识库名称为空，不绘制文字
            text = ""
        }
        return text
    }
}

extension String {
    public func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
