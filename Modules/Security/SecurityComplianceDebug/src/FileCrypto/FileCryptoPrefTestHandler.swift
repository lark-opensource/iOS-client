//
//  FileCryptoPerfTestHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/7/4.
//

import UIKit
import LarkContainer
import CryptoSwift
import LarkAccountInterface
import LarkSecurityCompliance
import UniverseDesignToast
import LarkEMM
import LarkRustClient
import RustPB

class FileCryptoPrefTestHandler: FileCryptoDebugHandle {
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    @ScopedProvider var rustService: RustService?
    
    let clearFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_prefs_data_clear").path
    let rustV1FilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_prefs_data_rust_v1").path
    let rustV2FilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_prefs_data_rust_v2").path
    let nativeFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_prefs_data_native").path
    let cryptoSwiftFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("security_test_prefs_data_crypto_swift").path


    private var count = 0 {
        didSet {
            let divider = 50 * 1000 * 1000
            let groups = count / divider
            var arr = Array(repeating: divider, count: groups)
            let reminder = count % divider
            if reminder > 0 {
                arr.append(reminder)
            }
            self.groups = arr
        }
    }
    
    var groups = [Int]()
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    var times = [String: [(Double, Double, Double)]]()
    
    func handle() {
        showAlert()
    }
    
    private func showAlert() {
        guard let viewController else { return }
        let alert = UIAlertController(title: "请输入要测试的文件大小，单位byte", message: "", preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "输入要进行性能测试文件大小，单位KB"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak alert] _ in
            guard let text = alert?.textFields?.first?.text else { return }
            let num = Int(text) ?? 0
            self.count = num * 1000
            self.realDo()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        navigator.present(alert, from: viewController)
    }
    
    private func realDo() {
        guard let view = viewController?.view.superview else { return }
        DispatchQueue.main.async {
            UDToast.showLoading(with: "性能测试中...", on: view)
        }
        DispatchQueue.global().async {
            for _ in 0 ..< 5 {
                self.groups.forEach {
                    guard let data = Array(repeating: "x", count: $0).joined().data(using: .utf8) else { return }
                    autoreleasepool {
                        self.testClear(data: data)
                    }
                    autoreleasepool {
                        self.testNative(data: data)
                    }
                    autoreleasepool {
                        self.testCryptoSwift(data: data)
                    }
                    autoreleasepool {
                        self.testRustV2(data: data)
                    }
                    autoreleasepool {
                        self.testRustV1(data: data)
                    }
                }
            }
            
            DispatchQueue.main.async {
                var averages = [String: (Double, Double, Double)]()
                self.times.forEach { (key, value) in
                    let result = value.reduce((0, 0, 0)) { p, c in
                        (p.0 + c.0, p.1 + c.1, p.2 + c.2)
                    }
                    averages[key] = (result.0 / Double(value.count), result.1 / Double(value.count), result.2 / Double(value.count))
                }
                SCPasteboard.general(SCPasteboard.defaultConfig()).string = self.times.description + averages.description
                print("性能测试数据：", self.times, "平均值：", averages)
                UDToast.showTips(with: "性能测试结束, 数据已写入粘贴板", on: view)
            }
        }
    }

    // 明文
    private func testClear(data: Data) {
        if FileManager.default.fileExists(atPath: clearFilePath) {
            try? FileManager.default.removeItem(atPath: clearFilePath)
        }
        FileManager.default.createFile(atPath: clearFilePath, contents: Data())
        
        let write = writeClear(data: data)
        
        let read = readClearData()
        
        var clearTimes = times["clear"] ?? []
        clearTimes.append((write, read, write + read))
        times["clear"] = clearTimes
    }
    
    private func writeClear(data: Data) -> Double {
        let start = CACurrentMediaTime()
        do {
            let fileHandle = try SCFileHandle(path: clearFilePath, option: .write)
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()
        } catch {
            print("ERROR: ", #function, error)
        }
        return CACurrentMediaTime() - start
    }
    
    private func readClearData() -> Double {
        let start = CACurrentMediaTime()
        do {
            let fileHandle = try SCFileHandle(path: clearFilePath, option: .read)
            _ = try fileHandle.readToEnd()
            try fileHandle.close()
        } catch {
            print("ERROR: ", #function, error)
        }
        return CACurrentMediaTime() - start
    }
    
    // V1加密
    private func testRustV1(data: Data) {
        if FileManager.default.fileExists(atPath: rustV1FilePath) {
            try? FileManager.default.removeItem(atPath: rustV1FilePath)
        }
        FileManager.default.createFile(atPath: rustV1FilePath, contents: Data())
        
        let write = writeRustV1Data(data: data)
        
        let read = readRustV1Data()
        
        var clearTimes = times["rust_v1"] ?? []
        clearTimes.append((write, read, write + read))
        times["rust_v1"] = clearTimes
    }
    
    private func writeRustV1Data(data: Data) -> Double {
        setupCipherMode(isBlockMode: true)
        // 测试写入
        let cipher = CryptoPath(userResolver: userResolver)
        let writeBegin = CFAbsoluteTimeGetCurrent()
        do {
            try data.write(to: rustV1FilePath.asPath())
            try cipher.encrypt(rustV1FilePath)
        } catch {
            print("文件写入失败：\(error)")
            return 0
        }
        return CFAbsoluteTimeGetCurrent() - writeBegin
    }
    
    private func readRustV1Data() -> Double {
        // 删除缓存
        let cipher = CryptoPath(userResolver: userResolver)
        do {
            let decryptPath = try cipher.decrypt(rustV1FilePath)
            try FileManager.default.removeItem(atPath: decryptPath)
        } catch {
            print("缓存文件删除失败：\(error)")
            return 0
        }
        // 没有缓存
        let noCacheReadBegin = CFAbsoluteTimeGetCurrent()
        do {
            // 有缓存的情况
            let decryptPath = try cipher.decrypt(rustV1FilePath)
            _ = try Data(contentsOf: URL(fileURLWithPath: decryptPath))
        } catch {
            print("无缓存文件读取失败：\(error)")
            return 0
        }
        return CFAbsoluteTimeGetCurrent() - noCacheReadBegin
    }
    
    //Rust v2加密
    
    private func testRustV2(data: Data) {
        if FileManager.default.fileExists(atPath: rustV2FilePath) {
            try? FileManager.default.removeItem(atPath: rustV2FilePath)
        }
        FileManager.default.createFile(atPath: rustV2FilePath, contents: Data())
        
        let write = writeRustV2Data(data: data)
        let read = readRustV2Data()
       
        var clearTimes = times["rust_v2"] ?? []
        clearTimes.append((write, read, write + read))
        times["rust_v2"] = clearTimes
    }
    
    private func writeRustV2Data(data: Data) -> Double {
        do {
            guard let rustService else { return 0 }
            setupCipherMode(isBlockMode: false)
            let readBegin = CFAbsoluteTimeGetCurrent()
            
            let crypto = RustCryptoFile(atFilePath: rustV2FilePath, rustService: rustService)
            try crypto.open(options: [.write])
            _ = try crypto.write(data: data, position: nil)
            try crypto.close()
            return CFAbsoluteTimeGetCurrent() - readBegin
        } catch {
            return 0
        }
    }
    
    private func readRustV2Data() -> Double {
        do {
            guard let rustService else { return 0 }
            setupCipherMode(isBlockMode: false)
            let readBegin = CFAbsoluteTimeGetCurrent()
            
            let crypto = RustCryptoFile(atFilePath: rustV2FilePath, rustService: rustService)
            try crypto.open(options: [.read])
            _ = try crypto.read(maxLength: UInt32.max, position: nil)
            try crypto.close()
            return CFAbsoluteTimeGetCurrent() - readBegin
        } catch {
            return 0
        }
    }
    
    //Native加密
    
    private func testNative(data: Data) {
        if FileManager.default.fileExists(atPath: nativeFilePath) {
            try? FileManager.default.removeItem(atPath: nativeFilePath)
        }
        FileManager.default.createFile(atPath: nativeFilePath, contents: Data())
        
        let write = writeNativeData(data: data)
        let read = readNativeData()
       
        var clearTimes = times["native"] ?? []
        clearTimes.append((write, read, write + read))
        times["native"] = clearTimes
    }
    
    private func writeNativeData(data: Data) -> Double {
        do {
            let start = CACurrentMediaTime()
            let cryptor = CryptoStream(enableStreamCipherMode: true, deviceKey: FileCryptoDeviceKey.deviceKey(), uid: userService.user.userID, did: passportService.deviceID, userResolver: userResolver)
            let encryptor = try cryptor.encrypt(to: nativeFilePath)
            try encryptor.open(shouldAppend: false)
            try encryptor.write(data: data)
            try encryptor.close()
            return CACurrentMediaTime() - start
        } catch {
            return 0
        }
    }
    
    private func readNativeData() -> Double {
        do {
            let start = CACurrentMediaTime()
            let cryptor = CryptoStream(enableStreamCipherMode: true, deviceKey: FileCryptoDeviceKey.deviceKey(), uid: userService.user.userID, did: passportService.deviceID, userResolver: userResolver)
            let decryptor = try cryptor.decrypt(from: nativeFilePath)
            try decryptor.open(shouldAppend: false)
            _ = try decryptor.read(maxLength: UInt32.max)

            try decryptor.close()
            
            return CACurrentMediaTime() - start
        } catch {
            return 0
        }
    }
    
    // CryptoSwift
    
    private var cryptoSwiftIV = [UInt8]()
    private func testCryptoSwift(data: Data) {
        if FileManager.default.fileExists(atPath: cryptoSwiftFilePath) {
            try? FileManager.default.removeItem(atPath: cryptoSwiftFilePath)
        }
        FileManager.default.createFile(atPath: cryptoSwiftFilePath, contents: Data())
        
        let write = writeCryptoSwiftData(data: data)
        let read = readCryptoSwiftData()
       
        var clearTimes = times["crypto_swift"] ?? []
        clearTimes.append((write, read, write + read))
        times["crypto_swift"] = clearTimes
    }
    
    private func writeCryptoSwiftData(data: Data) -> Double {
        do {
            let start = CACurrentMediaTime()

            if cryptoSwiftIV.isEmpty {
                cryptoSwiftIV = FileCryptoAESToCommonCryptorHandler.randomNonce()
            }
            let aes = try AES(key: FileCryptoDeviceKey.deviceKey().bytes, blockMode: CTR(iv: cryptoSwiftIV))
            let result = try aes.encrypt(data.bytes)
            FileManager.default.createFile(atPath: cryptoSwiftFilePath, contents: Data(result))
            return CACurrentMediaTime() - start
        } catch {
            return 0
        }
    }
    
    private func readCryptoSwiftData() -> Double {
        do {
            let start = CACurrentMediaTime()
            guard let data = FileManager.default.contents(atPath: cryptoSwiftFilePath) else {
                return 0
            }
            let aes = try AES(key: FileCryptoDeviceKey.deviceKey().bytes, blockMode: CTR(iv: cryptoSwiftIV))
            _ = try aes.decrypt(data.bytes)
            return CACurrentMediaTime() - start
        } catch {
            return 0
        }
    }
    
    //MARK: - Private
    
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
