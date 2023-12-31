//
//  LKMetric.swift
//  LKMetric
//
//  Created by Miaoqi Wang on 2019/11/5.
//

import Foundation
import LKCommonsLogging
import LKTracing

enum ParamKey {
    static let otherParams = "LKMetric.otherParams"
    static let domain = "LKMetric.domain"
    static let tracingId = "LKMetric.tracingId"
    static let type = "LKMetric.type"
    static let id = "LKMetric.id"
    static let emitType = "LKMetric.emitType"
    static let emitValue = "LKMetric.emitValue"
}

/// log category used to filter `LogEvent`
public let LKMetricLogCategory = "LKMetric.logCategory"

/// const key use when create params
public enum MetricConst {
    /// error code key
    public static let errorCode = "error_code"

    /// error msg key
    public static let errorMsg = "error_msg"

    /// other msg key
    public static let msg = "msg"

    /// emit default type
    public static let defaultEmitType: EmitType = .counter

    /// emit default value
    public static let defaultEmitValue: EmitValue = 1
}

/// internal
extension MetricConst {
    /// Swift `Error` does not has a code, naturally, this is only a placeholder
    static let swiftErrorCode: Int = -1
}

/// designed to be less than 1000
public enum MetricType: Int32 {
    case unkown
    case network, storage, ui, business, dataProcess
}

/// designed to be less than 10000
public typealias MetricID = Int32

/// emit type
public enum EmitType: Int32 {
    case unknown
    case counter, timer
}

/// emit value type
public typealias EmitValue = Int64

public struct MetricEvent: CustomStringConvertible {
    public let time: Int64
    public let tracingId: String
    public let params: String
    public let domain: [Int32]
    public let mType: Int32
    public let id: Int32
    public let emitType: Int32
    public let emitValue: Int64

    public init?(time: TimeInterval,
                 logParams: [String: String]?,
                 error: Error?) {
        guard var prms = logParams,
            let paramData = prms[ParamKey.otherParams]?.data(using: .utf8),
            let params = try? JSONSerialization.jsonObject(with: paramData, options: .allowFragments) as? [String: Any],
            let tracingId = params[ParamKey.tracingId] as? String,
            let domain = params[ParamKey.domain] as? [Int32],
            let type = params[ParamKey.type] as? Int32,
            let id = params[ParamKey.id] as? Int32 else {
                #if DEBUG
                print("LKMetric metric event params error \(logParams?.description ?? "no params")")
                #endif
                return nil
        }
        prms.removeValue(forKey: ParamKey.otherParams)

        var emitType: Int32 = MetricConst.defaultEmitType.rawValue
        if let eType = params[ParamKey.emitType] as? Int32 {
            emitType = eType
        }

        var emitValue: Int64 = MetricConst.defaultEmitValue
        if let eValue = params[ParamKey.emitValue] as? Int64 {
            emitValue = eValue
        }
        self.init(time: time,
                  tracingId: tracingId,
                  params: prms,
                  domain: domain,
                  mType: type,
                  id: id,
                  emitType: emitType,
                  emitValue: emitValue,
                  error: error)
    }

    public init(time: TimeInterval,
                tracingId: String,
                params: [String: String],
                domain: [Int32],
                mType: Int32,
                id: Int32,
                emitType: Int32,
                emitValue: Int64,
                error: Error?) {
        self.time = Int64(time)
        self.tracingId = tracingId
        self.domain = domain
        self.mType = mType
        self.id = id
        self.emitType = emitType
        self.emitValue = emitValue
        var prms = params

        if let err = error {
            if type(of: err) == NSError.self {
                let nse = err as NSError
                prms[MetricConst.errorCode] = "\(nse.code)"
                prms[MetricConst.errorMsg] = nse.localizedDescription
            } else {
                prms[MetricConst.errorCode] = "\(MetricConst.swiftErrorCode)"
                prms[MetricConst.errorMsg] = String(describing: err)
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: prms),
            let pString = String(data: data, encoding: .utf8) {
            self.params = pString
        } else {
            self.params = "{}"
        }
    }

    public var description: String {
        return "MetricEvent - time:\(time) tracingId:\(tracingId) "
        + "domain:\(domain) type:\(mType) id:\(id) "
        + "emitType: \(emitType) emitValue: \(emitValue) params:\(params)"
    }
}

/// Use to log metric event
public struct LKMetric {
    static let logger = Logger.log(LKMetric.self, category: LKMetricLogCategory)
    /// metric log
    /// - Parameters:
    ///   - time: timestamp
    ///   - tracingId: id used for tracing
    ///   - params: set additional info or error info, which designed to be one level.
    ///   when set error info using `MetricConst.errorCode` / `MetricConst.errorMsg`
    ///   take care of confiction with `error`
    ///   - domain: bussiness domain
    ///   - type: metric type
    ///   - id: id of bussiness definition
    ///   - error: error info - if error's type is NSError, will use error.code as `MetricConst.errorCode`
    ///   and error.localizedDescription as `MetricConst.errorMsg`,
    ///   otherwise will use String(describing: error) to make a `MetricConst.errorMsg`,
    ///   in this case, make error implement `CustomStringConvertible` is recommended
    public static func log(domain: MetricDomain,
                           type: MetricType,
                           id: MetricID,
                           emitType: EmitType = MetricConst.defaultEmitType,
                           emitValue: EmitValue = MetricConst.defaultEmitValue,
                           params: [String: String] = [:],
                           error: Error? = nil) {

        let otherParams: [String: Any] = [
            ParamKey.tracingId: LKTracing.identifier,
            ParamKey.domain: domain.value,
            ParamKey.type: type.rawValue,
            ParamKey.id: id,
            ParamKey.emitType: emitType.rawValue,
            ParamKey.emitValue: emitValue
        ]

        guard let paramData = try? JSONSerialization.data(withJSONObject: otherParams),
            let paramString = String(data: paramData, encoding: .utf8) else {
            return
        }

        var prms = params
        prms[ParamKey.otherParams] = paramString
        // level is not need but need set one
        logger.log(level: .trace, "", tag: "", additionalData: prms, error: error)
    }
}
