//
//  ModelExtension.swift
//  LarkChat
//
//  Created by qihongye on 2018/9/28.
//

import Foundation
import LarkModel

extension LarkModel.CardContent {
    public var title: String {
        guard type == .vote,
            let titlePId = richText.elementIds.first,
            let titleId = richText.elements[titlePId]?.childIds.first,
            let title = richText.elements[titleId],
            title.tag == .text else {
                return ""
        }
        return title.property.text.content
    }
}
