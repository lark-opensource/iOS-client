//
//  PermissionObserver.swift
//  SpaceKit
//
//  Created by zhongtianren on 2019/4/12.
//

import UIKit
import SwiftyJSON
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface
import SKInfra

public protocol PermissionObserverDelegate: AnyObject {
    func didReceivePermissionData(response: PermissionResponseModel)
}

public final class PermissionObserver {
    private let tagPrefix = StablePushPrefix.permission.rawValue
    private let serviceType = StablePushServiceType.permission.rawValue

    public enum PermissionObserveKey {
        case userPermissions
        case publicPermissions
        case all
    }

    let fileToken: String
    let shareToken: String
    let fileType: ShareDocsType

    private weak var delegate: PermissionObserverDelegate?

    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!

    private(set) var userPermissions: UserPermissionAbility?
    private(set) var publicPermissionMeta: PublicPermissionMeta?
    private(set) var permissionStatusCode: PermissionStatusCode?

    var linkPassword: Driver<String?> {
        return linkPasswordSubject.asDriver(onErrorJustReturn: nil)
    }

    private(set) var linkPasswordSubject: BehaviorSubject<String?>

    var observeKey: PermissionObserveKey?

    private var userRequest: DocsRequest<JSON>?
    private var publicRequest: DocsRequest<PublicPermissionMeta>?
    private var passwordRequest: DocsRequest<JSON>?

    // 信箱推送服务
    private let newPermissionPush: StablePushManager
    // Wiki、群变更等权限推送服务
    private let groupChangedPush: CommonPushDataManager

    public init(fileToken: String, shareToken: String = "", type: Int) {
        self.fileToken = fileToken
        self.shareToken = shareToken

        self.fileType = ShareDocsType(rawValue: type)
        if case .unknown = self.fileType {
            spaceAssertionFailure("unknown type \(type)")
        }

        let pushInfo = SKPushInfo(tag: tagPrefix + fileToken,
                                  resourceType: StablePushPrefix.permission.resourceType(),
                                  routeKey: fileToken,
                                  routeType: SKPushRouteType.token)
        self.newPermissionPush = StablePushManager(pushInfo: pushInfo)
        self.groupChangedPush = CommonPushDataManager(fileToken: fileToken, type: DocsType(rawValue: type), operation: .groupChange)
        self.linkPasswordSubject = BehaviorSubject<String?>(value: publicPermissionMeta?.linkPassword)
        self.groupChangedPush.delegate = self
    }

    deinit {
        DocsLogger.info("PermissionObserver - deinit, file: \(DocsTracker.encrypt(id: fileToken))")
        newPermissionPush.unRegister()
    }
}

// public api
extension PermissionObserver {
    /// 注销监听
    public func unRegister() {
        DocsLogger.info("PermissionObserver - unRegister, file: \(DocsTracker.encrypt(id: fileToken))")
        groupChangedPush.unRegister()
        newPermissionPush.unRegister()
    }

    /// 监听权限变化
    public func addObserveForPermission(delegate: PermissionObserverDelegate, observeKey: PermissionObserveKey) {
        self.observeKey = observeKey
        self.delegate = delegate
        
        groupChangedPush.register()
        newPermissionPush.register(with: self)
        DocsLogger.info("PermissionObserver - register, file: \(DocsTracker.encrypt(id: fileToken))")
    }

    /// 获取用户权限
    public func fetchUserPermissions(complete: @escaping (UserPermissionRequestInfo?, Error?) -> Void) {
        permissionManager.fetchUserPermissions(token: fileToken, type: fileType.rawValue) { (permissionInfo, error) in
            complete(permissionInfo, error)
        }
    }

    /// 获取form、文档公共权限
    public func fetchPublicPermissions(complete: @escaping (PublicPermissionMeta?, Error?) -> Void) {
        if fileType == .form {
            permissionManager.fetchFormPublicPermissions(baseToken: fileToken, shareToken: shareToken) { (permission, error) in
                guard let permission = permission else { complete(nil, error); return }
                complete(permission, error)
            }
        } else if fileType.isBitableSubType {
            permissionManager.fetchBitablePublicPermissions(baseToken: fileToken, shareToken: shareToken, complete: complete)
        } else {
            permissionManager.fetchPublicPermissions(token: fileToken, type: fileType.rawValue) { (permission, error) in
                guard let permission = permission else { complete(nil, error); return }
                complete(permission, error)
            }
        }
    }


    /// 同时获取公共权限和用户权限
    public func fetchAllPermission(completion: ((PermissionResponseModel) -> Void)?) {
        var requestError: Error?
        let permissionRequestGroup = DispatchGroup()
        permissionRequestGroup.enter()
        fetchUserPermissions { [weak self] (permissionInfo, error) in
            guard let `self` = self else { return }
            defer {
                permissionRequestGroup.leave()
            }
            if let error = error {
                requestError = error
            }
            self.userPermissions = permissionInfo?.mask
            self.permissionStatusCode = permissionInfo?.code
        }
        permissionRequestGroup.enter()
        fetchPublicPermissions {[weak self] (response, error) in
            guard let `self` = self else { return }
            defer {
                permissionRequestGroup.leave()
            }
            if let error = error {
                /// 优先处理userPermissions的error
                if requestError == nil {
                    requestError = error
                }
            }
            self.publicPermissionMeta = response
        }
        permissionRequestGroup.notify(queue: DispatchQueue.main) {
            let permissionResponseModel = PermissionResponseModel(userPermissions: self.userPermissions,
                                                                  publicPermissionMeta: self.publicPermissionMeta,
                                                                  permissionStatusCode: self.permissionStatusCode,
                                                                  error: requestError)
            completion?(permissionResponseModel)
        }
    }

}

extension PermissionObserver: StablePushManagerDelegate {
    public func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        DocsLogger.info("PermissionObserver - didReceivedRNData")
        handlePermissionChange()
    }

    public var pushFileToken: String? {
        return fileToken
    }

    public var pushFileType: Int? {
        return fileType.rawValue
    }
}

extension PermissionObserver {

    func handlePermissionChange() {
        guard let observeKey = observeKey else {
            spaceAssertionFailure("missing observe key")
            return
        }

        switch observeKey {
        case .userPermissions:
            fetchUserPermissions { [weak self] (permissionInfo, error) in
                self?.userPermissions = permissionInfo?.mask
                let responseModel = PermissionResponseModel(userPermissions: permissionInfo?.mask,
                                                            error: error)
                self?.delegate?.didReceivePermissionData(response: responseModel)
            }
        case .publicPermissions:
            fetchPublicPermissions { [weak self] (publicPermissionMeta, error) in
                self?.publicPermissionMeta = publicPermissionMeta
                let responseModel = PermissionResponseModel(publicPermissionMeta: publicPermissionMeta,
                                                            error: error)
                self?.delegate?.didReceivePermissionData(response: responseModel)
            }
        case .all:
            fetchAllPermission { [weak self] (response) in
                self?.publicPermissionMeta = response.publicPermissionMeta
                self?.userPermissions = response.userPermissions
                self?.delegate?.didReceivePermissionData(response: response)
            }
        }
    }
}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
public final class PermissionResponseModel {
    public var error: Error?
    public var userPermissions: UserPermissionAbility?
    public var publicPermissionMeta: PublicPermissionMeta?
    public var permissionStatusCode: PermissionStatusCode?
    public init(userPermissions: UserPermissionAbility? = nil,
         publicPermissionMeta: PublicPermissionMeta? = nil,
         permissionStatusCode: PermissionStatusCode? = nil,
         error: Error? = nil) {
        self.userPermissions = userPermissions
        self.publicPermissionMeta = publicPermissionMeta
        self.permissionStatusCode = permissionStatusCode
        self.error = error
    }
}

// password api
// docs: https://bytedance.feishu.cn/docs/NuM5adQ91RnB4BbOw7HwAe#
extension PermissionObserver {

    public func setupPassword(completionHandler: @escaping (Result<String, Error>, JSON?) -> Void) {
        passwordRequest?.cancel()
        let params: [String: Any] = ["token": fileToken, "type": fileType.rawValue]
        passwordRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordCreate, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { json, error in
                if let error = error {
                    DocsLogger.error("setupPassword failed!", extraInfo: nil, error: error, component: nil)
                    completionHandler(.failure(error), json)
                    return
                }
                guard let json = json,
                    let code = json["code"].int,
                    let data = json["data"].dictionaryObject else {
                        completionHandler(.failure(DocsNetworkError.invalidData), json)
                        DocsLogger.error("setupPassword invalidData!", extraInfo: nil, error: error, component: nil)
                        return
                }
                guard code == 0 else {
                    DocsLogger.error("setupPassword failed!", extraInfo: nil, error: error, component: nil)
                    completionHandler(.failure(PasswordSettingNetworkError.setupFailed), json)
                    return
                }
                guard let password = data["password"] as? String else {
                    completionHandler(.failure(PasswordSettingNetworkError.setupFailed), json)
                    DocsLogger.error("password is nil")
                    return
                }
                guard !password.isEmpty else {
                    completionHandler(.failure(PasswordSettingNetworkError.setupFailed), json)
                    DocsLogger.error("password is empty")
                    return
                }
                completionHandler(.success(password), json)
        })
    }

    public func deletePassword(completionHandler: @escaping (Result<Void, Error>, JSON?) -> Void) {
        passwordRequest?.cancel()
        let params: [String: Any] = ["token": fileToken, "type": fileType.rawValue]
        passwordRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordDelete, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { json, error in
                if let error = error {
                    completionHandler(.failure(error), json)
                    DocsLogger.error("deletePassword failed!", extraInfo: nil, error: error, component: nil)
                    return
                }
                guard let json = json,
                    let code = json["code"].int else {
                        completionHandler(.failure(DocsNetworkError.invalidData), json)
                        DocsLogger.error("setupPassword invalidData!", extraInfo: nil, error: error, component: nil)
                        return
                }
                guard code == 0 else {
                    DocsLogger.error("deletePassword failed!", extraInfo: nil, error: error, component: nil)
                    completionHandler(.failure(PasswordSettingNetworkError.deleteFailed), json)
                    return
                }
                completionHandler(.success(()), json)
        })
    }

    public func refreshPassword(completionHandler: @escaping (Result<String, Error>, JSON?) -> Void) {
        passwordRequest?.cancel()
        let params: [String: Any] = ["token": fileToken, "type": fileType.rawValue]
        passwordRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordRefresh, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { json, error in
                if let error = error {
                    DocsLogger.error("refreshPassword failed!", extraInfo: nil, error: error, component: nil)
                    guard (error as? URLError)?.errorCode != NSURLErrorCancelled else { return }
                    completionHandler(.failure(error), json)
                    return
                }
                guard let json = json,
                    let code = json["code"].int,
                    let data = json["data"].dictionaryObject else {
                        completionHandler(.failure(DocsNetworkError.invalidData), json)
                        DocsLogger.error("refreshPassword invalidData!", extraInfo: nil, error: error, component: nil)
                        return
                }
                guard code == 0 else {
                    DocsLogger.error("refreshPassword failed!", extraInfo: nil, error: error, component: nil)
                    completionHandler(.failure(PasswordSettingNetworkError.refreshFailed), json)
                    return
                }
                guard let password = data["password"] as? String else {
                    completionHandler(.failure(PasswordSettingNetworkError.refreshFailed), json)
                    DocsLogger.error("password is nil")
                    return
                }
                guard !password.isEmpty else {
                    completionHandler(.failure(PasswordSettingNetworkError.refreshFailed), json)
                    DocsLogger.error("password is empty")
                    return
                }
                completionHandler(.success(password), json)
        })
    }
}

// Wiki变更、群变更
extension PermissionObserver: CommonPushDataDelegate {

    public func didReceiveData(response: [String: Any]) {
        DocsLogger.info("已经收到了Wiki变更、群变更推送, 需要更新本地权限")
        self.fetchAllPermission { (model) in
            self.delegate?.didReceivePermissionData(response: model)
        }
    }
}
