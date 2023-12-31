//
//  BTColorModel.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/25.
//  


import Foundation
import HandyJSON
import SKCommon
import SKInfra

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
public struct BTColorModel: HandyJSON, Equatable, SKFastDecodable {
    public var color = ""
    public var id = 0
    public var textColor = ""

    public static func deserialized(with dictionary: [String : Any]) -> BTColorModel {
        var model = BTColorModel()
        model.color <~ (dictionary, "color")
        model.id <~ (dictionary, "id")
        model.textColor <~ (dictionary, "textColor")
        return model
    }

    public static func == (lhs: BTColorModel, rhs: BTColorModel) -> Bool {
        lhs.color == rhs.color &&
        lhs.id == rhs.id &&
        lhs.textColor == rhs.textColor
    }

    public init() {}

    public init(color: String = "", id: Int = 0, textColor: String = "") {
        self.color = color
        self.id = id
        self.textColor = textColor
    }
    
}

