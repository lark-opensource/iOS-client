//
//  HttpSerializer.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import Foundation

public final class HttpSerializer {

    // MARK: - JSONEncoder/JSONDecoder Codable<->Data
    /// 模型转Data
    @inline(__always)
    public static func toData<T>(_ model: T) -> Data? where T: Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(model) else { return nil }
        return data
    }

    /// 字典转模型
    @inline(__always)
    public static func toModel<T>(_ modelType: T.Type, data: Data) -> T? where T: Decodable {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let model = try? decoder.decode(modelType, from: data)
        return model
    }

    // MARK: - JSONSerialization Any<->Data
    @inline(__always)
    public static func toData(_ object: Any) -> Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else { return nil }
        return data
    }

    @inline(__always)
    public static func toObject(_ data: Data) -> Any? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return nil }
        return jsonObject
    }

    // MARK: - String<->Data
    @inline(__always)
    public static func toData(_ string: String) -> Data? {
        guard let data = string.data(using: .utf8) else { return nil }
        return data
    }

    @inline(__always)
    public static func toString(_ data: Data) -> String? {
        let string = String(data: data, encoding: String.Encoding.utf8)
        return string
    }

    @inline(__always)
    public static func encode(_ urlString: String) -> URL? {
        let encodeUrlSet = CharacterSet.urlQueryAllowed
        let encodeUrl = urlString.addingPercentEncoding(withAllowedCharacters: encodeUrlSet)
        guard let encode = encodeUrl, let url = URL(string: encode) else { return nil }
        return url
    }
}
