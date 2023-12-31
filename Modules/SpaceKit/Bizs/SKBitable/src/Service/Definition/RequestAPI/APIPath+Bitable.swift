//
//  APIPath+Bitable.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/7.
//

import Foundation
import SKInfra
import SKCommon

extension OpenAPI.APIPath {
    public static var getBaseRecordMeta: (_ shareToken: String) -> String = {
        return "/api/bitable/\($0)/share/record"
    }
}
