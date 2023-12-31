//
//  URL+AppLink.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/9/16.
//

import Foundation

private func encryptValue(_ value: String?) -> String? {
    guard let value = value else {
        return nil
    }
    
    if value.count <= 4 {
        return value
    }
    let prefix = value.prefix(2)
    let suffix = value.suffix(2)
    return "\(prefix)*\(suffix)_MD5\(value.md5())_L\(value.count)"
}

extension URL {
    
    func applinkEncyptString() -> String {
        // 打印整个 URL 的 md5
        let urlString = self.absoluteString
        
        // 可以打印 AppLink 的 schema、host、 path 部分, query 和 fragment 的 value 部分要加密
        
        var urlComponents = URLComponents(string: urlString)
        
        let queryItems: [URLQueryItem]? = urlComponents?.queryItems?.map({ queryItem -> URLQueryItem in
            return URLQueryItem(name: queryItem.name, value: encryptValue(queryItem.value))
        })
        
        urlComponents?.queryItems = queryItems
        
        let fragment = encryptValue(urlComponents?.fragment)
        urlComponents?.fragment = fragment
        
        return "AppLinkEncyptURL([\(encryptValue(urlString) ?? "nil")][\(urlComponents?.string ?? "nil")])"
    }
    
}
