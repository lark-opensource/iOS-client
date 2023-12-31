//
//  CommentOpenAPIResult.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/15.
//  


import LarkOpenAPIModel

@objcMembers
public final class DocsOpenAPIResult: OpenAPIBaseResult {
  
    var params: [String: Any] = [:]
    
    public init(params: [String: Any]?) {
        self.params = params ?? [:]
    }
    
    public override func toJSONDict() -> [AnyHashable: Any] {
        return params
    }
}
