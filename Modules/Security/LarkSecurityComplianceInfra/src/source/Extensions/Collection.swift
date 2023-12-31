//
//  Collection.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/1/13.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
