//
//  SearchBarModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/11.
//

import SKFoundation
import HandyJSON
import SKInfra

struct SearchBarModel: HandyJSON, SKFastDecodable, Codable, Equatable {
    var id: String?
    var hint: String?
    
    static func deserialized(with dictionary: [String : Any]) -> SearchBarModel {
        var model = SearchBarModel()
        model.id <~ (dictionary, "id")
        model.hint <~ (dictionary, "hint")
        return model
    }
}
