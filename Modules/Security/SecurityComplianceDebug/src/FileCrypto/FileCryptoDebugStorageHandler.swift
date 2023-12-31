//
//  FileCryptoDebugStorageHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/9/7.
//

import UIKit
import LarkContainer
import LarkStorage
import LarkSecurityCompliance
import UniverseDesignToast

class FileCryptoDebugStorageHandler: FileCryptoDebugHandle {

    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func handle() {
        do {
            let service = try userResolver.resolve(type: FileCryptoService.self)

            /// 使用LarkStorage进行操作
            /// 1. 明文写入、2. 密文写入、3. 明文写入

            guard let hello = "12345".data(using: .utf8) else { return }
            do {
                let cachePath = userResolver.isoPath(in: Domain.biz.snc.child("test_hello2"), type: .cache)
                print(">>>>>>>", cachePath.asAbsPath().absoluteString)
                if FileManager.default.fileExists(atPath: cachePath.absoluteString) {
                    try? FileManager.default.removeItem(atPath: cachePath.absoluteString)
                }
                /// 1. 明文创建文件
                try cachePath.createFile(with: hello, attributes: nil)
                /// 2. 明文写入
                let clear1FileHandle = try cachePath.fileHandleForWriting(append: true)
                _ = try clear1FileHandle.seekToEnd()
                if let data = "67890".data(using: .utf8) {
                    try clear1FileHandle.write(contentsOf: data)
                }
                try clear1FileHandle.close()

                /// 3. 密文写入
                let cachePath2 = userResolver.isoPath(in: Domain.biz.snc.child("test_hello2"), type: .cache).usingCipher()
                let secureWriteFileHandle = try cachePath2.fileHandleForWriting(append: true)
                _ = try secureWriteFileHandle.seekToEnd()
                if let data = "hello".data(using: .utf8) {
                    try secureWriteFileHandle.write(contentsOf: data)
                }
                try secureWriteFileHandle.close()

                /// 4. 明文写入

                let cachePath3 = userResolver.isoPath(in: Domain.biz.snc.child("test_hello2"), type: .cache)
                let clearFileHandle = try cachePath3.fileHandleForWriting(append: true)
                _ = try clearFileHandle.seekToEnd()
                if let data = "world".data(using: .utf8) {
                    try clearFileHandle.write(contentsOf: data)
                }
                try clearFileHandle.close()


                /// 5. 通过decryptPath解密
                let newPath = try SBUtils.decrypt(atPath: cachePath2)
                let pathData = try Data(contentsOf: URL(fileURLWithPath: newPath.absoluteString))
                if let str = String(data: pathData, encoding: .utf8) {
                    print(">>>>>>>>> read str: ", str)
                    UDToast.showTips(with: "数据读取完成：\(str)", on: (viewController?.view.superview)!)
                } else {
                    UDToast.showTips(with: "数据读取失败", on: (viewController?.view.superview)!)
                }




                do {
                    let newPath = try service.decrypt(from: cachePath.asAbsPath().absoluteString)
                    print(">>>>>>> 2: ", newPath)

                    let data = try Data(contentsOf: URL(fileURLWithPath: cachePath.asAbsPath().absoluteString))
                    let header = try AESHeader(data: data)
                    print(header.values)
                } catch {
                    print(">>>>>>> ERROR2: ", error)
                }

            } catch {
                print(">>>>>>> ERROR: ", error)
                UDToast.showTips(with: "数据读取失败: \(error)", on: (viewController?.view.superview)!)
            }

                        
            let cipherCachePath = userResolver.isoPath(in: Domain.biz.snc.child("test_hello_2"), type: .cache).usingCipher()
            let clearCachePath = userResolver.isoPath(in: Domain.biz.snc.child("test_hello_2"), type: .cache)
            if FileManager.default.fileExists(atPath: cipherCachePath.absoluteString) {
                try FileManager.default.removeItem(atPath: cipherCachePath.absoluteString)
            }
            FileManager.default.createFile(atPath: cipherCachePath.absoluteString, contents: Data())
            let fileHandle = try cipherCachePath.fileHandleForWriting(append: true)
            _ = try fileHandle.seekToEnd()
            if let data = "12345".data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }
            try fileHandle.close()
            
            let clearFileHandle = try clearCachePath.fileHandleForWriting(append: true)
            _ = try clearFileHandle.seekToEnd()
            let data = "67890".data(using: .utf8)!
            try clearFileHandle.write(contentsOf: data)
            try clearFileHandle.close()
            
            //1. 明文文件，2. 加密append
            do {
                // 1. 明文
                guard let data = "12345".data(using: .utf8) else { return }
                let path = NSTemporaryDirectory() + "test_cqc.txt"
                if FileManager.default.fileExists(atPath: path) {
                    try? FileManager.default.removeItem(atPath: path)
                }
                FileManager.default.createFile(atPath: path, contents: data)
                
                let service = try userResolver.resolve(type: FileCryptoService.self)
                
                //2. 加密append
                let fileHandle = try service.fileHandle(atPath: path, forUsage: .writing(shouldAppend: true))
                _ = try fileHandle.seekToEnd()
                let newData = "67890".data(using: .utf8) ?? Data()
                try fileHandle.write(contentsOf: newData)
                try fileHandle.close()
                
                let decryptedPath = try service.decryptPath(path)
                if decryptedPath != path {
                    _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: path), withItemAt: URL(fileURLWithPath: decryptedPath))
                }
                
                let writeFile = try SCFileHandle(path: path, option: .write)
                _ = try writeFile.seekToEnd()
                try writeFile.write(contentsOf: "hello".data(using: .utf8)!)
                try writeFile.close()
                
                let readFileHandle = try service.fileHandle(atPath: path, forUsage: .reading)
                if let readData = try readFileHandle.readToEnd() {
                    let str = String(data: readData, encoding: .utf8)
                    print(">>>>>>>>> read str 0: ", str)
                }
                try readFileHandle.close()
                
                //3. 通过decryptPath解密
                let newPath = try service.decryptPath(path)
                let pathData = try Data(contentsOf: URL(fileURLWithPath: newPath))
                if let str = String(data: pathData, encoding: .utf8) {
                    print(">>>>>>>>> read str 2: ", str)
                }
            } catch {
                print(">>>>>>> ERROR3: ", error)
            }
            
        } catch {
            
        }
        
    }
}
