//
//  FileCryptoFileHandleTestHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/8/3.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import LarkAccountInterface
import UniverseDesignToast

class FileCryptoFileHandleTestHandler: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func handle() {
        guard let view = viewController?.view.superview else { return }
        do {
            let path = NSTemporaryDirectory() + "file_handle_test_file_3"
            let write = try cryptoService.fileHandle(atPath: path, forUsage: .writing(shouldAppend: false))
            guard let hello = "hello world12345678901234567890".data(using: .utf8) else { return }
            try write.write(contentsOf: hello)
            try write.close()
            
            
            let read = try cryptoService.fileHandle(atPath: path, forUsage: .reading)
            let data = try read.readToEnd() ?? Data()
            try read.close()
            let str = String(data: data, encoding: .utf8) ?? ""
            UDToast.showTips(with: "已完成：\(str)", on: view)
        } catch {
            print(">>>>>> ERROR: ", error)
        }
    }
}
