//
//  OpenPromptModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIShowPromptParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    public var title: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "placeholder", defaultValue: BundleI18n.OPPlugin.show_prompt_placeholder)
    public var placeholder: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "maxLength", defaultValue: 140)
    public var maxLength: NSNumber

    @OpenAPIRequiredParam(userOptionWithJsonKey: "confirmText", defaultValue: BundleI18n.OPPlugin.show_prompt_ok)
    public var confirmText: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "cancelText", defaultValue: BundleI18n.OPPlugin.cancel)
    public var cancelText: String


    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _placeholder, _maxLength, _confirmText, _cancelText]
    }

}


final class OpenAPIShowPromptResult: OpenAPIBaseResult {


    public var confirm: Bool
    public var cancel: Bool
    public var inputValue: String?


    public init(confirm: Bool, cancel: Bool, inputValue: String?) {
        self.confirm = confirm
        self.cancel = cancel
        self.inputValue = inputValue
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        if let inputValue = inputValue {
            return ["confirm": confirm, "cancel": cancel, "inputValue": inputValue]
        }
        return ["confirm": confirm, "cancel": cancel]

    }
}
