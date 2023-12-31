//
//  OpenPluginReceiveBlockShareInfoModel.swift
//  OPBlock
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import LarkOpenAPIModel

open class OpenPluginReceiveBlockShareInfoRequest: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: "title")
    var title: [String: String]?

    @OpenAPIOptionalParam(jsonKey: "imageKey")
    var imageKey: [String: String]?

    @OpenAPIOptionalParam(jsonKey: "detailBtnName")
    var detailBtnName: [String: String]?

    @OpenAPIOptionalParam(jsonKey: "detailBtnLink")
    var detailBtnLink: [String: String]?

    @OpenAPIOptionalParam(jsonKey: "customMainLabel")
    var customMainLabel: [String: String]?


    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _imageKey, _detailBtnLink, _detailBtnName, _customMainLabel]
    }
}
