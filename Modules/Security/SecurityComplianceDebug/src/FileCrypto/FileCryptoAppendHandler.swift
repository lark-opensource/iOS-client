//
//  FileCryptoAppendHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/27.
//

import UIKit
import LarkContainer
import UniverseDesignToast
import LarkAccountInterface
import LarkSecurityCompliance

class FileCryptoAppendHandler: FileCryptoDebugHandle {
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_append_data").path
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    lazy var cipher = CryptoStream(enableStreamCipherMode: true,
                                   deviceKey: FileCryptoDeviceKey.deviceKey(),
                                   uid: userService.user.userID,
                                   did: passportService.deviceID,
                                   userResolver: userResolver)
    
    
    func handle() {
        
        // v2写入data
        writeData()
        
        // 继续写入
        appendData()
        
        // 读写
        readData()
    }
    
    private func appendData() {
        guard let view = viewController?.view.superview else { return }
        
        let text = "12345"
        guard let data = text.data(using: .utf8) else { return }
        do {
            let input = try cipher.encrypt(to: filePath)
            try input.open(shouldAppend: true)
            _ = try input.write(data: data)
            try input.close()
        } catch {
            UDToast.showTips(with: "数据Append报错: \(error)", on: view)
            print("数据Append报错: \(error)")
        }
    }
    
    private func writeData() {
        guard let view = viewController?.view.superview else { return }
        
        let text = "hellohellohhhhhhK"
        guard let data = text.data(using: .utf8) else { return }
        do {
            let input = try cipher.encrypt(to: filePath)
            try input.open(shouldAppend: false)
            _ = try input.write(data: data)
            try input.close()
        } catch {
            UDToast.showTips(with: "数据写入报错: \(error)", on: view)
            print("数据写入报错: \(error)")
        }
    }
    
    private func readData() {
        guard let view = viewController?.view.superview else { return }
        
        var data = Data()
        do {
            let input = try cipher.decrypt(from: filePath)
            try input.open(shouldAppend: false)
            data = try input.read(maxLength: UInt32.max)
            try input.close()
        } catch {
            UDToast.showTips(with: "数据读取报错: \(error)", on: view)
            print("数据读取报错: \(error)")
        }
        UDToast.showTips(with: "\(data.bytes), \(String(data: data, encoding: .utf8)), \("hellohellohhhhhh12345".data(using: .utf8)?.bytes)", on: view)
        
        print(">>>>>>>>>>>", data.bytes, String(data: data, encoding: .utf8), "hellohellohhhhhh12345".data(using: .utf8)?.bytes, filePath)
    }
}
