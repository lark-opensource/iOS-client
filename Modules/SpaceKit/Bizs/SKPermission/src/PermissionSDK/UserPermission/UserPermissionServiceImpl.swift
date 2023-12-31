//
//  UserPermissionServiceImpl.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import RxRelay

extension UserPermissionValidator {
    func shouldInvoke(rules: PermissionExemptRules) -> Bool {
        rules.shouldCheckUserPermission
    }
}

/// 提供 Space 1.0、Space 2.0 文档类型的用户权限能力
class UserPermissionServiceImpl<UserPermissionModel>: UserPermissionService {
    /// 用户权限已请求到
    var ready: Bool { permissionRelay.value != nil }
    /// 用户权限已请求到，且有权限
    var hasPermission: Bool { permissionRelay.value?.userPermission != nil }

    private typealias UserPermissionResult = UserPermissionAPIResult<UserPermissionModel>
    // 注意在往 permissionRelay 里塞东西后，需要在合适的时机也往 pushPermissionUpdateInput 塞个东西
    private let permissionRelay = BehaviorRelay<UserPermissionResult?>(value: nil)
    // 为解决 onPermissionUpdated 早于 updatePermission onSuccess 的问题, 额外用一个信号控制延后一下 update 事件的发送时机
    private let pushPermissionUpdateInput = BehaviorRelay<Void>(value: ())
    /// 会在主线程回调，请注意是否有耗时操作阻塞主线程
    var onPermissionUpdated: Observable<UserPermissionResponse> {
        Observable.zip(pushPermissionUpdateInput, permissionRelay) // 两个都是 BehaviorRelay，保证监听时收到一次重放
            .compactMap { $0.1?.userPermissionResponse } // 先 zip 再 compactMap, 避免 relay 初始值 nil 导致两个信号错位了
            .observeOn(MainScheduler.instance)
    }
    var permissionResponse: UserPermissionResponse? {
        permissionRelay.value?.userPermissionResponse
    }

    private let permissionCacheRelay = BehaviorRelay<UserPermissionModel?>(value: nil)
    var offlinePermission: Observable<UserPermissionResponse> {
        return permissionCacheRelay.filter{ $0 != nil }.compactMap { _ in .success }
    }

    var containerResponse: PermissionContainerResponse? {
        guard let permission = permissionRelay.value else { return nil }
        return permissionAPI.container(for: permission)
    }

    private let permissionAPI: any UserPermissionAPI<UserPermissionModel>
    private let validatorType: any UserPermissionValidator<UserPermissionModel>.Type
    private let permissionSDK: PermissionSDKInterface
    private let disposeBag = DisposeBag()
    private var extraInfo: PermissionExtraInfo = .default
    /// 针对 CCM 大部分场景，省略 bizDomain
    let defaultBizDomain: PermissionRequest.BizDomain

    let sessionID: String

    var dlpContext: DLPSceneContext? {
        didSet {
            monitorDLPUpdated()
        }
    }

    // 打包使用的 Xcode 14.1 (Swift 5.7.1) 存在 bug，导致 any/some 语法在 iOS 15及以下版本会 crash
    // 在打包机升级到 Xcode 14.2 之前，暂时通过禁用优化绕过此问题
    // https://github.com/apple/swift/issues/61403
    @_optimize(none)
    init(permissionAPI: any UserPermissionAPI<UserPermissionModel>,
         validatorType: any UserPermissionValidator<UserPermissionModel>.Type,
         permissionSDK: PermissionSDKInterface,
         defaultBizDomain: PermissionRequest.BizDomain = .ccm,
         sessionID: String,
         extraInfo: PermissionExtraInfo? = nil) {
        self.permissionAPI = permissionAPI
        self.validatorType = validatorType
        self.permissionSDK = permissionSDK
        self.defaultBizDomain = defaultBizDomain
        self.sessionID = sessionID
        self.extraInfo = extraInfo ?? .default
    }

    func updateUserPermission() -> Single<UserPermissionResponse> {
        let sessionID = self.sessionID
        Logger.info("UserPermission - start update user permission", extraInfo: [
            "sessionID": sessionID
        ])
        return permissionAPI.updateUserPermission()
            .do(onSuccess: { [weak self] result in
                Logger.info("UserPermission - update user permision success", extraInfo: [
                    "result": result.desensitizeDescription,
                    "sessionID": sessionID
                ])
                self?.permissionRelay.accept(result)
            }, afterSuccess: { [weak self] _ in
                // 延后到业务方处理完 onSuccess 再推送
                self?.pushPermissionUpdateInput.accept(())
            }, onError: { [weak self] error in
                Logger.error("UserPermission - update user permission failed", error: error)
                let noNetCode = -1009
                if (error as NSError).code == noNetCode && UserScopeNoChangeFG.PLF.offlineScreenshotEnable {
                    if let permission = self?.permissionAPI.offlineUserPermission {
                        self?.permissionCacheRelay.accept(permission)
                    }

                }
            })
            .map(\.userPermissionResponse)
    }

    @discardableResult
    func setUserPermission(data: Data) throws -> UserPermissionResponse {
        let sessionID = self.sessionID
        Logger.info("UserPermission - start manual set user permission", extraInfo: [
            "sessionID": sessionID
        ])
        do {
            let result = try permissionAPI.parseUserPermission(data: data)
            Logger.info("UserPermission - manual parse user permision success", extraInfo: [
                "result": result.desensitizeDescription,
                "sessionID": sessionID
            ])
            permissionRelay.accept(result)
            DispatchQueue.main.async { [weak self] in
                self?.pushPermissionUpdateInput.accept(())
            }
            return result.userPermissionResponse
        } catch {
            Logger.error("UserPermission - manual parse user permission failed", error: error)
            throw error
        }
    }

    /// 解析已获取到的数据为用户权限模型容器
    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse {
        let sessionID = self.sessionID
        Logger.info("UserPermission - start parse user permission container", extraInfo: [
            "sessionID": sessionID
        ])
        do {
            let result = try permissionAPI.parseUserPermission(data: data)
            Logger.info("UserPermission - manual parse user permision container success", extraInfo: [
                "result": result.desensitizeDescription,
                "sessionID": sessionID
            ])
            return permissionAPI.container(for: result)
        } catch {
            Logger.error("UserPermission - manual parse user permission container failed", error: error)
            throw error
        }
    }

    func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain) -> PermissionResponse {
        let request = PermissionRequest(entity: permissionAPI.entity,
                                        operation: operation,
                                        bizDomain: bizDomain,
                                        extraInfo: extraInfo)
        return validate(request: request)
    }

    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse {
        let request = permissionSDK.getExemptRequest(entity: permissionAPI.entity,
                                                     exemptScene: exemptScene,
                                                     extraInfo: extraInfo)
        return validate(request: request)
    }

    private func validate(request: PermissionRequest) -> PermissionResponse {
        Logger.info("UserPermission - start validate request",
                    extraInfo: [
                        "sessionID": sessionID,
                        "operation": request.operation,
                    ],
                    traceID: request.traceID)
        let sdkResponse = permissionSDK.validate(request: request)
        guard sdkResponse.allow else {
            Logger.info("UserPermission - skip user permission check, request forbidden by SDK",
                        extraInfo: ["sessionID": sessionID],
                        traceID: request.traceID)
            // SDK 拦截了，不需要再判断 UserPermission 了
            return sdkResponse
        }
        let model: UserPermissionModel?
        let isFromCache: Bool
        if !ready && UserScopeNoChangeFG.PLF.offlineScreenshotEnable {
            Logger.info("UserPermission - use permission cache",
                        extraInfo: [
                            "sessionID": sessionID,
                            "operation": request.operation,
                        ],
                        traceID: request.traceID)
            model = permissionCacheRelay.value
            isFromCache = true
        } else {
            model = permissionRelay.value?.userPermission
            isFromCache = false
        }
        let validator = validatorType.init(model: model, isFromCache: isFromCache)
        guard validator.shouldInvoke(rules: request.exemptRules) else {
            Logger.info("UserPermission - user permission check skipped, return allow response",
                        extraInfo: ["sessionID": sessionID],
                        traceID: request.traceID)
            return sdkResponse
        }
        let userPermissionResponse = validator.validate(request: request)
            .finalResponse(traceID: request.traceID)
        let response = PermissionResponse.merge(responses: [sdkResponse, userPermissionResponse], traceID: request.traceID)
        Logger.info("UserPermission - validate complete, final response isAllow: \(response.allow)",
                    extraInfo: [
                        "response": response.desensitizeDescription,
                        "sessionID": sessionID
                    ],
                    traceID: request.traceID)
        return response
    }

    func asyncValidate(operation: PermissionRequest.Operation,
                       bizDomain: PermissionRequest.BizDomain,
                       completion: @escaping (PermissionResponse) -> Void) {
        let request = PermissionRequest(entity: permissionAPI.entity,
                                        operation: operation,
                                        bizDomain: bizDomain,
                                        extraInfo: extraInfo)
        asyncValidate(request: request, completion: completion)
    }

    func asyncValidate(exemptScene: PermissionExemptScene,
                       completion: @escaping (PermissionResponse) -> Void) {
        let request = permissionSDK.getExemptRequest(entity: permissionAPI.entity,
                                                     exemptScene: exemptScene,
                                                     extraInfo: extraInfo)
        asyncValidate(request: request, completion: completion)
    }

    private func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
        let sessionID = self.sessionID
        Logger.info("UserPermission - start async validate request",
                    extraInfo: [
                        "sessionID": sessionID,
                        "operation": request.operation,
                    ],
                    traceID: request.traceID)
        permissionSDK.asyncValidate(request: request) { [weak self] response in
            guard response.allow else {
                Logger.info("UserPermission - skip user permission check, request forbidden by SDK",
                            extraInfo: ["sessionID": sessionID],
                            traceID: request.traceID)
                completion(response)
                return
            }
            guard let self else {
                Logger.warning("UserPermission - user permission service found nil during async validation, fallback return forbidden response",
                               extraInfo: ["sessionID": sessionID],
                               traceID: request.traceID)
                // 不能因为 self 没了而跳过 UserPermission 鉴权，要给一个兜底结果
                completion(UserPermissionUtils.defaultResponse(request: request).finalResponse(traceID: request.traceID))
                return
            }
            let validator = self.validatorType.init(model: self.permissionRelay.value?.userPermission, isFromCache: false)
            guard validator.shouldInvoke(rules: request.exemptRules) else {
                Logger.info("UserPermission - user permission check skipped, return allow response",
                            extraInfo: ["sessionID": sessionID],
                            traceID: request.traceID)
                completion(response)
                return
            }
            validator.asyncValidate(request: request) {
                let userPermissionResponse = $0.finalResponse(traceID: request.traceID)
                let finalResponse = PermissionResponse.merge(responses: [response, userPermissionResponse], traceID: request.traceID)
                Logger.info("UserPermission - async validate complete, final response isAllow: \(finalResponse.allow)",
                            extraInfo: [
                                "response": finalResponse.desensitizeDescription,
                                "sessionID": sessionID
                            ],
                            traceID: request.traceID)
                completion(finalResponse)
            }
        }
    }

    func update(tenantID: String) {
        Logger.info("UserPermision - updating extraInfo.entityTenantID",
                    extraInfo: ["sessionID": sessionID])
        extraInfo.entityTenantID = tenantID
        // TODO: 增加 ownerUserID
//        dlpContext?.update(ownerUserID: "", ownerTenantID: tenantID)
    }

    private func monitorDLPUpdated() {
        guard let dlpContext else { return }
        dlpContext.onDLPUpdated = { [weak self] in
            guard let self else { return }
            Logger.info("UserPermision - received DLP context update event",
                        extraInfo: ["sessionID": self.sessionID])
            // 这里重复触发 onPermissionUpdated 的当前值，让业务方按需更新相关权限判断
            self.permissionRelay.accept(self.permissionRelay.value)
            self.pushPermissionUpdateInput.accept(())
        }
    }

    /// 管控的资源可见时触发，对应 viewWillAppear
    func notifyResourceWillAppear() {
        dlpContext?.willAppear()
    }
    /// 管控的资源不可见时触发，对应 viewDidDisappear
    func notifyResourceDidDisappear() {
        dlpContext?.didDisappear()
    }
}

extension UserPermissionServiceImpl {
    func withPush() -> UserPermissionService {
        guard case let .ccm(token, type, _) = permissionAPI.entity else {
            spaceAssertionFailure("entity \(permissionAPI.entity.desensitizeDescription) not support push")
            Logger.error("UserPermission - entity: \(permissionAPI.entity) not support push",
                         extraInfo: ["sessionID": sessionID])
            return self
        }
        Logger.info("UserPermission - wrapping user permission service with push wrapper",
                    extraInfo: ["sessionID": sessionID])
        return UserPermissionServicePushWrapper(backing: self, objToken: token, objType: type)
    }
}
