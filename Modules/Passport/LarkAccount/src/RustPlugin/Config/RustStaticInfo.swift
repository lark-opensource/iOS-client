//
//  RustStaticInfo.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2022/9/30.
//

import Foundation
import LarkContainer
import LarkRustClient
import LKCommonsLogging

class RustStaticInfo {
    static let logger = Logger.plog(RustStaticInfo.self, category: "RustPlugin.Config.RustStaticInfo")

    @_silgen_name("lark_sdk_version")
    static private func lark_sdk_version(buf_ptr: inout UnsafeMutablePointer<UInt8>!) -> Int

    //使用静态计算属性实现lazy加载，下方代码仅在第一次调用时执行
    static var sdkVersion: String? = {
        var _version: UnsafeMutablePointer<UInt8>!
        var length = lark_sdk_version(buf_ptr: &_version)
        if let sdkversion = _version {
            let data = Data(bytes: sdkversion, count: length)
            let _str = String(data: data, encoding: String.Encoding.utf8)
            if let str = _str {
                logger.info("n_action_get_sdkVersion_succ",additionalData:["version":str])
                return str
            }
        }
        logger.info("n_action_get_sdkVersion_fail")
        return nil

    }()

}

