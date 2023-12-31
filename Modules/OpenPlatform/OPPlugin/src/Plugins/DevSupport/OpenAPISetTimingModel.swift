//
//  OpenAPISetTimingModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/7.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPISetTimingModel: OpenAPIBaseParams {

    public var data: [AnyHashable: Any] = [:]

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}
