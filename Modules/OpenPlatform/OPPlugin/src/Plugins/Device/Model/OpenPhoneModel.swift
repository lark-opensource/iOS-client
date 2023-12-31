//
//  OpenPhoneModel.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIMakePhoneCallParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "phoneNumber", validChecker: { value in
        if let url = URL(string: "tel://\(value)"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    })
    public var phoneNumber: String

    public convenience init(phoneNumber: String) throws {
        let dict: [String: Any] = ["phoneNumber": phoneNumber]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_phoneNumber]
    }

}
