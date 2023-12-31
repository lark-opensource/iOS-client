//
//  ECOIdentifier.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/14.
//

import Foundation
class ECOIdentifier {
    static private var identifiers: [String: Int] = [:]
    static private let semaphore = DispatchSemaphore(value: 1)
    
    static public func createIdentifier(key: String) -> String {
        semaphore.wait(); defer {semaphore.signal()}
        var value = 0
        if let existedValue = identifiers[key] {
            value = existedValue + 1
        }
        identifiers[key] = value
        return "\(key)_\(value)"
    }
}
