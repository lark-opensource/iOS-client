//
//  FileCryptoMultiThreadReadTestHandle.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/23.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance

final class FileCryptoMultiThreadReadTestHandle: FileCryptoDebugHandle {
    
    weak var vc: UIViewController?
    let userResolver: LarkContainer.UserResolver

    
    init(userResolver: LarkContainer.UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.vc = viewController
    }
    
    static let queue = DispatchQueue(label: "file_multi_thread_read", attributes: [.concurrent])
    
    let filePath = NSTemporaryDirectory() + "file_multi_thread_read.txt"
    @ScopedProvider var service: FileCryptoService?
    
    func handle() {
        guard let service else { return }
        testFileManager()
        let path = filePath
//        do {
//            let output = try service.encrypt(to: path)
//            try output.open(shouldAppend: false)
//            try output.write(data: "1234567112345671123456711234567112345671".data(using: .utf8)!)
//            try output.close()
//        } catch {
//            print("ERROR: ", error)
//        }
        FileManager.default.createFile(atPath: path, contents: nil)
        do {
            let file = try SCFileHandle(path: path, option: .write)
            for _ in 0 ..< 100 {
                try autoreleasepool {
                    let arr = Array(repeating: "1234567890", count: 10_000)
                    if let data = arr.description.data(using: .utf8) {
                        try file.write(contentsOf: data)
                    }
                }
            }
            try file.close()
        } catch {
            print(#fileID, #line, "ERROR: ", error)
        }
        for _ in 0 ..< 10 {
            Self.queue.async {
                autoreleasepool {
                    do {
                        _ = try service.readData(from: path)
                        print(#fileID, #line, path, " : ", Thread.current)
                    } catch {
                        print("ERROR: ", error)
                    }
                }
            }
        }
    }
    
    
    static let dirPath = NSTemporaryDirectory() + UUID().uuidString + "/" + UUID().uuidString + "/"
    private func testFileManager() {
        do {
            try FileManager.default.createDirectory(atPath: Self.dirPath, withIntermediateDirectories: true)
            let filePath = Self.dirPath + UUID().uuidString
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            FileManager.default.createFile(atPath: filePath, contents: nil)
            print(#fileID, "PATH: ", Self.dirPath)
        } catch {
            print(#fileID, "ERROR: ", error)
        }
    }
}
