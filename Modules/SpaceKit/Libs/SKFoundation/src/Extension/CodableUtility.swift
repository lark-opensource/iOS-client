//
//  Utility.swift
//  mastering-codable
//
//  Created by Satyenkumar Mourya on 09/05/21.
//
//  swiftlint:disable pattern_matching_keywords


import Foundation

public final class CodableUtility {
    /// Returns a value of the type you specify, decoded from a JSON object
    /// - Parameters:
    ///   - type: The type of the value to decode from the supplied JSON object
    ///   - obj: The object from which to generate JSON data. Must not be nil.
    ///   - opt: Options for creating the JSON data.
    /// - Returns: A value of the specified type, if the decoder can parse the obj & data.
    public static func decode<T: Decodable>(
        _ type: T.Type,
        withJSONObject obj: Any,
        options opt: JSONSerialization.WritingOptions = [],
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line
    ) throws -> T {
        // This method must be called, otherwise a crash will result
        guard JSONSerialization.isValidJSONObject(obj) else {
            let msg = "type: \(type), decode error, is not valid JSON object"
            DocsLogger.error(
                msg,
                fileName: fileName,
                funcName: funcName,
                funcLine: funcLine
            )
            throw NSError(domain: "JSON2ModelErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: obj, options: opt)
        } catch {
            DocsLogger.error(
                "type: \(type), decode error, JSONSerialization.data error",
                error: error,
                fileName: fileName,
                funcName: funcName,
                funcLine: funcLine
            )
            throw error
        }
        return try decode(type, data: data)
    }
    
    public static func decode<T: Decodable>(
        _ type: T.Type,
        withJSONString str: String,
        using encoding: String.Encoding = .utf8,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line
    ) throws -> T {
        guard let data = str.data(using: encoding) else {
            let msg = "type: \(type), decode error, str.data is nil"
            DocsLogger.error(
                msg,
                fileName: fileName,
                funcName: funcName,
                funcLine: funcLine
            )
            throw NSError(domain: "JSON2ModelErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try decode(type, data: data)
    }
    
    static public func decode<T: Decodable>(
        _ type: T.Type,
        data: Data,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line
    ) throws -> T {
        let model: T
        do {
            model = try JSONDecoder().decode(type, from: data)
        } catch {
            DocsLogger.error(
                "type: \(type), decode error, decoder.decode error",
                error: error,
                fileName: fileName,
                funcName: funcName,
                funcLine: funcLine
            )
            throw error
        }
        return model
    }
}

public extension Encodable {
    func toJson() throws -> Any {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data)
    }
    
    func toJsonOrNil(
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line
    ) -> Any? {
        do {
            let data = try JSONEncoder().encode(self)
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            DocsLogger.error(
                "json object convert failed",
                error: error,
                fileName: fileName,
                funcName: funcName,
                funcLine: funcLine
            )
            return nil
        }
    }
}
