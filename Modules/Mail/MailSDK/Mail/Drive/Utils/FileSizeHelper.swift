//
//  FileSizeHelper.swift
//  DocsSDK
//
//  Created by 邱沛 on 2019/3/19.
//

import Foundation

class FileSizeHelper {
    static func memoryFormat(_ byte: UInt64, useAbbrByte: Bool = false, spaceBeforeUnit: Bool = false) -> String {
        var size = Double(byte)
        let byte = useAbbrByte ? "B" : "Byte"
        let unit = [byte, "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        var index: Int = 0
        while size >= 1024 && (index + 1) < unit.count {
            size /= 1024
            index += 1
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let sizeString = formatter.string(from: NSNumber(value: size)) {
            let unitString = spaceBeforeUnit ? " \(unit[index])" : "\(unit[index])"
            return sizeString + unitString
        } else {
            return ""
        }
    }
}

