//
//  FileCryptoV1ToV2MigrateHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/27.
//

import UIKit
import UniverseDesignToast
import LarkContainer
import LarkSecurityCompliance
import LarkAccountInterface
import RustPB
import LarkRustClient

class FileCryptoV1ToV2MigrateHandler: FileCryptoDebugHandle {
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    @ScopedProvider var rustService: RustService?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("test_v1_to_v2")

    
    func handle() {
        guard let view = viewController?.view.superview else { return }
    
        setupCipherMode(isBlockMode: true)
        // 测试写入
        let arr = Array(repeating: "hello12345", count: 10)
        let data = arr.joined().data(using: .utf8)
        if FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.removeItem(atPath: filePath.path)
        }
        let cipher = CryptoPath(userResolver: userResolver)
        let writeBegin = CFAbsoluteTimeGetCurrent()
        var encryptedPath = ""
        do {
            try data?.write(to: filePath)
            encryptedPath = try cipher.encrypt(filePath.path)
        } catch {
            UDToast.showTips(with: "数据迁移报错: \(error)", on: view)
        }
//        let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath.path))
        let writeEnd = CFAbsoluteTimeGetCurrent()
        UDToast.showTips(with: "数据创建完成(v1)，耗时：\(writeEnd - writeBegin)", on: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.v2Read(path: encryptedPath)
        }
    }
    
    
    func v2Read(path: String) {
        guard let view = viewController?.view.superview else { return }
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
            let input = try decryptCipher.decrypt(from: path)
            try input.open(shouldAppend: false)
            decryptData = try input.read(maxLength: UInt32.max)
            try input.close()
        } catch {
            UDToast.showTips(with: "数据迁移报错: \(error)", on: view)
        }
                
        let readEnd = CFAbsoluteTimeGetCurrent()
        let decryptedStr = String(data: decryptData, encoding: .utf8) ?? ""
        UDToast.showTips(with: "数据迁移完成，耗时：\(readEnd - readBegin) 解密：\(decryptedStr.prefix(10))", on: view)
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
