//
//  BTBackground.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/30.
//

import Foundation
import SKInfra

struct BTBackground: SKFastDecodable {
    var color: String = ""
    var radius: Double = 0.0

    static func deserialized(with dictionary: [String: Any]) -> BTBackground {
        var model = BTBackground()
        model.color <~ (dictionary, "color")
        model.radius <~ (dictionary, "radius")
        return model
    }
}
