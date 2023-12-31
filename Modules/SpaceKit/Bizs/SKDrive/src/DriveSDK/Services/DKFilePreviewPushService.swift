//
//  DKFilePreviewPushService.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/18.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SKFoundation

// 推送技术文档：https://bytedance.feishu.cn/docs/doccnKsx2PHMm0mZhlBbyvup8ud#

struct DKFilePreviewPushData {
    let appID: String
    let fileID: String
    let dataVersion: String
    let previewType: Int
    let previewStatus: DriveFilePreview.PreviewStatus
}


protocol FilePreviewPushService {
    func registPushService() -> Observable<DKFilePreviewPushData>
    func unRegistPushService()
}

class DKFilePreviewPushService {
    private let tagPrefix = StablePushPrefix.previewGet.rawValue
    private let appID: String
    private let fileID: String
    private let pushManager: StablePushManager?
    private let pushDataRelay = PublishRelay<DKFilePreviewPushData>()
    
    init(appID: String, fileID: String) {
        self.appID = appID
        self.fileID = fileID
        let pushInfo = SKPushInfo(tag: tagPrefix + appID + "_" + fileID,
                                  resourceType: StablePushPrefix.previewGet.resourceType(),
                                  routeKey: fileID,
                                  routeType: SKPushRouteType.token)
        self.pushManager = StablePushManager(pushInfo: pushInfo)
    }
    
    deinit {
        self.pushManager?.unRegister()
    }
}

extension DKFilePreviewPushService: FilePreviewPushService {
    func registPushService() -> Observable<DKFilePreviewPushData> {
        pushManager?.register(with: self)
        return pushDataRelay.asObservable()
    }
    
    func unRegistPushService() {
        pushManager?.unRegister()
    }
}

extension DKFilePreviewPushService: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: data),
            let json = try? JSON(data: data),
            let newJsonString = json["body"]["data"].string else {
                DocsLogger.error("DriveSDK.PreviewPush: decode json failed")
                return
        }
        let newJson = JSON(parseJSON: newJsonString)
        guard let appID = newJson["app_id"].string,
            let fileID = newJson["app_file_id"].string,
            let previewType = newJson["body"]["preview_type"].int,
            let previewStatusRawValue = newJson["body"]["status"].int,
            let previewStatus = DKFilePreview.PreviewStatus(rawValue: previewStatusRawValue) else {
                DocsLogger.error("DriveSDK.PreviewPush: Get fileID and previewStatus failed")
                return
        }
        guard  appID == self.appID, fileID == self.fileID else {
            DocsLogger.driveInfo("DriveSDK.PreviewPush: not current file")
            return
        }
        let newData = DKFilePreviewPushData(appID: appID,
                                            fileID: fileID,
                                            dataVersion: "",
                                            previewType: previewType,
                                            previewStatus: previewStatus)
        pushDataRelay.accept(newData)
    }
}
