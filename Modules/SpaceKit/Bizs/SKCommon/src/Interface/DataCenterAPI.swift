//
//  DataCenterAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/6/10.
//

import Foundation
import RxSwift
import ReSwift
import SpaceInterface

public enum DataCenterListType: String {
    case pins
    case recent

    case personalFolder //我的文件夹根目录
    case personalFiles

    case sharedFolders
    case sharedFiles

    case favorites

    case manuOffline
}


public protocol SKDataObserverProtocol: AnyObject {
    func dataChange(state: [FileListDefine.Key: SpaceEntry])
    func identifier() -> String
}

public protocol DataCenterAPI {

    typealias ListType = DataCenterListType

    var manualOfflineTokens: [TokenStruct] { get }
    var hadLoadDBForCurrentUser: Bool { get }
    var simpleModeObserver: SimpleModeObserver { get }
    var personalRootNodeToken: FileListDefine.NodeToken { get }
    var dbLoadingStateObservable: Observable<Bool> { get }

    func forceAsyncLoadDBIfNeeded(_ userID: String, _ completion: @escaping (Bool) -> Void)
    // 以下三个方法目前的实现没有区别
    // Get SpaceEntry base on objToken from Memory
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func spaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry?

    func spaceEntry(objToken: FileListDefine.ObjToken,
                    callBack: @escaping (SpaceEntry?) -> Void)

    // Get SpaceEntry base on nodeToken from Memory
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func spaceEntry(nodeToken: FileListDefine.NodeToken) -> SpaceEntry?
    // Get SpaceEntry base on token from Memory
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func spaceEntry(token: TokenStruct) -> SpaceEntry?
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func loadDBSpaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry?

    func getMyFolder() -> SpaceEntry?

    func spaceEntries(for listType: ListType) -> [SpaceEntry]

    // Get SpaceEntry base on token from Memory
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func getAllSpaceEntries() -> [FileListDefine.ObjToken: SpaceEntry]

    // Get UserInfo base on userID from Memory
    @available(*, deprecated, message: "Space opt: Use async method instead")
    func userInfo(for userID: FileListDefine.UserID) -> UserInfo?

    func userInfoFor(_ userid: FileListDefine.UserID, callBack: @escaping (UserInfo?) -> Void)
    
    func refreshListData(of type: ListType, completion: ((Error?) -> Void)?)
    #warning ("Space opt: Space 1.0 场景下有可能找错！！！因为一个文档，可能出现在多处，此处的含义需要确认清楚")
    @available(*, deprecated, message: "Space opt: Use list data (folder context etc.) to get node token")
    func convertToNodeToken(for objToken: FileListDefine.ObjToken) -> FileListDefine.NodeToken?

    func folderToken(containing nodeToken: FileListDefine.NodeToken) -> FileListDefine.NodeToken?

    func notifyStartExecuteDelayBlock()

    // 其它模块订阅 allFileEntries 的变化
    func addObserver(_ observer: SKDataObserverProtocol)
    func removeObserver(_ observer: SKDataObserverProtocol)

    // MARK: Action
    // Corresponse to RemoveFileShareInfoAction
    func removeShareInfo(for nodeToken: FileListDefine.NodeToken)
    // Corresponse to TransferOwnerAction
    func updateOwner(for objToken: FileListDefine.ObjToken, newOwnerID: String, isFolder: Bool)
    // Corresponse to SyncUIModifierAction
    func updateUIModifier(tokenInfos: [FileListDefine.ObjToken: SyncStatus])
    // Corresponse to DeleteFileByTokenAction
    func deleteSpaceEntry(token: TokenStruct)
    // Corresponse to DeleteFileEntryByObjTokensAction
    func deleteSpaceEntriesForSimpleMode(files: [SimpleModeWillDeleteFile])
    // Corresponse to InsertFakeFileAction
    func insert(fakeEntry: SpaceEntry, folderToken: FileListDefine.NodeToken)
    // Corresponse to NeedSyncAction
    func updateNeedSyncState(objToken: FileListDefine.ObjToken, type: DocsType, needSync: Bool, completion: (() -> Void)?)
    // Corresponse to UpdateIconInfoToFileEntryAction
    func update(customIcon: CustomIcon, for objToken: FileListDefine.ObjToken)
    // Corresponse to ReplaceFakeTokenAction
    func update(fakeEntry: SpaceEntry, serverObjToken: FileListDefine.ObjToken, serverNodeToken: FileListDefine.NodeToken)
    // Corresponse to AppendUserAction
    func insert(users: FileListDefine.Users)
    // Corresponse to RenameFileAction
    func rename(objToken: FileListDefine.ObjToken, with newName: String)
    // Corresponse to DummyAction
    func forceUpdateState(completion: @escaping () -> Void)
    // Corresponse to AddFileEntriesAction/WikiAddEntryAction
    func insert(entries: [SpaceEntry])
    // 更新密级
    func updateSecurity(objToken: String, newSecurityName: String)
    func resetManuOfflineStatus(objToken: String)
    // 离线使用
    func resetManualOfflineTag(objToken: FileListDefine.ObjToken, isSetManuOffline: Bool, callback: (() -> Void)?)
    func resetMOFileFromDetailPage(entry: SpaceEntry, isSetManuOffline: Bool, callback: (() -> Void)?)
}
