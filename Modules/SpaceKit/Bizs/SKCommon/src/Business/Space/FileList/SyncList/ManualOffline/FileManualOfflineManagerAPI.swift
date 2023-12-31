//
//  FileManualOfflineManagerAPI.swift
//  SKCommon
//
//  Created by guoqp on 2020/7/1.
//

import Foundation
import SpaceInterface

public struct ManualOfflineFile {
    /// Wiki文档需要传本体的objToken
    public let objToken: FileListDefine.ObjToken
    public let type: DocsType
    public let wikiInfo: WikiInfo?

    public static let isSetManuOfflineKey = "is_set_manu_offline"
    public static let hadShownManuStatusKey = "had_shown_manu_status"
    public static let fileSizeKey = "file_size"
    public static let addManuOfflineTimeKey = "add_manu_offline_time"
    public static let syncStatusKey = "manu_offline_sync_status"

    public init(objToken: FileListDefine.ObjToken, type: DocsType, wikiInfo: WikiInfo? = nil) {
        self.objToken = objToken
        self.type = type
        self.wikiInfo = wikiInfo
    }
}

public struct ManualOfflineAction {

//    enum Status: Int {
//        case unOffline = 0
//        case offlining = 1
//        case offlined = 2
//    }
    public enum Event {

        /// 用于文件新增成为手动离线下载的时候
        case add

        /// 用于需要各个业务端（downloader）检查files中
        /// 把没有同步完成的，继续同步，一般调用时机是App重新启动
        case update

        /// 用于需要强制刷新一下的时候
        case refreshData

        case remove

        /// 用户对某个文件选择了某个下载策略
        case download(DownloadStrategy)

        /// 参数： old , new, oldIsreachable, newIsreachable
        case netStateChanged(NetState, NetState, Bool, Bool)

        //***** 发给 UI 层的事件写在下面 ******//

        /// 参数，文件大小，单位b
        case showDownloadJudgeUI(UInt64)
        
        /// 让UI层显示弹框提示没有存储空间了，仅仅在新增手动离线时弹框
        case showNoStorageUI

        case startOpen
        case endOpen
    }
    public enum DownloadStrategy {
        case wifiOnly
        case wwanAndWifi
    }

    public enum NetState {
        case wwan
        case wifi
        case unkown
    }

    public let event: ManualOfflineAction.Event
    public let files: [ManualOfflineFile]
    public var extra: [ManualOfflineCallBack.ExtraKey: Any]?

    public init(event: ManualOfflineAction.Event, files: [ManualOfflineFile], extra: [ManualOfflineCallBack.ExtraKey: Any]?) {
        self.event = event
        self.files = files
        self.extra = extra
    }
}


/// 执行离线下载的各个业务端，根据情况可以对manger进行回调
/// 把有关的事件和结果通知回来，
/// 通过调用ManualOfflineManager的excuteCallBack(_:)方法
public enum ManualOfflineCallBack {
    /// 有需要自行拓展
    public enum ExtraKey: String {

        case updateTime

        /// 文件大小，单位b
        case fileSize

        case entityDeleted

        // 没有权限
        case noPermission
        
        case listToken
    }

    case succeed(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)

    /// 中间这个String用来写errorMsg
    case failed(FileListDefine.ObjToken, String, extra: [ExtraKey: Any]?)

    case progressing(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)

    /// 更新文件的信息，比如大小，可根据后期业务开发，拓展属性
    case updateFileInfo(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)

    /// 流量环境下，弹框提示用户，选择下载策略
    case judgeDownload(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)

    /// 新增手动离线文件时，检查到没有存储空间了，弹框提示
    case noStorage(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)

    case canNotCacheFile(FileListDefine.ObjToken, extra: [ExtraKey: Any]?)
}


public protocol ManualOfflineFileStatusObserver: AnyObject {

    func didReceivedFileOfflineStatusAction(_ action: ManualOfflineAction)
}
/// 考虑到从lark聊天界面进入drive的详情页，添加手动离线，此时不一定能准确拿到列表页或者tabVC，所以放在此处
public protocol PopViewManagerProtocol: ManualOfflineFileStatusObserver {
    func clear()
    var hadShownDownloadJudge: Bool { get set }
}


public protocol FileManualOfflineManagerAPI: SimpleModeObserver {

    func addObserver(_ target: ManualOfflineFileStatusObserver)
    func removeObserver(_ target: ManualOfflineFileStatusObserver)
    func excuteCallBack(_ callBack: ManualOfflineCallBack)

    func addToOffline(_ file: ManualOfflineFile)
    func updateOffline(_ files: [ManualOfflineFile])
    func refreshOfflineData(of file: ManualOfflineFile)
    func removeFromOffline(by file: ManualOfflineFile, extra: [ManualOfflineCallBack.ExtraKey: Any]?)
    func removeFromOffline(files: [ManualOfflineFile], extra: [ManualOfflineCallBack.ExtraKey: Any]?)

    //开始进入详情页
    func startOpen(_ file: ManualOfflineFile)
    //结束进入详情页
    func endOpen(_ file: ManualOfflineFile)
    func download(_ file: ManualOfflineFile, use strategy: ManualOfflineAction.DownloadStrategy)
    func clear()
}
