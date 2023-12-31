//
//  CommonHeaderKey.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/14.
//

import Foundation


// NARK: - Header

let ContentTypeKey = "Content-Type"

// MARK: - Header Value

// ContentType
// 边扩展边增加字段
enum ContentType {
    case json
    case multipart(String)
    
    static let key: String = ContentTypeKey
    
    func toString() -> String {
        switch self {
        case .json:
            return "application/json"
        case .multipart(let boundary):
            return "multipart/form-data; boundary=\(boundary)"
        }
    }
    
}
