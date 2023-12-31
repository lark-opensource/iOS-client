//
//  SKListServiceProtocol.swift
//  SKECM
//
//  Created by guoqp on 2021/4/6.
//

import Foundation
import SKCommon

public protocol SKListData: AnyObject {
    var folderNodeToken: String { get } 
    var files: [SpaceEntry] { get }
}

public protocol SKListServiceProtocol: AnyObject {
    func dataChange(data: SKListData, operational: SKOperational)
    var type: SKObserverDataType { get }
    var token: String { get }
}

public enum SKOperational: Equatable {
    case loadNewDBData
    case deleteFile
    case deleteRecentFile
    case resetRecentFileListOld
    case appendRecentFileListOld
    case mergeRecentFiles
    case resetRecentFilesByTokens
    case receiveRustPush
    case deleteFileByToken
    case resetManualOfflineTag
    case resetFavorites
    case updateFavorites
    case moveFileToNewPositionInFavorites
    case setRootFile
    case updateFileExternal
    case appendFileList
    case updatePersionalFilesList
    case appendPersionalFilesList
    case deletePersonFile
    case resetPins
    case deleteShareWithMeFile
    case setShareFolderNewList
    case setShareFolderList
    case setShareFolderV2List   //space2.0新共享空间共享文件夹列表
    case appendShareFolderV2List
    case setHiddenFolderList
    case appendHiddenFolderList
    case resetShareFileList
    case appendShareFileList
    case updateFileSize
    case renameFile
    case trashDeleteFile
    case trashRestoreFile
    case moveFile
    case updateFileStarValueInAllList
    case updatePin
    case addFile
    case removeShareInfo
    case updateOwner
    case updateUIModifier
    case deleteSpaceEntry
    case deleteSpaceEntriesForSimpleMode
    case insertFakeEntry
    case updateNeedSyncState
    case updateCustomIcon
    case updateFakeEntry
    case forceUpdateState
    case insertUsers
    case rename
    case insertEntries
    case openNoCacheFolderLink //打开无缓存的文件夹链接
    case loadSubFolder(nodeToken: String)
    case loadSpecialFolder(type: DocFolderKey)
    case setHiddenV2
    case updateSecurity //更新密级
    case resetManualSynStatu

    var descriptionInLog: String {
        switch self {
        case .loadSubFolder:
            return "loadSubFolder"
        default:
        // iOS 15.4 上这段代码容易触发系统 bug 导致 crash，目前控制下仅在 DEBUG 模式打印
        // 未来应该推动 DocsLogger 改造，message 入参改为闭包，延后按需执行
        #if DEBUG
            return String(describing: self)
        #else
            return ""
        #endif
        }
    }
}

//public struct SKOperational {
//    var listType: SKObserverDataType
//    var operate: OperateType
//}
//
//public enum OperateType: Int {
//    case loadFromDB //从db加载
//    case refresh  //刷新
//    case loadMore //加载更多
//    case delete //删除
//}


public enum SKObserverDataType: Equatable, Hashable {
    case all
    case subFolder
    case specialList(folderKey: DocFolderKey)
}
