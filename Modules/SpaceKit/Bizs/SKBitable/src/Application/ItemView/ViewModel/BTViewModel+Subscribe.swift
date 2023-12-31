//
//  BTViewModel+Subscribe.swift
//  SKBitable
//
//  Created by ByteDance on 2023/9/12.
//

import Foundation
import SKCommon
import SKBrowser
import SwiftyJSON
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import HandyJSON
import SpaceInterface
import SKInfra

//自动订阅弹窗操作
enum BTRecordAutoSubscribeAlertBehavior: Int {
    // 解除编辑自动订阅
    case confirmNoAutoSubscribe = 2
    // 用户点击解除弹窗中的取消
    case cancel = 3
}

enum BTRecordAutoSubStatus: Int {
    // 允许编辑操作触发自动订阅
    case editAutoSubDefault = 1
    // 不允许编辑操作触发自动订阅
    case editNoAutoSub = 2
}

enum BTRecordSubscribeStatus: Int {
    // 状态异常&未知
    case unknown = -1
    // 没有订阅
    case unSubscribe = 0
    // 订阅
    case subscribe = 1
    // 无权限
    case forbidden = 2
    
    init?(rawValue: Int) {
      switch rawValue {
        case -1:
          self = .unknown
        case 0:
          self = .unSubscribe
        case 1:
          self = .subscribe
        case 2:
          self = .forbidden
        default:
          return nil
      }
    }
    var rawValue: Int {
      switch self {
        case .unknown:
          return -1
        case .unSubscribe:
          return 0
        case .subscribe:
          return 1
        case .forbidden:
          return 2
      }
    }
}
enum BTRecordSubscribeCode: Int {
    // 成功
    case success
    // 无权限
    case forbidden
    // 超过订阅上限
    case overNumLimit
    // 异常
    case unknownError
    
    init?(rawValue: Int) {
      switch rawValue {
        case 0:
          self = .success
        case 800004011:
          self = .forbidden
        case 800004133:
          self = .overNumLimit
        default:
          return nil
      }
    }
    var rawValue: Int {
      switch self {
        case .success:
          return 0
        case .forbidden:
          return 800004011
        case .overNumLimit:
          return 800004133
        case .unknownError:
          return -1
      }
    }
    func codeTitle(isSubscribe: Bool) -> String {
        switch self {
        case .success:
            return isSubscribe ? BundleI18n.SKResource.Bitable_SubscribeRecords_Mobile_Subscribed_Toast :     BundleI18n.SKResource.Bitable_SubscribeRecords_Mobile_Unsubscribed_Toast
        case .overNumLimit:
            return BundleI18n.SKResource.Bitable_SubscribeRecords_FollowerLimitReached_ErrorMsg
        case .forbidden:
            return isSubscribe ? BundleI18n.SKResource.Bitable_SubscribeRecords_PermissionsChanged_ErrorMsg : BundleI18n.SKResource.Bitable_SubscribeRecords_UnfollowFailedPermitChanged_ErrorMsg()
        case .unknownError:
             return isSubscribe ? BundleI18n.SKResource.Bitable_SubscribeRecords_UnknownError_ErrorMsg : BundleI18n.SKResource.Bitable_SubscribeRecords_UnfollowFailedUnknown_ErrorMsg
        }  
    }
}

extension BTViewModel {
    enum SubscribeScene: Int {
        // 普通的订阅模式（只有 apply 完成的记录才能被订阅）
        case normal = 0
        // 添加记录场景下的订阅模式，后端将越过 apply 直接允许对 recordID 进行订阅
        case addRecord = 1
    }
    
    ///订阅&&取消订阅
    func subscribeRecord(token: String,
                       tableID: String,
                      recordId: String,
                   isSubscribe: Bool,
                         scene: SubscribeScene = .normal,
                    completion: @escaping (BTRecordSubscribeCode, Bool) -> Void)
    {
        var params: [String: Any] = [:]
        params["tableID"] = tableID
        params["recordID"] = recordId
        params["status"] = isSubscribe ? "1" : "0"
        params["scene"] = scene.rawValue
       let request =  DocsRequest<JSON>(path: OpenAPI.APIPath.getRecordSubscribeBehaviourPath(token), params: params)
            .set(method: .POST)
            .set(needVerifyData: false)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .set(retryCount: 0)
            .start(result: { json, error in
                guard error == nil else {
                    DocsLogger.error("subscribe record behaviour error", error: error)
                    completion(.unknownError, false)
                    return
                }
                guard let dict = json?.dictionaryObject else {
                    DocsLogger.btError("subscribe record behaviour error because of json")
                    completion(.unknownError, false)
                    return
                }
                guard let codeValue = dict["code"] as? Int else {
                    DocsLogger.btError("subscribe record behaviour error because of failing to parse code")
                    completion(.unknownError, false)
                    return
                }
                var isBaseUnSubscribe = false
                if let dataValue = dict["data"] as? NSDictionary, let value = dataValue["isBaseUnSubscribe"] as? Bool {
                    isBaseUnSubscribe = value
                }
                if let code = BTRecordSubscribeCode.init(rawValue: codeValue) {
                    completion(code, isBaseUnSubscribe)
                } else {
                    completion(.unknownError, isBaseUnSubscribe)
                }
               
            })
        request.makeSelfReferenced()
    }
    ///获取卡片订阅状态
    func fetchRecordSubscribeState(token: String,
                                 tableID: String,
                                recordId: String,
                                completion: @escaping (BTRecordSubscribeStatus,BTRecordAutoSubStatus) -> Void) {
        
        var params: [String: Any] = [:]
        params["tableID"] = tableID
        params["recordIDs"] = [recordId]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getRecordSubscribeStatePath(token), params: params)
            .set(method: .POST)
            .set(needVerifyData: false)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .set(retryCount: 0)
            .start(result: { json, error in
                guard error == nil else {
                    DocsLogger.error("get record subscribe state error", error: error)
                    completion(.unknown, .editAutoSubDefault)
                    return
                }
                guard let dict = json?.dictionaryObject else {
                    DocsLogger.btError("get record subscribe state error because of json")
                    completion(.unknown, .editAutoSubDefault)
                    return
                }
                guard let code = dict["code"] as? Int, let dataMap = dict["data"] as? [String: Any], code == 0 else {
                    DocsLogger.btError("get record subscribe state error because of failing to parse code")
                    completion(.unknown, .editAutoSubDefault)
                    return
                }
                //订阅状态
                var status: BTRecordSubscribeStatus = .unknown
                if let statusMap = dataMap["status"] as? [String: Any], let statusValue = statusMap[recordId] as? Int, let s = BTRecordSubscribeStatus.init(rawValue: statusValue) {
                    status = s
                }
                //编辑是否支持自动订阅
                var autoStatus: BTRecordAutoSubStatus = .editAutoSubDefault
                if let autoStatusMap = dataMap["autoSubStatusMap"] as? [String: Any],  let autoStatusValue = autoStatusMap [recordId] as? Int, let autoS = BTRecordAutoSubStatus(rawValue: autoStatusValue)  {
                    autoStatus = autoS
                }
                completion(status, autoStatus)
        
            })
        request.makeSelfReferenced()
    }
    // 编辑是否触发自动订阅
    func updateAutoSubscribeStatus(token: String,
                                 behaviour: BTRecordAutoSubscribeAlertBehavior,
                                   completion: ((Bool) -> Void)? = nil) {
        var params: [String: Any] = [:]
        params["status"] = behaviour.rawValue
        let timeOut: Double = 20.0
        let request =  DocsRequest<JSON>(path: OpenAPI.APIPath.getRecordAutoSubscribeEditPath(token), params: params)
            .set(method: .POST)
            .set(needVerifyData: false)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: timeOut)
            .set(retryCount: 0)
            .start(result: { json, error in
                guard error == nil else {
                    DocsLogger.error("autoSubscribe behaviour error", error: error)
                    return
                }
                guard let dict = json?.dictionaryObject else {
                    DocsLogger.btError("autoSubscribe behaviour error because of json")
                    return
                }
                guard let codeValue = dict["code"] as? Int else {
                    DocsLogger.btError("autoSubscribe behaviour error because of failing to parse code")
                    return
                }
                let editNoNeedToSubscribe = codeValue == 0 && behaviour == .confirmNoAutoSubscribe
                completion?(editNoNeedToSubscribe)
            })
        request.makeSelfReferenced()
    }
}
