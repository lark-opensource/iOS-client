//
//  BTPanelEmptyContentModel.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/9.
//

import Foundation
import HandyJSON
import UniverseDesignEmpty

enum BTPanelEmptyContentImage: Int, HandyJSONEnum {
    case noContent = 0

    func image() -> UIImage {
        switch self {
        case .noContent:
            return UDEmptyType.noContent.defaultImage()
        }
    }
}

struct BTPanelEmptyContentModel: HandyJSON {
    /*
     1. 目前双端都不支持 empty icon 通过 key 去获取，所以没法使用 BTPanelIcon，只能是 native 独有字段，不提供给前端
     2. 目前前端暂时也没有设置 contentImage 的需求
     */
    var contentImage: BTPanelEmptyContentImage?
    var desc: String?
}
