//
//  LKTextRenderDebugOptions.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/8.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class LKTextRenderDebugOptions {
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let drawLineRect = Options(rawValue: 2 << 0)
        public static let drawRunRect = Options(rawValue: 2 << 1)
        public static let drawGlyphRect = Options(rawValue: 2 << 2)
        public static let drawOutOfRangeTextRect = Options(rawValue: 2 << 3)
    }

    var options: Options

    public init(_ options: Options) {
        self.options = options
    }

    public func contains(_ option: Options) -> Bool {
        return self.options.contains(option)
    }
}
