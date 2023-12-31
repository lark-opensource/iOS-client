//
//  CryptoSBInputStream.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/2.
//

import UIKit
import LarkStorage
import LarkContainer
import LarkSecurityComplianceInfra

extension Foundation.OutputStream {
    func write(data: Data) -> Int {
        data.withUnsafeBytes { bytes in
            guard let addr = bytes.bindMemory(to: UInt8.self).baseAddress else { return }
            self.write(addr, maxLength: data.count)
        }
        return data.count
    }
}

extension Foundation.InputStream {
    func read(maxLength len: Int) -> Data {
        var data = Array(repeating: UInt8(0), count: len)
        _ = self.read(&data, maxLength: len)
        return Data(data)
    }
}

extension Crypto {
    
    typealias SysInputStream = Foundation.InputStream
    typealias SysOutputStream = Foundation.OutputStream
    
    final class InputStream: NSObject, SBInputStream, Foundation.StreamDelegate {
        private var stream: SysInputStream?
       
        var hasBytesAvailable: Bool { stream?.hasBytesAvailable ?? false }
        
        let info: AESMetaInfo
        let userResolver: UserResolver
        let header: AESHeader
        let cryptor: AESCryptor
        
        init(userResolver: UserResolver, info: AESMetaInfo) throws {
            Logger.info("create input stream begin \(info.filePath)")
            self.userResolver = userResolver
            self.info = info
            let (_, header) = try CryptoPreprocess.Read.v2Preprocess(userResolver: userResolver, info: info)
            self.header = header
            guard let nonce = header.values[.nonce] else {
                throw CryptoFileError.customError("nonce is nil")
            }
            cryptor = AESCryptor(operation: .decrypt, key: info.deviceKey, iv: nonce)
            super.init()
            Logger.info("create input stream end \(info.filePath)")
        }
        
        func open() {
            guard let stream = SysInputStream(fileAtPath: info.filePath) else {
                Logger.error("create input stream failed")
                return
            }
            stream.delegate = self
            stream.open()
            self.stream = stream
            
            let data = stream.read(maxLength: Int(AESHeader.size))
            Logger.info("input stream open end: \(data.count)")
        }
        
        func close() {
            stream?.close()
        }
        
        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            do {
                let stream = try currentStream()
                let data = stream.read(maxLength: len)
               
                let result = try cryptor.updateData(with: Data(data))
                result.withUnsafeBytes { bytes in
                    guard let addr = bytes.bindMemory(to: UInt8.self).baseAddress else { return }
#if swift(>=5.8)
                    buffer.update(from: addr, count: result.count)
#else
                    buffer.assign(from: addr, count: result.count)
#endif
                }
                return result.count
            } catch {
                Logger.error("input stream read with error: \(error)")
                return 0
            }
        }
        
        var streamStatus: Stream.Status { stream?.streamStatus ?? .notOpen }
        
        var streamError: Error? { stream?.streamError }
        
        weak var delegate: StreamDelegate?
        
        private func currentStream() throws -> SysInputStream {
            guard let stream else {
                throw CryptoFileError.customError("inputstream is nil")
            }
            return stream
        }
        
        // MARK: - StreamDelegate
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            delegate?.stream?(aStream, handle: eventCode)
        }
    }
    
    final class OutputStream: NSObject, SBOutputStream, Foundation.StreamDelegate {
        
        var hasSpaceAvailable: Bool { stream?.hasSpaceAvailable ?? false }

        let info: AESMetaInfo
        let append: Bool
        let userResolver: UserResolver
        let header: AESHeader
        let cryptor: AESCryptor

        private var stream: SysOutputStream?
        
        init(userResolver: UserResolver, info: AESMetaInfo, append shouldAppend: Bool) throws {
            Logger.info("create output stream begin \(info.filePath)")
            self.userResolver = userResolver
            self.append = shouldAppend
            self.info = info
            let (_, header) = try CryptoPreprocess.Write.v2Preprocess(append: shouldAppend, userResolver: userResolver, info: info)
            self.header = header
            
            guard let nonce = header.values[.nonce] else {
                throw CryptoFileError.customError("nonce is nil")
            }
            cryptor = AESCryptor(operation: .encrypt, key: info.deviceKey, iv: nonce)
            super.init()
            Logger.info("create output stream end \(info.filePath)")
        }
        
        func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
            do {
                let bufferPointer = UnsafeBufferPointer<UInt8>(start: buffer, count: len).map { $0 }
                // UnsafeBufferPointer
                let raw = Data(bufferPointer)
                let data = try cryptor.updateData(with: raw)
                let stream = try currentStream()
                return stream.write(data: data)
            } catch {
                Logger.error("output stream read with error: \(error)")
                return 0
            }
        }
        
        var streamStatus: Stream.Status { stream?.streamStatus ?? .notOpen }
        
        var streamError: Error? { stream?.streamError }
        
        weak var delegate: StreamDelegate?
        
        func open() {
            let url: URL
            if #available(iOS 16.0, *) {
                url = URL(filePath: info.filePath)
            } else {
                url = URL(fileURLWithPath: info.filePath)
            }
            
            guard let stream = SysOutputStream(url: url, append: append) else {
                Logger.error("create output stream failed")
                return
            }
            self.stream = stream
            stream.delegate = self
            stream.open()
            if append {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: info.filePath)
                    let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
                    let fileSize = max(size - AESHeader.size, 0)
                    cryptor.seek(to: fileSize)
                } catch {
                    Logger.error("output stream failed to seek")
                }
            } else {
                let size = stream.write(data: header.data)
                Logger.info("create header with size: \(size)")
            }
        }
        
        func close() {
            stream?.close()
        }
        
        private func currentStream() throws -> SysOutputStream {
            guard let stream else {
                throw CryptoFileError.customError("outputstream is nil")
            }
            return stream
        }
        
        // MARK: - StreamDelegate
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            delegate?.stream?(aStream, handle: eventCode)
        }
    }
}
