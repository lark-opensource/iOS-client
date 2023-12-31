//
//  RustRequestProtocols.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public protocol NetworkRequest: NetworkEncodable {
    /// 请求的Command，详见 https://code.byted.org/lark/rust-sdk/blob/master/lark-facade/src/commands.rs
    /// https://code.byted.org/lark/rust-sdk/blob/master/lark-biz-byteview/src/app/client_commands/mod.rs
    static var command: NetworkCommand { get }
    static var defaultOptions: NetworkRequestOptions? { get }
}

public protocol NetworkResponse: NetworkDecodable { }

public protocol CustomNetworkResponse: CustomNetworkDecodable { }

public protocol NetworkRequestWithResponse: NetworkRequest {
    associatedtype Response: NetworkResponse
}

public protocol NetworkRequestWithCustomResponse: NetworkRequest {
    associatedtype Response: CustomNetworkResponse
}

public extension NetworkRequest {
    static var defaultOptions: NetworkRequestOptions? { nil }
}

protocol RustRequest: NetworkRequest, ProtobufEncodable, _NetworkEncodable { }

protocol RustRequestWithResponse: NetworkRequestWithResponse, ProtobufEncodable, _NetworkEncodable { }

protocol RustRequestWithCustomResponse: NetworkRequestWithCustomResponse, ProtobufEncodable, _NetworkEncodable { }

protocol RustResponse: NetworkResponse, ProtobufDecodable, _NetworkDecodable { }
