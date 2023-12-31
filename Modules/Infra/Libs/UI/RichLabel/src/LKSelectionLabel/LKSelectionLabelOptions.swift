//
//  SelectionLKLabelOptions.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/19.
//

import UIKit
import Foundation
public enum LKSelectionLabelOption {
    case cursorTouchHitTestInsets(UIEdgeInsets)
    case selectionColor(UIColor)
    case cursorColor(UIColor)
    case touchInsets(UIEdgeInsets)
    case startCursor(LKSelectionCursor)
    case endCursor(LKSelectionCursor)
    case textRangeMagnifier(LKMagnifier)

    public var key: Int {
        switch self {
        case .cursorTouchHitTestInsets:
            return 0
        case .selectionColor:
            return 1
        case .cursorColor:
            return 2
        case .touchInsets:
            return 3
        case .startCursor:
            return 4
        case .endCursor:
            return 5
        case .textRangeMagnifier:
            return 6
        }
    }
}

public typealias SelectionLKLabelOptions = [LKSelectionLabelOption]
public let DefaultSelectionLKLabelOptions: SelectionLKLabelOptions = []

extension Array where Iterator.Element == LKSelectionLabelOption {
    func lastMatch(_ targetKey: Int) -> Iterator.Element? {
        if isEmpty {
            return nil
        }
        return self.last(where: { $0.key == targetKey })
    }
}

public extension Array where Iterator.Element == LKSelectionLabelOption {
    var cursorTouchHitTestInsets: UIEdgeInsets? {
        guard let item = lastMatch(0),
            case .cursorTouchHitTestInsets(let insets) = item else {
                return nil
        }
        return insets
    }

    var selectionColor: UIColor? {
        guard let item = lastMatch(1),
            case .selectionColor(let color) = item else {
                return nil
        }
        return color
    }

    var cursorColor: UIColor? {
        guard let item = lastMatch(2),
            case .cursorColor(let color) = item else {
                return nil
        }
        return color
    }

    var touchInsets: UIEdgeInsets? {
        guard let item = lastMatch(3),
            case .touchInsets(let insets) = item else {
                return nil
        }
        return insets
    }

    var startCursor: LKSelectionCursor? {
        guard let item = lastMatch(4),
            case .startCursor(let cursor) = item else {
                return nil
        }
        return cursor
    }

    var endCursor: LKSelectionCursor? {
        guard let item = lastMatch(5),
            case .endCursor(let cursor) = item else {
                return nil
        }
        return cursor
    }

    var textRangeMagnifier: LKMagnifier? {
        guard let item = lastMatch(6),
            case .textRangeMagnifier(let magnifier) = item else {
                return nil
        }
        return magnifier
    }
}

public final class LKSelectionLabelDebugOptions {
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let drawStartEndRect = Options(rawValue: 2 << 0)
        public static let drawLineRect = Options(rawValue: 2 << 1)
        public static let printTouchEvent = Options(rawValue: 2 << 2)
    }

    var options: Options

    public init(_ options: Options) {
        self.options = options
    }

    public func contains(_ option: Options) -> Bool {
        return self.options.contains(option)
    }
}
