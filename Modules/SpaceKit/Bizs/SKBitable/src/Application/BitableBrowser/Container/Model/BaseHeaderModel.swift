//
//  BaseHeaderModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/12.
//

import Foundation
import SKInfra
import HandyJSON

struct BaseHeaderModel: SKFastDecodable {
    var mainTitle: String?
    var subTitle: String?
    var icon: BTIcon?
    var tableIcon: BTIcon?
    
    static func deserialized(with dictionary: [String : Any]) -> BaseHeaderModel {
        var model = BaseHeaderModel()
        model.mainTitle <~ (dictionary, "mainTitle")
        model.subTitle <~ (dictionary, "subTitle")
        model.icon <~ (dictionary, "icon")
        model.tableIcon <~ (dictionary, "tableIcon")
        return model
    }
}

extension BaseHeaderModel {
    func hasValidData() -> Bool {
        return subTitle.isEmpty == false
    }
}
