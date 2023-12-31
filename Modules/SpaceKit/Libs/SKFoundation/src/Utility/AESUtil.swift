//
//  AESUtil.swift
//  SpaceKit
//
//  Created by zenghao on 2019/5/23.
//
// ref: http://www.hangge.com/blog/cache/detail_1869.html
import Foundation
import CryptoSwift
// AES_ECB必须使用16位秘钥,不要随便改这个哦
private let masterKey = "7v#A3q.$5vESi5r2"

public final class AESUtil {

    public static func encrypt_AES_ECB(msg: String) -> String {
        //使用AES-128-ECB加密模式，pkcs5
        do {
            let aes = try AES(key: masterKey.bytes, blockMode: ECB())

            //开始加密
            let encrypted = try aes.encrypt(msg.bytes)
            //将加密结果转成base64形式
            guard let encryptedBase64 = encrypted.toBase64() else {
                DocsLogger.warning("AESUtil encrypt_AES_ECB to base64 failed")
                return ""
            }
            return encryptedBase64
        } catch let error {
            DocsLogger.warning("AESUtil encrypt_AES_ECB encrypt failed", extraInfo: ["errorInfo": error])
        }
        return ""
    }

    public static func decrypt_AES_ECB(base64String: String) -> String {
        //使用AES-128-ECB解密模式
        do {
            let aes = try AES(key: masterKey.bytes, blockMode: ECB())

            // 从加密后的base64字符串解密
            let decryptedMsg = try base64String.decryptBase64ToString(cipher: aes)

            return decryptedMsg
        } catch let error {
            DocsLogger.warning("AESUtil encrypt_AES_ECB decrypt failed", extraInfo: ["errorInfo": error])
        }
        return ""
    }
}
