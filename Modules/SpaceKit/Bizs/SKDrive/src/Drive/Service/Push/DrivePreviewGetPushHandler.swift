//
//  DrivePreviewGetPushHandler.swift
//  SpaceKit
//
//  Created by liweiye on 2019/9/17.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa

/// 文档：https://bytedance.feishu.cn/space/doc/doccn0CZnrcuRD6el6L7ihIXpaa
class DrivePreviewGetPushService: FilePreviewPushService {
    private let tagPrefix = StablePushPrefix.previewGet.rawValue
    let fileToken: String
    private let pushManager: StablePushManager
    private let pushDataRelay = PublishRelay<DKFilePreviewPushData>()

    init(fileToken: String) {
        self.fileToken = fileToken
        let pushInfo = SKPushInfo(tag: tagPrefix + fileToken,
                                  resourceType: StablePushPrefix.previewGet.resourceType(),
                                  routeKey: fileToken,
                                  routeType: SKPushRouteType.token)
        pushManager = StablePushManager(pushInfo: pushInfo)
    }

    deinit {
        pushManager.unRegister()
        DocsLogger.debug("DrivePreviewGetPushHandler deinit")
    }
    
    func registPushService() -> Observable<DKFilePreviewPushData> {
        pushManager.register(with: self)
        return pushDataRelay.asObservable()
    }
    
    func unRegistPushService() {
        pushManager.unRegister()
    }
}

extension DrivePreviewGetPushService: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: data),
            let json = try? JSON(data: data),
            let newJsonString = json["body"]["data"].string else {
                DocsLogger.driveInfo("Drive.PreviewPush: Decode json failed")
                return
        }
        let newJson = JSON(parseJSON: newJsonString)
        guard let fileToken = newJson["file_token"].string,
            let dataVersion = newJson["data_version"].string,
            let previewType = newJson["body"]["preview_type"].int,
            let previewStatusRawValue = newJson["body"]["status"].int,
            let previewStatus = DriveFilePreview.PreviewStatus(rawValue: previewStatusRawValue) else {
                DocsLogger.driveInfo("Get fileToken and dataVersion failed")
                return
        }
        let newData = DKFilePreviewPushData(appID: "",
                                            fileID: fileToken,
                                            dataVersion: dataVersion,
                                            previewType: previewType,
                                            previewStatus: previewStatus)
        pushDataRelay.accept(newData)
    }
}
