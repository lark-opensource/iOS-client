//
//  NetworkCodable.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public protocol NetworkDecodable {
    static var protoName: String { get }
    init(serializedData data: Data) throws
}

public protocol NetworkEncodable {
    static var protoName: String { get }
    func serializedData() throws -> Data
}

public protocol CustomNetworkDecodable {
    associatedtype CustomContext
    static var protoName: String { get }
    init(serializedData data: Data, context: CustomContext) throws
}

/// internal bridge
protocol _NetworkDecodable: ProtobufDecodable { }

/// internal bridge
protocol _NetworkEncodable: ProtobufEncodable { }

protocol _CustomNetworkDecodable: ProtobufCustomDecodable { }

extension _NetworkDecodable {
    public init(serializedData data: Data) throws {
        try self.init(pb: try ProtobufType.init(serializedData: data, options: .discardUnknownFieldsOption))
    }
}

extension _NetworkEncodable {
    public func serializedData() throws -> Data {
        try toProtobuf().serializedData()
    }
}

extension _CustomNetworkDecodable {
    public init(serializedData data: Data, context: CustomContext) throws {
        try self.init(pb: try ProtobufType.init(serializedData: data, options: .discardUnknownFieldsOption), context: context)
    }
}
