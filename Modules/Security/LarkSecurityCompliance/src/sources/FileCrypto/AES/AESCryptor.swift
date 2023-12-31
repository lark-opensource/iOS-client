//
//  Cryptor.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/29.
//

import Foundation
import CommonCrypto
import LarkSecurityComplianceInfra

public final class AESCryptor {
    
    public enum Operation: CCOperation {
        case encrypt = 0
        case decrypt = 1
    }
    
    public enum CryptorError: Error {
        /// 加解密operation错误
        case invalidOperation
        case createCryptorFailed
        case updateCryptorFailed
        case finalCryptorFailed
    }
    
    class var blockSize: Int {
        kCCBlockSizeAES128
    }
    
    private var cryptor: CCCryptorRef?
    
    let key: Data
    let initialIV: Data
    let operation: Operation
    private(set) var iv: Data
    private var seekOffset = 0
    
    public init(operation: Operation, key: Data, iv: Data) {
        self.operation = operation
        self.key = key
        self.initialIV = iv
        self.iv = iv
    }
    
    deinit {
        releaseCryptor()
    }
    
    public func updateData(with data: Data) throws -> Data {
        try setupCryptorIfNeeded()
        
        var dataOutMoved = 0
        var dataOutMovedTotal = 0
        var dataIn = data
        if seekOffset > 0 {
            // add padding 0 at first index to fix the offset of blockSize
            dataIn.insert(contentsOf: Array(repeating: 0, count: seekOffset), at: 0)
        }
       
        let dataOutLength = CCCryptorGetOutputLength(cryptor, dataIn.count, true)
        var dataOut = Data(count: dataOutLength)

        var result = dataIn.withUnsafeBytes { dataPtr in
            dataOut.withUnsafeMutableBytes { bufferPtr in
                guard let dataAddr = dataPtr.baseAddress,
                      let bufferAddr = bufferPtr.baseAddress
                else { return Int32(-1) }
                return CCCryptorUpdate(
                    cryptor,
                    dataAddr, dataPtr.count,
                    bufferAddr, dataOutLength,
                    &dataOutMoved)
            }
        }
        
        dataOutMovedTotal += dataOutMoved
        
        // The only error returned by CCCryptorUpdate is kCCBufferTooSmall, which would be a programming error
        assert(result == CCCryptorStatus(kCCSuccess), "RNCRYPTOR BUG. PLEASE REPORT. (\(result)")
        if result != CCCryptorStatus(kCCSuccess) {
            SCLogger.error("AESCryptor/update/error:\(result)")
            throw CryptorError.updateCryptorFailed
        }
        
        result = dataOut.withUnsafeMutableBytes {
            guard let dataAddr = $0.baseAddress else { return Int32(-1) }
            return CCCryptorFinal(
                cryptor,
                dataAddr + dataOutMoved, dataOutLength - dataOutMoved,
                &dataOutMoved
            )
        }
        // Note that since iOS 6, CCryptor will never return padding errors or other decode errors.
        // I'm not aware of any non-catastrophic (MemoryAllocation) situation in which this
        // can fail. Using assert() just in case, but we'll ignore errors in Release.
        // https://devforums.apple.com/message/920802#920802
        // ErrCode: https://opensource.apple.com/source/CommonCrypto/CommonCrypto-36064/CommonCrypto/CommonCryptor.h
        assert(result == CCCryptorStatus(kCCSuccess), "RNCRYPTOR BUG. PLEASE REPORT. (\(result)")
        if result != CCCryptorStatus(kCCSuccess) {
            SCLogger.error("AESCryptor/update/error:\(result)")
            throw CryptorError.finalCryptorFailed
        }
        dataOutMovedTotal += dataOutMoved
        dataOut.count = dataOutMovedTotal
        if seekOffset > 0 {
            dataOut.removeSubrange(0..<seekOffset)
            seekOffset = 0
        }
        return dataOut
    }
    
    public func seek(to position: UInt64) {
        let blockSize = UInt64(Self.blockSize)
        let ivBytes = buildCounterValue(initialIV.bytes, offset: position / blockSize)
        self.iv = Data(ivBytes)
        iv.withUnsafeBytes { ivPtr in
            guard let ivAddr = ivPtr.baseAddress else { return }
            CCCryptorReset(cryptor, ivAddr)
        }
        self.seekOffset = Int(position % blockSize)
    }
    
    private func setupCryptorIfNeeded() throws {
        guard cryptor == nil else { return }
        
        cryptor = try key.withUnsafeBytes { (keyPtr) in
            try iv.withUnsafeBytes { (ivPtr) in
                guard let keyPtrAddr = keyPtr.baseAddress,
                      let ivPtrAddr = ivPtr.baseAddress
                else { return nil }
                var cryptorOut: CCCryptorRef?
                let result = CCCryptorCreateWithMode(operation.rawValue,
                                                     CCMode(kCCModeCTR),
                                                     CCAlgorithm(kCCAlgorithmAES),
                                                     CCPadding(ccNoPadding),
                                                     ivPtrAddr,
                                                     keyPtrAddr,
                                                     keyPtr.count,
                                                     nil, 0, 0, // tweak XTS mode, numRounds
                                                     CCModeOptions(kCCModeOptionCTR_BE),
                                                     &cryptorOut)
                // It is a programming error to create us with illegal values
                // This is an internal class, so we can constrain what is sent to us.
                // If this is ever made public, it should throw instead of asserting.
                assert(result == CCCryptorStatus(kCCSuccess))
                if result != CCCryptorStatus(kCCSuccess) {
                    SCLogger.error("AESCryptor/create/error:\(result)")
                    throw CryptorError.createCryptorFailed
                }
                return cryptorOut
            }
        }
    }
    
    private func releaseCryptor() {
        if let cryptor {
            CCCryptorRelease(cryptor)
        }
        cryptor = nil
    }
}

private func buildCounterValue(_ iv: Array<UInt8>, offset: UInt64) -> Array<UInt8> {
    guard offset > 0 else { return iv }
    let noncePartLen = iv.count / 2
    let noncePrefix = iv[iv.startIndex..<iv.startIndex.advanced(by: noncePartLen)]
    let nonceSuffix = iv[iv.startIndex.advanced(by: noncePartLen)..<iv.startIndex.advanced(by: iv.count)]
    let c = UInt64(bytes: nonceSuffix) + offset
    return noncePrefix + c.bytes()
}
