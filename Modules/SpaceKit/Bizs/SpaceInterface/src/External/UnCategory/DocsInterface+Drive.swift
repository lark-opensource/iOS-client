//
//  DocsInterface+Drive.swift
//  SpaceInterface
//
//  Created by bupozhuang on 2019/7/29.
//

import EENavigator
import UIKit

/// 第三方附件预览更多操作
public enum DriveAlertVCAction {
    case openWithOtherApp
    // 使用其他应用打开支持业务自定义
    // customAction为业务提供的自定义事件处理动作，如果为nil，则由DriveSDK弹出其他应用打开面板。
    case customOpenWithOtherApp(customAction: ((UIViewController) -> Void)?)
    case saveToSpace // 保存到云盘
    case forward(handler: (UIViewController, DriveAttachmentInfo) -> Void) // 转发
    case saveAlbum(handler: (UIViewController, DriveAttachmentInfo) -> Void) // 保存相册
    case saveToFile(handler: (UIViewController, DriveAttachmentInfo) -> Void) // 保存到文件
    case customUserDefine(provider: DriveSDKCustomMoreActionProvider) // 用户自定义行为
    
    public var sdkMoreAction: DriveSDKMoreAction {
        switch self {
        case .openWithOtherApp:
            return .customOpenWithOtherApp(customAction: nil, callback: nil)
        case let .customOpenWithOtherApp(customAction):
            return .customOpenWithOtherApp(customAction: customAction, callback: nil)
        case .saveToSpace:
            return .saveToSpace(handler: { _ in })
        case let .saveAlbum(handler):
            return .saveAlbum(handler: { vc, info in
                let driveAttachInfo = info.driveInfo
                handler(vc, driveAttachInfo)
            })
        case let .forward(handler):
            return .forward { (vc, info) in
                let driveAttachInfo = info.driveInfo
                handler(vc, driveAttachInfo)
            }
        case let .saveToFile(handler):
            return .saveToFile { (vc, info) in
                let driveAttachInfo = info.driveInfo
                handler(vc, driveAttachInfo)
            }
        case let .customUserDefine(provider):
            return .customUserDefine(provider: provider)
        }
    }
}

public struct DriveAttachmentInfo {
    public let token: String
    public let name: String
    public let type: String
    public let size: UInt64
    public var localPath: URL? // 本地路径，已下载的附件才会有本地路径
    public init(token: String, name: String, type: String, size: UInt64, localPath: URL? = nil) {
        self.token = token
        self.name = name
        self.type = type
        self.size = size
        self.localPath = localPath
    }
}

public struct DriveLocalFileEntity {
    public let fileURL: URL //本地文件的路径
    public let name: String? //预览时展示的文件名，不传则会通过path截取
    public let fileType: String? //根据这个后缀名预览，不传则会通过path名截取后缀名
    public let canExport: Bool //是否可以通过第三方应用打开
    public let fileID: String? // 本地文件的标识，用于审计上报
    /// Deprecated: 更多按钮支持的选项，目前本地文件只支持使用其他应用打开（该属性未来会弃用）
    @available(*, deprecated, message: "use DriveSDKLocalPreviewDependency.moreDependency instead")
    public let moreActions: [DriveSDKLocalMoreAction]
    public let dependency: DriveSDKLocalPreviewDependency
    
    @available(*, deprecated, message: "请使用带 DriveSDKLocalPreviewDependency 的接口")
    public init(fileURL: URL, name: String?, fileType: String?, canExport: Bool, fileID: String? = nil) {
        self.fileURL = fileURL
        self.name = name
        self.fileType = fileType
        self.canExport = canExport
        self.fileID = fileID
        self.moreActions = canExport ? [.openWithOtherApp(customAction: nil)] : []
        self.dependency = DriveSDKLocalPreviewDependencyDefaultImpl()
    }
    
    @available(*, deprecated, message: "请使用带 DriveSDKLocalPreviewDependency 的接口")
    public init(fileURL: URL, name: String?, fileType: String?, moreActons: [DriveSDKLocalMoreAction], fileID: String? = nil) {
        self.fileURL = fileURL
        self.name = name
        self.fileType = fileType
        self.fileID = fileID
        self.moreActions = moreActons
        self.canExport = moreActions.contains(.openWithOtherApp(customAction: nil))
        self.dependency = DriveSDKLocalPreviewDependencyDefaultImpl()
    }
    
    public init(fileURL: URL, name: String?, fileType: String?, canExport: Bool, fileID: String? = nil, dependency: DriveSDKLocalPreviewDependency) {
        self.fileURL = fileURL
        self.name = name
        self.fileType = fileType
        self.canExport = canExport
        self.fileID = fileID
        moreActions = canExport ? [.openWithOtherApp(customAction: nil)] : []
        self.dependency = dependency
    }
    
    public init(fileURL: URL, name: String?, fileType: String?, fileID: String? = nil, dependency: DriveSDKLocalPreviewDependency) {
        self.fileURL = fileURL
        self.name = name
        self.fileType = fileType
        self.fileID = fileID
        self.moreActions = dependency.moreDependency.actions
        self.canExport = dependency.moreDependency.actions.contains(.openWithOtherApp(customAction: nil))
        self.dependency = dependency
    }
}

public struct DriveThirdPartyFileEntity {
    public let fileToken: String // 文件token
    public let docsType: Int // docs文档类型  .file = 12
    public let mountNodePoint: String? // optional String 父节点token，有的话就传
    public let mountPoint: String // 挂载点，mail为“email”
    // 文件类型，多文件预览，当前设置了subType，且是图片才支持滑动切换，后续再开放其他类型
    public let fileType: String?
    public let authExtra: String? // 透传给业务方后端鉴权用，根据业务需要传递
    public init(fileToken: String,
                docsType: Int,
                mountNodePoint: String?,
                mountPoint: String,
                fileType: String? = nil,
                authExtra: String? = nil) {
        self.fileToken = fileToken
        self.docsType = docsType
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.fileType = fileType
        self.authExtra = authExtra
    }
}

public struct DriveLocalFileControllerBody: PlainBody {
    public static let pattern = "//client/drive/preview/local"
    public let files: [DriveLocalFileEntity] // 文件信息列表
    public let index: Int // 当前文件Index
    public init(files: [DriveLocalFileEntity], index: Int) {
        self.files = files
        self.index = index
    }
}

public struct DriveThirdPartyAttachControllerBody: PlainBody {
    public static let pattern = "//client/drive/preview/thirdparty"
    public let files: [DriveThirdPartyFileEntity] // 文件列表信息，目前只支持单文件预览，使用 list用于后续扩展
    public let index: Int // 当前文件index
    public let actions: [DriveAlertVCAction] // 右上角更多按钮选项
    public let bussinessId: String // 比如 "mail",require，业务标记，上报用
    public var isInVCFollow: Bool = false //是否在VCFollow情况下
    public init(files: [DriveThirdPartyFileEntity],
                index: Int,
                actions: [DriveAlertVCAction] = [.openWithOtherApp, .saveToSpace],
                bussinessId: String) {
        self.files = files
        self.index = index
        self.actions = actions
        self.bussinessId = bussinessId
    }
}
