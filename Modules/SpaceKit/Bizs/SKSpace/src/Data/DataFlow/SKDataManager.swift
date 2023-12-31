//
//  SKDataManager.swift
//  SKSpace
//
//  Created by guoqp on 2021/6/17.
// swiftlint:disable file_length


import Foundation
import SQLiteMigrationManager
import SQLite
import SKFoundation
import LarkContainer
import SwiftyJSON
import SKCommon
import ReSwift
import RxRelay
import RxSwift
import SpaceInterface
import SKInfra

//public extension CCMExtension where Base == UserResolver {
//
//    var skDataManager: SKDataManager? {
//        if CCMUserScope.spaceEnabled {
//            if let obj = try? base.resolve(type: SKDataManager.self) {
//                return obj
//            } else {
//                return nil
//            }
//        } else {
//            return SKDataManager.shared
//        }
//    }
//}

public final class SKDataManager: NSObject {
    private let dataCenter: DataCenter
    private let fileResource: FileResource = FileResource()

    private var observers: [SKObserverDataType: [SKListServiceProtocolWrapper]] = [:]
    private var subFolderObservers: [SKListServiceProtocolWrapper] = []
    private var dataForwarders: [SKDataForwarder] = []
    private var operational: SKOperational = .loadNewDBData

    private var allDataObservers: [String: SKDataObserverProtocolWrapper] = [:]

    public weak var dataModelsContainer: DataModelsContainerProtocol?


    let dbLoadingState = BehaviorRelay<Bool>(value: false)

    public private(set) var hadLoadDBForCurrentUser: Bool = false
    public var dbDataHadReady: Bool { hadLoadDBForCurrentUser }

    @available(*, deprecated, message: "new code should use `userResolver.docs.skDataManager`")
    public static let shared = SKDataManager()

    private var memoryData: ResourceState {
        return fileResource.mainStore.state
    }
    
    private override init() {
        self.dataCenter = DataCenter.shared
    }

//    let userResolver: UserResolver? // 为nil表示是单例对象
//
//    public init(userResolver: UserResolver?) {
//        self.userResolver = userResolver
//        if let ur = userResolver {
//            self.dataCenter = ur.docs.dataCenter
//        } else {
//            self.dataCenter = DataCenter.shared
//        }
//    }

    public func expectOnQueue() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(dataQueue))
        #endif
    }

    public func addObserver(_ observer: SKListServiceProtocol) {
        DispatchQueue.dataQueueAsyn { [weak self] in
            guard let self = self else { return }
            switch observer.type {
            case .subFolder:
                self.addDataFolderMapObservers(observer: observer)
            default:
                self.addDataListObserver(observer: observer)
            }
        }
    }

    public func removeObserver(_ observer: SKListServiceProtocol) {
        DispatchQueue.dataQueueAsyn { [weak self] in
            guard let self = self else { return }
            switch observer.type {
            case .subFolder:
                self.removeDataFolderMapObservers(observer: observer)
            default:
                self.removeDataListObserver(observer: observer)
            }
        }
    }

    public func addObserver(_ observer: SKDataObserverProtocol) {
        DispatchQueue.dataQueueAsyn { [weak self] in
            guard let self = self else { return }
            self.allDataObservers[observer.identifier()] = SKDataObserverProtocolWrapper(observer)
        }
    }
    public func removeObserver(_ observer: SKDataObserverProtocol) {
        DispatchQueue.dataQueueAsyn { [weak self] in
            guard let self = self else { return }
            self.allDataObservers.removeValue(forKey: observer.identifier())
        }
    }

    public func loadData(_ userID: String, _ completion: @escaping (Bool) -> Void) {
        DocsLogger.info("begin load data")
        DispatchQueue.dataQueueAsyn {
            guard !self.hadLoadDBForCurrentUser else {
                DocsLogger.info("had loadDB for current user")
                DispatchQueue.main.async {
                    completion(true)
                }
                return
            }
            self.dataCenter.loadDB(userID, fileResource: self.fileResource) { (ret) in
                guard ret, let dbData = self.dataCenter.getdbData() else {
                    DocsLogger.error("db connect fail \(ret), or get db data nil")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                self.hadLoadDBForCurrentUser = true
                self.operational = .loadNewDBData
                let loadNewDBDataAction = LoadNewDBDataAction(dbData: dbData)
                Self.dispatch(loadNewDBDataAction) { _ in
                    DispatchQueue.dataQueueAsyn {
                        self.dataForwardersListenModify()
                    }
                    self.dataModelListenModify()
                    self.dbLoadingState.accept(true)
                    completion(true)
                }

            }
        }
    }

    public func clear(_ completion: @escaping (Bool) -> Void) {
        self.dbLoadingState.accept(false)

        DispatchQueue.dataQueueAsyn {
            self.hadLoadDBForCurrentUser = false
            self.clearDataForwarders()
            self.memoryData.clear()
            self.dataCenter.reset()
            DispatchQueue.main.async {
                completion(true)
            }
        }

    }
}

// MARK: - 收敛space action
extension SKDataManager {
    func deleteFile(nodeToken: FileListDefine.NodeToken, parent: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .deleteFile
        let action = DeleteFileAction(file: nodeToken, folder: parent)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func deleteRecentFile(tokens: [FileListDefine.ObjToken]) {
        self.operational = .deleteRecentFile
        let action = DeleteRecentFileAction(tokens: tokens)
        Self.dispatch(action)
    }
    func resetRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .resetRecentFileListOld
        let action = ResetRecentFileListOldAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func appendRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendRecentFileListOld
        let action = AppendRecentFileListOldAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func mergeRecentFiles(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .mergeRecentFiles
        let action = MergeRecentFilesAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func resetRecentFilesByTokens(tokens: [FileListDefine.ObjToken], folderKey: DocFolderKey) {
        self.operational = .resetRecentFilesByTokens
        let action = ResetRecentFilesByTokensAction(tokens: tokens, folderKey: folderKey)
        Self.dispatch(action)
    }
    public func deleteFileByToken(token: TokenStruct, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .deleteFileByToken
        let action = DeleteFileByTokenAction(token: token)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    /*
    func resetBitaleRecentFileListOld(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .resetRecentFileListOld
        let action = ResetRecentFileListOldAction(data: data, homeType: .baseHomeType(context: nil))
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func appendBitaleRecentFileListOld(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendRecentFileListOld
        let action = AppendRecentFileListOldAction(data: data, homeType: .baseHomeType(context: nil))
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func mergeBitaleRecentFiles(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .mergeRecentFiles
        let action = MergeRecentFilesAction(data: data, homeType: .baseHomeType(context: nil))
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func resetBitaleRecentFilesByTokens(tokens: [FileListDefine.ObjToken]) {
        self.operational = .resetRecentFilesByTokens
        let action = ResetRecentFilesByTokensAction(tokens: tokens, homeType: .baseHomeType(context: nil))
        Self.dispatch(action)
    }
     */
    func resetFavorites(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .resetFavorites
        let action = ResetFavoritesAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func updateFavorites(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updateFavorites
        let action = UpdateFavoritesAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func setRootFile(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .setRootFile
        Self.dispatch(V2SetRootFileAction(data: data)) { state in
            callback?(state)
        }
    }
    func updateFileExternal(info: [FileListDefine.ObjToken: Bool], callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updateFileExternal
        Self.dispatch(V2UpdateFileExternalAction(info: info)) { state in
            callback?(state)
        }
    }
    func appendFileList(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendFileList
        Self.dispatch(AppendFileListAction(data: data)) { state in
            callback?(state)
        }
    }
    func updatePersionalFilesList(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updatePersionalFilesList
        Self.dispatch(UpdatePersionalFilesListAction(data: data, folderKey: folderKey)) { state in
            callback?(state)
        }
    }
    func appendPersionalFilesList(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendPersionalFilesList
        Self.dispatch(AppendPersionalFilesListAction(data: data, folderKey: folderKey)) { state in
            callback?(state)
        }
    }

    func deletePersonFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .deletePersonFile
        let action = DeletePersonFileAction(token: nodeToken)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func resetPins(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .resetPins
        Self.dispatch(ResetPinsAction(data: data, folderKey: folderKey)) { state in
            callback?(state)
        }
    }

    func deleteShareWithMeFile(nodeToken: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .deleteShareWithMeFile
        let action = DeleteShareWithMeFileAction(nodeToken)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func setShareFolderList(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .setShareFolderList
        let action = SetShareFolderListAction(data: data)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    
    func setShareFolderListV2(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .setShareFolderV2List
        let action = SetShareFolderListV2Action(data: data)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    
    func appendShareFolderList(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendShareFolderV2List
        let action = AppendShareFolderListAction(data: data)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    
    func setHiddenFolderList(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .setHiddenFolderList
        let action = SetHiddenFolderAction(data: data)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    
    func appendHiddenFolderList(data: FileDataDiff, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendHiddenFolderList
        let action = AppendHiddenFolderAction(data: data)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func resetShareFileList(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .resetShareFileList
        let action = ResetShareFileListAction(data: data, folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func appendShareFileList(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .appendShareFileList
        let action = AppendShareFileListAction(data: data, folderKey: folderKey)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    func updateFileSize(objToken: FileListDefine.ObjToken, fileSize: UInt64, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updateFileSize
        let action = UpdateFileSizeAction(objToken: objToken, fileSize: fileSize)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func renameFile(objToken: String, newName: String, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .renameFile
        let action = RenameFileAction(objToken: objToken, newName)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
//    func trashDeleteFile(file: String, folder: String, callback: ((ResourceState) -> Void)? = nil) {
//        self.operational = .trashDeleteFile
//        let action = TrashDeleteFileAction(file: file, folder: folder)
//        Self.dispatch(action) { state in
//            callback?(state)
//        }
//    }
//    func trashRestoreFile(file: String, folder: String, callback: ((ResourceState) -> Void)? = nil) {
//        self.operational = .trashRestoreFile
//        let action = TrashRestoreFileAction(file: file, folder: folder)
//        Self.dispatch(action) { state in
//            callback?(state)
//        }
//    }
    func moveFile(file: FileListDefine.NodeToken, from: FileListDefine.NodeToken, to: FileListDefine.NodeToken, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .moveFile
        let action = MoveFileAction(file: file, from: from, to: to)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func updateFileStarValueInAllList(objToken: FileListDefine.ObjToken, isStared: Bool, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updateFileStarValueInAllList
        let action = UpdateFileStarValueInAllListAction(objToken: objToken, isStared: isStared)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func updatePin(objToken: FileListDefine.ObjToken, isPined: Bool, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updatePin
        let action = UpdatePinAction(objToken: objToken, isPined: isPined)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }

    public func updateSecurity(objToken: String, newSecurityName: String) {
        updateSecurity(objToken: objToken, newSecurityName: newSecurityName, callback: nil)
    }
    func updateSecurity(objToken: String, newSecurityName: String, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .updateSecurity
        let action = UpdateSecretAction(objToken: objToken, newSecurityName)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
    func updateHiddenV2(objToken: String, hidden: Bool, callback: ((ResourceState) -> Void)? = nil) {
        self.operational = .setHiddenV2
        let action = UpdateHiddenStatusV2Action(nodeToken: objToken, hidden: hidden)
        Self.dispatch(action) { state in
            callback?(state)
        }
    }
}

extension SKDataManager {
    public func getFileEntries(by tokens: [FileListDefine.ObjToken], completion: @escaping ([SpaceEntry]) -> Void) {
        guard self.hadLoadDBForCurrentUser else {
            DocsLogger.warning("db not load")
            completion([])
            return
        }
        DispatchQueue.dataQueueAsyn {
            self.dataCenter.getFileEntries(by: tokens) { entries in
                DispatchQueue.main.async {
                    completion(entries)
                }
            }
        }
    }
}

extension SKDataManager {
    func getFilterCacheTokens(listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool, completion: @escaping ([String]?) -> Void) {
        guard self.hadLoadDBForCurrentUser else {
            DocsLogger.warning("db not load")
            completion(nil)
            return
        }
        DispatchQueue.dataQueueAsyn {
            self.dataCenter.getFilterCacheTokens(listID: listID,
                                                 filterType: filterType,
                                                 sortType: sortType,
                                                 isAscending: isAscending) { tokens in
                DispatchQueue.main.async {
                    completion(tokens)
                }
            }
        }

    }

    func save(filterCacheTokens tokens: [String], listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool) {
        guard self.hadLoadDBForCurrentUser else {
            DocsLogger.warning("db not load")
            return
        }
        DispatchQueue.dataQueueAsyn {
            self.dataCenter.save(filterCacheTokens: tokens,
                                 listID: listID,
                                 filterType: filterType,
                                 sortType: sortType,
                                 isAscending: isAscending)
        }
    }
}

// MARK: - Deprecated Sync Functions
extension SKDataManager {

    @available(*, deprecated, message: "Space opt: Use block style API instead. TODO: Space Refactor")
    public func getFileEntries(by tokens: [FileListDefine.ObjToken]) -> [SpaceEntry] {
        guard SKDataManager.shared.hadLoadDBForCurrentUser else {
            DocsLogger.warning("db has not been loaded")
            return []
        }
        return DispatchQueue.dataQueueSyn {
            let files = dataCenter.getFileEntries(by: tokens)
            return files ?? []
        }
    }
}

extension SKDataManager {
    public class func dispatch(_ action: Action, callback: ((ResourceState) -> Void)? = nil) {
        guard SKDataManager.shared.hadLoadDBForCurrentUser else {
            DocsLogger.warning("db has not been loaded, \(type(of: action)) will not executed, action logInfo")
            return
        }
        DispatchQueue.dataQueueAsyn {
            SKDataManager.shared.fileResource.dispatch(action) { state in
                DispatchQueue.main.async {
                    callback?(state)
                }
            }
        }
    }

    public func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<ResourceState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState {
        DispatchQueue.dataQueueAsyn {
            self.fileResource.subscribe(subscriber, transform: transform)
        }
    }

    public func unsubscribe(_ subscriber: AnyStoreSubscriber) {
        DispatchQueue.dataQueueAsyn {
            self.fileResource.unsubscribe(subscriber)
        }
    }
}

extension SKDataManager {

    /// 从数据库加nodeToken对应的子目录SpaceEntry列表到内存中，通过reswift更新到UI
    public func loadSubFolderEntries(nodeToken: String) {
        operational = .loadSubFolder(nodeToken: nodeToken)
        let action = LoadSubFolderEntriesAction(nodeToken: nodeToken)
        Self.dispatch(action)
    }

    public func deleteSubFolderEntries(nodeToken: String) {
        let action = DeleteSubFolderEntriesAction(nodeToken: nodeToken)
        Self.dispatch(action)
    }

    /// 从数据库加载对应的特殊目录SpaceEntry列表到内存中，通过reswift更新到UI
    public func loadFolderFileEntries(folderKey: DocFolderKey, limit: Int) {
        operational = .loadSpecialFolder(type: folderKey)
        let action = LoadFolderEntriesAction(folderKey: folderKey, limit: limit)
        Self.dispatch(action)
    }
}

extension SKDataManager {

    public func loadSubordinateRecentEntries(subordinateID: String) {
        operational = .loadSubFolder(nodeToken: subordinateID)
        let action = LoadSubFolderEntriesAction(nodeToken: subordinateID)
        Self.dispatch(action)
    }

    public func userInfoFor(subordinateID: String, callBack: @escaping (UserInfo?) -> Void) {
        userInfoFor(subordinateID, callBack: callBack)
    }
}

extension SKDataManager: DataCenterAPI {
    public var manualOfflineTokens: [TokenStruct] {
        if UserScopeNoChangeFG.HYF.offlineTokensSyncEnable {
            // memoryData要保证线程安全，在同一线程读取
            if DispatchQueue.isDataQueue {
                return self.memoryData.specialTokens[.manuOffline]
            } else {
                return DispatchQueue.dataQueueSyn {
                    return self.memoryData.specialTokens[.manuOffline]
                }
            }
        } else {
            return memoryData.specialTokens[.manuOffline]
        }
    }

    public var simpleModeObserver: SimpleModeObserver {
        return self
    }

    public var personalRootNodeToken: FileListDefine.NodeToken {
        return SettingConfig.singleContainerEnable ? "" : MyFolderDataModel.rootToken
    }

    public var dbLoadingStateObservable: Observable<Bool> {
        return self.dbLoadingState.asObservable()
    }

    public func forceAsyncLoadDBIfNeeded(_ userID: String, _ completion: @escaping (Bool) -> Void) {
        DocsLogger.info("begin forceAsyncLoadDBIfNeeded")
        if hadLoadDBForCurrentUser {
            DocsLogger.info("db has been loaded")
            completion(true)
        }
        loadData(userID) { ret in
            completion(ret)
        }
    }

    public func spaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return self.memoryData.getFileEntry(tokenNode: TokenStruct(token: objToken))
        }
    }

    public func spaceEntry(objToken: FileListDefine.ObjToken,
                           callBack: @escaping (SpaceEntry?) -> Void) {
        DispatchQueue.dataQueueAsyn { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    callBack(nil)
                }
                return
            }
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                DispatchQueue.main.async {
                    callBack(nil)
                }
                return
            }
            let fileEntry = self.memoryData.getFileEntry(tokenNode: TokenStruct(token: objToken))
            DispatchQueue.main.async {
                callBack(fileEntry)
            }
        }
    }

    public func spaceEntry(nodeToken: FileListDefine.NodeToken) -> SpaceEntry? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return memoryData.getFileEntry(tokenNode: TokenStruct(token: nodeToken))
        }
    }

    public func spaceEntry(token: TokenStruct) -> SpaceEntry? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return memoryData.getFileEntry(tokenNode: token)
        }
    }
    
    public func spaceEntry(token: TokenStruct, callBack: @escaping (SpaceEntry?) -> Void) {
        DispatchQueue.dataQueueAsyn {
            let fileEntry = self.memoryData.getFileEntry(tokenNode: token)
            DispatchQueue.main.async {
                callBack(fileEntry)
            }
        }
    }

    public func loadDBSpaceEntry(objToken: FileListDefine.ObjToken) -> SpaceEntry? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return dataCenter.getFileEntryFromDB(by: objToken)
        }
    }

    public func getMyFolder() -> SpaceEntry? {
        dataModelsContainer?.getMyFolder()
    }

    public func spaceEntries(for listType: ListType) -> [SpaceEntry] {
        if listType == .recent {
            spaceAssertionFailure("RecentFiles has been removed, avoid using this")
            return DispatchQueue.dataQueueSyn { () -> [SpaceEntry] in
                guard self.hadLoadDBForCurrentUser else { return [] }
                return memoryData.userFile.specialListMap[.recent]?.files ?? []
            }
        }
        spaceAssertionFailure("DataModel has been removed, avoid using this")
        return []
    }

    public func getAllSpaceEntries() -> [FileListDefine.ObjToken: SpaceEntry] {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return [:]
            }
            return memoryData.allFileEntries
        }
    }

    public func userInfo(for userID: FileListDefine.UserID) -> UserInfo? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return memoryData.userInfoFor(userID)
        }
    }

    public func userInfoFor(_ userid: FileListDefine.UserID, callBack: @escaping (UserInfo?) -> Void) {
        DispatchQueue.dataQueueAsyn {
            let userInfo = self.memoryData.userInfoFor(userid)
            DispatchQueue.main.async {
                callBack(userInfo)
            }
        }
    }

    public func convertToNodeToken(for objToken: FileListDefine.ObjToken) -> FileListDefine.NodeToken? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return memoryData.getNodeTokenForObjToken(objToken)
        }
    }

    public func folderToken(containing nodeToken: FileListDefine.NodeToken) -> FileListDefine.NodeToken? {
        DispatchQueue.dataQueueSyn {
            guard self.hadLoadDBForCurrentUser else {
                DocsLogger.warning("db has not been loaded")
                return nil
            }
            return memoryData.getFolderTokenForNodeToken(nodeToken)
        }
    }

    public func removeShareInfo(for nodeToken: FileListDefine.NodeToken) {
        self.operational = .removeShareInfo
        let action = RemoveFileShareInfoAction(fileToken: nodeToken)
        Self.dispatch(action)
    }

    public func updateOwner(for objToken: FileListDefine.NodeToken, newOwnerID: FileListDefine.UserID, isFolder: Bool) {
        self.operational = .updateOwner
        let action = TransferOwnerAction(token: objToken, newOwner: newOwnerID, isFolder: isFolder)
        Self.dispatch(action)
    }

    public func updateUIModifier(tokenInfos: [FileListDefine.ObjToken: SyncStatus]) {
        self.operational = .updateUIModifier
        let action = SyncUIModifierAction(tokenInfos: tokenInfos)
        Self.dispatch(action)
    }

    public func deleteSpaceEntry(token: TokenStruct) {
        self.operational = .deleteSpaceEntry
        let action = DeleteFileByTokenAction(token: token)
        Self.dispatch(action)
    }

    public func deleteSpaceEntriesForSimpleMode(files: [SimpleModeWillDeleteFile]) {
        self.operational = .deleteSpaceEntriesForSimpleMode
        let action = DeleteFileEntryByObjTokensAction(files)
        Self.dispatch(action)
    }

    public func insert(fakeEntry: SpaceEntry, folderToken: FileListDefine.NodeToken) {
        self.operational = .insertFakeEntry
        let action = InsertFakeFileAction(fakeFileEntry: fakeEntry, folder: folderToken)
        Self.dispatch(action)
    }

    public func insertUploadedFileEntry(_ entry: SpaceEntry, folderToken: FileListDefine.NodeToken) {
        self.operational = .insertFakeEntry
        let action = InsertUploadFileAction(entry: entry, parentFolderToken: folderToken)
        Self.dispatch(action)
    }

    public func insertUploadedWikiEntry(_ entry: SpaceEntry) {
        self.operational = .insertFakeEntry
        let action = InsertUploadWikiAction(entry: entry)
        Self.dispatch(action)
    }

    public func updateNeedSyncState(objToken: FileListDefine.ObjToken, type: DocsType, needSync: Bool, completion: (() -> Void)?) {
        self.operational = .updateNeedSyncState
        let action = NeedSyncAction(objToken: objToken, type: type, needSync: needSync)
        Self.dispatch(action) { _ in
            completion?()
        }
    }

    public func update(customIcon: CustomIcon, for objToken: FileListDefine.ObjToken) {
        self.operational = .updateCustomIcon
        let action = UpdateIconInfoToFileEntryAction(customIcon: customIcon, objToken: objToken)
        Self.dispatch(action)
    }

    public func update(fakeEntry: SpaceEntry, serverObjToken: FileListDefine.ObjToken, serverNodeToken: FileListDefine.NodeToken) {
        self.operational = .updateFakeEntry
        let action = ReplaceFakeTokenAction(fileEntry: fakeEntry, newObjToken: serverObjToken, newNodeToken: serverNodeToken)
        Self.dispatch(action)
    }

    public func forceUpdateState(completion: @escaping () -> Void) {
        self.operational = .forceUpdateState
        let action = DummyAction()
        Self.dispatch(action) { _ in
            completion()
        }
    }

    public func insert(users: FileListDefine.Users) {
        self.operational = .insertUsers
        let action = AppendUserAction(users)
        Self.dispatch(action)
    }

    public func rename(objToken: FileListDefine.ObjToken, with newName: String) {
        self.operational = .rename
        let action = RenameFileAction(objToken: objToken, newName)
        Self.dispatch(action)
    }

    public func insert(entries: [SpaceEntry]) {
        self.operational = .insertEntries
        let action = AddFileEntriesAction(entries)
        Self.dispatch(action)
    }
    
    public func resetManuOfflineStatus(objToken: String) {
        self.operational = .resetManualSynStatu
        let action = ResetManuOfflineStatusAction(token: objToken)
        Self.dispatch(action)
    }
    
    public func resetManualOfflineTag(objToken: FileListDefine.ObjToken, isSetManuOffline: Bool, callback: (() -> Void)? = nil) {
        self.operational = .resetManualOfflineTag
        let action = ResetManualOfflineTagAction(objToken: objToken, isSetManuOffline: isSetManuOffline)
        Self.dispatch(action) { _ in
            callback?()
        }
    }
    
    public func resetMOFileFromDetailPage(entry: SpaceEntry, isSetManuOffline: Bool, callback: (() -> Void)? = nil) {
        self.operational = .resetManualOfflineTag
        let action = ResetMOFileFromDetailPage(entry: entry, isSetManuOffline: isSetManuOffline)
        Self.dispatch(action) { _ in
            callback?()
        }
    }

}

extension SKDataManager {
    public func refreshListData(of type: ListType, completion: ((Error?) -> Void)? = nil) {
        let name: Notification.Name
        switch type {
        case .pins:
            name = QuickAccessDataModel.quickAccessNeedUpdate
        case .recent:
            name = RecentListDataModel.recentListNeedUpdate
        case .personalFiles, .personalFolder:
            name = PersonalFileDataModel.personalFileNeedUpdate
        case .sharedFolders, .sharedFiles:
            name = SharedFileDataModel.sharedFileNeedUpdate
        case .favorites:
            name = FavoritesDataModel.favoritesNeedUpdate
        case .manuOffline:
            return
        }
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension SKDataManager: SimpleModeObserver {
    public func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        // 暂时没事干
    }
}

extension SKDataManager {
    public func notifyStartExecuteDelayBlock() {
        // 暂时没事干
    }
}

private extension SKDataManager {
    private func dataModelListenModify() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dataCenter.subscribeMainStore()
        }
    }

    private func clearDataForwarders() {
        for wrapper in dataForwarders {
            if let storeSubscriber = wrapper as? AnyStoreSubscriber {
                unsubscribe(storeSubscriber)
            }
        }
        self.dataForwarders.removeAll()
    }

    private func addDataFolderMapObservers(observer: SKListServiceProtocol) {
        var subFolderObservers1 = self.subFolderObservers.compactMap { (wrapper) -> SKListServiceProtocolWrapper? in
            guard wrapper.observer != nil else {
                return nil
            }
            return wrapper
        }
        subFolderObservers1.append(SKListServiceProtocolWrapper(observer))
        self.subFolderObservers = subFolderObservers1
    }
    private func removeDataFolderMapObservers(observer: SKListServiceProtocol) {
        self.subFolderObservers.removeAll(where: {
            guard let observer1 = $0.observer else {
                /// _observer  destructed
                return true
            }
            return observer1 === observer
        })
    }
    private func addDataListObserver(observer: SKListServiceProtocol) {
        let oldObservers = observers[observer.type] ?? []
        var newObservers = oldObservers.compactMap { wrapper -> SKListServiceProtocolWrapper? in
            guard wrapper.observer != nil else { return nil }
            return wrapper
        }
        newObservers.append(SKListServiceProtocolWrapper(observer))
        self.observers[observer.type] = newObservers
    }
    private func removeDataListObserver(observer: SKListServiceProtocol) {
        guard var typeObservers = observers[observer.type] else { return }
        typeObservers.removeAll { wrapper in
            guard let nextObserver = wrapper.observer else { return true }
            return nextObserver === observer
        }
        observers[observer.type] = typeObservers
    }

    private func folderInfo(type: SKObserverDataType, state: ResourceState) -> FolderInfo {
        switch type {
        case let .specialList(folderKey):
            return state.userFile.specialListMap[folderKey] ?? FolderInfo()
        case .subFolder, .all:
            spaceAssertionFailure()
            return state.userFile.specialListMap[.recent] ?? FolderInfo()
        }
    }

    private func dataForwardersListenModify() {
        expectOnQueue()
        for forwarder in dataForwarders {
            if let subscriber = forwarder as? AnyStoreSubscriber {
                unsubscribe(subscriber)
            }
        }
        dataForwarders.removeAll()

        DocFolderKey.allCases.forEach { folderKey in
            addDataListForwarder(type: .specialList(folderKey: folderKey))
        }
        addDataFolderMapForwarder()
        addAllFilesForwarder()
    }

    private func addDataListForwarder(type: SKObserverDataType) {
        expectOnQueue()
        guard hadLoadDBForCurrentUser else {
            spaceAssertionFailure()
            DocsLogger.info("db has not been loaded, listType \(type)")
            return
        }
        let dataForwarder = SKDataListForwarder(type: type)
        subscribe(dataForwarder) { (state) in
            state.select {
                let folderInfo = self.folderInfo(type: type, state: $0)
                return (folderInfo, self.observers[type], self.operational)
            }
        }
        self.dataForwarders.append(dataForwarder)
    }

    private func addDataFolderMapForwarder() {
        expectOnQueue()
        guard hadLoadDBForCurrentUser else {
            DocsLogger.info("db has not been loaded")
            return
        }
        DocsLogger.info("add data folder map forwarder type subFolder")

        let subFolderForwarder = SKDataFolderMapForwarder(type: .subFolder)
        subscribe(subFolderForwarder) { (state) in
            state.select { ($0.userFile.folderInfoMap, self.subFolderObservers, self.operational) }
        }
        self.dataForwarders.append(subFolderForwarder)
    }

    private func addAllFilesForwarder() {
        expectOnQueue()
        guard hadLoadDBForCurrentUser else {
            DocsLogger.info("db has not been loaded")
            return
        }
        DocsLogger.info("create all data forwarder")
        let allDataForwarder = SKDataAllFilesForwarder(type: .all)
        subscribe(allDataForwarder) { (state) in
            state.select { state in
                let allFiles = state.allFileEntries
                return (allFiles, self.allDataObservers)
            }
        }
        self.dataForwarders.append(allDataForwarder)
    }
}
