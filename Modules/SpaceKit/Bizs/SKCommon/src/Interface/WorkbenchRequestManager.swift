//
//  WorkbenchRequestManager.swift
//  SpaceKit
//
//  Created by zengsenyuan on 2022/12/8.
//  


import SKFoundation
import SKResource
import SwiftyJSON
import SKInfra

public enum WorkbenchAddError: Int, Error {
    case addExceedLimit = 800004109 // 工作台-我的常用快捷方式超过阈值
    case addCommonBlockNotExist = 800004110 // 我的常用组件不存在，需要联系管理员添加
    
    public var toast: String {
        switch self {
        case .addExceedLimit: return BundleI18n.SKResource.Bitable_ShareToWorkplace_WorkplaceExceededLimit_Toast
        case .addCommonBlockNotExist: return BundleI18n.SKResource.Bitable_ShareToWorkplace_NoMyFavoritesYet_Toast
        }
    }
    
    var description: String {
        switch self {
        case .addExceedLimit:
            return "workbench add exceed limit code: \(self.rawValue)"
        case .addCommonBlockNotExist:
            return "workbench common block not exsist code: \(self.rawValue)"
        }
    }
}

enum WorkbenchError: Error {
    case dataParseError
    
    var description: String {
        switch self {
        case .dataParseError:
            return "workbench data parse error"
        }
    }
}

public struct WorkbenchAddAgrs: DictionaryConvertable {
    var token: String
    var uid: String
    var name: String
    var viewId: String?
    var tableId: String?
    
    public init(token: String,
                uid: String,
                name: String,
                viewId: String?,
                tableId: String?) {
        self.token = token
        self.uid = uid
        self.name = name
        self.viewId = viewId
        self.tableId = tableId
    }
}

public class WorkbenchRequestManager {
    
    var statusRequest: DocsRequest<JSON>?
    var addRequest: DocsRequest<JSON>?
    var removeRequest: DocsRequest<JSON>?
    var isShowOnboardingRequest: DocsRequest<JSON>?
    
    public static let shared = WorkbenchRequestManager()
    
    public func requestWorkbenchStatus(token: String, userId: String, completion: ((Result<Bool, Error>) -> Void)?) {
        let params = [
            "token": token,
            "uid": userId
        ]
        statusRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getWorkbenchStatus(token), params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { (response, error) in
                if let error = error {
                    DocsLogger.error("workbench requestWorkbenchStatus error \(error)")
                    completion?(.failure(error))
                    return
                }
                guard let isAdded = response?["data"]["isAdded"].bool else {
                    completion?(.failure(WorkbenchError.dataParseError))
                    DocsLogger.error("workbench requestWorkbenchStatus dataParseError \(response)")
                    return
                }
                completion?(.success(isAdded))
            })
    }
    
    public func requestForAddToWorkbench(args: WorkbenchAddAgrs, completion: ((Result<Void, Error>) -> Void)?) {
        addRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.workbenchAdd(args.token), params: args.dictionary ?? [:])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (response, error) in
                if let error = error {
                    DocsLogger.error("workbench requestForAddToWorkbench error \(error)")
                    if let code = response?["code"].int, let addError = WorkbenchAddError(rawValue: code) {
                        completion?(.failure(addError))
                    } else {
                        completion?(.failure(error))
                    }
                    return
                }
                completion?(.success(()))
            })
    }
    
    public func requestForRemoveFormWorkbench(token: String, userId: String, completion: ((Result<Void, Error>) -> Void)?) {
        let params = [
            "token": token,
            "uid": userId
        ]
        removeRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.workbenchRemove(token), params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (response, error) in
                if let error = error {
                    DocsLogger.error("workbench requestForRemoveFormWorkbench error \(error)")
                    completion?(.failure(error))
                    return
                }
                completion?(.success(()))
        })
    }
    
    public func shouldShowOnboarding(token: String, userId: String, completion: ((Result<Bool, Error>) -> Void)?) {
        let params = [
            "token": token,
            "uid": userId
        ]
        isShowOnboardingRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.shouldShowWorkbenchOnboarding(token), params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { (response, error) in
                if let error = error {
                    DocsLogger.error("workbench requestWorkbenchStatus error \(error)")
                    completion?(.failure(error))
                    return
                }
                guard let isShow = response?["data"]["isShow"].bool else {
                    completion?(.failure(WorkbenchError.dataParseError))
                    DocsLogger.error("workbench requestWorkbenchStatus dataParseError \(response)")
                    return
                }
                completion?(.success(isShow))
            })
    }
    
    public func clearAllRequest() {
        statusRequest?.cancel()
        addRequest?.cancel()
        removeRequest?.cancel()
        isShowOnboardingRequest?.cancel()
        statusRequest = nil
        addRequest = nil
        removeRequest = nil
        isShowOnboardingRequest = nil
    }
}
