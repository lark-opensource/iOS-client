//  Generated code. DO NOT EDIT.
//  source: lark-fg.yaml

import Foundation
import SwiftProtobuf

/// Get runtime immutable feature gating after client invoke [`MakeUserOnline`]
public func getImmutableFeatureGating(userid: String, key: String) 

throws


-> Bool

{
  var params = LarkFg_Proto_FuncParamsXe310569e8131bb62()
  
  
  params.userid = userid
  
  
  
  params.key = key
  
  
  
  let ret = try makeRustCallWithParams(params, molten_ffi_lark_fg_get_immutable_feature_gating_d544) {
    let errData = Data(rustBuffer: $0)
    let err =  try LarkFg_Proto_FuncErrorXb7613bdc761bb2dc(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  let retData = Data(rustBuffer: ret)
  let ret2 = try! LarkFg_Proto_FuncReturnX3dc8b8542df1cbb1(serializedData: retData)
  
  return ret2.ret
  
  
}



/// feature gating interface error type
public enum LarkFgError {
  
  /// Interface call failed due to unknown error.
  case unknownError
  
  /// Interface call failed due to user validation error.
  case userValidError
  
}

fileprivate extension LarkFg_Proto_LarkFgError {
  func into() -> LarkFgError {
    switch self {
    
    case .unknownError: return .unknownError
    
    case .userValidError: return .userValidError
    
    }
  }
}

fileprivate extension LarkFgError {
  func into() -> LarkFg_Proto_LarkFgError {
    switch self {
    
    case .unknownError: return .unknownError
    
    case .userValidError: return .userValidError
    
    }
  }
}





extension LarkFgError: Error {}

fileprivate extension Data {
    init(rustBuffer: RustBuffer) {
        self.init(bytesNoCopy: rustBuffer.data!, count: Int(rustBuffer.len), deallocator: .custom({ ptr, count in
            rustBuffer.deallocate()
        }))
    }
}

fileprivate extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

fileprivate extension RustBuffer {
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }
    
    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        var status = RustCallStatus()
        return uniffi_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), &status)
    }
    
    func deallocate() {
        var status = RustCallStatus()
        uniffi_rustbuffer_free(self, &status)
    }
}

fileprivate enum InternalError: LocalizedError {
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case rustPanic(_ message: String)
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "Unexpected RustCall error"
        case let .rustPanic(message): return message
        }
    }
}

fileprivate let CALL_SUCCESS: Int8 = 0
fileprivate let CALL_ERROR: Int8 = 1
fileprivate let CALL_PANIC: Int8 = 2

fileprivate extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            error_buf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func makeRustCall<T>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T, 
    throwError: ((RustBuffer) throws -> Error)? = nil) throws -> T {
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(&callStatus)
    switch callStatus.code {
    case CALL_SUCCESS:
        return returnedVal

    case CALL_ERROR:
        guard let throwError = throwError else {
            callStatus.error_buf.deallocate()
            throw InternalError.unexpectedRustCallError
        }
        throw try throwError(callStatus.error_buf)

    case CALL_PANIC:
        let errorBuf = callStatus.error_buf
        defer {
            errorBuf.deallocate()
        }
        if errorBuf.len > 0 && errorBuf.data != nil {
            let bytes = UnsafeBufferPointer<UInt8>(start: errorBuf.data!, count: Int(errorBuf.len))
            let message = String(bytes: bytes, encoding: String.Encoding.utf8)!
            throw InternalError.rustPanic(message)
        } else {
            throw InternalError.rustPanic("Rust panic")
        }

    default:
        throw InternalError.unexpectedRustCallStatusCode
    }
}

private func makeRustCallWithParams<T, P: Message>(
    _ params: P,
    _ callback: (RustBuffer, UnsafeMutablePointer<RustCallStatus>) -> T, 
    throwError: ((RustBuffer) throws -> Error)? = nil) throws -> T {
    let paramsData = try! params.serializedData()
    let paramsBuffer = paramsData.withUnsafeBytes { ptr in
        RustBuffer.from(ptr.bindMemory(to: UInt8.self))
    }
    return try makeRustCall({ callback(paramsBuffer, $0) }, throwError: throwError)
}