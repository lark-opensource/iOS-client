//
//  FileCryptoDebugEntranceVC.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/26.
//

import UIKit
import LarkContainer
import UniverseDesignToast

protocol FileCryptoDebugHandle: UserResolverWrapper {
    init(userResolver: UserResolver, viewController: UIViewController?)
    func handle()
}

enum Crypto: String, CaseIterable {
    case lookupHeader = "查看文件头信息"
    case multiThreadRead = "多线程解密读取(v7.8)"
    case oldDebug = "性能测试（旧）"
    case fileMigration = "测试数据迁移(v7.8)"
    case createEmptyFile = "不加密文件迁移到V2加密"
    case v1ToV2 = "v1加密迁移到v2加密"
    case appendData = "数据Append"
    case group = "测试分组加解密数据"
    case aesToCommonCryptor = "CryptorSwift迁移到CommonCryptor"
    case seekRead = "Seek读取文件"
    case rustToCommonCryptor = "Rust迁移到CommonCryptor"
    case prefTests = "性能测试"
    case testStream = "InputStream/OutputStream"
    case fileHandle = "FileHandle"
    case testLarkStorage = "LarkStorage"
    case rustV2 = "Rust V2测试"
    case fileSize = "File Size 测试"
}

let cryptoEntrances: [Crypto: FileCryptoDebugHandle.Type] = {
    [
        .lookupHeader: FileCryptorLookupHeaderHandler.self,
        .oldDebug: FileCryptoDebugViewController.self,
        .fileMigration: FileMigrationDebugVC.self,
        .createEmptyFile: FileCryptoV2MigrateHandler.self,
        .v1ToV2: FileCryptoV1ToV2MigrateHandler.self,
        .appendData: FileCryptoAppendHandler.self,
        .group: FileCryptoGroupHandler.self,
        .aesToCommonCryptor: FileCryptoAESToCommonCryptorHandler.self,
        .seekRead: FileCryptorReadSeekHandler.self,
        .rustToCommonCryptor: FileCryptoRustToCommonCryptorHandler.self,
        .prefTests: FileCryptoPrefTestHandler.self,
        .testStream: FileCryptoStreamTestHandler.self,
        .fileHandle: FileCryptoFileHandleTestHandler.self,
        .testLarkStorage: FileCryptoDebugStorageHandler.self,
        .rustV2: FileCryptoRustV2TestHandler.self,
        .fileSize: FileCryptoFileSizeHandle.self,
        .multiThreadRead: FileCryptoMultiThreadReadTestHandle.self,
    ]
}()

class FileCryptoDebugEntranceVC: UITableViewController {
   
    
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "文件加解密测试"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Crypto.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        let key = Crypto.allCases[indexPath.row]
        cell?.textLabel?.text = key.rawValue
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = Crypto.allCases[indexPath.row]
        let debugType = cryptoEntrances[key]
        debugType?.init(userResolver: userResolver, viewController: self).handle()
    }
}
