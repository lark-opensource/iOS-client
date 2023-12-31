//
//  WADataSessionError.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/9.
//

import Foundation

enum WAErrorDomain: String {
    case offline
}

enum WebAppDataSessionErrorCode: Int {
    case invalidParam = -1
    case redirect = -2
    case requestInPreload = -3
}

enum WAError: Error {
    static func offlineError(code: WebAppDataSessionErrorCode, msg: String, url: URL? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: msg]
        if let url {
            userInfo[NSURLErrorFailingURLErrorKey] = url
            userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
            
        }
        return NSError(domain: WAErrorDomain.offline.rawValue, code: code.rawValue, userInfo: userInfo)
    }
}
