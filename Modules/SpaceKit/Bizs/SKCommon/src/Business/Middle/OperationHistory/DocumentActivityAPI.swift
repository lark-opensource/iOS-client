//
//  DocumentActivityAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/9.
//

import Foundation
import RxSwift
import SKFoundation
import SwiftyJSON
import UniverseDesignToast
import EENavigator
import LarkUIKit
import SpaceInterface
import SKInfra

private extension DocumentActivity {
    var data: [String: Any] {
        [
            "event_uuid": uuid,
            "operate_scene": scene,
            "operate_time": time,
            "operate_name": operationName
        ]
    }
}

enum DocumentActivityPermission: Int {
    /// 可访问操作记录
    case accessible = 0
    /// 用户无权限访问操作记录
    case noPermission = 4
    /// 租户无权限（需要管理员打开该计费功能）
    case featureDisabled = 10
}

public enum DocumentActivityAPI {
    enum APIError: Error {
        case parseJSONFailed
        case unknown(code: Int)
    }

    static func report(token: String, type: Int, activities: [DocumentActivity]) -> Single<[String]> {
        let validRecords = activities.filter { record in
            record.objID == token && record.objType == type
        }
        if validRecords.isEmpty {
            spaceAssertionFailure()
            return .just([])
        }
        let params: [String: Any] = [
            "token": token,
            "obj_type": type,
            "records": validRecords.map(\.data)
        ]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.reportOperation, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxResponse().map { json, error in
            guard let json = json,
                  let code = json["code"].int else {
                      throw (error ?? APIError.parseJSONFailed)
                  }
            if shouldDeleteLocalRecord(code: code) {
                return validRecords.map(\.uuid)
            } else {
                throw error ?? APIError.unknown(code: code)
            }
        }
    }

    private static func shouldDeleteLocalRecord(code: Int) -> Bool {
        // 成功、文档被删除、文档不存在，需要删本地记录
        [0, 3, 1002].contains(code)
    }

    private static func fetchSuiteType() -> Single<SuiteType> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getBusinessInfo, params: nil)
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let value = json?["data"]["suite_type"].int else {
                throw APIError.parseJSONFailed
            }
            guard let suiteType = SuiteType(rawValue: value) else {
                DocsLogger.error("document activity API found unknown suite type")
                throw APIError.unknown(code: value)
            }
            return suiteType
        }
    }

    private static func checkHavePermission(objToken: String, objType: DocsType) -> Single<Bool> {
        return Single.create { single in
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.fetchUserPermissions(token: objToken, type: objType.rawValue) { info, error in
                if let error = error {
                    single(.error(error))
                    return
                }
                guard let mask = info?.mask else {
                    single(.error(APIError.parseJSONFailed))
                    return
                }
                let havePermission = mask.canManageMeta() || mask.canSinglePageManageMeta()
                single(.success(havePermission))
            }
            // 没法取消权限请求
            return Disposables.create()
        }
    }
    
    private static func getOperateDetail(objToken: String, objType: DocsType) -> Single<DocumentActivityPermission> {
        let params: [String: Any] = [
            "obj_type": objType.rawValue,
            "token": objToken,
            "operate_scene": 0,
            "page_size": 1
        ]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getOperateDetail, params: params)
            .set(method: .GET)
        return request.rxResponse().map({ (json, error) in
            guard let code = json?["code"].int else {
                throw APIError.parseJSONFailed
            }
            guard let permission = DocumentActivityPermission(rawValue: code) else {
                DocsLogger.error("document activity API found unknown document activity permission code")
                throw APIError.unknown(code: code)
            }
            return permission
        })
    }

    public static func open(objToken: String, objType: DocsType, from: UIViewController) -> Disposable {
        open(objToken: objToken, objType: objType, from: from) { [weak from] controller in
            guard let from = from else { return }
            Navigator.shared.present(controller, from: from)
        }
    }

    public static func open(objToken: String, objType: DocsType, from: UIViewController, presenter: @escaping (UIViewController) -> Void) -> Disposable {
        UDToast.showDefaultLoading(on: from.view.window ?? from.view, disableUserInteraction: false)
        let suiteTypeRequest = fetchSuiteType()
        let permissionRequest = getOperateDetail(objToken: objToken, objType: objType)
        let fromSupportOrientations = from.supportedInterfaceOrientations ?? .portrait
        return Single.zip(suiteTypeRequest, permissionRequest)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak from] suiteType, permission in
                if let from = from {
                    UDToast.removeToast(on: from.view.window ?? from.view)
                }
                switch permission {
                case .accessible:
                    let vc = DocsOpHistoryViewController(token: objToken, type: objType)
                    vc.supportOrientations = fromSupportOrientations
                    let nav = LkNavigationController(rootViewController: vc)
                    presenter(nav)
                case .noPermission:
                    let controller = DocumentActivityNoPermissionController()
                    controller.supportOrientations = fromSupportOrientations
                    presenter(controller)
                case .featureDisabled:
                    let controller = DocumentActivityUpgradeController(suiteType: suiteType.rawValue)
                    presenter(controller)
                }
            } onError: { [weak from] error in
                if let from = from {
                    UDToast.removeToast(on: from.view.window ?? from.view)
                }
                DocsLogger.error("check suite type failed when open document activity", error: error)
                let vc = DocsOpHistoryViewController(token: objToken, type: objType)
                vc.supportOrientations = fromSupportOrientations
                let nav = LkNavigationController(rootViewController: vc)
                presenter(nav)
            }
    }
}

private extension SuiteType {
    var documentActivityFeatureEnabled: Bool {
        switch self {
        case .legacyFree, .standard, .certStandard:
            return false
        case .legacyEnterprise, .business, .enterprise:
            return true
        }
    }
}
