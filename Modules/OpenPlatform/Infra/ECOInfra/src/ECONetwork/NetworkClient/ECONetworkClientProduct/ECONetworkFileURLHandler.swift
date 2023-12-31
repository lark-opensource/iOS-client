//
//  File.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/27.
//

import Foundation

class ECONetworkFileURLHandler: ECONetworkResponseDataHandler {
    let targetLocation: URL
    
    init(with url: URL) { targetLocation = url }
    
    func receiveChunk(withBuffer buffer: UnsafeMutablePointer<UInt8>, size: Int) -> Error? {
        assertionFailure("Use wrong handler:\(Self.self) with url")
        return OPError.responseDataReceiveError(message: "Use wrong handler")
    }
    
    func receiveChunk(withData data: Data) -> Error? {
        assertionFailure("Use wrong handler:\(Self.self) with url")
        return OPError.responseDataReceiveError(message: "Use wrong handler")
    }
    
    func receiveURL(source: URL) -> Error? {
        // lint:disable:next lark_storage_check
        do { try FileManager.default.moveItem(at: source, to: targetLocation) }
        catch let error { return error }
        return nil
    }
    
    func ready() -> Error? { return nil }
    
    func finish() {}
    
    func clean() -> Error? {
        // lint:disable:next lark_storage_check
        do { try FileManager.default.removeItem(at: targetLocation) }
        catch let error { return error }
        return nil
    }
    
    func productType() -> ECONetworkProduct.Type { URL.self }
    
    func product() -> ECONetworkProduct? { targetLocation }
}
