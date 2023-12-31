//
//  Path+Operators.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

/// Concatenates two `Path` instances and returns the result.
///
/// ```swift
/// let systemLibrary: Path = "/System/Library"
/// print(systemLib + "Fonts")  // "/System/Library/Fonts"
/// ```
///

public func + (lhs: Path, rhs: Path) -> Path {
    if lhs.rawValue.isEmpty || lhs.rawValue == "." { return rhs }
    if rhs.rawValue.isEmpty || rhs.rawValue == "." { return lhs }
    switch (lhs.rawValue.hasSuffix(Path.separator), rhs.rawValue.hasPrefix(Path.separator)) {
    case (true, true):
        let newRhs = Path(String(rhs.rawValue.dropFirst()))
        return lhs + newRhs
    case (false, false):
        return Path("\(lhs.rawValue)\(Path.separator)\(rhs.rawValue)")
    default:
        return Path("\(lhs.rawValue)\(rhs.rawValue)")
    }
}

/// Converts a `String` to a `Path` and returns the concatenated result.

public func + (lhs: Path, rhs: String) -> Path {
    return lhs + Path(rhs)
}

/// Appends the right path to the left path.
public func += (lhs: inout Path, rhs: Path) {
    // swiftlint:disable:next shorthand_operator
    lhs = lhs + rhs
}
