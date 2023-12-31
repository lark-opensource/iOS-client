//
//  OpenShowModalTipModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/19.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIShowModalTipResult: OpenAPIBaseResult {
    public var title: String
    public var cancelText: String
    public var confirmText: String
    public init(title: String, cancelText: String, confirmText: String) {
        self.title = title
        self.cancelText = cancelText
        self.confirmText = confirmText
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["title": title,
                "cancelText": cancelText,
                "confirmText": confirmText]
    }
}
