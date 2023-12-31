//
//  StringInterpolation.swift
//  ByteView
//
//  Created by liujianlong on 2021/3/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
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
