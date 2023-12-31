//
//  Extensions.swift
//  LKRichView
//
//  Created by qihongye on 2020/1/20.
//

import UIKit
import Foundation

postfix operator %

let MAX_SIZE = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

extension CGFloat: LKCopying {
    public static postfix func % (value: CGFloat) -> NumbericValue {
        return .percent(value)
    }

    public func copy() -> Any {
        return self
    }
}

extension Double: LKCopying {
    public static postfix func % (value: Double) -> NumbericValue {
        return .percent(CGFloat(value))
    }

    public func copy() -> Any {
        return self
    }
}

extension Int: LKCopying {
    public static postfix func % (value: Int) -> NumbericValue {
        return .percent(CGFloat(value))
    }

    public func copy() -> Any {
        return self
    }
}

extension Bool: LKCopying {
    public func copy() -> Any {
        return self
    }
}

extension NSObject: LKCopying {
}

extension CGRect {
    @inline(__always)
    func convertCoreText2UIViewCoordinate(_ frame: CGRect) -> CGRect {
        return self.applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: frame.height))
    }

    @inline(__always)
    func distance(to point: CGPoint) -> CGFloat {
        let distanceX = max(0, max(minX - point.x, point.x - maxX))
        let distanceY = max(0, max(minY - point.y, point.y - maxY))
        return CGFloat(hypotf(Float(distanceX), Float(distanceY)))
    }

    @inline(__always)
    func containsX(_ point: CGPoint) -> Bool {
        point.x >= minX - 1 && point.x <= maxX + 1
    }

    @inline(__always)
    func containsY(_ point: CGPoint) -> Bool {
        point.y >= minY - 1 && point.y <= maxY + 1
    }

    @inline(__always)
    func containsNearly(_ point: CGPoint) -> Bool {
        return containsX(point) && containsY(point)
    }

    /// Alias for origin.
    @inline(__always)
    var x: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }

    /// Alias for origin.y.
    @inline(__always)
    var y: CGFloat {
        get { return origin.y }
        set { origin.y = newValue }
    }

    /// Accesses origin.x + 0.5 * size.width.
    @inline(__always)
    var centerX: CGFloat {
        get { return x + width * 0.5 }
        set { x = newValue - width * 0.5 }
    }

    /// Accesses origin.y + 0.5 * size.height.
    @inline(__always)
    var centerY: CGFloat {
        get { return y + height * 0.5 }
        set { y = newValue - height * 0.5 }
    }

    /// Alias for origin.x.
    @inline(__always)
    var left: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }

    /// Accesses origin.x + size.width.
    @inline(__always)
    var right: CGFloat {
        get { return x + width }
        set { x = newValue - width }
    }

    /// Alias for origin.y.
    @inline(__always)
    var top: CGFloat {
        get { return y }
        set { y = newValue }
    }

    /// Accesses origin.y + size.height.
    @inline(__always)
    var bottom: CGFloat {
        get { return y + height }
        set { y = newValue - height }
    }
    // swiftlint:enable implicit_getter
}

extension CGSize {
    @inline(__always)
    func mainAxisWidth(writingMode: WritingMode) -> CGFloat {
        switch writingMode {
        case .horizontalTB:
            return width
        default:
            return height
        }
    }

    @inline(__always)
    mutating func setMainAxisWidth(writingMode: WritingMode, _ value: CGFloat) {
        switch writingMode {
        case .horizontalTB:
            width = value
        default:
            height = value
        }
    }

    @inline(__always)
    func crossAxisWidth(writingMode: WritingMode) -> CGFloat {
        switch writingMode {
        case .horizontalTB:
            return height
        default:
            return width
        }
    }

    @inline(__always)
    mutating func setCrossAxisWidth(writingMode: WritingMode, _ value: CGFloat) {
        switch writingMode {
        case .horizontalTB:
            height = value
        default:
            width = value
        }
    }
}

func multiplication(_ size: CGSize) -> UInt {
    let res = size.width * size.height
    let uIntMax = CGFloat(UInt.max)
    let uIntMin = CGFloat(UInt.min)
    guard res <= uIntMax, res >= uIntMin else {
        return res < uIntMin ? UInt.min : UInt.max
    }
    return UInt(res)
}

/// Returns a point by adding the coordinates of another point.
func + (p1: CGPoint, p2: CGPoint) -> CGPoint {
    return CGPoint(x: p1.x + p2.x, y: p1.y + p2.y)
}

/// Modifies the x and y values by adding the coordinates of another point.
func += (p1: inout CGPoint, p2: CGPoint) {
    p1.x += p2.x
    p1.y += p2.y
}

/// Returns a point by subtracting the coordinates of another point.
func - (p1: CGPoint, p2: CGPoint) -> CGPoint {
    return CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
}

/// Modifies the x and y values by subtracting the coordinates of another points.
func -= (p1: inout CGPoint, p2: CGPoint) {
    p1.x -= p2.x
    p1.y -= p2.y
}

infix operator ~<=
func ~<= (_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    return lhs <= rhs + 1
}

infix operator ~>
func ~> (_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    return lhs > rhs + 1
}

enum SequenceType: Int32 {
    case ascending
    case descending
}

extension Array {
    /**
     二分查找element所在位置（前提是已经按照某种规则排过顺序了）
     - parameters:
     - element: 要查找的元素
     - comparable: (a, b) -> Int 判定排列顺序的方法，相当于执行 a - b的结果
     - sequence: .ascending 升序 .descending 降序 default .ascending
     - Returns:
     (before: Int, after: Int) 返回所在的区间范围，
     比如：[1, 3].bsearch(2) -> (0, 1) 2不在原数组里，所以返回它应该在的区间
     比如：[1, 2, 3].bsearch(2) -> (1, 1)
     比如：[1, 1, 1].bsearch(1) -> (0, 2)
     */
    func lf_bsearch(
        _ element: Element,
        comparable: ((Element, Element) -> Int),
        sequence: SequenceType = .ascending
    ) -> (before: Int, after: Int) {
        var before = 0
        var after = self.count - 1

        // 如果超出了range直接返回最开始活着最后面
        if self.isEmpty {
            return (0, 0)
        }

        var mid = 0
        var res = 0

        var compare: (Int) -> Int

        switch sequence {
        case .ascending:
            compare = { $0 }
        case .descending:
            compare = { $0 * -1 }
        }

        switch compare(comparable(self.first!, element)) {
        case 1..<Int.max:
            return (before - 1, before)
        case 0:
            return (before, lf_last(element, start: before, end: after, comparable: comparable) ?? before)
        default:
            break
        }

        switch compare(comparable(self.last!, element)) {
        case -Int.max..<0:
            return (after, after + 1)
        case 0:
            return (lf_first(element, end: after, comparable: comparable) ?? after, after)
        default:
            break
        }

        while after - before > 1 {
            mid = (before + after) >> 1
            res = compare(comparable(self[mid], element))
            if res == 0 {
                return (lf_first(element, start: before + 1, end: mid, comparable: comparable) ?? mid,
                        lf_last(element, start: mid + 1, end: after, comparable: comparable) ?? mid)
            } else if res < 0 {
                before = mid
            } else {
                after = mid
            }
        }

        if comparable(self[before], element) == 0 {
            return (before, before)
        }
        if comparable(self[after], element) == 0 {
            return (after, after)
        }

        return (before, after)
    }

    /// 查找从end到start找第一个element
    private func lf_first(
        _ element: Element,
        start: Int? = nil,
        end: Int? = nil,
        comparable: ((Element, Element) -> Int)) -> Int? {
        let start = start ?? 0
        var end = end ?? self.count - 1

        while start <= end && end > 0 {
            end -= 1
            if comparable(self[end], element) != 0 {
                return end + 1
            }
        }
        return nil
    }

    /// 查找从start到end找第一个element
    private func lf_last(
        _ element: Element,
        start: Int? = nil,
        end: Int? = nil,
        comparable: ((Element, Element) -> Int)) -> Int? {
        var start = start ?? 0
        let end = end ?? self.count

        while start < end {
            if comparable(self[start], element) != 0 {
                return start - 1
            }
            start += 1
        }
        return nil
    }
}

@inline(__always)
func runInMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
        return
    }
    DispatchQueue.main.async {
        block()
    }
}
