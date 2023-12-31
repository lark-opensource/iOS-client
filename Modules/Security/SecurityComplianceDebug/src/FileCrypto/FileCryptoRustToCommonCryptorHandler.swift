//
//  FileCryptoRustToCommonCryptorHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/7/2.
//

import UIKit
import LarkRustClient
import LarkContainer
import LarkAccountInterface
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import RustPB
import UniverseDesignToast

class FileCryptoRustToCommonCryptorHandler: FileCryptoDebugHandle {
    func handle() {
        
    }
    
  
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    @ScopedProvider private var rustService: RustService?
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_rust_data").path
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func hanlde() {
        guard let view = viewController?.view.superview else { return }
        UDToast.showLoading(with: "Rust加密中", on: view)
        DispatchQueue.global().async {
            do {
                
                try self.writeNativeData()
                
                try self.readNativeDataByRust()
                
                if FileManager.default.fileExists(atPath: self.filePath) {
                    try FileManager.default.removeItem(atPath: self.filePath)
                }
                FileManager.default.createFile(atPath: self.filePath, contents: Data())
                
                try self.writeRustData()
                
                try self.readRustDataByNative()
                
            } catch {
                print(">>>>>>> ERROR: ", error)
            }
        }
        
    }
    
    private func writeNativeData() throws {
        // v2测试写入
        @Provider var cryptoService: FileCryptoService
        @Provider var passportService: PassportService
        let decryptCipher = CryptoStream(enableStreamCipherMode: true,
                                         deviceKey: FileCryptoDeviceKey.deviceKey(),
                                         uid: passportService.foregroundUser?.userID ?? "",
                                         did: passportService.deviceID,
                                         userResolver: userResolver)
        let readBegin = CFAbsoluteTimeGetCurrent()
        do {
            let output = try decryptCipher.encrypt(to: filePath)
            try output.open(shouldAppend: false)
            let array = Array(repeating: "0123456789", count: 1000_000)
            guard let data = array.joined().data(using: .utf8) else { return }
            for _ in 0 ..< 10 {
                try autoreleasepool(invoking: {
                    _ = try output.write(data: data)
                })
            }
            try output.close()
        } catch {
            DispatchQueue.main.async {
                guard let view = self.viewController?.view.superview else { return }
                UDToast.showTips(with: "数据读取报错: \(error)", on: view)
            }
        }
                
        let readEnd = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.async {
            guard let view = self.viewController?.view.superview else { return }
            UDToast.showTips(with: "数据Native加密完成，耗时：\(readEnd - readBegin)", on: view)
        }
    }
    
    private func readNativeDataByRust() throws {

        guard let rustService else { return }
        setupCipherMode(isBlockMode: false)
        let readBegin = CFAbsoluteTimeGetCurrent()

        let crypto = RustCryptoFile(atFilePath: filePath, rustService: rustService)
        try crypto.open(options: [.write])
        _ = try crypto.read(maxLength: UInt32.max, position: nil)
        try crypto.close()
        let readEnd = CFAbsoluteTimeGetCurrent()

        DispatchQueue.main.async {
            guard let view = self.viewController?.view.superview else { return }
            UDToast.showTips(with: "Rust数据读取完成 \(readEnd - readBegin)", on: view)
        }

    }
    
    private func writeRustData() throws {
        guard let rustService else { return }
        setupCipherMode(isBlockMode: false)
        let crypto = RustCryptoFile(atFilePath: filePath, rustService: rustService)
        try crypto.open(options: [.write])
        let array = Array(repeating: "0123456789", count: 1_000_000)
        guard let data = array.joined().data(using: .utf8) else { return }
        for _ in 0 ..< 10 {
            try autoreleasepool(invoking: {
                _ = try crypto.write(data: data, position: nil)
            })
        }
        try crypto.close()
    }
    
    private func readRustDataByNative() throws {
        // v2测试写入
        @Provider var cryptoService: FileCryptoService
        @Provider var passportService: PassportService
        let decryptCipher = CryptoStream(enableStreamCipherMode: true,
                                         deviceKey: FileCryptoDeviceKey.deviceKey(),
                                         uid: passportService.foregroundUser?.userID ?? "",
                                         did: passportService.deviceID,
                                         userResolver: userResolver)
        let readBegin = CFAbsoluteTimeGetCurrent()
        var decryptData = Data()
        do {
            let input = try decryptCipher.decrypt(from: filePath)
            try input.open(shouldAppend: false)
            decryptData = try input.read(maxLength: UInt32.max)
            try input.close()
        } catch {
            DispatchQueue.main.async {
                guard let view = self.viewController?.view.superview else { return }
                UDToast.showTips(with: "数据读取报错: \(error)", on: view)
            }
        }
                
        let readEnd = CFAbsoluteTimeGetCurrent()
        let decryptedStr = String(data: decryptData, encoding: .utf8) ?? ""
        DispatchQueue.main.async {
            guard let view = self.viewController?.view.superview else { return }
            UDToast.showTips(with: "数据读取完成，耗时：\(readEnd - readBegin), 字符长度：\(decryptedStr.count)", on: view)
        }
    }
    
    func setupCipherMode(isBlockMode: Bool) {
        guard let rustService else { return }
        print("set crypto downgrade mode begin: \(isBlockMode)")
        var updateFileSettingRequest = Security_V1_UpdateFileSettingRequest()
        updateFileSettingRequest.downgrade = isBlockMode
        _ = rustService.async(message: updateFileSettingRequest)
            .subscribe(onNext: { (_: Security_V1_UpdateFileSettingResponse) in
                print("set crypto downgrade mode end: \(isBlockMode)")
            })
    }
}
