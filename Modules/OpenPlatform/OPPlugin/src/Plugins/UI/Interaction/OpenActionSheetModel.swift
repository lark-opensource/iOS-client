//
//  OpenActionSheetModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIShowActionSheetParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "itemList", validChecker: {
        !$0.isEmpty && $0.count <= 6
    })
    public var itemList: [String]


    @OpenAPIRequiredParam(userOptionWithJsonKey: "itemColor", defaultValue: "")
    public var itemColor: String

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        var itemListParam: [String] = []
        for item in self.itemList {
            if !item.isEmpty {
                itemListParam.append(item)
            }
        }
        if !itemListParam.isEmpty {
            self.itemList = itemListParam
        } else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage(BundleI18n.OPPlugin.itemlist_non_null())
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_itemList, _itemColor]
    }

}

final class OpenAPIShowActionSheetResult: OpenAPIBaseResult {


    public var tapIndex: Int


    public init(tapIndex: Int) {
        self.tapIndex = tapIndex
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["tapIndex": tapIndex]

    }
}
