//
//  LKTextLink.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

public struct LKTextLink: Equatable {
    public typealias LKTextLinkBlock = (LKLabel, LKTextLink) -> Void

    private(set) var type: NSTextCheckingResult.CheckingType
    private(set) var attributes: [NSAttributedString.Key: Any]?
    private(set) var activeAttributes: [NSAttributedString.Key: Any]?
    private(set) var inactiveAttributes: [NSAttributedString.Key: Any]?
    public var url: URL?
    public var range: NSRange
    public var phoneNumber: String?
    public var accessibilityValue: String {
        return "\(range.location):\(range.length)"
    }
    public var linkTapBlock: LKTextLinkBlock?
    public var linkLongPressBlock: LKTextLinkBlock?

    public init(result: NSTextCheckingResult,
         attributes: [NSAttributedString.Key: Any]? = nil,
         activeAttributes: [NSAttributedString.Key: Any]? = nil,
         inactiveAttributes: [NSAttributedString.Key: Any]? = nil) {
        self.init(range: result.range,
                  type: result.resultType,
                  attributes: attributes,
                  activeAttributes: activeAttributes,
                  inactiveAttributes: inactiveAttributes)
        switch result.resultType {
        case NSTextCheckingResult.CheckingType.link:
            url = result.url
        case NSTextCheckingResult.CheckingType.phoneNumber:
            phoneNumber = result.phoneNumber
        default:
            break
        }
    }

    public init(range: NSRange,
         type: NSTextCheckingResult.CheckingType,
         attributes: [NSAttributedString.Key: Any]? = nil,
         activeAttributes: [NSAttributedString.Key: Any]? = nil,
         inactiveAttributes: [NSAttributedString.Key: Any]? = nil) {
        self.range = range
        self.type = type
        self.attributes = attributes
        self.activeAttributes = activeAttributes
        self.inactiveAttributes = inactiveAttributes
    }

    public static func == (_ lhs: LKTextLink, _ rhs: LKTextLink) -> Bool {
        return lhs.range.length == rhs.range.length
            && lhs.range.location == rhs.range.location
            && lhs.type.rawValue == rhs.type.rawValue
            && lhs.url?.absoluteString == rhs.url?.absoluteString
            && lhs.phoneNumber == rhs.phoneNumber
            && lhs.attributes === rhs.attributes
            && lhs.activeAttributes === rhs.activeAttributes
            && lhs.inactiveAttributes === rhs.inactiveAttributes
    }
}

func === (lhs: [NSAttributedString.Key: Any]?, rhs: [NSAttributedString.Key: Any]?) -> Bool {
    if lhs == nil, rhs == nil {
         return true
    } else if lhs == nil || rhs == nil {
        return false
    } else {
        // swiftlint:disable force_cast
        return (lhs! as NSDictionary).isEqual(to: ((rhs! as NSDictionary) as! [AnyHashable: Any]))
        // swiftlint:enable force_cast
    }
}
