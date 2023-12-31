//
//  SlideActionManager.swift
//  DocsTabs
//
//  Created by weidong fu on 18/1/2018.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

/// 手动离线
public final class ManualOfflineHelper {
    // 列表操作
    public static func handleManualOffline(_ objToken: FileListDefine.ObjToken,
                                           type: DocsType,
                                           wikiInfo: WikiInfo?,
                                           isAdd: Bool) {
        var listToken = objToken
        var realToken = objToken
        if let wikiInfo {
            listToken = wikiInfo.wikiToken
            realToken = wikiInfo.objToken
        }

        // TODO(chenwenjun.cn): migrating to `UserReslover`
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return
        }

        dataCenterAPI.resetManualOfflineTag(objToken: listToken, isSetManuOffline: isAdd) {
            let moFile = ManualOfflineFile(objToken: realToken, type: type, wikiInfo: wikiInfo)
            guard let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
                return
            }
            if isAdd {
                moMgr.addToOffline(moFile)
            } else {
                moMgr.removeFromOffline(by: moFile, extra: nil)
            }
        }

        if isAdd {
            Self.reportManualOffline(objToken: objToken, type: type)
        }
    }
    // 文档详情页操作
    public static func handleManualOfflineFromDetailPage(entry: SpaceEntry, wikiInfo: WikiInfo?, isAdd: Bool) {
        var realToken = entry.objToken
        if let wikiInfo {
            realToken = wikiInfo.objToken
        }

        // TODO(chenwenjun.cn): migrating to `UserReslover`
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return
        }

        dataCenterAPI.resetMOFileFromDetailPage(entry: entry, isSetManuOffline: isAdd) {
            let moFile = ManualOfflineFile(objToken: realToken, type: entry.docsType, wikiInfo: wikiInfo)
            guard let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
                return
            }
            if isAdd {
                moMgr.addToOffline(moFile)
            } else {
                moMgr.removeFromOffline(by: moFile, extra: nil)
            }
        }
        if isAdd {
            Self.reportManualOffline(objToken: entry.objToken, type: entry.docsType)
        }
    }
    
    private static func reportManualOffline(objToken: String, type: DocsType) {
        guard let userID = User.current.basicInfo?.userID,
              let reporter = DocsContainer.shared.resolve(DocumentActivityReporter.self) else {
            return
        }
        let activity = DocumentActivity(objToken: objToken,
                                        objType: type,
                                        operatorID: userID,
                                        scene: .download,
                                        operationType: .offline)
        reporter.report(activity: activity)
    }
}
