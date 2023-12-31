//
//  JPEG.swift
//  EEImageMagick
//
//  Created by qihongye on 2019/12/3.
//

import Foundation

public func isJPEG(_ data: Data) -> Bool {
    return data.withUnsafeBytes({ (buffer) -> Bool in
        guard let bytes = buffer.baseAddress?.bindMemory(to: UInt8.self, capacity: 3) else {
            return false
        }
        return is_jpeg(bytes, data.count) == 1
    })
}

/// Get JPEG data's quality.
/// - Parameter data: JPEG data
/// - Retuens: [0, 100]. Get nil if image is not jpeg or can not get its quality.
public func getJPEGQuality(_ data: Data) -> Int? {
    return data.withUnsafeBytes { (buffer) -> Int? in
        guard let bytes = buffer.baseAddress?.bindMemory(to: UInt8.self, capacity: buffer.count) else {
            return nil
        }
        if is_jpeg(bytes, data.count) != 1 {
            return nil
        }
        return jpeg_get_quality(bytes, data.count)
    }
}

public func getJPEGQuality(path: String) -> Int? {
    return path.withCString({ (pointer) -> Int in
        jpeg_get_quality_by_path(pointer)
    })
}
