//
//  SimpleItemModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/11.
//

import SKFoundation
import HandyJSON
import SKInfra

enum SimpleItemStyle: String, HandyJSONEnum, SKFastDecodableEnum {
    case NORMAL = "normal"
    case DISABLE = "disable"
}

struct SimpleItem: HandyJSON, SKFastDecodable, Equatable {
    var id: String?
    var icon: BTIcon?
    var text: String?
    var style: SimpleItemStyle?
    var clickAction: String?
    var clickActionPayload: Any? // native无需感知，透传给前端
    
    static func == (lhs: SimpleItem, rhs: SimpleItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.icon == rhs.icon &&
        lhs.text == rhs.text &&
        lhs.style == rhs.style &&
        lhs.clickAction == rhs.clickAction
    }
    
    static func deserialized(with dictionary: [String : Any]) -> SimpleItem {
        var model = SimpleItem()
        model.id <~ (dictionary, "id")
        model.icon <~ (dictionary, "icon")
        model.text <~ (dictionary, "text")
        model.style <~ (dictionary, "style")
        model.clickAction <~ (dictionary, "clickAction")
        model.clickActionPayload <~ (dictionary, "clickActionPayload")
        return model
    }

    var iconImage: UIImage? {
        guard let icon = icon else { return nil }
        return BTUtil.getImage(icon: icon, style: nil)
    }
}
