//
//  CommonError.swift
//  ByteViewCommon
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public enum CommonError: Error, Equatable, CustomStringConvertible {
    case methodNotImplemented
    case serviceNotFound
    case selfIsReleased
    case unsupportedType(String)

    public var description: String {
        switch self {
        case .methodNotImplemented:
            return "methodNotImplemented"
        case .serviceNotFound:
            return "serviceNotFound"
        case .selfIsReleased:
            return "selfIsReleased"
        case .unsupportedType(let type):
            return "unsupportedType(\(type))"
        }
    }
}
