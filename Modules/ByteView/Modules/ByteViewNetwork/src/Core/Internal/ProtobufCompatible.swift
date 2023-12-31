//
//  ProtobufCompatible.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol ProtobufCompatible {
    associatedtype ProtobufType: Message
}

protocol ProtobufEncodable: ProtobufCompatible {
    func toProtobuf() throws -> ProtobufType
}

protocol ProtobufDecodable: ProtobufCompatible {
    init(pb: ProtobufType) throws
}

protocol ProtobufCustomDecodable: ProtobufCompatible {
    associatedtype CustomContext
    init(pb: ProtobufType, context: CustomContext) throws
}

struct ProtobufCodableError: Error, Hashable, CustomStringConvertible {
    let type: ErrorType
    let msg: String

    init(_ type: ErrorType, _ msg: String = "") {
        self.type = type
        self.msg = msg
    }

    enum ErrorType: String {
        case notSupported
        case decodeFailed
        case encodeFailed
        case emptyMessage
    }

    var description: String {
        if msg.isEmpty {
            return "ProtobufCodableError(\(type.rawValue))"
        } else {
            return "ProtobufCodableError(\(type.rawValue): \(msg))"
        }
    }
}

extension ProtobufCompatible {
    public static var protoName: String { ProtobufType.protoMessageName }
}

extension BinaryDecodingOptions {
    static let discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

extension JSONDecodingOptions {
    static let ignoreUnknownFieldsOption: JSONDecodingOptions = {
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true
        return options
    }()
}
