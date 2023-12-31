//
//  HighlightableBody.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/7/1.
//

import Foundation
import EENavigator

public protocol HighlightableBody: PlainBody {
    var highlight: String? { get }
}

extension HighlightableBody {
    // swiftlint:disable all
    public var _url: URL {
        if let key = highlight, !key.isEmpty {
            return URL(string: "\(Self.pattern)#highlight") ?? .init(fileURLWithPath: "")
        }
        return URL(string: Self.pattern) ?? .init(fileURLWithPath: "")
    }
    // swiftlint:enable all
}
