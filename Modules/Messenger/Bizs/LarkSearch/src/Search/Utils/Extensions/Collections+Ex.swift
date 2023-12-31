//
//  Collections+Ex.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/20.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
