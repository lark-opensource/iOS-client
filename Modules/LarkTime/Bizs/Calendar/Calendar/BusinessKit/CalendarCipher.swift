//
//  CalendarCipher.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/8.
//

import Foundation
import CryptoSwift
import Swinject
import LarkContainer
import LarkAccountInterface

final class CalendarCipher {
    private var key32: String = ""
    private var key16: String = ""
    private var iv8: String = ""
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

}
