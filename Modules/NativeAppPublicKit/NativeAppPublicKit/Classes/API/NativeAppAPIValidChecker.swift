//
//  NativeAppAPIValidChecker.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/13.
//

import Foundation

public struct NativeAppAPIValidChecker {

    /// 参数验证器
    public typealias Checker<T> = (T) -> Bool

    /// String 参数校验非空
    public static func notEmpty(_ param: String) -> Bool {
        return !param.isEmpty
    }

    /// String 参数校验长度
    ///
    /// ...5            ---> (-∞, 5]    PartialRangeThrough
    /// ..<5            ---> (-∞, 5)    PartialRangeUpTo
    /// 5...            ---> [5, +∞)    PartialRangeFrom
    /// 5.nextUp...     ---> (5, +∞)
    /// 3..<5           ---> [3, 5)     Range
    /// 3.nextUp..<5    ---> (3, 5)
    /// 4...5           ---> [4, 5]     ClosedRange
    /// 4.nextUp...5    ---> (4, 5]
    public static func length<R: RangeExpression>(_ range: R) -> (String) -> Bool where R.Bound == Int {
        return { range ~= $0.count }
    }

    /// Number 参数校验范围
    ///
    /// ...5            ---> (-∞, 5]    PartialRangeThrough
    /// ..<5            ---> (-∞, 5)    PartialRangeUpTo
    /// 5...            ---> [5, +∞)    PartialRangeFrom
    /// 5.nextUp...     ---> (5, +∞)
    /// 3..<5           ---> [3, 5)     Range
    /// 3.nextUp..<5    ---> (3, 5)
    /// 4...5           ---> [4, 5]     ClosedRange
    /// 4.nextUp...5    ---> (4, 5]
    public static func range<R: RangeExpression>(_ range: R) -> (Int) -> Bool where R.Bound == Int {
        return { range ~= $0 }
    }

    /// Number 参数校验范围
    ///
    /// ...5.0            ---> (-∞, 5.0]    PartialRangeThrough
    /// ..<5.0            ---> (-∞, 5.0)    PartialRangeUpTo
    /// 5.0...            ---> [5.0, +∞)    PartialRangeFrom
    /// 5.0.nextUp...     ---> (5.0, +∞)
    /// 3.0..<5.0         ---> [3.0, 5.0)   Range
    /// 3.0.nextUp..<5.0  ---> (3.0, 5.0)
    /// 4.0...5.0         ---> [4.0, 5.0]   ClosedRange
    /// 4.0.nextUp...5.0  ---> (4.0, 5.0]
    public static func range<R: RangeExpression>(_ range: R) -> (Float) -> Bool where R.Bound == Float {
        return { range ~= $0 }
    }

    /// Number 参数校验范围
    ///
    /// ...5.0            ---> (-∞, 5.0]    PartialRangeThrough
    /// ..<5.0            ---> (-∞, 5.0)    PartialRangeUpTo
    /// 5.0...            ---> [5.0, +∞)    PartialRangeFrom
    /// 5.0.nextUp...     ---> (5.0, +∞)
    /// 3.0..<5.0         ---> [3.0, 5.0)   Range
    /// 3.0.nextUp..<5.0  ---> (3.0, 5.0)
    /// 4.0...5.0         ---> [4.0, 5.0]   ClosedRange
    /// 4.0.nextUp...5.0  ---> (4.0, 5.0]
    public static func range<R: RangeExpression>(_ range: R) -> (CGFloat) -> Bool where R.Bound == CGFloat {
        return { range ~= $0 }
    }

    /// Number 参数校验范围
    ///
    /// ...5.0            ---> (-∞, 5.0]    PartialRangeThrough
    /// ..<5.0            ---> (-∞, 5.0)    PartialRangeUpTo
    /// 5.0...            ---> [5.0, +∞)    PartialRangeFrom
    /// 5.0.nextUp...     ---> (5.0, +∞)
    /// 3.0..<5.0         ---> [3.0, 5.0)   Range
    /// 3.0.nextUp..<5.0  ---> (3.0, 5.0)
    /// 4.0...5.0         ---> [4.0, 5.0]   ClosedRange
    /// 4.0.nextUp...5.0  ---> (4.0, 5.0]
    public static func range<R: RangeExpression>(_ range: R) -> (Double) -> Bool where R.Bound == Double {
        return { range ~= $0 }
    }

    /// String 可选值参数校验，建议声明为 Swift Enum 并使用 OpenAPIEnum 约束
    public static func `enum`(_ options: [String]) -> (String) -> Bool {
        return { options.contains($0) }
    }

    /// [String] 可选值参数校验，建议声明为 Swift Enum 并使用 OpenAPIEnum 约束
    ///
    /// 任意一个元素不满足则参数整体校验失败，比如枚举类型为：["one", "two"]
    /// ["one", "two"]          -> 校验成功
    /// ["one"]                 -> 校验成功
    /// []                      -> 校验成功/失败，取决于 allowEmpty
    /// ["one", "one"]          -> 校验成功
    /// ["one", "three"]        -> 校验失败
    /// ["three"]               -> 校验失败
    public static func `enum`(_ options: [String], allowEmpty: Bool = true) -> ([String]) -> Bool {
        return {
            guard allowEmpty || (!allowEmpty && !$0.isEmpty) else {
                return false
            }
            return $0.allSatisfy(Self.enum(options))
        }
    }

    /// Number 可选值参数校验，建议声明为 Swift Enum 并使用 OpenAPIEnum 约束
    public static func `enum`(_ options: [Int]) -> (Int) -> Bool {
        return { options.contains($0) }
    }

    /// [Number] 可选值参数校验，建议声明为 Swift Enum 并使用 OpenAPIEnum 约束
    ///
    /// 任意一个元素不满足则参数整体校验失败，比如枚举类型为：[1, 2]
    /// [1, 2]         -> 校验成功
    /// [1]            -> 校验成功
    /// []             -> 校验成功/失败，取决于 allowEmpty
    /// [1, 1]         -> 校验成功
    /// [1, 3]         -> 校验失败
    /// [3]            -> 校验失败
    public static func `enum`(_ options: [Int], allowEmpty: Bool = true) -> ([Int]) -> Bool {
        return {
            guard allowEmpty || (!allowEmpty && !$0.isEmpty) else {
                return false
            }
            return $0.allSatisfy(Self.enum(options))
        }
    }

    /// String 类型的 pattern 校验
    ///
    /// pattern 建议使用 Swift 5 raw string 的方式(https://github.com/apple/swift-evolution/blob/master/proposals/0200-raw-string-escaping.md):
    /// OpenAPIValidChecher.regex(#"your pattern"#)
    ///
    /// regex 校验参考: https://nshipster.com/swift-regular-expressions/
    public static func regex(_ pattern: String) -> (String) -> Bool {
        return { $0.range(of: pattern, options: .regularExpression) != nil }
    }
}
