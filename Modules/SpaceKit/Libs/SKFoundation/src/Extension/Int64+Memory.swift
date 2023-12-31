//
//  Int64+Memory.swift
//  SKFoundation
//
//  Created by bupozhuang on 2020/7/8.
//

import Foundation

extension Int64 {
    public var memoryFormat: String {
        let unit = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        let (size, index) = memorySize(unit: unit)
        return String(format: "%.2f", Double(size)) + unit[index]
    }
    public var memoryFormatWithoutFlow: String {
        let unit = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        let (size, index) = memorySize(unit: unit)
        return String(format: "%d", Int(size)) + unit[index]
    }
    
    private func memorySize(unit: [String]) -> (Double, Int) {
        var size = Double(self)
        var index: Int = 0
        while size >= 1024 && (index + 1) < unit.count {
            size /= 1024
            index += 1
        }
        return (size, index)
    }
}
