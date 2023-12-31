//
//  BTButtonModel.swift
//  SKBitable
//
//  Created by zoujie on 2023/1/6.
//  

import Foundation
import HandyJSON
import SKCommon
import SKInfra

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTButtonModel: HandyJSON, Equatable, Hashable, SKFastDecodable {
    /// 按钮文档
    var title: String = ""
    /// 按钮颜色
    var color: Int = 0
    /// 按钮状态
    var status: BTButtonFieldStatus = .general
    /// 点击是否触发流程
//    var clickable: Bool = true
    
    static func deserialized(with dictionary: [String : Any]) -> BTButtonModel {
        var model = BTButtonModel()
        model.title <~ (dictionary, "title")
        model.color <~ (dictionary, "color")
        model.status <~ (dictionary, "status")
        return model
    }
    
    static func == (lhs: BTButtonModel, rhs: BTButtonModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(color)
        hasher.combine(status)
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTButtonColorModel: HandyJSON, Equatable, SKFastDecodable {
    struct ButtonColor: HandyJSON, Equatable, SKFastDecodable {
        var bgColor: String = ""
        var textColor: String = ""
        static func deserialized(with dictionary: [String : Any]) -> ButtonColor {
            var model = ButtonColor()
            model.bgColor <~ (dictionary, "bgColor")
            model.textColor <~ (dictionary, "textColor")
            return model
        }
    }
    
    //默认蓝色
    var id: Int = 0
    var name: String = ""
    var styles: [String: ButtonColor] = [:]
    
    static func deserialized(with dictionary: [String : Any]) -> BTButtonColorModel {
        var model = BTButtonColorModel()
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.styles <~ (dictionary, "styles")
        return model
    }
}

enum BTButtonFieldStatus: String, HandyJSONEnum, SKFastDecodableEnum {
    case general = "default" //默认态，可点击
    case loading //执行态，不可点击
    case active //点击态
    case done // 执行完成，800ms后转换为general状态，不可点击
    case disable //不可点态
}

enum BTTriggerType: Int, HandyJSONEnum, SKFastDecodableEnum {
    case none = 0
    case automation = 1
}

enum BTButtonFieldTriggerResultCode: Int {
    case success = 0
    case failed = -1
    case longTime = -2 //trigger执行超过4s
}
