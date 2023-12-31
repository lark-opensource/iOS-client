//
//  ManuOffLineNotifyFunction.swift
//  SKSpace
//
//  Created by majie.7 on 2021/10/29.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import SKInfra

public final class ManuOffLineNotifySection {
    
    private let dataManager: SKDataManager
    static var hadNotifyFirstTime: Bool = false
    
    init() {
        self.dataManager = SKDataManager.shared
    }
    
    public func notify() {
        dataManager.addObserver(self)
        dataManager.loadFolderFileEntries(folderKey: .manuOffline, limit: ManuOffLineDataModel.offLineListPageCount)
    }
    
    public func clear() {
        Self.hadNotifyFirstTime = false
    }
}

extension ManuOffLineNotifySection: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        let entries = data.files
        checkToNotifyDownloaders(entries)
    }
    
    private func checkToNotifyDownloaders(_ files: [SpaceEntry]) {
        // 数据从0 到有的时候，给用户发一次，只发一次
        guard !Self.hadNotifyFirstTime,
              let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
            return
        }
        // 第一次，通知给各个业务下载端，用户退出登录时重置为false
        Self.hadNotifyFirstTime = true
        
        guard !files.isEmpty else { return }
        
        var array = [ManualOfflineFile]()
        files.forEach { file in
            var wikiInfo: WikiInfo?
            if file.type == .wiki, let wikiEntry = file as? WikiEntry {
                wikiInfo = wikiEntry.wikiInfo
            }
            let moFile = ManualOfflineFile(objToken: file.objToken, type: file.type, wikiInfo: wikiInfo)
            array.append(moFile)
        }
        moMgr.updateOffline(array)
    }
    
    public var type: SKObserverDataType {
        .specialList(folderKey: .manuOffline)
    }
    
    public var token: String {
        ManuOffLineDataModel.listToken
    }
    
    
}
