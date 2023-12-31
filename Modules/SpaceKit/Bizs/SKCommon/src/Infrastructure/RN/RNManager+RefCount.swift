//
//  RNManager+RefCount.swift
//  SpaceKit
//
//  Created by maxiao on 2019/10/17.
//

import SKFoundation
import SwiftyJSON

extension RNManager {
    enum RNManagerReferenceAction {
        case plus
        case minus
    }

    enum RNManagerReferenceOperation: String {
        case beginSync
        case endSync
        case pushList
    }

    enum RNManagerPulistType: String {
        case registerList
        case unRegisterList
    }

    // swiftlint:disable cyclomatic_complexity
    func handleReferenceCount(data: [String: Any]) -> Bool {

        let data = JSON(data)
        let business = RNManager.RNEventName(rawValue: data["business"].stringValue) ?? .unknown
        let operation = data["data"]["operation"].stringValue
        let fileTokenRaw = data["data"]["identifier"]["token"].string ?? ""
        let fileType = data["data"]["identifier"]["type"].int ?? 0
        let extraId = data["data"]["identifier"]["extraId"].string ?? ""
        let pushListType = data["data"]["body"]["type"].string ?? ""
        // Drive特殊场景的key
        var tag = data["data"]["body"]["tag"].string
        if let driveTag = tag, let subType = data["data"]["body"]["subtype"].string {
            tag = driveTag + subType
        }

        if business != .base, fileTokenRaw.isEmpty {
            return false
        }

        // 通用场景的key
        let encryToken = DocsTracker.encrypt(id: fileTokenRaw)
        let key = "\(business)_\(encryToken)_\(fileType)_\(extraId)"


        switch business {
        case .base:
            guard let driveTag = tag else { return false }
            let encryDriveTag = driveTag.encryptToken
            if operation == RNManagerReferenceOperation.beginSync.rawValue {
                DocsLogger.debug("======> RN  base event \(String(describing: encryDriveTag)) 计数器加一")
                return updateReferenceCount(key: encryDriveTag, action: .plus)
            } else if operation == RNManagerReferenceOperation.endSync.rawValue {
                DocsLogger.debug("======> RN  base event \(String(describing: encryDriveTag)) 计数器减一")
                return updateReferenceCount(key: encryDriveTag, action: .minus)
            } else if operation == RNManagerReferenceOperation.pushList.rawValue {
                if pushListType == RNManagerPulistType.registerList.rawValue {
                    DocsLogger.debug("======> RN pushList event \(String(describing: encryDriveTag)) 计数器加一")
                    return updateReferenceCount(key: encryDriveTag, action: .plus)
                } else if pushListType == RNManagerPulistType.unRegisterList.rawValue {
                    DocsLogger.debug("======> RN pushList event \(String(describing: encryDriveTag)) 计数器减一")
                    return updateReferenceCount(key: encryDriveTag, action: .minus)
                }
            }
        case .comment:
//            if operation == RNManagerReferenceOperation.beginSync.rawValue {
//                DocsLogger.debug("======> RN  comment event \(key) 计数器加一")
//                return updateReferenceCount(key: key, action: .plus)
//            } else if operation == RNManagerReferenceOperation.endSync.rawValue {
//                DocsLogger.debug("======> RN  comment event \(key) 计数器减一")
//                return updateReferenceCount(key: key, action: .minus)
//            }
            return false
        case .common:
            if operation == RNManagerReferenceOperation.beginSync.rawValue {
                DocsLogger.debug("======> RN  common event \(key) 计数器加一")
                return updateReferenceCount(key: key, action: .plus)
            } else if operation == RNManagerReferenceOperation.endSync.rawValue {
                DocsLogger.debug("======> RN  common event \(key) 计数器减一")
                return updateReferenceCount(key: key, action: .minus)
            }
        case .version:
            if operation == RNManagerReferenceOperation.beginSync.rawValue {
                DocsLogger.debug("======> RN  version event \(key) 计数器加一")
                return updateReferenceCount(key: key, action: .plus)
            } else if operation == RNManagerReferenceOperation.endSync.rawValue {
                DocsLogger.debug("======> RN  version event \(key) 计数器减一")
                return updateReferenceCount(key: key, action: .minus)
            }
        default:
            return false
        }
        return false
    }

    private func updateReferenceCount(key: String, action: RNManagerReferenceAction) -> Bool {
        // 已经存在
        if var count = referenceCount[key] {
            switch action {
            case .plus:
                count += 1
            case .minus:
                count -= 1
            }

            if count == 0 {
                referenceCount.removeValue(forKey: key)
                DocsLogger.info("======> RN event \(key), return = false, 计数器为零 ，当前剩余在计数的为\(referenceCount.keys.count)个")
                return false
            } else if count >= 1 {
                referenceCount[key] = count
                DocsLogger.info("======> RN event \(key), return = true, count >= 1")
                return true
            } else if count < 0 {
                assertionFailure("引用计数不能为负数！")
                DocsLogger.info("======> RN event \(key), return = true, 引用计数不能为负数！")
                return true
            }
        } else {
            switch action {
            case .plus:
                referenceCount[key] = 1
                return false
            case .minus:
                //assertionFailure("没有计数的时候不能减！")
                DocsLogger.info("======> RN event \(key), return = true, 没有计数的时候不能减！")
                return true
            }
        }
        return false
    }
}
