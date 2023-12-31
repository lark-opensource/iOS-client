//
//  RequestUtil.swift
//  ByteView
//
//  Created by kiri on 2022/12/16.
//

import Foundation
import SwiftProtobuf
import ByteViewNetwork

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

protocol RustRequest: NetworkRequest, ProtobufEncodable { }

protocol RustRequestWithResponse: NetworkRequestWithResponse, ProtobufEncodable { }

protocol RustRequestWithCustomResponse: NetworkRequestWithCustomResponse, ProtobufEncodable { }

protocol RustResponse: NetworkResponse, ProtobufDecodable { }

protocol RustCustomResponse: NetworkResponse, ProtobufCustomDecodable { }

extension BinaryDecodingOptions {
    static let discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

extension ProtobufCompatible {
    static var protoName: String { ProtobufType.protoMessageName }
}

extension ProtobufEncodable {
    func serializedData() throws -> Data {
        try toProtobuf().serializedData()
    }
}

extension ProtobufDecodable {
    init(serializedData data: Data) throws {
        try self.init(pb: try ProtobufType.init(serializedData: data, options: .discardUnknownFieldsOption))
    }
}

extension ProtobufCustomDecodable {
    init(serializedData data: Data, context: CustomContext) throws {
        try self.init(pb: try ProtobufType.init(serializedData: data, options: .discardUnknownFieldsOption), context: context)
    }
}
