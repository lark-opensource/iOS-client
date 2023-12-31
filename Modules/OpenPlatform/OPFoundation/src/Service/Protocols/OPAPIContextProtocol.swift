//
//  OPAPIContextProtocol.swift
//  OPSDK
//
//  Created by lixiaorui on 2021/2/9.
//

import Foundation

//  此协议为开放平台用于PluginSystem系统Api调度的context依赖集合，会以”gadgetContext“为key塞到OPAPIContext的additionalInfo中

public protocol OPAPIContextProtocol: NSObjectProtocol {

    var uniqueID: OPAppUniqueID { get }

    @available(*, deprecated, message: "Use GadgetSessionPlugin instead")
    var session: String { get }

    var controller: UIViewController? { get }

    // fireEvent在当前engine
    func fireEvent(event: String, sourceID: Int, data: [AnyHashable: Any]?) -> Bool

}

