//
//  String+Description.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

extension String {
    init(indent: String, sep: String = ", ", _ arguments: String...) {
        var dest: String = "\(indent)("
        let count = arguments.count - 1
        for (idx, item) in arguments.enumerated() {
            dest.append(item)
            if idx < count {
                dest.append(sep)
            }
        }
        dest.append(")")
        self = dest
    }

    init(name: String, dropNil: Bool = true, _ arguments: ModelDescriptionProps) {
        var dest: String = "\(name)("
        let count = arguments.props.count - 1
        for (idx, (key, value)) in arguments.props.enumerated() {
            if let value = value {
                dest.append("\(key): \(value)")
            } else if dropNil {
                continue
            } else {
                dest.append("\(key): <nil>")
            }
            if idx < count {
                dest.append(", ")
            }
        }
        dest.append(")")
        self = dest
    }
}

struct ModelDescriptionProps: ExpressibleByDictionaryLiteral {
    let props: [(String, Any?)]
    init(dictionaryLiteral elements: (String, Any?)...) {
        var list: [(String, Any?)] = []
        for prop in elements {
            list.append(prop)
        }
        self.props = list
    }
}

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

extension Bool {
    @inline(__always)
    var toInt: Int {
        self ? 1 : 0
    }
}
