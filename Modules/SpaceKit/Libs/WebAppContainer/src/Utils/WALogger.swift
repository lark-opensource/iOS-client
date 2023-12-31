//
//  WALogger.swift
//  WALogger
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LKCommonsLogging

struct WALogger {
    static let TAG = "=webapp="
    
    static let logger = Logger.log(WALogger.self, category: Self.TAG)
}


enum LogTag: String {
    case open = "[open]"
    case router = "[router]"
    case net = "[net]"
    case offline = "[offline]"
    case preload = "[preload]"
    case bridge = "[bridge]"
    case plugin = "[plugin]"
    case lifeCycle = "[lifecycle]"
}


extension URL {
    var urlForLog: String {
#if DEBUG
        return self.absoluteString
#else
        guard var component = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return ""
        }
        component.query = nil
        return component.url?.absoluteString ?? ""
#endif
    }
}
