//
//  Font.swift
//  LarkZoomableDev
//
//  Created by bytedance on 2021/4/26.
//

import Foundation
import UIKit
import LarkZoomable

struct Font {
    var font: UIFont
    var name: String
    var weight: String {
        guard var weight = font.fontDescriptor.fontAttributes[UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")] as? String else { return "" }
        weight.removeFirst(6)
        weight.removeLast(5)
        return weight
    }
}

extension Font {

    static func getExamples(zoom: Zoom) -> [Font] {
        return [
            Font(font: LarkFont.getTitle0(for: zoom), name: "title0"),
            Font(font: LarkFont.getTitle1(for: zoom), name: "title1"),
            Font(font: LarkFont.getTitle2(for: zoom), name: "title2"),
            Font(font: LarkFont.getTitle3(for: zoom), name: "title3"),
            Font(font: LarkFont.getTitle4(for: zoom), name: "title4"),
            Font(font: LarkFont.getHeadline(for: zoom), name: "headline"),
            Font(font: LarkFont.getBody0(for: zoom), name: "body0"),
            Font(font: LarkFont.getBody1(for: zoom), name: "body1"),
            Font(font: LarkFont.getBody2(for: zoom), name: "body2"),
            Font(font: LarkFont.getCaption0(for: zoom), name: "caption0"),
            Font(font: LarkFont.getCaption1(for: zoom), name: "caption1"),
            Font(font: LarkFont.getCaption2(for: zoom), name: "caption2"),
            Font(font: LarkFont.getCaption3(for: zoom), name: "caption3")
        ]
    }
}
