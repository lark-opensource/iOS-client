//
//  Bind.swift
//  LarkWorkplaceModel
//
//  Created by Meng on 2022/11/6.
//

import Foundation

/// Bind2 Codable descriptor.
///
/// bind for two optional types.
/// - throws: `DecodingError.typeMismatch` if decode more than one type success, only one value type should be decode success.
/// - throws: `DecodingError.valueNotFound` if decode none value type success.
public enum Bind2<Value1: Codable, Value2: Codable>: Codable {
    case value1(Value1)
    case value2(Value2)

    public var value1: Value1? {
        if case .value1(let v1) = self {
            return v1
        }
        return nil
    }

    public var value2: Value2? {
        if case .value2(let v2) = self {
            return v2
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let v1Result = decode(Value1.self, container: container)
        let v2Result = decode(Value2.self, container: container)

        let results = [v1Result.isSuccess, v2Result.isSuccess]
        if results.filter({ $0 }).count > 1 {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "decode Bind2 more than one success, results: \([v1Result, v2Result])."
            ))
        }

        if v1Result.isSuccess {
            self = .value1(try v1Result.get())
            return
        }
        if v2Result.isSuccess {
            self = .value2(try v2Result.get())
            return
        }
        throw DecodingError.valueNotFound(Self.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "decode Bind2 failed, results: \([v1Result, v2Result])"
        ))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .value1(let v1):
            try container.encode(v1)
        case .value2(let v2):
            try container.encode(v2)
        }
    }
}

/// Bind3 Codable descriptor.
///
/// bind for three optional types.
/// - throws: `DecodingError.typeMismatch` if decode more than one type success, only one value type should be decode success.
/// - throws: `DecodingError.valueNotFound` if decode none value type success.
public enum Bind3<Value1: Codable, Value2: Codable, Value3: Codable>: Codable {
    case value1(Value1)
    case value2(Value2)
    case value3(Value3)

    public var value1: Value1? {
        if case .value1(let v1) = self {
            return v1
        }
        return nil
    }

    public var value2: Value2? {
        if case .value2(let v2) = self {
            return v2
        }
        return nil
    }

    public var value3: Value3? {
        if case .value3(let v3) = self {
            return v3
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let v1Result = decode(Value1.self, container: container)
        let v2Result = decode(Value2.self, container: container)
        let v3Result = decode(Value3.self, container: container)

        let results = [v1Result.isSuccess, v2Result.isSuccess, v3Result.isSuccess]
        if results.filter({ $0 }).count > 1 {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "decode Bind3 more than one success, results: \([v1Result, v2Result, v3Result])."
            ))
        }

        if v1Result.isSuccess {
            self = .value1(try v1Result.get())
            return
        }
        if v2Result.isSuccess {
            self = .value2(try v2Result.get())
            return
        }
        if v3Result.isSuccess {
            self = .value3(try v3Result.get())
            return
        }
        throw DecodingError.valueNotFound(Self.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "decode Bind3 failed, results: \([v1Result, v2Result, v3Result])"
        ))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .value1(let v1):
            try container.encode(v1)
        case .value2(let v2):
            try container.encode(v2)
        case .value3(let v3):
            try container.encode(v3)
        }
    }
}

/// Bind4 Codable descriptor.
///
/// bind for four optional types.
/// - throws: `DecodingError.typeMismatch` if decode more than one type success, only one value type should be decode success.
/// - throws: `DecodingError.valueNotFound` if decode none value type success.
public enum Bind4<Value1: Codable, Value2: Codable, Value3: Codable, Value4: Codable>: Codable {
    case value1(Value1)
    case value2(Value2)
    case value3(Value3)
    case value4(Value4)

    public var value1: Value1? {
        if case .value1(let v1) = self {
            return v1
        }
        return nil
    }

    public var value2: Value2? {
        if case .value2(let v2) = self {
            return v2
        }
        return nil
    }

    public var value3: Value3? {
        if case .value3(let v3) = self {
            return v3
        }
        return nil
    }

    public var value4: Value4? {
        if case .value4(let v4) = self {
            return v4
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let v1Result = decode(Value1.self, container: container)
        let v2Result = decode(Value2.self, container: container)
        let v3Result = decode(Value3.self, container: container)
        let v4Result = decode(Value4.self, container: container)

        let results = [v1Result.isSuccess, v2Result.isSuccess, v3Result.isSuccess, v4Result.isSuccess]
        if results.filter({ $0 }).count > 1 {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "decode Bind4 more than one success, results: \([v1Result, v2Result, v3Result, v4Result])."
            ))
        }

        if v1Result.isSuccess {
            self = .value1(try v1Result.get())
            return
        }
        if v2Result.isSuccess {
            self = .value2(try v2Result.get())
            return
        }
        if v3Result.isSuccess {
            self = .value3(try v3Result.get())
            return
        }
        if v4Result.isSuccess {
            self = .value4(try v4Result.get())
            return
        }
        throw DecodingError.valueNotFound(Self.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "decode Bind4 failed, results: \([v1Result, v2Result, v3Result, v4Result])"
        ))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .value1(let v1):
            try container.encode(v1)
        case .value2(let v2):
            try container.encode(v2)
        case .value3(let v3):
            try container.encode(v3)
        case .value4(let v4):
            try container.encode(v4)
        }
    }
}

fileprivate func decode<T: Codable>(_ type: T.Type, container: SingleValueDecodingContainer) -> Result<T, DecodingError> {
    do {
        let value = try container.decode(T.self)
        return .success(value)
    } catch {
        if let decodingError = error as? DecodingError {
            return .failure(decodingError)
        }
        return .failure(DecodingError.valueNotFound(T.self, DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "decode bind type \(T.self) failed. Unknown error \(error)"
        )))
    }
}

extension Result {
    fileprivate var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    fileprivate var messageInfo: String {
        switch self {
        case .success:
            return "success"
        case .failure(let error):
            return "error: \(error)"
        }
    }
}

