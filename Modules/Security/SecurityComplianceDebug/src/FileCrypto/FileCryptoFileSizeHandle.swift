//
//  FileCryptoFileSizeHandle.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/10/9.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import LarkRustClient
import RustPB
import UniverseDesignToast
import LarkStorage

class FileCryptoFileSizeHandle: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    @ScopedProvider var rustService: RustService?
    @ScopedProvider var cryptoService: FileCryptoService?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func handle() {
        guard let viewController else { return }
        let alert = UIAlertController(title: "请输出要计算FileSize大小的字符串", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "自定义字符串"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak alert] _ in
            guard let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            self.start(target: text)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        navigator.present(alert, from: viewController)
    }
    
    func start(target: String) {
        guard let view = viewController?.view.superview else { return }
        guard let data = target.data(using: .utf8) else { return }
        guard let cryptoService else { return }
        do {
            let path = NSTemporaryDirectory() + "file_size_test_file"
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            // rust v1:
            FileManager.default.createFile(atPath: path, contents: data)
            setupCipherMode(isBlockMode: true)
            let newPath = try cryptoService.encryptPath(path)
            let v1Size = SBUtils.fileSize(atPath: newPath) ?? 0
            
            // rust v2:
            try FileManager.default.removeItem(atPath: path)
            FileManager.default.createFile(atPath: path, contents: data)
            setupCipherMode(isBlockMode: false)
            let newV2Path = try cryptoService.encryptPath(path)
            let v2Size = SBUtils.fileSize(atPath: newV2Path) ?? 0
            
            // native v2:
            try FileManager.default.removeItem(atPath: path)
            let fileHandle = try cryptoService.fileHandle(atPath: path, forUsage: .writing(shouldAppend: false))
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()
            let nativeSize = SBUtils.fileSize(atPath: path) ?? 0
            
            UDToast.showTips(with: "v1: \(v1Size), v2: \(v2Size), native: \(nativeSize), target: \(data.count)", on: view)
            
        } catch {
            UDToast.showFailure(with: "ERROR: \(error)", on: view)
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
