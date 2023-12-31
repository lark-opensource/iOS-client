//
//  DriveAuditStatusPushHandler.swift
//  SpaceKit
//
//  Created by zenghao on 2019/8/13.
//

import Foundation
import SKCommon
import SKFoundation

//protocol DriveAuditStatusPushHandlerDelegate: AnyObject {
//    func auditStatusChanged()
//}
//
// 由于文件审核也是使用权限推送服务（信箱版本），不需要使用这个。留着后续作为Demo
//class DriveAuditStatusPushHandler {
//    private let tagPrefix = StablePushPrefix.permission.rawValue
//
//    let fileToken: String
//    private let pushManager: StablePushManager
//
//    weak var delegate: DriveAuditStatusPushHandlerDelegate?
//
//    init(fileToken: String) {
//        self.fileToken = fileToken
//        pushManager = StablePushManager(tag: tagPrefix + fileToken)
//        pushManager.register(with: self)
//    }
//
//    deinit {
//        pushManager.unRegister()
//        DocsLogger.debug("DriveAuditStatusPushHandler deinit")
//    }
//}
//
//extension DriveAuditStatusPushHandler: StablePushManagerDelegate {
//    func stablePushManager(_ manager: StablePushManager,
//                           didReceivedData data: [String: Any],
//                           forServiceType type: String,
//                           andTag tag: String) {
//        delegate?.auditStatusChanged()
//    }
//}
