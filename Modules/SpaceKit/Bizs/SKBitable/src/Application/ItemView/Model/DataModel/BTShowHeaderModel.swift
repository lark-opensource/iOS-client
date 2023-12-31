//
//  BTShowHeaderModel.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/9/14.
//

import Foundation
import SKInfra

enum BTShowHeaderType: String, SKFastDecodableEnum {
    case start
    case end
    case cancel
}

struct BTShowHeaderPoint: SKFastDecodable {
    var x: Float?
    var y: Float?

    static func deserialized(with dictionary: [String : Any]) -> BTShowHeaderPoint {
        var model = BTShowHeaderPoint()
        model.x <~ (dictionary, "x")
        model.y <~ (dictionary, "y")
        return model
    }
}

struct BTShowHeaderModel: SKFastDecodable {
    var isTopInertia: Bool?

    var type: BTShowHeaderType?
    var scrollY: Float?

    var lastPoints: [BTShowHeaderPoint]?
    var lastPointIndex: Int?

    var lastTimePoints: [BTShowHeaderPoint]?
    var lastTimePointIndex: Int?

    static func deserialized(with dictionary: [String : Any]) -> BTShowHeaderModel {
        var model = BTShowHeaderModel()
        model.isTopInertia <~ (dictionary, "isTopInertia")
        model.type <~ (dictionary, "type")
        model.scrollY <~ (dictionary, "scrollY")
        model.lastPoints <~ (dictionary, "lastPoints")
        model.lastPointIndex <~ (dictionary, "lastPointIndex")
        model.lastTimePoints <~ (dictionary, "lastTimePoints")
        model.lastTimePointIndex <~ (dictionary, "lastTimePointIndex")
        return model
    }
}
