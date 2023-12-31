//
// Created by liujianlong on 2022/8/18.
//

import Foundation

public protocol DefaultDecodableValueSource {
    associatedtype ValueType: Decodable
    static var defaultValue: ValueType { get }
}

@propertyWrapper
public struct DefaultDecodableWrapper<ValueSource: DefaultDecodableValueSource>: Decodable {
    public typealias Value = ValueSource.ValueType
    public var wrappedValue: Value = ValueSource.defaultValue
    public init() {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(Value.self)
    }
}

public enum DefaultDecodable {
    public enum DefaultEmptyString: DefaultDecodableValueSource {
        public static let defaultValue: String = ""
    }

    public enum DefaultFalse: DefaultDecodableValueSource {
        public static let defaultValue: Bool = false
    }

    public enum DefaultTrue: DefaultDecodableValueSource {
        public static let defaultValue: Bool = true
    }

    public enum Default0: DefaultDecodableValueSource {
        public static let defaultValue: Int = 0
    }

    public enum DefaultMinus1: DefaultDecodableValueSource {
        public static let defaultValue: Int = -1
    }

    public enum Default1Float: DefaultDecodableValueSource {
        public static let defaultValue: Float = 1.0
    }

    public typealias Int0 = DefaultDecodableWrapper<Default0>
    public typealias Float1 = DefaultDecodableWrapper<Default1Float>
    public typealias IntMinus1 = DefaultDecodableWrapper<DefaultMinus1>
    public typealias False = DefaultDecodableWrapper<DefaultFalse>
    public typealias True = DefaultDecodableWrapper<DefaultTrue>
    public typealias EmptyString = DefaultDecodableWrapper<DefaultEmptyString>

}

public extension KeyedDecodingContainer {
    func decode<T>(_ type: DefaultDecodableWrapper<T>.Type, forKey key: Key) throws -> DefaultDecodableWrapper<T> {
        try decodeIfPresent(DefaultDecodableWrapper<T>.self, forKey: key) ?? DefaultDecodableWrapper()
    }
}

extension DefaultDecodableWrapper: Equatable where Value: Equatable {
}

extension DefaultDecodableWrapper: Hashable where Value: Hashable {
}

extension DefaultDecodableWrapper: ExpressibleByIntegerLiteral where Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Value.IntegerLiteralType) {
        self.wrappedValue = Value(integerLiteral: value)
    }
}

extension DefaultDecodableWrapper: ExpressibleByFloatLiteral where Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Value.FloatLiteralType) {
        self.wrappedValue = Value(floatLiteral: value)
    }
}

extension DefaultDecodableWrapper: CustomStringConvertible where Value: CustomStringConvertible {
    public var description: String { wrappedValue.description }
}
