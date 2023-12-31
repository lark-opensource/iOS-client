//
//  MD5.swift
//  LibArchiveExample
//
//  Created by ZhangYuanping on 2021/9/28.
//  


import Foundation
import CommonCrypto

public final class MD5 {
    /// 计算文件的md5值
    ///
    /// - Parameter url: 文件的url linke
    /// - Returns: md5 16进制串
    public static func calculateMD5(of url: URL) -> String? {
        let bufferSize = 1024 * 1024
        do {
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in
                        _ = CC_MD5_Update(&context, ptr.baseAddress, numericCast(data.count))
                    })
                    return true
                } else {
                    return false
                }
            }) { }
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) in
                let int8Ptr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                _ = CC_MD5_Final(int8Ptr, &context)
            })
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            return nil
        }
    }
}
