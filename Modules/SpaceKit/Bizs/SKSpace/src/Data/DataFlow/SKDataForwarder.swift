//
//  SKDataForwarder.swift
//  SKSpace
//
//  Created by guoqp on 2021/6/29.
//

import Foundation
import SwiftyJSON
import ReSwift
import SKCommon
import SKFoundation
import RxSwift
import RxRelay

public final class SKListServiceProtocolWrapper {
    weak var observer: SKListServiceProtocol?
    init(_ observer: SKListServiceProtocol) {
        self.observer = observer
     }
}

public class SKDataForwarder: NSObject {
    let listType: SKObserverDataType
    public init(type: SKObserverDataType) {
        self.listType = type
    }
}

public final class SKDataListForwarder: SKDataForwarder, StoreSubscriber {
    public func newState(state: (FolderInfo, [SKListServiceProtocolWrapper]?, SKOperational)) {
        guard let wrappers = state.1 else {
            return
        }
        let services = wrappers.compactMap(\.observer)
        let operational = state.2
        let info = state.0
        DispatchQueue.main.async {
            services.forEach { service in
                service.dataChange(data: info, operational: operational)
            }
        }
    }
}

public final class SKDataFolderMapForwarder: SKDataForwarder, StoreSubscriber {
    public func newState(state: (FolderInfoMap, [SKListServiceProtocolWrapper], SKOperational)) {
        let wrappers = state.1
        let folderInfoMap = state.0
        let operational = state.2
        for wrapper in wrappers {
            if let observer = wrapper.observer {
                if let fileInfo = folderInfoMap.folders[observer.token] {
                    DispatchQueue.main.async {
                        observer.dataChange(data: fileInfo, operational: operational)
                    }
                } else {
                    let folder = FolderInfo()
                    folder.folderNodeToken = observer.token
                    DispatchQueue.main.async {
                        observer.dataChange(data: folder, operational: .openNoCacheFolderLink)
                    }
                }
            }
        }
    }
}


public final class SKDataObserverProtocolWrapper {
    weak var observer: SKDataObserverProtocol?
    init(_ observer: SKDataObserverProtocol) {
        self.observer = observer
     }
}

public final class SKDataAllFilesForwarder: SKDataForwarder, StoreSubscriber {
    public func newState(state: ([FileListDefine.Key: SpaceEntry], [String: SKDataObserverProtocolWrapper])) {
        let wrappers = state.1
        let allFiles = state.0
        for (_, wrapper) in wrappers {
            if let observer = wrapper.observer {
                DispatchQueue.main.async {
                    observer.dataChange(state: allFiles)
                }
            }
        }
    }
}
