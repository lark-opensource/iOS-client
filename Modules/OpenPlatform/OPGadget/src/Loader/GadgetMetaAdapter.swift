//
//  GadgetMetaAdapter.swift
//  OPGadget
//
//  Created by lixiaorui on 2020/12/2.
//
/// 该文件是原有gadget相关数据结构适配到新版架构的适配器

import Foundation
import TTMicroApp
import OPSDK

extension GadgetMeta: OPBizMetaProtocol {

//    public var appVersion: String {
//        return version
//    }

    /// 应用唯一ID
    public var appID: String {
        return uniqueID.appID
    }

    /// 应用版本号，目前后端未区分应用版本号和形态版本号，下发的都是形态版本号
    public var applicationVersion: String {
        return version
    }

    public var appName: String {
        return name
    }

    public var appIconUrl: String {
        return iconUrl
    }

    public var openSchemas: [Any]? {
        return (businessData as! GadgetBusinessData).extraDict["openSchemaWhiteList"] as? [Any]
    }

    public var useOpenSchemas: Bool? {
        return (businessData as! GadgetBusinessData).extraDict["useOpenSchemaWhiteList"] as? Bool
    }

    public var botID: String {
        return (businessData as! GadgetBusinessData).extraDict["botid"] as? String ?? ""
    }

    public var canFeedBack: Bool {
        return (businessData as! GadgetBusinessData).extraDict["feedback"] as? Bool ?? false
    }

    public var shareLevel: Int {
        return Int((businessData as! GadgetBusinessData).shareLevel.rawValue)
    }

}

extension BDPPackageStreamingFileHandle: OPPackageReaderProtocol {
    public func syncRead(file: String) throws -> Data {
        try readData(withFilePath: file)
    }
}
