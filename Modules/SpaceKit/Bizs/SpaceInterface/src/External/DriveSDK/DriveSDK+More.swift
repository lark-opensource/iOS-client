//
//  DriveSDK+More.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2020/6/17.
//

import Foundation
import RxSwift

public enum DriveSDKDownloadState {
    case downloading(progress: Double)
    case success(fileURL: URL)
    case interrupted(reason: String)
}

public protocol DriveSDKFileProvider {
    var fileSize: UInt64 { get } // 文件总大小，用于显示下载进度
    var localFileURL: URL? { get } // 如果已下载完成，提供LocalFileURL，直接从本地打开
    func download() -> Observable<DriveSDKDownloadState>
    /// 下载操作前置拦截
    func canDownload(fromView: UIView?) -> Observable<Bool>
    func cancelDownload()
}
extension DriveSDKFileProvider {
    func canDownload(fromView: UIView?) -> Observable<Bool> {
        return .just(true)
    }
}

// 保存到云盘功能状态
public enum DKSaveToSpaceState: Equatable {
    // 未保存到云盘，更多按钮显示"保存到云盘"
    case unsave
    // 已经保存到云盘，更多按钮显示"在云文档查看"
    case saved(fileToken: String)
    // 无法进行保存
    case unable
}

public enum DriveSDKMoreAction {
    // 源文件由业务方提供的场景，使用其他应用打开需要业务方提供fileProvider，接入业务IM附件
    case openWithOtherApp(fileProvider: DriveSDKFileProvider)
    case IMSaveToLocal(fileProvider: DriveSDKFileProvider)
    // customAction为业务提供的自定义事件处理动作，如果为nil，则由DriveSDK弹出其他应用打开面板。
    // callback: 点击分享到其他应用后回调，提供DKAttachmentInfo和分享目标bundleID 和是否分享成功的Bool值
    case customOpenWithOtherApp(customAction: ((UIViewController) -> Void)?,
                                callback: ((DKAttachmentInfo, String, Bool) -> Void)?)
    // 保存到云空间按钮点击，DriveSDK触发保存到云空间，同时通过handler通知业务方，业务方可以在handler进行埋点上报
    // handler参数：DKSaveToSpaceState为点击按钮时保存到云空间按钮的状态
    case saveToSpace(handler: (DKSaveToSpaceState) -> Void)
    // 转发按钮被点击后调用handler由业务方处理转发逻辑
    case forward(handler: (UIViewController, DKAttachmentInfo) -> Void) // 转发
    case saveAlbum(handler: (UIViewController, DKAttachmentInfo) -> Void) // 保存相册
    case saveToFile(handler: (UIViewController, DKAttachmentInfo) -> Void) // 保存到文件
    case saveToLocal(handler: (UIViewController, DKAttachmentInfo) -> Void) // 保存到本地
    // 5.15
    case convertToOnlineFile // 转在线文档
    case customUserDefine(provider: DriveSDKCustomMoreActionProvider)  //用户自定义
}

public enum DriveSDKLocalMoreAction {
    // 使用其他应用打开支持业务自定义
    // customAction为业务提供的自定义事件处理动作，如果为nil，则由DriveSDK弹出其他应用打开面板。
    case openWithOtherApp(customAction: ((UIViewController) -> Void)?)
    public var newMoreAction: DriveSDKMoreAction {
        switch self {
        case let .openWithOtherApp(customAction):
            return .customOpenWithOtherApp(customAction: customAction, callback: nil)
        }
    }
}

extension DriveSDKLocalMoreAction: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (openWithOtherApp(customAction: _), openWithOtherApp(customAction: _)):
            return true
        }
    }
}

public protocol DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> { get }
    var moreMenuEnable: Observable<Bool> { get }
    var actions: [DriveSDKMoreAction] { get }
}

/// 本地文件预览，更多操作依赖
public protocol DriveSDKLocalMoreDependency {
    var moreMenuVisable: Observable<Bool> { get }
    var moreMenuEnable: Observable<Bool> { get }
    var actions: [DriveSDKLocalMoreAction] { get }
}

public protocol DriveSDKCustomMoreActionProvider {
    var actionId: String { get }
    var text: String { get }
    var handler: (UIViewController, DKAttachmentInfo) -> Void { get }
}

public protocol DriveMoreActionProtocol {
    /// 保存到本地
    ///
    /// - Parameters:
    ///   - fileSize: 文件大小
    ///   - fileName： 文件名字
    ///   - fileObjToken:打开文档时，唯一id（文章对应的 URL）
    ///   - sourceController:目前的VC
    func saveToLocal(fileSize: UInt64,
                     fileObjToken: String,
                     fileName: String,
                     sourceController: UIViewController)
    /// 保存到云空间
    ///
    /// - Parameters:
    ///   - fileObjToken:打开文档时，唯一id（文章对应的 URL）
    ///   - fileSize: 文件大小
    ///   - fileName：文件名字
    ///   - sourceController:目前的VC
    func saveToSpace(fileObjToken: String,
                     fileSize: UInt64,
                     fileName: String,
                     sourceController: UIViewController)
    /// 用其他应用打开
    ///
    /// - Parameters:
    ///   - fileSize: 文件大小
    ///   - fileName：文件名字
    ///   - fileObjToken:打开文档时，唯一id（文章对应的 URL）
    ///   - sourceController: 当前的VC
    func openDriveFileWithOtherApp(fileSize: UInt64,
                                   fileObjToken: String,
                                   fileName: String,
                                   sourceController: UIViewController)
    
}
