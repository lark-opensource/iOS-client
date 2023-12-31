//
//  FileCryptoV2MigrateHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/26.
//

import UIKit
import UniverseDesignToast
import LarkContainer
import LarkSecurityCompliance
import LarkAccountInterface
import RustPB
import LarkRustClient

class FileCryptoV2MigrateHandler: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
   
    @ScopedProvider var rustService: RustService?
    
    func handle() {
        guard let view = viewController?.view.superview else { return }
        do {
            let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("test_file_to_v2").path
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            let arr = Array(repeating: "helloworld", count: 100)
            if let data = arr.joined().data(using: .utf8) {
                let result = FileManager.default.createFile(atPath: filePath, contents: data)
                UDToast.showTips(with: "创建文件\(result)~", on: view)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.testStream(filePath: filePath, view: view)
            }
        } catch {
            UDToast.showTips(with: "数据迁移报错: \(error) \(#file.identity) \(#line) \(#function)", on: view)
            print("数据迁移报错: \(error) \(#file.identity) \(#line) \(#function)")
        }
    }
    
    func testStream(filePath: String, view: UIView) {
        setupCipherMode(isBlockMode: false)
        // 测试写入
        @Provider var cryptoService: FileCryptoService
        @Provider var passportService: PassportService
        let cipher = CryptoStream(enableStreamCipherMode: true,
                                  deviceKey: FileCryptoDeviceKey.deviceKey(),
                                  uid: passportService.foregroundUser?.userID ?? "",
                                  did: passportService.deviceID,
                                  userResolver: userResolver)
        let readBegin = CFAbsoluteTimeGetCurrent()
        var data = Data()
        do {
            let input = try cipher.decrypt(from: filePath)
            try input.open(shouldAppend: false)
            data = try input.read(maxLength: UInt32.max)
            try input.close()
        } catch {
            UDToast.showTips(with: "数据迁移报错: \(error)", on: view)
            print("数据迁移报错: \(error)")
        }
                
        let readEnd = CFAbsoluteTimeGetCurrent()
        let decryptedStr = String(data: data, encoding: .utf8) ?? ""
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
