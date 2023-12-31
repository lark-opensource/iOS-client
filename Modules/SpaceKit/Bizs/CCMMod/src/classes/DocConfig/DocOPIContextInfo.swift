//
//  DocOPIContextInfo.swift
//  LarkSpaceKit
//
//  Created by huayufan on 2021/8/2.
//  

import UIKit
import OPSDK
import SKCommon

struct DocOPIContextInfo: DocsOPAPIContextProtocol {

    weak var controller: UIViewController?

    var appId: String?

    init(_ params: [AnyHashable: Any]) throws {
        guard let context = params["gadgetContext"] as? OPAPIContextProtocol else {
            throw NSError(domain: "gadgetContext type conver fail", code: -1, userInfo: nil)
        }
        self.controller = context.controller
    }
}
