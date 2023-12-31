//
//  MockPermissionSDK.swift
//  SKCommon-Unit-Tests
//
//  Created by Weston Wu on 2023/5/15.
//

import Foundation
import SpaceInterface
import RxSwift

enum MockError: Error {
    case notImplement
    case expectedError
}

extension PermissionResponse {
    static var pass: PermissionResponse { .allow(traceID: "") { _, _ in } }
}

class MockPermissionSDK: PermissionSDK {
    func driveSDKPermissionService(domain: DriveSDKPermissionDomain, fileID: String, bizDomain: PermissionRequest.BizDomain) -> UserPermissionService {
        MockUserPermissionService()
    }

    func driveSDKCustomUserPermissionService<UserPermissionModel>(permissionAPI: any UserPermissionAPI<UserPermissionModel>,
                                                                  validatorType: any UserPermissionValidator<UserPermissionModel>.Type,
                                                                  tokenForDLP: String?,
                                                                  bizDomain: PermissionRequest.BizDomain,
                                                                  sessionID: String) -> UserPermissionService {
        MockUserPermissionService()
    }


    var response = PermissionResponse.pass

    func validate(request: PermissionRequest) -> PermissionResponse {
        response
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
        completion(response)
    }

    func userPermissionService(for entity: UserPermissionEntity, withPush: Bool, extraInfo: PermissionExtraInfo?) -> UserPermissionService {
        MockUserPermissionService()
    }

    func getExemptRequest(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene, extraInfo: PermissionExtraInfo) -> PermissionRequest {
        PermissionRequest(entity: entity, operation: .upload, bizDomain: .ccm)
    }

    func canHandle(error: Error, context: SpaceInterface.PermissionCommonErrorContext) -> PermissionResponse.Behavior? {
        nil
    }
}

class MockUserPermissionService: UserPermissionService {
    var defaultBizDomain: PermissionRequest.BizDomain = .ccm

    func notifyResourceWillAppear() {

    }

    func notifyResourceDidDisappear() {

    }

    var hasPermission: Bool = false

    var containerResponse: PermissionContainerResponse?

    func setUserPermission(data: Data) throws -> UserPermissionResponse {
        throw MockError.notImplement
    }

    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse {
        throw MockError.notImplement
    }

    var sessionID: String = "MOCK_SESSION_ID"

    var asyncExemptResponse = PermissionResponse.pass
    func asyncValidate(exemptScene: PermissionExemptScene, completion: @escaping (PermissionResponse) -> Void) {
        completion(asyncExemptResponse)
    }

    var asyncResponse = PermissionResponse.pass
    func asyncValidate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain, completion: @escaping (PermissionResponse) -> Void) {
        completion(asyncResponse)
    }

    var syncExemptResponse = PermissionResponse.pass
    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse {
        syncExemptResponse
    }

    var syncResponse = PermissionResponse.pass
    func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain) -> PermissionResponse {
        syncResponse
    }

    var ready: Bool = true

    var onPermissionUpdated: Observable<UserPermissionResponse> = .empty()

    var offlinePermission: Observable<UserPermissionResponse> = .empty()

    var permissionResponse: UserPermissionResponse?

    var updateResponse = UserPermissionResponse.success
    func updateUserPermission() -> Single<UserPermissionResponse> {
        .just(updateResponse)
    }

    var tenantID: String?
    func update(tenantID: String) {
        self.tenantID = tenantID
    }
}
