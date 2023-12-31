//
//  DocsCipher.swift
//  SKCommon
//
//  Created by LiXiaolin on 2021/3/4.
//  


import Foundation
import CryptoSwift

class DocsCipher {
    private let key32: String
    private let key16: String
    private let iv8: String

    init(userId: String, tenentId: String) {
        let uniqueId = "\(userId)-\(tenentId)"
        let uniqueString = uniqueId.sha256()
        self.key32 = uniqueString.subString(firstIndex: 0, length: 32) ?? ""
        self.key16 = uniqueString.subString(firstIndex: 0, length: 16) ?? ""
        self.iv8 = uniqueString.subString(firstIndex: 32, length: 8) ?? ""
    }

    func generateAES() throws -> Cipher {
        return try AES(key: key16.bytes, blockMode: ECB())
    }

//    func generateChacha20() throws -> Cipher {
//        return try ChaCha20(key: key32.bytes, iv: iv8.bytes)
//    }
}

extension String {
    /// 16进制字符串转Int
//    func hexStringToInt() -> Int? {
//        let str = self.uppercased()
//        var sum = 0
//        for i in str.utf8 {
//            guard (i >= 48 && i <= 57) || (i >= 65 && i <= 90) else {
//                return nil
//            }
//
//            let i = i >= 65 ? i - 7 : i // 9是57，A是65，需去掉差值7来达到16进制的效果
//            sum = sum * 16 + Int(i) - 48 // 0是48，这里每次*16相当于整体向左移1位
//        }
//        return sum
//    }

    /// JavaScript风格的返回子字符串方法
    func subString(firstIndex: Int, length: Int) -> String? {
        guard firstIndex >= 0, length >= 0, firstIndex + length <= self.count else {
            return nil
        }
        let firstIndex = self.index(startIndex, offsetBy: firstIndex)
        let lastIndex = self.index(firstIndex, offsetBy: length - 1)
        return String(self[firstIndex...lastIndex])
    }
}
