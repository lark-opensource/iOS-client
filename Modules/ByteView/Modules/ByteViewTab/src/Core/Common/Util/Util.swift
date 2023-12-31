//
//  Util.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/17.
//

import Foundation
import UIKit
import ByteViewCommon

final class Util {
    static func typeDescription(of value: Any) -> String {
        return String(describing: type(of: value))
    }

    static func address(of value: AnyObject) -> String {
        let p = "\(Unmanaged.passUnretained(value).toOpaque())"
        return p.replacingOccurrences(of: "^0x0*", with: "0x", options: .regularExpression)
    }

    // 在deinit的时候调用可能造成闪退
    static func metadataDescription(of value: AnyObject) -> String {
        return "\(typeDescription(of: value)): \(address(of: value))"
    }

    static var rootTraitCollection: UITraitCollection? {
        self.dependency?.mainSceneWindow?.traitCollection
    }

    static func formatMeetingNumber(_ meetingNumber: String) -> String {
        let s = meetingNumber
        guard s.count >= 9 else {
            return ""
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let index2 = s.index(s.endIndex, offsetBy: -3)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }

    @inline(__always)
    @usableFromInline
    static func runInMainThread(_ block: @escaping () -> Void) {
        if Thread.current == Thread.main {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    static func textSize(_ text: String, font: UIFont, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        return NSString(string: text).boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font: font],
                                                   context: nil).size
    }

    static func textSize(_ text: String, attributes: [NSAttributedString.Key: Any], maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        return NSString(string: text).boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: attributes,
                                                   context: nil).size
    }

    /// 台前调度下会有bug
    static var isSplit: Bool {
        if Display.pad, let window = self.dependency?.mainSceneWindow {
            if window.traitCollection.isCompact {
                return true
            }
            if #available(iOS 13.0, *), let scene = window.windowScene {
                return !scene.coordinateSpace.bounds.size.equalSizeTo(scene.screen.bounds.size)
            } else {
                return !window.bounds.size.equalSizeTo(window.screen.bounds.size)
            }
        } else {
            return false
        }
    }

    static var isIpadFullScreen: Bool {
        return Display.pad && !isSplit
    }

    @RwAtomic fileprivate static var dependency: TabGlobalDependency?
    static func setup(_ dependency: TabGlobalDependency) {
        self.dependency = dependency
    }
}

extension DateUtil {
    static var is24HourTime: Bool {
        Util.dependency?.is24HourTime ?? false
    }

    static func formatCalendarDateTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String {
        Util.dependency?.formatCalendarDateTimeRange(startTime: startTime, endTime: endTime) ?? ""
    }

    static func formatRRuleString(rrule: String, userId: String) -> String {
        Util.dependency?.formatRRuleString(rrule: rrule, userId: userId) ?? ""
    }
}

fileprivate extension CGSize {
    func equalSizeTo(_ other: CGSize) -> Bool {
        return (width == other.width && height == other.height) || (height == other.width && width == other.height)
    }
}

extension UITraitCollection {
    var isRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var isCompact: Bool {
        return !isRegular
    }
}

extension UIColor {
    /// 使用色值时，作为标记
    var dynamicColor: UIColor {
        return self
    }
}

extension NSMutableAttributedString {
    func set(string: String) {
        if length > 0 {
            let attributes = attributes(at: 0, effectiveRange: nil)
            mutableString.setString(string)
            setAttributes(attributes, range: NSRange(location: 0, length: length))
        } else {
            mutableString.setString(string)
        }
    }
}

extension String {
    func substring(from index: Int) -> String {
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[startIndex..<self.endIndex]

            return String(subString)
        } else {
            return self
        }
    }

    func substring(to index: Int) -> String {
        if self.count > index {
            let endIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[..<endIndex]
            return String(subString)
        } else {
            return self
        }
    }

    func substring(from: Int, length: Int) -> String? {
        guard length > 0 else { return nil }
        let start = from
        let end = min(count, max(0, start) + length)
        guard start < end else { return nil }
        return self[start..<end]
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
