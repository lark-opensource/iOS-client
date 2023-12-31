//
//  ECOCodableSerializer.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/1/8.
//

import Foundation
import ECOInfra

private typealias WPMonitorCode = EPMClientOpenPlatformAppCenterWorkplaceCode

final class ECORequestCodableSerializer<T: Encodable>: ECONetworkRequestSerializer {
    func serialize(context: ECONetworkServiceContext, request: ECONetworkRequestOrigin, params: T) throws -> ECONetworkSerializeResult {
        WPMonitor()
            .setTrace(context.getTrace())
            .setCode(WPMonitorCode.workplace_net_model_codable_start)
            .setInfo([
                .pipeline: WPMonitor.Pipeline.encode.rawValue,
                .modelName: String(describing: T.self)
            ])
            .flush()

        let successMonitor = WPMonitor()
            .setTrace(context.getTrace())
            .setCode(WPMonitorCode.workplace_net_model_codable_success)
            .setInfo([
                .pipeline: WPMonitor.Pipeline.encode.rawValue,
                .modelName: String(describing: T.self)
            ])
            .timing()

        do {
            let paramDict = try params.asDictionary()
            let body = mergeBodyFields(base: request.bodyFields, add: paramDict)
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            successMonitor.setInfo([.dataSize: bodyData.count]).timing().flush()
            return .bodyData(bodyData, "application/json")
        } catch {
            WPMonitor()
                .setTrace(context.getTrace())
                .setCode(WPMonitorCode.workplace_net_model_codable_fail)
                .setInfo([
                    .pipeline: WPMonitor.Pipeline.encode.rawValue,
                    .modelName: String(describing: T.self),
                    .errorCode: WPMonitor.errorCode(error).rawValue,
                    .errorMessage: WPMonitor.errorMessage(error)
                ])
                .flush()
            throw error
        }
    }

    /// Merge query parameters.
    private func mergeBodyFields(base: [String: Any], add: [String: Any]) -> [String: Any] {
        return base.merging(add, uniquingKeysWith: {
            // `add` dictionary should not overwrites the `base` dictionary
            assertionFailure("merge new object to existed key, first:\($0), second:\($1)")
            return $1
        })
    }
}

final class ECOResponseCodableSerializer<T: Decodable>: ECONetworkResponseSerializer {
    func serialize(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws -> T? {
        guard let data = response.bodyData else { return nil }

        WPMonitor()
            .setTrace(context.getTrace())
            .setCode(WPMonitorCode.workplace_net_model_codable_start)
            .setInfo([
                .pipeline: WPMonitor.Pipeline.decode.rawValue,
                .dataSize: data.count,
                .modelName: String(describing: T.self)
            ])
            .flush()

        let successMonitor = WPMonitor()
            .setTrace(context.getTrace())
            .setCode(WPMonitorCode.workplace_net_model_codable_success)
            .setInfo([
                .pipeline: WPMonitor.Pipeline.decode.rawValue,
                .dataSize: data.count,
                .modelName: String(describing: T.self)
            ])
            .timing()

        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            successMonitor.timing().flush()
            return result
        } catch {
            WPMonitor()
                .setTrace(context.getTrace())
                .setCode(WPMonitorCode.workplace_net_model_codable_fail)
                .setInfo([
                    .pipeline: WPMonitor.Pipeline.decode.rawValue,
                    .dataSize: data.count,
                    .modelName: String(describing: T.self),
                    .errorCode: WPMonitor.errorCode(error).rawValue,
                    .errorMessage: WPMonitor.errorMessage(error)
                ])
                .flush()
            throw error
        }
    }
}

extension Encodable {
    /// Create a [String: Any] object from JSON data.
    fileprivate func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "codable struct serialization", code: -1)
        }
        return dict
    }
}

/// Codable monitor service
extension WPMonitor {
    /// Set monitor extra parameters
    ///
    /// - Parameter info: extra parameters dictionary
    @discardableResult fileprivate func setInfo(_ extraParams: [ExtraParams: Any]) -> WPMonitor {
        for (key, value) in extraParams {
            self.setInfo(value, key: key.rawValue)
        }
        return self
    }

    /// Error code in monitor extra parameters,
    /// represent the type of error thrown in encoding & decoding pipeline
    fileprivate enum ErrorCode: Int {
        /// Unexpected error type
        case unexpected = 0

        /// Same meaning as `DecodingError.typeMismatch`
        ///
        /// An indication that a value of the given type could not be decoded because
        /// it did not match the type of what was found in the encoded payload.
        case typeMismatch = 1

        /// Same meaning as `DecodingError.valueNotFound`
        ///
        /// An indication that a non-optional value of the given type was expected,
        /// but a null value was found.
        case valueNotFound = 2

        /// Same meaning as `DecodingError.keyNotFound`
        ///
        /// An indication that a keyed decoding container was asked for an entry for
        /// the given key, but did not contain one.
        case keyNotFound = 3

        /// Same meaning as `DecodingError.dataCorrupted`
        ///
        /// An indication that the data is corrupted or otherwise invalid.
        case dataCorrupted = 4

        /// Same meaning as `EncodingError.invalidValue`
        ///
        /// An indication that an encoder or its containers could not encode the given value.
        case invalidValue = 5
    }

    /// Pipeline type in monitor extra parameters
    fileprivate enum Pipeline: String {
        /// Encoding pipeline
        case encode
        /// Decoing pipeline
        case decode
    }

    /// Key of extra parameters
    fileprivate enum ExtraParams: String {
        /// Codable pipeline, see enum `Monitor.Pipeline`
        case pipeline = "pipeline"
        /// The size of the data to be encoded or decoded (in bytes)
        case dataSize = "data_size"
        /// Codable struct name
        case modelName = "model_name"
        /// Codable error type, see enum `Monitor.ErrorCode`
        case errorCode = "error_code"
        /// Codable error description
        case errorMessage = "error_msg"
    }

    /// Generate error code
    ///
    /// - Parameter error: the error thrown in encoding and decoding pipeline
    /// - Returns: error code
    fileprivate static func errorCode(_ error: Error) -> ErrorCode {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .typeMismatch(_, _):
                return .typeMismatch
            case .keyNotFound(_, _):
                return .keyNotFound
            case .valueNotFound(_, _):
                return .valueNotFound
            case .dataCorrupted(_):
                return .dataCorrupted
            @unknown default:
                return .unexpected
            }
        } else if let encodingError = error as? EncodingError {
            switch encodingError {
            case .invalidValue(_, _):
                return .invalidValue
            @unknown default:
                return .unexpected
            }
        } else {
            return .unexpected
        }
    }

    /// Generate error message
    ///
    /// - Parameter error: the error thrown in encoding and decoding pipeline
    /// - Returns: error message
    fileprivate static func errorMessage(_ error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                return """
                       data corrupted: \(context.debugDescription)
                       codingPath: \(context.codingPath)
                       """
            case .keyNotFound(let key, let context):
                return """
                       key \(key) not found: \(context.debugDescription)
                       codingPath: \(context.codingPath)
                       """
            case .typeMismatch(let type, let context):
                return """
                       type \(type) mismatch: \(context.debugDescription)
                       codingPath: \(context.codingPath)
                       """
            case .valueNotFound(let type, let context):
                return """
                       value with type \(type) not found: \(context.debugDescription)
                       codingPath: \(context.codingPath)
                       """
            @unknown default:
                return error.localizedDescription
            }
        } else if let encodingError = error as? EncodingError {
            switch encodingError {
            case .invalidValue(let value, let context):
                return """
                       invalid value \(value): \(context.debugDescription)
                       codingPath: \(context.codingPath)
                       """
            @unknown default:
                return error.localizedDescription
            }
        } else {
            return error.localizedDescription
        }
    }
}
