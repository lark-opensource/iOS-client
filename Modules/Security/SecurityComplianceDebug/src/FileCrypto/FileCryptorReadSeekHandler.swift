//
//  FileCryptorReadSeekHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/30.
//

import UIKit
import LarkContainer
import CryptoSwift
import LarkAccountInterface
import LarkSecurityCompliance
import UniverseDesignToast

class FileCryptorReadSeekHandler: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_read_seek_data").path

    
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func handle() {
        do {
            try writeData()
            
            try self.readData(offset: 0)
            try self.readData(offset: 10)
            try self.readData(offset: 17)
            try readData(offset: 34)
            
        } catch {
            print(">>>>> error: ", error)
        }
    }
    
    private func writeData() throws {
        guard let data = "helloworld12345678901234567890jk;lfjfkhfakfhakjfahflajklfhjkafjkfkhjafkafjkfajkhfhjahjkfa".data(using: .utf8) else { return }
        let cryptor = CryptoStream(enableStreamCipherMode: true, deviceKey: FileCryptoDeviceKey.deviceKey(), uid: userService.user.userID, did: passportService.deviceID, userResolver: userResolver)
        let encryptor = try cryptor.encrypt(to: filePath)
        try encryptor.open(shouldAppend: false)
        try encryptor.write(data: data)
        try encryptor.close()
        
        print(#fileID, #function, #line, "data: ", data.bytes.description)
        if let view = viewController?.view.superview {
            UDToast.showTips(with: "\(#fileID), \(#function), \(#line), data: , \(data.bytes.description)", on: view)
        }
    }
    
    
    private func readData(offset: Int) throws {
        let cryptor = CryptoStream(enableStreamCipherMode: true, deviceKey: FileCryptoDeviceKey.deviceKey(), uid: userService.user.userID, did: passportService.deviceID, userResolver: userResolver)
        let decryptor = try cryptor.decrypt(from: filePath)
        try decryptor.open(shouldAppend: false)
        _ = try decryptor.seek(from: .start, offset: UInt64(offset))
        let readData = try decryptor.read(maxLength: UInt32.max)

        try decryptor.close()
        print(#fileID, #function, #line, readData.bytes.description, String(data: readData, encoding: .utf8) ?? "")
        if let view = viewController?.view.superview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UDToast.showTips(with: "\(#fileID), \(#function), \(#line), data: , \(readData.bytes.description), \(String(data: readData, encoding: .utf8) ?? "")", on: view)
            }
        }
    }
    
}
