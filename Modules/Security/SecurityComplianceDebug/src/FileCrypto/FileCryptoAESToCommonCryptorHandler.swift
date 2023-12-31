//
//  FileCryptoDebugGroupHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/29.
//

import UIKit
import LarkContainer
import CryptoSwift
import LarkAccountInterface
import LarkSecurityCompliance
import UniverseDesignToast

class FileCryptoAESToCommonCryptorHandler: FileCryptoDebugHandle {
   
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService

    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    
    func handle() {
        guard let view = viewController?.view.superview else { return }
        do {
            let iv = Self.randomNonce()
            let aes = try AES(key: FileCryptoDeviceKey.deviceKey().bytes, blockMode: CTR(iv: iv), padding: .noPadding)
            if let data = "helloworld12345678901234567890".data(using: .utf8) {
                var bytes = try aes.encrypt(data.bytes)
                
                let aesCTR = AESCryptor(operation: .decrypt, key: FileCryptoDeviceKey.deviceKey(), iv: Data(iv))
                aesCTR.seek(to: 16)
                bytes.removeSubrange(0..<16)
                let result = try aesCTR.updateData(with: Data(bytes))
                UDToast.showTips(with: "\(result.bytes) \(String(data: result, encoding: .utf8))", on: view)
                print(">>>>>>>> ", result.bytes, String(data: result, encoding: .utf8))
            }
        } catch {
            print(">>>>>>>> ERROR", error)
        }
    }
    
    
    
    
    static func randomNonce() -> [UInt8] {
        var result: [UInt8] = Array(repeating: 0, count: 16)
        result.enumerated().forEach { each in
            result[each.offset] = UInt8.random(in: 0 ..< UInt8.max)
        }
        return result
    }
}
