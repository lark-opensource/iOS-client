//
//  FileMigrationNormalToV2DebugHandle.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/28.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import UniverseDesignToast

class FileMigrationNormalToV2DebugHandle: FileMigrationDebug {
    
    let resolver: UserResolver
    let from: FileMigrationDebugFrom
    weak var vc: UIViewController?
   
    required init(userResolver: UserResolver, from: FileMigrationDebugVC.From, vc: UIViewController?) {
        self.resolver = userResolver
        self.from = from
        self.vc = vc
    }
    
    func trigger() {
        guard let view = vc?.view.superview else { return }
        let path = NSTemporaryDirectory() + "security_temp"
        do {
            /// 明文
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true)
            let filePath = path + "/normal_to_v2"
            let data = "helloworld".data(using: .utf8)
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            FileManager.default.createFile(atPath: filePath, contents: data)
            UDToast.showTips(with: "明文写入完成:helloworld", on: view)
            /// 明文
            
            switch from {
            case .fileHandle:
                fileHandle(filePath: filePath)
            case .inputStream:
                inputStream(filePath: filePath)
            case .sandboxInputStream:
                sandboxInputStream(filePath: filePath)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                let header = try? AESHeader(filePath: filePath)
                let ver = header?.encryptVersion() ?? .regular
                print("\(#fileID), \(#function) \(#line) #Result: ", ver, "From: ", self.from)
                UDToast.showTips(with: "数据迁移完成: \(ver), \(self.from)", on: view)
            }
        } catch {
            print("\(#fileID), \(#function) \(#line) #ERROR: ", error)
        }
    }
    
    private func inputStream(filePath: String) {
        for _ in 0 ..< 10 {
            DispatchQueue.global().async {
                do {
                    let service = try self.resolver.resolve(type: FileCryptoService.self)
                    let input = service.inputStream(atPath: filePath)
                    input?.open()
                    var data = Array(repeating: UInt8(0), count: 10000)
                    _ = input?.read(&data, maxLength: 10000)
                    input?.close()
                } catch {
                    print("\(#fileID), \(#function) \(#line) #Error: ", error)
                }
            }
        }
    }
    private func sandboxInputStream(filePath: String) {
        for _ in 0 ..< 10 {
            DispatchQueue.global().async {
                do {
                    let service = try self.resolver.resolve(type: FileCryptoService.self)
                    let input = try service.decrypt(from: filePath)
                    try input.open(shouldAppend: false)
                    _ = try input.readAll()
                    try input.close()
                } catch {
                    print("\(#fileID), \(#function) \(#line) #Error: ", error)
                }
            }
        }
    }
    
    private func fileHandle(filePath: String) {
        for _ in 0 ..< 10 {
            DispatchQueue.global().async {
                do {
                    let service = try self.resolver.resolve(type: FileCryptoService.self)
                    let fileHandle = try service.fileHandle(atPath: filePath, forUsage: .reading)
                    if let data = try fileHandle.readToEnd() {
                        print("\(#fileID), \(#function) \(#line) #Data: ", String(data: data, encoding: .utf8) ?? "")
                    }
                    try fileHandle.close()
                } catch {
                    print("\(#fileID), \(#function) \(#line) #Error: ", error)
                }
            }
        }
    }
}
