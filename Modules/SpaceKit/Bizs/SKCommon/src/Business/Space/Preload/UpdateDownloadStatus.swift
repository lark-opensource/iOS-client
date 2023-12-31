//
//  UpdateDownloadStatus.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/26.
//  

import Foundation
import SKInfra

extension PreloadKey {
    func updateDownloadStatus(_ status: DownloadStatus) {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else { return }
        //wiki在列表中的objToken是WikiToken，因此需要通过wikiToken获取列表对应的文档
        var listToken = objToken
        if let wikiInfo {
            listToken = wikiInfo.wikiToken
        }
        guard let fileEntry = dataCenterAPI.getAllSpaceEntries()[listToken] else { return }
        var syncTokenInfo = [FileListDefine.ObjToken: SyncStatus]()
        if status != .success {
            syncTokenInfo[listToken] = fileEntry.syncStatus.modifingDownLoadStatus(status)
        } else {
            syncTokenInfo[listToken] = fileEntry.syncStatus.modifingDownLoadStatus(.success)
            DispatchQueue.main.docAsyncAfter(2, block: {
                guard let fileEntry = dataCenterAPI.getAllSpaceEntries()[listToken] else { return }
                if fileEntry.syncStatus.downloadStatus == .success {
                    let delaySyncTokenInfo = [listToken: fileEntry.syncStatus.modifingDownLoadStatus(.successOver2s)]
                    dataCenterAPI.updateUIModifier(tokenInfos: delaySyncTokenInfo)
                }
            })
        }
        dataCenterAPI.updateUIModifier(tokenInfos: syncTokenInfo)
    }
}
