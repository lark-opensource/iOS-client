//
//  OpenAPIMapParams.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/7.
//  


import LarkOpenAPIModel

open class OpenAPICommentParams: OpenAPIBaseParams {

    public var data: [AnyHashable: Any] = [:]
    
    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}
