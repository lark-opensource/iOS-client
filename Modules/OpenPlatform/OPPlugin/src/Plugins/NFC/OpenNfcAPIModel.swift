//
//  OpenNFCAPIModel.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/28.
//

import Foundation
import LarkOpenAPIModel
/// NFC标签类型
enum OPNfcTechnology: String, OpenAPIEnum {
    case ndef = "NDEF"
    case nfcA = "NFC-A"
/// 下面的类型暂不支持
//    case nfcB = "NFC-B"
//    case nfcF = "NFC-F"
//    case nfcV = "NFC-V"
//    case isoDep = "ISO-DEP"
//    case mifareClassic = "MIFARE-Classic"
//    case mifareUltralight = "MIFARE-Ultralight"
}
// MARK: - OpenPluginNfcConnectRequest
final class OpenPluginNfcConnectRequest: OpenAPIBaseParams {
    /// description: 需要传递的二进制数据
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "tech")
    var tech: OPNfcTechnology
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_tech];
    }
}
// MARK: - OpenPluginNfcCloseRequest
final class OpenPluginNfcCloseRequest: OpenAPIBaseParams {
    /// description: 需要传递的二进制数据
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "tech")
    var tech: OPNfcTechnology
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_tech];
    }
}

// MARK: - OpenPluginNfcTransceiveRequest
final class OpenPluginNfcTransceiveRequest: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "tech")
    var tech: OPNfcTechnology
    
    /// description: 需要传递的二进制数据
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "data")
    var data: Data
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_data, _tech];
    }
}

// MARK: - OpenPluginNfcTransceiveResponse
final class OpenPluginNfcTransceiveResponse: OpenAPIBaseResult {
    
    /// description: 返回的二进制数据
    let data: Data?
    
    init(data: Data?) {
        self.data = data
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        var result: [AnyHashable : Any] = [:]
        result["data"] = data
        return result
    }
}
