//
//  SKError.swift
//  SKCommon
//
//  Created by peilongfei on 2022/6/22.
//  


import Foundation

enum SKError: LocalizedError {
    case general(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case let .general(message):
            return message
        case .unknown:
            return "unknown"
        }
    }
}
