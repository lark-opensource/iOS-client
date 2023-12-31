//
//  Path+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/23.
//

import Foundation
import LarkStorageCore

extension PathType {

    /// 获取加密路径，CCM 业务分享第三方场景用到，后续可能会下掉
    public func encrypt(suite: SBCipherSuite) throws -> AbsPath {
        guard let cipher = SBCipherManager.shared.cipher(for: suite) else {
            return AbsPath(absoluteString)
        }
        return AbsPath(try cipher.encryptPath(absoluteString))
    }

}
