//  Generated code. DO NOT EDIT.
//  source: meego_rust.yaml

import Foundation
import SwiftProtobuf

/// The instance of a MeegoDB created from rust-sdk side of which implementation based on squam-db.
public struct MeegoDb {
    
    
    public let handle: Int64
    
}

fileprivate extension MeegoDb {
  func into() -> MeegoRust_Proto_MeegoDb {
    var t = MeegoRust_Proto_MeegoDb()
    
    
    t.handle = handle
    
    
    return t
  }
}

fileprivate extension MeegoRust_Proto_MeegoDb {
  func into() -> MeegoDb {
    .init(
      
      handle:
        
        handle
        
        
      
    )
  }
}

/// config the meego db
public func rustConfigMeegoDb(path: String) 



{
  var params = MeegoRust_Proto_RustConfigMeegoDbParams()
  
  
  params.path = path
  
  
  
  let ret: Void = try! makeRustCallWithParams(params, 6864945385969571137, 


molten_ffi_meego_rust_call1


)
  
  
  return ret
  
}

/// Open or created if not exists the meego db.
public func rustGetMeegoDb(scope: MeegoDbScope) 

throws


-> MeegoDb

{
  var params = MeegoRust_Proto_RustGetMeegoDbParams()
  
  
  params.scope = scope.into()
  
  
  
  let ret = try makeRustCallWithParams(params, -2161084199847955396, 


molten_ffi_meego_rust_call3


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_RustGetMeegoDbError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  let retData = Data(rustBuffer: ret)
  let ret2 = try! MeegoRust_Proto_RustGetMeegoDbReturn(serializedData: retData)
  
  return ret2.ret.into()
  
  
}

/// Close the meego db.
public func rustCloseMeegoDb(scope: MeegoDbScope) 

throws



{
  var params = MeegoRust_Proto_RustCloseMeegoDbParams()
  
  
  params.scope = scope.into()
  
  
  
  let ret: Void = try makeRustCallWithParams(params, 5841898811429449052, 


molten_ffi_meego_rust_call1


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_RustCloseMeegoDbError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  return ret
  
}




public enum MeegoDbScope {
  
  
  case memory
  
  
  case global
  
  /// The id of user.
  case user(String)
  
}

fileprivate extension MeegoRust_Proto_MeegoDbScope {
  func into() -> MeegoDbScope {
    switch self.inner! {
    
    case .memory: return .memory
    
    case .global: return .global
    
    case .user(let t0): return .user(t0)
    
    }
  }
}

fileprivate extension MeegoDbScope {
  func into() -> MeegoRust_Proto_MeegoDbScope {
    var t = MeegoRust_Proto_MeegoDbScope()
    switch self {
    
    case .memory: 
      t.inner = .memory(true)
    
    case .global: 
      t.inner = .global(true)
    
    case .user(let t0): 
      t.inner = .user(t0)
    
    }
    return t
  }
}





/// The error occured in MeegoDB related APIs.
public enum MeegoDbError {
  
  /// The error marked as database category.
  case database(String)
  
  /// The error marked as handle category.
  case handle(String)
  
  /// The error marked as io category.
  case io(String)
  
}

fileprivate extension MeegoRust_Proto_MeegoDbError {
  func into() -> MeegoDbError {
    switch self.inner! {
    
    case .database(let t0): return .database(t0)
    
    case .handle(let t0): return .handle(t0)
    
    case .io(let t0): return .io(t0)
    
    }
  }
}

fileprivate extension MeegoDbError {
  func into() -> MeegoRust_Proto_MeegoDbError {
    var t = MeegoRust_Proto_MeegoDbError()
    switch self {
    
    case .database(let t0): 
      t.inner = .database(t0)
    
    case .handle(let t0): 
      t.inner = .handle(t0)
    
    case .io(let t0): 
      t.inner = .io(t0)
    
    }
    return t
  }
}






public enum DataType {
  
  
  case ofBool
  
  
  case ofInt
  
  
  case ofDouble
  
  
  case ofString
  
}

fileprivate extension MeegoRust_Proto_DataType {
  func into() -> DataType {
    switch self {
    
    case .ofBool: return .ofBool
    
    case .ofInt: return .ofInt
    
    case .ofDouble: return .ofDouble
    
    case .ofString: return .ofString
    
    }
  }
}

fileprivate extension DataType {
  func into() -> MeegoRust_Proto_DataType {
    switch self {
    
    case .ofBool: return .ofBool
    
    case .ofInt: return .ofInt
    
    case .ofDouble: return .ofDouble
    
    case .ofString: return .ofString
    
    }
  }
}






public enum DataValue {
  
  
  case ofBool(Bool)
  
  
  case ofInt(Int64)
  
  
  case ofDouble(Double)
  
  
  case ofString(String)
  
}

fileprivate extension MeegoRust_Proto_DataValue {
  func into() -> DataValue {
    switch self.inner! {
    
    case .ofBool(let t0): return .ofBool(t0)
    
    case .ofInt(let t0): return .ofInt(t0)
    
    case .ofDouble(let t0): return .ofDouble(t0)
    
    case .ofString(let t0): return .ofString(t0)
    
    }
  }
}

fileprivate extension DataValue {
  func into() -> MeegoRust_Proto_DataValue {
    var t = MeegoRust_Proto_DataValue()
    switch self {
    
    case .ofBool(let t0): 
      t.inner = .ofBool(t0)
    
    case .ofInt(let t0): 
      t.inner = .ofInt(t0)
    
    case .ofDouble(let t0): 
      t.inner = .ofDouble(t0)
    
    case .ofString(let t0): 
      t.inner = .ofString(t0)
    
    }
    return t
  }
}



/// 根据 key 获取 MeegoKV 表 domain 中的 type 值
public func rustKvGet(dataType: DataType, db: MeegoDb, domain: String, key: String) 

throws


-> DataValue?

{
  var params = MeegoRust_Proto_RustKvGetParams()
  
  
  params.dataType = dataType.into()
  
  
  
  params.db = db.into()
  
  
  
  params.domain = domain
  
  
  
  params.key = key
  
  
  
  let ret = try makeRustCallWithParams(params, 6548483312358882058, 


molten_ffi_meego_rust_call3


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_RustKvGetError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  let retData = Data(rustBuffer: ret)
  let ret2 = try! MeegoRust_Proto_RustKvGetReturn(serializedData: retData)
  
  return ret2.hasRet ? ret2.ret.into() : nil
  
  
}

/// 设置 MeegoKV 表 domain 中 key 的值为 value
public func rustKvSet(isAsync: Bool, db: MeegoDb, domain: String, key: String, value: DataValue, expiredMillis: Int64?) 

throws



{
  var params = MeegoRust_Proto_RustKvSetParams()
  
  
  params.isAsync = isAsync
  
  
  
  params.db = db.into()
  
  
  
  params.domain = domain
  
  
  
  params.key = key
  
  
  
  params.value = value.into()
  
  
  
  if let expiredMillis = expiredMillis {
    params.expiredMillis = expiredMillis
  }
  
  
  
  let ret: Void = try makeRustCallWithParams(params, -7827123959524451627, 


molten_ffi_meego_rust_call1


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_RustKvSetError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  return ret
  
}

/// 添加一条用户记录
public func userTrackAdd(db: MeegoDb, larkScene: Int64, meegoScene: String, action: Int64, timestampMillis: Int64) 

throws



{
  var params = MeegoRust_Proto_UserTrackAddParams()
  
  
  params.db = db.into()
  
  
  
  params.larkScene = larkScene
  
  
  
  params.meegoScene = meegoScene
  
  
  
  params.action = action
  
  
  
  params.timestampMillis = timestampMillis
  
  
  
  let ret: Void = try makeRustCallWithParams(params, -3020416091564874108, 


molten_ffi_meego_rust_call1


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_UserTrackAddError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  return ret
  
}

/// 获取 after_time_stamp_millis 之后的 action 总数，lark_scene 为空取全集，meego_scene 为空取全集
public func userTrackCount(db: MeegoDb, larkScene: Int64?, meegoScene: String?, action: Int64, afterTimeStampMillis: Int64) 

throws


-> Int64

{
  var params = MeegoRust_Proto_UserTrackCountParams()
  
  
  params.db = db.into()
  
  
  
  if let larkScene = larkScene {
    params.larkScene = larkScene
  }
  
  
  
  if let meegoScene = meegoScene {
    params.meegoScene = meegoScene
  }
  
  
  
  params.action = action
  
  
  
  params.afterTimeStampMillis = afterTimeStampMillis
  
  
  
  let ret = try makeRustCallWithParams(params, -2989325305045574809, 


molten_ffi_meego_rust_call3


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_UserTrackCountError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  let retData = Data(rustBuffer: ret)
  let ret2 = try! MeegoRust_Proto_UserTrackCountReturn(serializedData: retData)
  
  return ret2.ret
  
  
}

/// 删除 before_time_stamp_millis 之前的数据
public func userTrackDelete(db: MeegoDb, beforeTimeStampMillis: Int64) 

throws



{
  var params = MeegoRust_Proto_UserTrackDeleteParams()
  
  
  params.db = db.into()
  
  
  
  params.beforeTimeStampMillis = beforeTimeStampMillis
  
  
  
  let ret: Void = try makeRustCallWithParams(params, -8547308116120648525, 


molten_ffi_meego_rust_call1


) {
    let errData = Data(rustBuffer: $0)
    let err =  try MeegoRust_Proto_UserTrackDeleteError(serializedData: errData)
    
    return err.err.into()
    
  }
  
  
  return ret
  
}



extension MeegoDbError: Error {}

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
    _ method: Int64,
    _ callback: (Int64, UnsafeMutablePointer<RustCallStatus>) -> T, 
    throwError: ((RustBuffer) throws -> Error)? = nil) throws -> T {
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(method, &callStatus)
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
    _ method: Int64,
    _ callback: (Int64, RustBuffer, UnsafeMutablePointer<RustCallStatus>) -> T, 
    throwError: ((RustBuffer) throws -> Error)? = nil) throws -> T {
    let paramsData = try! params.serializedData()
    let paramsBuffer = paramsData.withUnsafeBytes { ptr in
        RustBuffer.from(ptr.bindMemory(to: UInt8.self))
    }
    return try makeRustCall(method, { callback($0, paramsBuffer, $1) }, throwError: throwError)
}