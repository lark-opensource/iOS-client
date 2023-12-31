//
//  EmptyModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/11.
//

import SKFoundation
import HandyJSON
import SKInfra

struct EmptyModel: HandyJSON, SKFastDecodable, Equatable {
    var text: String?
    var icon: BTIcon?
    
    static func deserialized(with dictionary: [String : Any]) -> EmptyModel {
        var model = EmptyModel()
        model.text <~ (dictionary, "text")
        model.icon <~ (dictionary, "icon")
        return model
    }
}
