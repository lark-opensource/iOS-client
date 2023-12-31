//
//  FileCryptoRustV2TestHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/9/25.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import LarkRustClient
import RustPB
import UniverseDesignToast

class FileCryptoRustV2TestHandler: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    var view: UIView {
        guard let view = viewController?.view.superview else { return UIView() }
        return view
    }
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    @ScopedProvider var rustService: RustService?
    
    func handle() {
        do {
            let path = NSTemporaryDirectory() + "rust_v2_test_file_\(type(of: self))"
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: "12345".data(using: .utf8)!)
            }
            
            setupCipherMode(isBlockMode: false)
            try testRustCrypto(path: path)
            
            
            setupCipherMode(isBlockMode: true)
            try testRustCrypto(path: path)
            
        } catch {
            print(">>>> ERROR: ", error)
            UDToast.showFailure(with: "ERROR: \(error)", on: view)
        }
    }
    
    
    private func testRustCrypto(path: String) throws {
        let service = try userResolver.resolve(type: FileCryptoService.self)
        let encryptedPath = try service.encryptPath(path)
        let encryptedHeader = try? AESHeader(filePath: encryptedPath)
        let encryptedVersion = encryptedHeader?.encryptVersion() ?? .regular

        print(">>>> Result: encrypted path version: \(encryptedVersion), \(encryptedPath)")
        UDToast.showTips(with: "Result: encrypted path version: \(encryptedVersion), \(encryptedPath)", on: view)
        
        setupCipherMode(isBlockMode: false)
        
        let decryptedPath = try service.decryptPath(encryptedPath)
        let decryptedHeader = try? AESHeader(filePath: decryptedPath)
        let version = decryptedHeader?.encryptVersion() ?? .regular
        print(">>>> Result: decrypted path version: \(version), \(decryptedPath)")
        UDToast.showTips(with: "Result: decrypted path version: \(version), \(decryptedPath)", on: view)
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

extension AESHeader {
    init(filePath: String) throws {
        let fileHandle = try SCFileHandle(path: filePath, option: .read)
        guard let headerData = try fileHandle.read(upToCount: Int(AESHeader.size)) else {
            try fileHandle.close()
            throw NSError(domain: "crypto is nil", code: 100001)
        }
        try fileHandle.close()
        try self.init(data: headerData)
    }
}
