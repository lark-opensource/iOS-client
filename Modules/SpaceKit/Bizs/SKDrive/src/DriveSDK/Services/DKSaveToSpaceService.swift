//
//  DKSaveToSpaceService.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/7/6.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra

private class RxStablePushManager: StablePushManagerDelegate {

    typealias PushData = (data: [String: Any], serviceType: String, tag: String)

    var pushFileToken: String?
    var pushFileType: Int?
    private let stablePushManager: StablePushManager
    let pushData = PublishSubject<PushData>()

    init(pushInfo: SKPushInfo, additionParams: [String: Any]? = nil) {
        stablePushManager = StablePushManager(pushInfo: pushInfo, additionParams: additionParams)
        stablePushManager.register(with: self)
    }

    func invalidate() {
        stablePushManager.unRegister()
    }

    func stablePushManager(_ manager: StablePushManagerProtocol, didReceivedData data: [String: Any], forServiceType type: String, andTag tag: String) {
        pushData.onNext((data, type, tag))
    }
}


enum DKSaveToSpaceStatus {
    case saved(token: String)
    case saving
    case deleted
    case crossRegionUnsupport
}

enum DKSaveToSpaceError: Error {
    case parseCodeFailed
    case unknownResultCode(code: Int)
    case missingFileToken
}

protocol DKSaveToSpaceService {
    func saveToSpace() -> Observable<DKSaveToSpaceStatus>
}

class DKSaveToSpacePushService: DKSaveToSpaceService {

    private enum ResultCode: Int {
        case saved = 0
        case saving = 90002101
        case deleted = 90002102
        // 90002103 已经替换为 900004511 或 900004510, 仅做兼容使用
        case crossRegionUnsupport = 90002103

        init?(code: Int) {
            if code == DocsNetworkError.Code.unavailableForCrossBrand.rawValue
                || code == DocsNetworkError.Code.unavailableForCrossTenantGeo.rawValue {
                self = .crossRegionUnsupport
            } else {
                self.init(rawValue: code)
            }
        }
    }

    private let appID: String
    private let fileID: String
    private let authExtra: String?

    private let tagPrefix = StablePushPrefix.sdkFile.rawValue
    private let pushTag: String
    private let pushManager: RxStablePushManager

    init(appID: String, fileID: String, authExtra: String?, userID: String) {
        self.appID = appID
        self.fileID = fileID
        self.authExtra = authExtra
        pushTag = tagPrefix + userID
        let pushInfo = SKPushInfo(tag: pushTag,
                                  resourceType: StablePushPrefix.sdkFile.resourceType(),
                                  routeKey: userID,
                                  routeType: SKPushRouteType.uid)
        pushManager = RxStablePushManager(pushInfo: pushInfo)
    }

    deinit {
        pushManager.invalidate()
    }

    func saveToSpace() -> Observable<DKSaveToSpaceStatus> {
        var params: [String: Any] = [
            "app_id": appID,
            "app_file_id": fileID,
            "size_checker": SettingConfig.sizeLimitEnable
        ]
        if let authExtra = authExtra {
            params["auth_extra"] = authExtra
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.driveSDKsaveToSpace, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().asObservable()
            .flatMap { [weak self] result -> Observable<DKSaveToSpaceStatus> in
                guard let self = self else { return .empty() }
                guard let json = result else {
                    return .error(DKSaveToSpaceError.parseCodeFailed)
                }
                guard let code = json["code"].int else {
                    return .error(DKSaveToSpaceError.parseCodeFailed)
                }
                guard let resultCode = ResultCode(code: code) else {
                    return .error(DKSaveToSpaceError.unknownResultCode(code: code))
                }
                switch resultCode {
                case .saving:
                    return self.registerPushService().startWith(.saving)
                case .saved:
                    guard let token = json["data"]["file_token"].string else {
                        return .error(DKSaveToSpaceError.missingFileToken)
                    }
                    return .just(.saved(token: token))
                case .deleted:
                    return .just(.deleted)
                case .crossRegionUnsupport:
                    return .just(.crossRegionUnsupport)
                }
            }
    }

    private func registerPushService() -> Observable<DKSaveToSpaceStatus> {
        return pushManager.pushData.compactMap { [weak self] (data, _, tag) -> DKSaveToSpaceStatus? in
            guard let self = self else { return nil }
            guard tag == self.pushTag else { return nil }
            guard let body = data["body"] as? [String: Any],
                let innerData = body["data"] as? String else {
                    DocsLogger.error("drive.sdk.saveToSpace --- failed to parse push data")
                    return nil
            }
            let json = JSON(parseJSON: innerData)
            guard let appID = json["app_id"].string,
                let fileID = json["app_file_id"].string,
                let operation = json["operation"].string else {
                    DocsLogger.error("drive.sdk.saveToSpace --- failed to parse json from push data")
                    return nil
            }
            guard appID == self.appID,
                fileID == self.fileID,
                operation == "SAVE_TO_DRIVE" else {
                    DocsLogger.error("drive.sdk.saveToSpace --- push data mismatch current task")
                    return nil
            }
            guard let fileToken = json["file_token"].string else {
                DocsLogger.error("drive.sdk.saveToSpace --- failed to retrive file token from push message")
                return nil
            }
            return .saved(token: fileToken)
        }
    }
}
