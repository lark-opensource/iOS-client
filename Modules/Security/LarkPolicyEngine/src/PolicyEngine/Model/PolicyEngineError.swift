//
//  PolicyEngineError.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/11/16.
//

import Foundation
import LarkExpressionEngine
import LarkSnCService
import Reachability

public enum PolicyEngineErrorCode: UInt {
    case unknow = 200
    case policyFetchFailed = 201
    case pointcutFetchFailed = 202
    case remoteValidateRequestFailed = 203
    case queryCombineAlgorithmFailed = 204
    case queryDowngradeDecisionFailed = 205
    case queryFastPassConfigFailed = 206
    case fetchFastPassConfigFailed = 207
    case queryPointcutFailed = 208
    case remoteValidateFailed = 210
    case subjectFactorFetchFailed = 211
    case ipFactorFetchFailed = 212
}

public enum ErrorType {
    case policyError(PolicyEngineErrorCode)
    case unknownError

    public var code: UInt {
        switch self {
        case .policyError(let policyEngineErrorCode):
            return policyEngineErrorCode.rawValue
        case .unknownError:
            return 999
        }
    }
}

public struct PolicyEngineError: Error, CustomStringConvertible {

    public let error: ErrorType
    public let message: String
    public var description: String {
        return "PolicyEngineError: code: \(error.code), message:\(message)"
    }

    public init(error: ErrorType, message: String) {
        self.error = error
        self.message = message
    }
}

extension PolicyEngineError {
    static let reachability = Reachability()

    func report(monitor: Monitor?) {
        let isReachable = Self.reachability?.isReachable

        monitor?.info(service: "internal_error", category: [
            "code": error.code,
            "network_status": String(describing: isReachable),
            "reason": message
        ])
    }
}
