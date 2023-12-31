//
//  FileMigrationPrefsDebugHandle.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/30.
//

import Foundation
import LarkContainer
import LarkSecurityCompliance
import UniverseDesignToast

final class FileMigrationPerfsDebugHandle: FileMigrationDebug {
    
    let userResolver: UserResolver
    let from: FileMigrationDebugFrom
    let vc: UIViewController?
    
    init(userResolver: UserResolver, from: FileMigrationDebugFrom, vc: UIViewController?) {
        self.userResolver = userResolver
        self.from = from
        self.vc = vc
    }
    
    func trigger() {
        guard let view = vc?.view.superview else { return }
        let filePath = NSTemporaryDirectory() + "security_temp"
        /// 大文件写入：100M
        let fileSize = 1000_000
        let arr = Array(repeating: "1", count: fileSize)
        do {
            let path = filePath + "/big_file"
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            
            UDToast.showLoading(with: "数据写入中...", on: view)
            
            DispatchQueue.global().async {
                do {
                    FileManager.default.createFile(atPath: path, contents: nil)
                    let file = try SCFileHandle(path: path, option: .write)
                    for _ in 0 ..< 100 {
                        guard let data = arr.joined().data(using: .utf8) else { return }
                        try file.write(contentsOf: data)
                    }
                    try file.close()
                    
                    DispatchQueue.main.async {
                        UDToast.showTips(with: "开始数据迁移", on: view)
                    }
                    let start = CACurrentMediaTime()
                    let service = try self.userResolver.resolve(type: FileCryptoService.self)
                    let fileHandle = try service.fileHandle(atPath: path, forUsage: .reading)
                    _ = try fileHandle.readToEnd()
                    try fileHandle.close()
                    let cost = CACurrentMediaTime() - start
                    print("\(#fileID), \(#function) \(#line) #Result: ", cost)
                    
                    DispatchQueue.main.async {
                        UDToast.showTips(with: "数据迁移完成，耗时: \(cost)", on: view)
                    }
                } catch {
                    print("\(#fileID), \(#function) \(#line) #Error: ", error, "From: ", self.from)
                }
            }
        } catch {
            print("\(#fileID), \(#function) \(#line) #Error: ", error, "From: ", self.from)
        }
        
        
    }
}
