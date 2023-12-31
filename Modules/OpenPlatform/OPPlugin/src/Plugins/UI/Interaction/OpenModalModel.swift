//
//  OpenModalModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenAPIModel
import ECOInfra

final class OpenAPIShowModalParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    public var title: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "content", defaultValue: "")
    public var content: String

    public var confirmText: String = BundleI18n.OPPlugin.Lark_Legacy_Confirm

    public var cancelText: String = BundleI18n.OPPlugin.cancel

    public var showCancel: Bool = true

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        // 不能同时为空
        if self.title.isEmpty && self.content.isEmpty {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage(BundleI18n.OPPlugin.title_or_content_non_null)
            .setErrno(OpenAPIShowModalErrno.invalidParams)
        }
        if let showCancelParam = params["showCancel"] as? Bool {
            self.showCancel = showCancelParam
        } else if let showCancelParam = params["showCancel"] as? NSNumber {
            self.showCancel = (showCancelParam.intValue != 0)
        } else if let showCancelParam = params["showCancel"] as? String {
            self.showCancel = Int(showCancelParam) != 0
        }
        
        if self.showCancel, let cancelTextParam = params["cancelText"] as? String, !cancelTextParam.isEmpty {
            self.cancelText = cancelTextParam
        }
        
        if let confirmTextParam = params["confirmText"] as? String, !confirmTextParam.isEmpty {
            self.confirmText = confirmTextParam
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _content]
    }

}

final class OpenAPIShowModalResult: OpenAPIBaseResult {


    public var confirm: Bool
    public var cancel: Bool


    public init(confirm: Bool, cancel: Bool) {
        self.confirm = confirm
        self.cancel = cancel
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["confirm": confirm, "cancel": cancel]

    }
}
