//
//  CommonUtil.swift
//  ByteViewTracker
//
//  Created by kiri on 2023/8/1.
//

import Foundation

// suppress diagnostic debug_description_in_string_interpolation_segment
extension String.StringInterpolation {
    mutating func appendInterpolation<T>(_ val: T?) {
        if let noNil = val {
            appendInterpolation(noNil)
        } else {
            appendInterpolation("<nil>")
        }
    }
}
