//
//  PhoneNumberParser.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/10/7.
//

import UIKit
import Foundation
import RustPB

public final class PhoneNumberAndLinkParser {
    public enum ResultType {
        case phoneNumber(String)
        case link(URL)
        case other
    }

    public enum Detector {
        case onlyPhoneNumber
        case onlyLink
        case phoneNumberAndLink

        private static let phoneNumberAndLinkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue + NSTextCheckingResult.CheckingType.link.rawValue)
        private static let onlyLinkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        private static let onlyPhoneNumberDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

        var rawValue: NSDataDetector? {
            switch self {
            case .onlyPhoneNumber:
                return Self.onlyPhoneNumberDetector
            case .onlyLink:
                return Self.onlyLinkDetector
            case .phoneNumberAndLink:
                return Self.phoneNumberAndLinkDetector
            }
        }
    }
    public typealias ParserResult = (resultType: ResultType, range: NSRange)

    private let serialQueue: OperationQueue

    public init() {
        let queue = OperationQueue()
        queue.name = "PhoneNumberParserQueue"
        queue.maxConcurrentOperationCount = 1
        // 跟global queue使用一个优先级
        queue.qualityOfService = .default
        self.serialQueue = queue
    }

    /// limitLength: 当字符数超过limitLength时，考虑性能不再解析，默认字符数5000
    /// completion: 异步解析结束后子线程回调结果
    public func asyncParser(
        contents: [String: String],
        detector: Detector,
        limitLength: Int = 5000,
        completion: @escaping ([String: [ParserResult]]) -> Void
    ) {
        let contents = contents.compactMapValues { element in
            return element.count < limitLength ? element : nil
        }
        if contents.isEmpty {
            completion([:])
            return
        }
        serialQueue.addOperation {
            let result = PhoneNumberAndLinkParser.parser(contents: contents, detector: detector, limitLength: limitLength)
            completion(result)
        }
    }

    /// 同步解析
    /// limitLength: 当字符数超过limitLength时，考虑性能不再解析，默认字符数5000
    public static func syncParser(contents: [String: String], detector: Detector, limitLength: Int = 5000) -> [String: [ParserResult]] {
        let contents = contents.compactMapValues { element in
            return element.count < limitLength ? element : nil
        }
        if contents.isEmpty {
            return [:]
        }
        return parser(contents: contents, detector: detector, limitLength: limitLength)
    }

    private static func parser(contents: [String: String], detector: Detector, limitLength: Int) -> [String: [ParserResult]] {
        guard let detector = detector.rawValue, !contents.isEmpty else {
            return [:]
        }
        var rawResult: [String: [NSTextCheckingResult]] = [:]
        contents.forEach { (elementID, element) in
            let matchRes: [NSTextCheckingResult] = detector.matches(
                in: element,
                options: .reportProgress,
                range: NSRange(location: 0, length: element.utf16.count)
            )
            if !matchRes.isEmpty {
                rawResult[elementID] = matchRes
            }
        }
        let result: [String: [ParserResult]] = rawResult.mapValues { match in
            return match.compactMap { res in
                if let phoneNumber = res.phoneNumber {
                    return (resultType: .phoneNumber(phoneNumber), range: res.range)
                }
                if let url = res.url {
                    return (resultType: .link(url), range: res.range)
                }
                return nil
            }
        }
        return result
    }

    /// 电话号码的解析会在子线程，为防止多线程问题，将要用的数据先提出来
    /// Returns: elementID -> content
    public static func getNeedParserContent(richText: Basic_V1_RichText) -> [String: String] {
        var contents: [String: String] = [:]
        richText.elements.forEach { (elementID, element) in
            if element.tag == .text {
                // 创建一个新的String，否则底层还是引用
                contents[elementID] = String(element.property.text.content)
            } else if element.tag == .u {
                contents[elementID] = String(element.property.underline.content)
            }
        }
        return contents
    }
}
