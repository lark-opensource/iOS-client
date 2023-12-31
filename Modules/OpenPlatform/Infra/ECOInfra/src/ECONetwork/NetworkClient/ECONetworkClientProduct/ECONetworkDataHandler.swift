//
//  ECONetworkDataHandler.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/27.
//

import Foundation

class ECONetworkDataHandler: ECONetworkResponseDataHandler {
    var data: NSMutableData?
    
    func receiveChunk(withBuffer buffer: UnsafeMutablePointer<UInt8>, size: Int) -> Error? {
        guard let data = data else {
            assertionFailure("data is nil, call ready() first")
            return OPError.responseDataReceiveError(message: "receiveChunk data is nil")
        }
        data.append(buffer, length: size)
        return nil
    }
    
    func receiveChunk(withData receiveData: Data) -> Error? {
        guard let data = data else {
            assertionFailure("data is nil, call ready() first")
            return OPError.responseDataReceiveError(message: "receiveChunk data is nil")
        }
        data.append(receiveData)
        return nil
    }
    
    func receiveURL(source: URL) -> Error? {
        assertionFailure("Use wrong handler:\(Self.self) with url")
        return OPError.responseDataReceiveError(message: "Use wrong handler")
    }
    
    func ready() -> Error? {
        if data == nil {
            data = NSMutableData();
        }
        return nil
    }
    
    func finish() {}
    
    func clean() -> Error?  { data = nil; return nil }
    
    func productType() -> ECONetworkProduct.Type { Data.self }
    
    func product() -> ECONetworkProduct? { data as Data? }
    
}
