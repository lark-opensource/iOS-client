//
//  AttachmentPreviewProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/11/2.
//

import Foundation
import RxSwift

public enum docsTypes: Int {
    case file = 12
}

public struct DKAttachmentInfo {
    public let fileID: String
    public let name: String
    public let type: String
    public let size: UInt64
    public var localPath: URL? // 本地路径，已下载的附件才会有本地路径
    public init(fileID: String, name: String, type: String, size: UInt64, localPath: URL? = nil) {
        self.fileID = fileID
        self.name = name
        self.type = type
        self.size = size
        self.localPath = localPath
    }
    
    public var driveInfo: DriveAttachmentInfo {
        return DriveAttachmentInfo(token: fileID, name: name, type: type, size: size, localPath: localPath)
    }
}

public struct DriveAttachmentInfo: Equatable {
    public let token: String
    public let name: String
    public var type: String
    public var size: UInt64
    public var localPath: URL? // 本地路径，已下载的附件才会有本地路径
    public init(token: String, name: String, type: String, size: UInt64, localPath: URL? = nil) {
        self.token = token
        self.name = name
        self.type = type
        self.size = size
        self.localPath = localPath
    }

    static func localAuditInfo(localPath: String, info: DriveAttachmentInfo) -> DriveAttachmentInfo {
        var name = info.name
        if !name.hasSuffix(".\(info.type)") {
            name = name + ".\(info.type)"
        }
        return DriveAttachmentInfo(token: localPath,
                                   name: name,
                                   type: info.type,
                                   size: info.size,
                                   localPath: URL(string: localPath))
    }
}

public protocol DriveSDKCustomMoreActionProvider {
    var actionId: String { get }
    var text: String { get }
    var handler: (UIViewController, DKAttachmentInfo) -> Void { get }
}

public struct CustomMoreActionProviderImpl: DriveSDKCustomMoreActionProvider {
    public var actionId: String
    public var text: String
    public var handler: (UIViewController, DKAttachmentInfo) -> Void
    public init(actionId:String, text:String, handler:@escaping (UIViewController, DKAttachmentInfo) -> Void) {
        self.actionId = actionId
        self.text = text
        self.handler = handler
    }
}

//public class DriveActionImpl: DriveMoreActionProtocol {
//    func saveToLocal(fileSize: UInt64,
//                            fileObjToken: String,
//                            fileName: String,
//                            sourceController: UIViewController) {
//
//    }
//    func saveToSpace(fileSize: UInt64,
//                     fileObjToken: String,
//                     fileName: String,
//                     sourceController: UIViewController) {
//
//    }
//
//    func openDriveFileWithOtherApp(fileSize: UInt64,
//                                   fileObjToken: String,
//                                   fileName: String,
//                                   sourceController: UIViewController) {
//
//    }
//}

public enum DriveAlertVCAction {
    case openWithOtherApp(callback: ((DriveAttachmentInfo, String, Bool) -> Void)?)
    case saveToSpace // 保存到云盘
    case forward(handler: (UIViewController, DriveAttachmentInfo) -> Void) // 转发
    case saveToLocal(handler: (UIViewController, DriveAttachmentInfo) -> Void) // 保存到文件
    case customUserDefine(impl: CustomMoreActionProviderImpl)  //用户自定义

}

public struct DriveLocalFileEntity {
    public let fileURL: URL //本地文件的路径
    public let name: String? //预览时展示的文件名，不传则会通过path截取
    public let fileType: String? //根据这个后缀名预览，不传则会通过path名截取后缀名
    public let canExport: Bool //是否可以通过第三方应用打开
    public let actions: [DriveAlertVCAction]

    public init(fileURL: URL, name: String?, fileType: String?, canExport: Bool, fileID: String? = nil, actions: [DriveAlertVCAction]) {
        self.fileURL = fileURL
        self.name = name
        self.fileType = fileType
        self.canExport = canExport
        self.actions = actions
    }
}

public enum MailDriveSDKUIAction {
    /// 在预览界面展示一个banner
    ///  参数
    ///  banner: UIView  业务自定义的banner样式，业务自己响应banner交互逻辑，DriveSDK负责把banner视图展示在预览界面
    ///  bannerID:  用于唯一表示banner，如果存在多个banner，通过bannerID 处理对应的banner， 只需要在一次预览过程中唯一即可
    case showBanner(banner: UIView, bannerID: String)
    ///  关闭banner
    ///  参数
    ///  bannerID: 如果业务展示了多个banner，可以通过bannerID唯一表示关闭哪一个banner
    case hideBanner(bannerID: String)
}

public struct DriveThirdPartyFileEntity {
    public let fileToken: String // 文件token
    public let docsType: Int // docs文档类型  .file = 12
    public let mountNodePoint: String? // optional String 父节点token，有的话就传
    public let mountPoint: String // 挂载点，mail为“email”
    // 文件类型，多文件预览，当前设置了subType，且是图片才支持滑动切换，后续再开放其他类型
    public let fileType: String?
    public let authExtra: String? // 透传给业务方后端鉴权用，根据业务需要传递
    public let actions: [DriveAlertVCAction]

    public var handleBizPermission: (PublishSubject<MailDriveSDKUIAction>) -> (([String: Any]) -> Void)?

    public init(fileToken: String,
                docsType: docsTypes,
                mountNodePoint: String?,
                mountPoint: String,
                fileType: String? = nil,
                authExtra: String? = nil,
                actions: [DriveAlertVCAction],
                handleBizPermission: @escaping (PublishSubject<MailDriveSDKUIAction>) -> (([String: Any]) -> Void)?) {
        self.fileToken = fileToken
        self.docsType = docsType.rawValue
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.fileType = fileType
        self.authExtra = authExtra
        self.actions = actions
        self.handleBizPermission = handleBizPermission
    }
}

/*
 public struct DriveThirdPartyAttachControllerBody: PlainBody {
     public static let pattern = "//client/drive/preview/thirdparty"
     public let files: [DriveThirdPartyFileEntity] // 文件列表信息，目前只支持单文件预览，使用 list用于后续扩展
     public let index: Int // 当前文件index
     public let actions: [DriveAlertVCAction] // 右上角更多按钮选项
     public let bussinessId: String // 比如 "mail",require，业务标记，上报用
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

 public struct DriveLocalFileControllerBody: PlainBody {
     public static let pattern = "//client/drive/preview/local"
     public let files: [DriveLocalFileEntity] // 文件信息列表
     public let index: Int // 当前文件Index
     public init(files: [DriveLocalFileEntity], index: Int) {
         self.files = files
         self.index = index
     }
 }
 */

public protocol AttachmentPreviewProxy {
    func driveThirdPartyActtachController(files: [DriveThirdPartyFileEntity],
                                          index: Int,
                                          from: UIViewController)
    
    func driveLocalFileController(files: [DriveLocalFileEntity], index: Int, from: UIViewController)
    
    func saveToLocal(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController)
    
    func openDriveFileWithOtherApp(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController)
    
    func saveToSpace(fileObjToken: String, fileSize: UInt64, fileName: String, sourceController: UIViewController)

}
