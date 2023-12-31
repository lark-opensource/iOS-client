//
//  CryptoPreprocess.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/1.
//

import Foundation
import LarkContainer

struct CryptoPreprocess {
    struct Read {
        /// 读文件预处理：1. 迁移到v2、2. header校验
        static func v2Preprocess(userResolver: UserResolver, info: AESMetaInfo) throws -> (Data, AESHeader) {
            let aHeader: AESHeader
            var deviceKey = info.deviceKey
            let migrateFile = MigrateFileV2(userResolver: userResolver, info: info)
            if let header = try migrateFile.doProcess() { // 迁移完成直接返回新header
                aHeader = header
            } else { // 无需迁移，取当前的header
                aHeader = try AESHeader(filePath: info.filePath)
                do {
                    try aHeader.checkV2Header(did: info.did, uid: info.uid, deviceKey: info.deviceKey)
                } catch AESHeader.CheckError.didNotMatched(let did) {
                    let service = try userResolver.resolve(type: FileCryptoService.self)
                    deviceKey = try service.deviceKey(did: did)
                }
            }
            return (deviceKey, aHeader)
        }
    }
    
    // 写文件预处理：append情况下会迁移，链路和read一致；
    struct Write {
        static func v2Preprocess(append: Bool, userResolver: UserResolver, info: AESMetaInfo) throws -> (Data, AESHeader) {
            if append {
                return try Read.v2Preprocess(userResolver: userResolver, info: info)
            } else {
                let aHeader = AESHeader(key: info.deviceKey,
                                        uid: Int64(info.uid) ?? 0,
                                        did: Int64(info.did) ?? 0)
                return (info.deviceKey, aHeader)
            }
        }
    }
}
