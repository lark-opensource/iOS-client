//
//  FileCryptoStreamTestHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/8/3.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import LarkAccountInterface
import LarkEMM
import UniverseDesignToast

class FileCryptoStreamTestHandler: FileCryptoDebugHandle {
    
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
        let path = NSTemporaryDirectory() + "stream_test_file"
        guard let output = cryptoService.outputStream(atPath: path, append: false) else { return }
        guard let hello = "hello world".data(using: .utf8) else { return }
        output.open()
        hello.withUnsafeBytes { pointer in
            guard let addr = pointer.bindMemory(to: UInt8.self).baseAddress else { return }
            _ = output.write(addr, maxLength: hello.count)
        }
        output.close()
        
        guard let input = cryptoService.inputStream(atPath: path) else { return }
        input.open()
        var data = Array(repeating: UInt8(0), count: hello.count)
        _ = input.read(&data, maxLength: hello.count)
        let str = String(data: Data(data), encoding: .utf8)
        UDToast.showTips(with: "数据加密已完成\(str ?? "")，路径写入粘贴板中~", on: view)
        UIPasteboard.general.string = path
    }
}
