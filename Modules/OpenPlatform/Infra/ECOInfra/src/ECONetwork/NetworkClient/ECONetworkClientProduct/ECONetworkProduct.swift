//
//  ECONetworkResponseValue.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/14.
//

import Foundation
import LKCommonsLogging

internal typealias TaskCompletionHandler = (AnyObject?, ECONetworkProduct?, URLResponse?, Error?) -> Void

//MARK: - ECONetworkProduct

/// NetworkDataType
/// 网络请求结束后拿到的返回结果 (比如下载数据 返回的 URL, 普通请求返回的 Data)
internal protocol ECONetworkProduct {}

extension URL: ECONetworkProduct {}
extension Data: ECONetworkProduct {}
extension NSMutableData: ECONetworkProduct {}

//MARK: - ECONetworkResponseDataHandler
/// NetworkDataReceiver
/// 网络请求中的数据接受器, 用于接收对应数据类型的数据
internal protocol ECONetworkResponseDataHandler {
    func receiveChunk(withBuffer buffer: UnsafeMutablePointer<UInt8>, size: Int) -> Error?
    func receiveChunk(withData data: Data) -> Error?
    func receiveURL(source: URL) -> Error?
    func ready() -> Error?
    func finish()
    func clean() -> Error?
    func productType() -> ECONetworkProduct.Type
    func product() -> ECONetworkProduct?
}
