//
//  DriveMockPermissionService.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/8/23.
//

import Foundation
import SpaceInterface
import RxSwift

extension PermissionResponse {
    static var pass: PermissionResponse { .allow(traceID: "") { _, _ in } }
}

class MockUserPermissionService: UserPermissionService {

    func notifyResourceWillAppear() {

    }

    func notifyResourceDidDisappear() {
        
    }


    enum MockError: Error {
        case notImplement
        case expectedError
    }

    var defaultBizDomain: PermissionRequest.BizDomain = .ccm

    var hasPermission: Bool { false }

    var containerResponse: PermissionContainerResponse? { nil }

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
}
