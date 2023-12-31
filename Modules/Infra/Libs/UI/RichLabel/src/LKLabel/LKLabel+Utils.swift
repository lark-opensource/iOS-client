//
//  LKLabel+Utils.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/3/8.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UniverseDesignFont
import UIKit

public func convertAttributeStringToImage(_ attrStr: NSAttributedString, size: CGSize? = nil) -> UIImage? {
    var textColor = UIColor.black.cgColor
    let foregoundColorKey = NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)
    if CFGetTypeID(attrStr.attribute(foregoundColorKey, at: 0, effectiveRange: nil) as CFTypeRef) == CGColor.typeID {
        // swiftlint:disable:next force_cast
        textColor = attrStr.attribute(foregoundColorKey, at: 0, effectiveRange: nil) as! CGColor
    } else if let color = attrStr.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
        textColor = color.cgColor
    }
    let mutable = NSMutableAttributedString(attributedString: attrStr)
    mutable.addAttribute(.foregroundColor,
                         value: UIColor(cgColor: textColor),
                         range: NSRange(location: 0, length: mutable.length))
    UIGraphicsBeginImageContextWithOptions(size ?? mutable.size(), false, 0.0)
    mutable.draw(at: .zero)
    defer {
        UIGraphicsEndImageContext()
    }
    return UIGraphicsGetImageFromCurrentImageContext()
}

func convertPointWith(_ point: CGPoint, initialRect: CGRect, toRect: CGRect) -> CGPoint {
    CGPoint(x: point.x - toRect.origin.x + initialRect.origin.x, y: point.y - toRect.origin.y + initialRect.origin.y)
}

extension UIFont {

    public func italic() -> UIFont {
        return self.italic
    }

    public func bold() -> UIFont {
        return self.medium
    }

    public func italicBold() -> UIFont {
        return self.boldItalic
    }

    public func noItalic() -> UIFont {
        return self.removeItalic()
    }
}

extension NSRange {
    func toArray() -> [CFIndex] {
        var array = [CFIndex].init(repeating: 0, count: self.length)
        for i in 0..<self.length {
            array[i] = self.location + i
        }
        return array
    }
}

func LKTextLineGetTextRunIndexForPosition(_ line: LKTextLine, _ position: CGPoint, _ fuzzyFrame: (CGRect) -> CGRect) -> CFIndex {
    let lineFrame = fuzzyFrame(line.frame)
    guard lineFrame.contains(position) else {
        return kCFNotFound
    }
    let pt = CGPoint(x: position.x - lineFrame.origin.x, y: position.y - lineFrame.origin.y)
    guard let pointAtRunIdx = bsearchPointAt(pt, frames: line.runs.map({ fuzzyFrame($0.frame) }), direction: 1) else {
        return kCFNotFound
    }
    return pointAtRunIdx
}

/// LTR下，自行实现返回一个点在line的Index，系统实现有误差
///
/// - Parameters:
///   - line: LKTextLine
///   - position: CGPoint
/// - Returns: CFIndex, return kCFNotFound if not contain
func LKTextLineGetStringIndexForPosition(_ line: LKTextLine, _ position: CGPoint, _ fuzzyFrame: (CGRect) -> CGRect) -> CFIndex {
    let pointAtRunIdx = LKTextLineGetTextRunIndexForPosition(line, position, fuzzyFrame)
    guard pointAtRunIdx != kCFNotFound else {
        return pointAtRunIdx
    }
    let (beforeIdx, _) = line.runs[pointAtRunIdx].glyphPoints.map({ $0.x }).lf_bsearch(position.x - line.origin.x, comparable: ({ Int($0 - $1) }))

    if beforeIdx == kCFNotFound {
        return line.runs[pointAtRunIdx].range.location
    }
    return line.runs[pointAtRunIdx].indices[beforeIdx]
}

func LKTextRunGetGlyphIndexForStringIndex(_ run: LKTextRun, location: CFIndex) -> CFIndex {
    let (glyphIndex, _) = run.indices.lf_bsearch(location, comparable: { $0 - $1 })
    return glyphIndex
}

func LKTextLineGetTextRunIndexForStringIndex(_ line: LKTextLine, _ location: CFIndex) -> CFIndex {
    guard !line.runs.isEmpty,
        line.range.location <= location else {
            return kCFNotFound
    }
    guard location < line.range.location + line.range.length else {
        return line.runs.count
    }
    var start = 0
    var end = line.runs.count - 1
    var runIdx = 0
    while start < end {
        runIdx = (start + end) / 2
        let lowerBound = line.runs[runIdx].range.location
        let upperBound = line.runs[runIdx].range.location + line.runs[runIdx].range.length
        if location < lowerBound {
            end = runIdx - 1
            continue
        }
        if location >= upperBound {
            start = runIdx + 1
            continue
        }
        break
    }
    if start == end {
        runIdx = start
    }
    return runIdx
}

/// LTR下，自行实现返回line的某个index距line origin的offset
///
/// - Parameters:
///   - line: LKTextLine
///   - index: CFIndex
/// - Returns: Offset CGFloat or 0.0 if failure.
func LKTextLineGetOffsetForStringIndex(_ line: LKTextLine, _ index: CFIndex) -> CGFloat {
    let runIdx = LKTextLineGetTextRunIndexForStringIndex(line, index)
    guard runIdx != kCFNotFound else {
        return 0
    }
    guard runIdx < line.runs.count else {
        return line.frame.width
    }
    let run = line.runs[runIdx]
    let glyphIndex = LKTextRunGetGlyphIndexForStringIndex(run, location: index)
    guard !run.glyphPoints.isEmpty, glyphIndex >= 0 else {
        return run.origin.x
    }
    guard glyphIndex < run.glyphPoints.count else {
        return run.glyphPoints.last!.x
    }
    return run.glyphPoints[glyphIndex].x
}

@inline(__always)
func nearlyIndexAt(_ arr: [CGFloat], value: CGFloat) -> (CFIndex, CFIndex) {
    return arr.lf_bsearch(value, comparable: { Int($0 - $1) }, isDescending: true)
}

/// 返回point是否在一堆有序列的frames中
///
/// - Parameters:
///   - point: CGPoint
///   - frmaes: 一组有顺序的frames
///   - direction: 顺序方向：0是↓ 1是→ 2是↑ 3是←
/// - Returns: Index
func bsearchPointAt(_ point: CGPoint, frames: [CGRect], direction: Int = 0) -> Int? {
    if direction > 3 || direction < 0 {
        return nil
    }
    var start = 0
    var end = frames.count - 1
    var select = 0
    let handler: (Int, inout Int, inout Int, [CGRect], CGPoint) -> Void = [
        // ↓
        { (select, start, end, frames, point) in
            if frames[select].minY > point.y {
                end = select - 1
                return
            }
            if frames[select].maxY < point.y {
                start = select + 1
                return
            }
            start = end + 1
        },
        // →
        { (select, start, end, frames, point) in
            if frames[select].maxX < point.x {
                start = select + 1
                return
            }
            if frames[select].minX > point.x {
                end = select - 1
                return
            }
            start = end + 1
        },
        // ↑
        { (select, start, end, frames, point) in
            if frames[select].minY < point.y {
                end = select - 1
                return
            }
            if frames[select].maxY > point.y {
                start = select + 1
                return
            }
            start = end + 1
        },
        // ←
        { (select, start, end, frames, point) in
            if frames[select].minX < point.x {
                end = select - 1
                return
            }
            if frames[select].maxX > point.x {
                start = select + 1
                return
            }
            start = end + 1
        }
    ][direction]
    while end >= start {
        select = (start + end) / 2
        if frames[select].contains(point) {
            return select
        }
        handler(select, &start, &end, frames, point)
    }

    return nil
}

func StringUnicodeScalarRanges(string: String) -> [NSRange] {
    if string.isEmpty {
        return []
    }
    var ranges = [NSRange](repeating: NSRange(location: 0, length: 0), count: string.indices.count)
    var i = 0
    for index in string.indices {
        let now = index.utf16Offset(in: string)
        if i != 0 {
            ranges[i - 1].length = now - ranges[i - 1].location
        }
        ranges[i].location = now

        i += 1
    }
    ranges[ranges.count - 1].length = NSString(string: string).length - ranges[ranges.count - 1].location

    return ranges
}

func StringUnicodeScalarRanges(attrString: NSAttributedString) -> [NSRange] {
    if attrString.string.isEmpty {
        return []
    }
    return StringUnicodeScalarRanges(string: attrString.string)
}

/// Returns the special chracter ranges like 1⃣️.
///
/// - Parameter attrString: NSAttributedString
/// - Returns: [NSRange]
func AttributedStringUnicodeScalarRanges(attrString: NSAttributedString) -> [NSRange] {
    if attrString.string.isEmpty {
        return []
    }
    var ranges: [NSRange] = []
    var prevEncodeOffset = 0
    var unicodeLength = 0
    let string = attrString.string
    for index in string.indices {
        let encodeOffset = index.utf16Offset(in: string)
        unicodeLength = encodeOffset - prevEncodeOffset
        if unicodeLength > 1 {
            ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
        }
        prevEncodeOffset = encodeOffset
    }

    unicodeLength = attrString.length - prevEncodeOffset
    if unicodeLength > 1 {
        ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
    }

    return ranges
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
        isDescending: Bool = false
    ) -> (before: Int, after: Int) {
        var before = 0
        var after = self.count - 1

        // 如果超出了range直接返回最开始活着最后面
        if self.isEmpty {
            return (0, 0)
        }

        var mid = 0
        var res = 0

        let compare: (Int) -> Int = isDescending ? { $0 * -1 } : { $0 }

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
