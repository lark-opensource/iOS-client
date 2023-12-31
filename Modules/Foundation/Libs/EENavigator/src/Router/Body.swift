//
//  Body.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/10/22.
//

import Foundation
import SuiteCodable

// swiftlint:disable identifier_name
public protocol URLConvertible {
    var _url: URL { get }
}
// swiftlint:enable identifier_name

public enum PatternType {
    case plain, path, regex
}

public struct PatternConfig {
    /// url pattern
    public let pattern: String
    /// true for custom regular expression pattern and false for path pattern
    public let type: PatternType

    public init(pattern: String, type: PatternType = .plain) {
        self.pattern = pattern
        self.type = type
    }
}

public protocol Body: URLConvertible {
    static var patternConfig: PatternConfig { get }
    // 当导航栈中，已经有同样的页面的时候，是否push新页面还是pop回页面
    // 当forcePush为true，则push新页面
    // 当forcePush为空，则使用NaviParams中的forcePush参数
    // 当forcePush不为空，则覆盖NaviParams中的forcePush参数
    var forcePush: Bool? { get }
    static func getBody(req: Request) -> Self?
}

public extension Body {
    var forcePush: Bool? { nil }
    static func getBody(req: Request) -> Self? {
        return req.context[ContextKeys.body] as? Self
    }
    static func getBody(req: Request) -> Self? where Self: Codable {
        if let body = req.context[ContextKeys.body] as? Self { return body }
        let allParameters = req.parameters
        if let body = try? dictionaryDecoder.decode(Self.self, from: allParameters) {
            req.context[ContextKeys.body] = body
            return body
        }

        return nil
    }
}

public typealias CodableBody = Body & Codable

public protocol PlainBody: Body {
    static var pattern: String { get }
}

public typealias CodablePlainBody = PlainBody & Codable

extension PlainBody {
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: pattern)
    }

    // swiftlint:disable identifier_name
    public var _url: URL {
        return URL(string: Self.pattern)!
    }
    // swiftlint:enable identifier_name
}

extension Request {
    public func getBody<T: Body>() throws -> T {
        guard let body = T.getBody(req: self) else {
            throw invalidBodyError()
        }
        return body
    }
    public func invalidBodyError() -> Error {
        return RouterError.invalidParameters(ContextKeys.body)
        .patchExtraInfo(with: url.absoluteString,
                        from: context.from(),
                        naviParams: context.naviParams)
    }
}
