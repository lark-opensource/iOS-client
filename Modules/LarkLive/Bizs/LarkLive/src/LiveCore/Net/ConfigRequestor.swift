//
//  ConfigRequestor.swift
//  ByteView
//
//  Created by kiri on 2021/5/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

struct ConfigRequestor {
    static func requestSettings(_ fields: [VCSettingsField], completion: ((Result<Settings_V1_GetSettingsResponse, Error>) -> Void)? = nil) {
        var request = Settings_V1_GetSettingsRequest()
        let fieldStrings = fields.map { $0.rawValue }
        request.fields = fieldStrings
        HttpClient.async(request, Settings_V1_GetSettingsResponse.self) { result in
            if let resp = result.value {
                Logger.network.info("requestSettings success: key = \(fieldStrings), response = \(resp)")
            } else {
                Logger.network.error("requestSettings success, but resp is nil")
            }
            completion?(result)
        }
    }

    static func requestSettings<T: Decodable>(_ field: VCSettingsField, type: T.Type,
                                              completion: ((Result<T, Error>) -> Void)? = nil) {
        let key = field.rawValue
        var request = Settings_V1_GetSettingsRequest()
        request.fields = [key]
        HttpClient.async(request, Settings_V1_GetSettingsResponse.self, completion: { (result) in
            if let value = result.value?.fieldGroups[key], let obj = field.decode(value, type: type) {
                Logger.network.info("requestSettings success: key = \(key), settings = \(obj)")
                completion?(.success(obj))
            } else {
                completion?(.failure(VCError.unknown))
            }
        })
    }
}

enum VCSettingsField: String, CaseIterable, RawRepresentable, Hashable {
    case liveSettings = "vc_live_link_identifier"
    case quicFallbackSettings = "lark_live_quic_fallback_rule"
    case quicLibraAB = "lark_live_quic_libra_ab"
    case nodeOptimizeConfig = "lark_live_node_optimize_config"
    
    var shouldCache: Bool {
        switch self {
        case .liveSettings:
            return false
        case .quicFallbackSettings:
            return false
        case .quicLibraAB:
            return false
        case .nodeOptimizeConfig:
            return false
        default:
            return true
        }
    }

    var cacheKey: String {
        "Cache.Settings|\(rawValue)"
    }

    func decode(_ value: String, decoder: JSONDecoder = Self.decoder) -> Any? {
        switch self {
        case .liveSettings:
            return decode(value, type: NewLarkLiveSettings.self, decoder: decoder)
        case .quicFallbackSettings:
            return decode(value, type: LiveQuicFallbackRules.self, decoder: decoder)
        case .quicLibraAB:
            return decode(value, type: LiveQuicLibraAB.self, decoder: decoder)
        case .nodeOptimizeConfig:
            return decode(value, type: LiveNodeOptimizeConfig.self, decoder: decoder)
        }
    }

    func decode<T: Decodable>(_ value: String, type: T.Type, decoder: JSONDecoder = Self.decoder) -> T? {
        guard let data = value.data(using: .utf8) else { return nil }
        let logger = Logger.network
        do {
            return try decoder.decode(type, from: data)
        } catch DecodingError.dataCorrupted(let context) {
            logger.error("failed decoding settings \(self), error = dataCorrupted, context = \(context)")
        } catch DecodingError.keyNotFound(let key, let context) {
            logger.error("failed decoding settings \(self), error = keyNotFound, key = \(key), context = \(context)")
        } catch DecodingError.valueNotFound(let value, let context) {
            logger.error("failed decoding settings \(self), error = valueNotFound, value = \(value), context = \(context)")
        } catch DecodingError.typeMismatch(let type, let context) {
            logger.error("failed decoding settings \(self), error = typeMismatch, type = \(type), context = \(context)")
        } catch {
            logger.error("failed decoding settings \(self), error = unknown")
        }
        return nil
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
