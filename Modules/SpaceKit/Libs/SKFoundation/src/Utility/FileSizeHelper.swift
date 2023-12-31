//
//  FileSizeHelper.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/3/19.
//

import Foundation

public final class FileSizeHelper {
    public static func memoryFormat(_ byte: UInt64) -> String {
        var size = Double(byte)
        let unit = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        var index: Int = 0
        while size >= 1024 && (index + 1) < unit.count {
            size /= 1024
            index += 1
        }
        return String(format: "%.2f", Double(size)) + unit[index]
    }
}
