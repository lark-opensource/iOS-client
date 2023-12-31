//
//  EncryptionTool.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/12/30.
//

import Foundation
import CryptoSwift

/// 用于user_id 和 device_id 加密

/// 数据加密
/// - Parameter str: 要加密的数据
func secreatString(str: String) -> String {
    let md5 = (str + "42b91e").md5()
    let sha1 = ("08a441" + md5).sha1()
    return sha1
}
