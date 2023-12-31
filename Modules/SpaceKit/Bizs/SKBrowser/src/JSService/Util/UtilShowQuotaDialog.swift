//
//  UtilShowQuotaDialog.swift
//  SKBrowser
//
//  Created by bupozhuang on 2021/3/28.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator
import SpaceInterface

public final class UtilShowQuotaDialog: BaseJSService { }

extension UtilShowQuotaDialog: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.showQuotaDialog]
    }
    public func handle(params: [String: Any], serviceName: String) {
        guard let typeCode = params["type"] as? Int,
              let type = QuotaAlertType(rawValue: typeCode) else {
            DocsLogger.error("showQuotaDialog params error")
            return
        }
        guard let from = registeredVC else {
            DocsLogger.error("can not get from vc")
            return
        }
        
        if type == .userQuotaLimited { // 用户容量弹出
            let mountPoint = params["mount_point"] as? String
            let moutToken = params["mount_token"] as? String
            QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: moutToken, mountPoint: mountPoint, from: from)
        } else { // 租户容量弹出
            QuotaAlertPresentor.shared.showQuotaAlert(type: type, from: from)
        }
    }
}
