//
//  FileCryptoGroupHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/7/8.
//

import UIKit
import CryptoSwift
import LarkSecurityComplianceInfra
import LarkSecurityCompliance
import LarkContainer
import UniverseDesignToast
import LarkEMM

class FileCryptoGroupHandler: FileCryptoDebugHandle {
    
    static let queue = DispatchQueue(label: "FileCryptoGroupHandler")
  
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    let encryptedFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_large_encrypted_file").path
    let decryptedFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_large_decrypted_file").path
    
    
    func handle() {
        guard let viewController, let view = viewController.view.superview else { return }
        let alert = UIAlertController(title: "请选择加解密方式", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = self.viewController?.view
        alert.addAction(UIAlertAction(title: "加密", style: .default) { _ in
            if FileManager.default.fileExists(atPath: self.encryptedFilePath) {
                try? FileManager.default.removeItem(atPath: self.encryptedFilePath)
            }
            self.encryptFile()
        })
        alert.addAction(UIAlertAction(title: "解密", style: .default) { _ in
            if !FileManager.default.fileExists(atPath: self.encryptedFilePath) {
                UDToast.showFailure(with: "加密文件不存在，请先进行加密", on: view)
                return
            }
            Self.queue.async {
                do {
                    try self.decryptFile()
                } catch {
                    print("ERROR: ", error)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        navigator.present(alert, from: viewController)
        
        
        
//        do {
//            try testEncrypt(str: "000000ABCDEFTHIJ")
//            try testEncrypt(str: "123456ABCDEFTHIJ")
//
//            let aes = try AES(key: [104, 101, 108, 108, 111, 119, 111, 114, 104, 101, 108, 108, 111, 119, 111, 114], blockMode: CTR(iv: [108, 100, 49, 50, 51, 52, 53, 54, 108, 100, 49, 50, 51, 52, 53, 54]))
//            var arr: [UInt8] = [103, 124, 180, 102, 26, 163, 221, 87, 194, 52]
//            arr.insert(contentsOf: Array(repeating: 0, count: 38), at: 0)
//            let result = try aes.decrypt(arr)
//            print(">>>>>>>>> ", result.description, "ABCDEFTHIJ".data(using: .utf8)?.bytes.description)
//        } catch {
//            print("ERROR: ", error)
//        }
    }
    
    func testEncrypt(str: String) throws -> [UInt8] {
        guard var data = str.data(using: .utf8) else { return [] }
        data.insert(contentsOf: Array(repeating: 0, count: 32), at: 0)
        let aes = try AES(key: [104, 101, 108, 108, 111, 119, 111, 114, 104, 101, 108, 108, 111, 119, 111, 114], blockMode: CTR(iv: [108, 100, 49, 50, 51, 52, 53, 54, 108, 100, 49, 50, 51, 52, 53, 54]), padding: .noPadding)
        let result = try aes.encrypt(data.bytes)
        print("test ", str, result)
        return result
    }
    
    
    
    private func encryptFile() {
        guard let viewController else { return }
        let alert = UIAlertController(title: "请输入加密的文件大小（单位M）", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "文件大小，单位M"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak alert] _ in
            guard let text = alert?.textFields?.first?.text, let view = self.viewController?.view.superview else { return }
            let int = Int(text) ?? 0
            Self.queue.async {
                do {
                    
                    try self.realEncryptFile(int)
                } catch {
                    UDToast.showFailure(with: "加密失败：\(error.localizedDescription)", on: view)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.navigator.present(alert, from: viewController)
        }
    }
    
    private func realEncryptFile(_ size: Int) throws {
        let divider = 30
        let realSize = size
        var groups = Array(repeating: divider, count: realSize / divider)
        if realSize % divider > 0 {
            groups.append(realSize % divider)
        }
        
        let service = try userResolver.resolve(type: FileCryptoService.self)
        let input = try service.encrypt(to: encryptedFilePath)
        try input.open(shouldAppend: false)
        
        for (index, group) in groups.enumerated() {
            DispatchQueue.main.async {
                guard let view = self.viewController?.view.superview else { return }

                UDToast.showLoading(with: "\(index)/\(groups.count)加密中...", on: view)
            }
            let bytes = group * 1000 * 1000
            let char = "ABCDEFG".randomElement() ?? "A"
            guard let data = Array(repeating: "\(char)", count: bytes).joined().data(using: .utf8) else { return }
            try input.write(data: data)
        }
        try input.close()
        DispatchQueue.main.async {
            guard let view = self.viewController?.view.superview else { return }

            UDToast.showTips(with: "加密完成，路径已写入粘贴板", on: view)
            SCPasteboard.general(SCPasteboard.defaultConfig()).string = self.encryptedFilePath
        }
    }
    
    private func decryptFile() throws {
        if FileManager.default.fileExists(atPath: decryptedFilePath) {
            try FileManager.default.removeItem(atPath: decryptedFilePath)
        }
        FileManager.default.createFile(atPath: decryptedFilePath, contents: nil)
        let divider = 30 * 1000 * 1000
        let attrs = try FileManager.default.attributesOfItem(atPath: encryptedFilePath)
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        var groups = Array(repeating: divider, count: size / divider)
        if size % divider > 0 {
            groups.append(size % divider)
        }
        let service = try userResolver.resolve(type: FileCryptoService.self)
        let output = try service.decrypt(from: encryptedFilePath)
        try output.open(shouldAppend: false)
        
        let fileHandle = try SCFileHandle(path: decryptedFilePath, option: .write)

        for (index, group) in groups.enumerated() {
            DispatchQueue.main.async {
                guard let view = self.viewController?.view.superview else { return }

                UDToast.showLoading(with: "\(index)/\(groups.count)解密中...", on: view)
            }
            let data = try output.read(maxLength: UInt32(group))
            try fileHandle.write(contentsOf: data)
        }
        try output.close()
        try fileHandle.close()
        DispatchQueue.main.async {
            guard let view = self.viewController?.view.superview else { return }

            UDToast.showTips(with: "解密完成，路径已写入粘贴板", on: view)
            SCPasteboard.general(SCPasteboard.defaultConfig()).string = self.decryptedFilePath
        }
    }
}
