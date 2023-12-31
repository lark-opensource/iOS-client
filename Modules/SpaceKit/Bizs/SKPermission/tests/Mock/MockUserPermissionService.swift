//
//  MockUserPermissionAPI.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/20.
//

import Foundation
@testable import SKPermission
import SpaceInterface
import RxSwift

enum MockError: Error, Equatable {
    case expectedFailure
    case notImplement
}

private extension PermissionResponse {
    static func pass(traceID: String) -> PermissionResponse {
        .allow(traceID: traceID, behavior: { _, _ in })
    }
}

class MockUserPermissionAPI: UserPermissionAPI {

    var offlineUserPermission: String? = nil

    var parsePermissionResult: Result<PermissionResult, Error> = .failure(MockError.notImplement)
    func parseUserPermission(data: Data) throws -> PermissionResult {
        try parsePermissionResult.get()
    }

    var containerResponse: PermissionContainerResponse = .noPermission(container: nil,
                                                                       statusCode: .normal,
                                                                       applyUserInfo: nil)
    func container(for permissionResult: PermissionResult) -> PermissionContainerResponse {
        containerResponse
    }

    typealias UserPermissionModel = String

    var entity: PermissionRequest.Entity = .ccm(token: "MOCK_TOKEN", type: .docX)
    var result: Result<PermissionResult, Error> = .success(PermissionResult.success(permission: "MOCK_PERMISSION"))

    func updateUserPermission() -> Single<PermissionResult> {
        switch result {
        case let .success(permissionResult):
            return .just(permissionResult)
        case let .failure(error):
            return .error(error)
        }
    }
}

protocol MockResponseProviderType {
    static func getResponse(model: String?,
                            request: PermissionRequest,
                            isAsync: Bool) -> PermissionValidatorResponse
}

enum MockAllowResponseProvider: MockResponseProviderType {
    static func getResponse(model: String?,
                            request: PermissionRequest,
                            isAsync: Bool) -> PermissionValidatorResponse {
        .pass
    }
}

class MockUserPermissionValidator<Provider: MockResponseProviderType>: UserPermissionValidator {
    var name: String { "MockUserPermissionValidator" }

    typealias UserPermissionModel = String

    let model: String?
    let isFromCache: Bool

    required init(model: String?, isFromCache: Bool) {
        self.model = model
        self.isFromCache = isFromCache
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Provider.getResponse(model: model,
                             request: request,
                             isAsync: false)
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        let response = Provider.getResponse(model: model, request: request, isAsync: true)
        completion(response)
    }
}

class MockPermissionSDK: PermissionSDKInterface {

    var response = PermissionResponse.pass(traceID: "MOCK_TRACE_ID")

    func validate(request: PermissionRequest) -> PermissionResponse {
        response
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
        completion(response)
    }

    func userPermissionService(for entity: UserPermissionEntity, withPush: Bool, extraInfo: PermissionExtraInfo?) -> UserPermissionService {
        UserPermissionServiceImpl(permissionAPI: MockUserPermissionAPI(),
                                  validatorType: MockUserPermissionValidator<MockAllowResponseProvider>.self,
                                  permissionSDK: self,
                                  sessionID: "MOCK_SESSION_ID")
    }

    func driveSDKPermissionService(domain: DriveSDKPermissionDomain, fileID: String, bizDomain: PermissionRequest.BizDomain) -> UserPermissionService {
        UserPermissionServiceImpl(permissionAPI: MockUserPermissionAPI(),
                                  validatorType: MockUserPermissionValidator<MockAllowResponseProvider>.self,
                                  permissionSDK: self,
                                  defaultBizDomain: bizDomain,
                                  sessionID: "MOCK_SESSION_ID")
    }

    func driveSDKCustomUserPermissionService<UserPermissionModel>(permissionAPI: any UserPermissionAPI<UserPermissionModel>,
                                                                  validatorType: any UserPermissionValidator<UserPermissionModel>.Type,
                                                                  tokenForDLP: String?,
                                                                  bizDomain: PermissionRequest.BizDomain, sessionID: String) -> UserPermissionService {
        UserPermissionServiceImpl(permissionAPI: permissionAPI,
                                  validatorType: validatorType,
                                  permissionSDK: self,
                                  sessionID: "MOCK_SESSION_ID")
    }

    func getExemptRequest(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene, extraInfo: PermissionExtraInfo) -> PermissionRequest {
        PermissionRequest(entity: entity, exemptScene: exemptScene, extraInfo: extraInfo)
    }

    func canHandle(error: Error, context: PermissionCommonErrorContext) -> PermissionResponse.Behavior? {
        nil
    }
}

class MockPermissionValidator: PermissionValidator {
    var name: String { "MockPermissionValidator" }
    var invoke = true
    var syncResponse = PermissionValidatorResponse.pass
    var asyncResponse = PermissionValidatorResponse.pass

    func shouldInvoke(rules: PermissionExemptRules) -> Bool { invoke }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse { syncResponse }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) { completion(asyncResponse) }
}

class MockUserPermissionService: UserPermissionService {
    var sessionID = "MOCK_SESSION_ID"
    var asyncExemptResponse = PermissionResponse.allow(traceID: "MOCK_TRACE_ID") { _, _ in }
    func asyncValidate(exemptScene: PermissionExemptScene, completion: @escaping (PermissionResponse) -> Void) {
        completion(asyncExemptResponse)
    }

    var asyncResponse = PermissionResponse.pass(traceID: "MOCK_TRACE_ID")
    func asyncValidate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain, completion: @escaping (PermissionResponse) -> Void) {
        completion(asyncResponse)
    }

    var syncExemptResponse = PermissionResponse.pass(traceID: "MOCK_TRACE_ID")
    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse {
        syncExemptResponse
    }

    var syncResponse = PermissionResponse.pass(traceID: "MOCK_TRACE_ID")
    func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain) -> PermissionResponse {
        syncResponse
    }

    var ready: Bool = true

    var hasPermission: Bool = true

    var containerResponse: PermissionContainerResponse?

    var setUserPermissionResult: Result<UserPermissionResponse, Error> = .failure(MockError.notImplement)
    func setUserPermission(data: Data) throws -> UserPermissionResponse {
        try setUserPermissionResult.get()
    }

    var parseContainerResult: Result<PermissionContainerResponse, Error> = .failure(MockError.notImplement)
    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse {
        try parseContainerResult.get()
    }

    var onPermissionUpdated: Observable<SpaceInterface.UserPermissionResponse> = .empty()

    var offlinePermission: Observable<SpaceInterface.UserPermissionResponse> = .empty()

    var permissionResponse: UserPermissionResponse?

    var updateResponse = UserPermissionResponse.success
    func updateUserPermission() -> Single<UserPermissionResponse> {
        .just(updateResponse)
    }

    var tenantID: String?
    func update(tenantID: String) {
        self.tenantID = tenantID
    }

    var defaultBizDomain: PermissionRequest.BizDomain = .ccm

    func notifyResourceWillAppear() {}

    func notifyResourceDidDisappear() {}
}
