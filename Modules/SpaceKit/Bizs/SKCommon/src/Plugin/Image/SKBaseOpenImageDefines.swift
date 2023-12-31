//
//  SKBaseOpenImageDefines.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/23.
//

import Foundation
import LarkUIKit
import SpaceInterface
import SKFoundation
import UniverseDesignDialog

public typealias PhotoUUID = String

public struct OpenImageData: Codable {
    public let showImageData: ShowPositionData? //定位图片
    public let imageList: [PhotoImageData] //图片列表
    public let callback: String?
    public let toolStatus: PhotoToolStatus? //控件栏展示状态

    public init(showImageData: ShowPositionData?, imageList: [PhotoImageData], toolStatus: PhotoToolStatus?, callback: String?) {
        self.showImageData = showImageData
        self.imageList = imageList
        self.toolStatus = toolStatus
        self.callback = callback
    }

    private enum CodingKeys: String, CodingKey {
        case showImageData = "image"
        case imageList = "image_list"
        case toolStatus = "tool_status"
        case callback = "callback"
    }
    
    public func equalsTo(_ other: OpenImageData) -> Bool {
        //忽略callback进行对比
        return self.showImageData == other.showImageData &&
        self.imageList == other.imageList &&
        self.toolStatus == other.toolStatus
    }
}

public struct PhotoToolStatus: Codable, Equatable, CustomStringConvertible {
    public let comment: Bool?  //是否可以评论
    public let copy: Bool? //是否可以复制
    public let delete: Bool? //是否可以删除
    public let export: Bool? //是否可以导出,前端使用这个点位来控制是否可以下载图片

    public init(comment: Bool?, copy: Bool?, delete: Bool?, export: Bool?) {
        self.comment = comment
        self.copy = copy
        self.delete = delete
        self.export = export
    }
    
    public static func == (lhs: PhotoToolStatus, rhs: PhotoToolStatus) -> Bool {
        return lhs.comment == rhs.comment &&
        lhs.copy == rhs.copy &&
        lhs.delete == rhs.delete &&
        lhs.export == rhs.export
    }
    
    public var description: String {
        return "[copy:\(String(describing: copy)),comment:\(String(describing: comment)),delete:\(String(describing: delete)),export:\(String(describing: export))]"
    }
}

extension PhotoUUID {
    public var isDiagramSVG: Bool {
        return self.contains(SKPhotoType.diagramSVG.rawValue)
    }
}

public struct ShowPositionData: Codable, Equatable {
    public let uuid: PhotoUUID?
    public let src: String? // 缩率图地址(定位图片可能为空)
    public let originalSrc: String? // 原图地址
    public var position: PhotoPosition? //图片展示的位置，不是所有图片都需要，一般是定位展示的图片会带上
    public let subToolStatus: PhotoToolStatus? //控件栏展示状态
    public let crop: [CGFloat]? //裁剪范围
    public let srcObjToken: String? //图片对应源文档token（如sync block或base block场景）
    public let srcObjType: Int? //图片对应源文档type（如sync block或base block场景）
    
    //图片Block对应的docsInfo (宿主文档或block)
    public var imageDocsInfo: DocsInfo? {
        if UserScopeNoChangeFG.LJY.enableSyncBlock, let srcObjToken = srcObjToken, let srcObjType = srcObjType {
            return DocsInfo(type: DocsType(rawValue: srcObjType), objToken: srcObjToken)
        }
        return nil
    }

    public init(uuid: PhotoUUID?,
                src: String,
                originalSrc: String?,
                position: PhotoPosition?,
                subToolStatus: PhotoToolStatus? = nil,
                crop: [CGFloat]? = nil,
                srcObjToken: String? = nil,
                srcObjType: Int? = nil) {
        self.uuid = uuid
        self.src = src
        self.originalSrc = originalSrc
        self.position = position
        self.subToolStatus = subToolStatus
        self.crop = crop
        self.srcObjToken = srcObjToken
        self.srcObjType = srcObjType
    }

    private enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case src = "src"
        case originalSrc = "originalSrc"
        case position = "position"
        case subToolStatus = "single_tool_status"
        case crop = "crop"
        case srcObjToken = "srcObjToken"
        case srcObjType = "srcObjType"
    }
    
    public static func == (lhs: ShowPositionData, rhs: ShowPositionData) -> Bool {
        return lhs.uuid == rhs.uuid &&
        lhs.src == rhs.src &&
        lhs.originalSrc == rhs.originalSrc &&
        lhs.position == rhs.position &&
        lhs.subToolStatus == rhs.subToolStatus
    }
    
    public func toPhotoImageData() -> PhotoImageData {
        PhotoImageData(uuid: self.uuid,
                       src: self.src ?? "",
                       originalSrc: self.originalSrc,
                       token: nil, //缺少token
                       subToolStatus: self.subToolStatus,
                       crop: self.crop,
                       srcObjToken: self.srcObjToken,
                       srcObjType: self.srcObjType)
    }
}

public struct PhotoImageData: Codable, Equatable {
    public let uuid: PhotoUUID?
    public let src: String // 缩率图地址
    public let originalSrc: String? // 原图地址
    public let token: String? //图片Token
    public let subToolStatus: PhotoToolStatus? //控件栏展示状态
    public let crop: [CGFloat]? //裁剪范围
    public let srcObjToken: String? //图片对应源文档token（如sync block或base block场景）
    public let srcObjType: Int? //图片对应源文档type（如sync block或base block场景）
    public let sourceInfo: SourceInfo?
    
    //图片Block对应的docsInfo (宿主文档或block)
    public var imageDocsInfo: DocsInfo? {
        guard UserScopeNoChangeFG.LJY.enableSyncBlock else { return nil }
        if let srcObjToken = sourceInfo?.token, let srcObjType = sourceInfo?.type {
            return DocsInfo(type: DocsType(rawValue: srcObjType), objToken: srcObjToken)
        }
        if let srcObjToken = srcObjToken, let srcObjType = srcObjType {
            return DocsInfo(type: DocsType(rawValue: srcObjType), objToken: srcObjToken)
        }
        return nil
    }

    public init(uuid: PhotoUUID?,
                src: String,
                originalSrc: String?,
                token: String? = "",
                subToolStatus: PhotoToolStatus? = nil,
                crop: [CGFloat]? = nil,
                srcObjToken: String? = nil,
                srcObjType: Int? = nil,
                sourceInfo: SourceInfo? = nil) {
        self.uuid = uuid
        self.src = src
        self.token = token
        self.originalSrc = originalSrc
        self.subToolStatus = subToolStatus
        self.crop = crop
        self.srcObjToken = srcObjToken
        self.srcObjType = srcObjType
        self.sourceInfo = sourceInfo
    }

    private enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case src = "src"
        case originalSrc = "originalSrc"
        case token = "token"
        case subToolStatus = "single_tool_status"
        case crop = "crop"
        case srcObjToken = "srcObjToken"
        case srcObjType = "srcObjType"
        case sourceInfo = "sourceInfo"
    }
    
    public static func == (lhs: PhotoImageData, rhs: PhotoImageData) -> Bool {
        return lhs.uuid == rhs.uuid &&
        lhs.src == rhs.src &&
        lhs.originalSrc == rhs.originalSrc &&
        lhs.token == rhs.token &&
        lhs.subToolStatus == rhs.subToolStatus &&
        lhs.srcObjToken == rhs.srcObjToken &&
        lhs.srcObjType == rhs.srcObjType
    }
}

public struct SourceInfo: Codable{
    let token: String
    let type: Int
    public init(token: String, type: Int) {
        self.token = token
        self.type = type
    }
}

public struct PhotoPosition: Codable, Equatable {
    public init(height: CGFloat, width: CGFloat, x: CGFloat, y: CGFloat) {
        self.height = height
        self.width = width
        self.x = x
        self.y = y
    }
    
    let height: CGFloat
    let width: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    public static func == (lhs: PhotoPosition, rhs: PhotoPosition) -> Bool {
        return lhs.height == rhs.height &&
        lhs.width == rhs.width &&
        lhs.x == rhs.x &&
        lhs.y == rhs.y
    }
}

public enum SKPhotoType: String {
    case normal = "image_"
    case diagramSVG = "diagram_"

    public var statisticsValue: String {
        switch self {
        case .normal:
            return "image"
        case .diagramSVG:
            return "diagram"
        }
    }
}

//因为每次切换图片都要查询权限，缓存起来相关权限
public struct OpenImagePermission: CustomStringConvertible {
    public var canCopy: Bool
    public var canShowDownload: Bool
    public var canDownloadDoc: Bool
    public var canDownloadAttachment: Bool
    
    public init(canCopy: Bool, canShowDownload: Bool, canDownloadDoc: Bool, canDownloadAttachment: Bool) {
        self.canCopy = canCopy
        self.canShowDownload = canShowDownload
        self.canDownloadDoc = canDownloadDoc
        self.canDownloadAttachment = canDownloadAttachment
    }
    
    public var description: String {
        return "[copy:\(canCopy),showDownload:\(canShowDownload),downloadDoc:\(canDownloadDoc),downloadAttachment:\(canDownloadAttachment)]"
    }
}

public struct LarkActionSheetItem {
    var title: String
    var action: () -> Void
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}


public enum DiagramActionType: String {
    case downloadDiagramPhoto // 下载Diagram照片
    case shareDiagramPhoto //分享Diagram照片
}

public final class PhotoCommentData {
    public var comments = [Comment]()
    public var commentable: Bool = false
    public var currentPage = 0
    public init() {
    }
}

public struct DeleteAlertInfo {
    public var deletedAlertDialog: UDDialog?
    public var tempImgList: [PhotoImageData]?
    public var tempAssects: [LKDisplayAsset]?

    public mutating func clearInfo() {
        deletedAlertDialog = nil
        tempImgList = nil
        tempAssects = nil
    }
    public init() {
    }
}

extension LKDisplayAsset {
    private static var imageDocsInfoKey: UInt8 = 0
    /// 图片Block对应的docsInfo (宿主文档或block)
    var imageDocsInfo: DocsInfo? {
        get {
            return objc_getAssociatedObject(self, &LKDisplayAsset.imageDocsInfoKey) as? DocsInfo
        }
        set {
            objc_setAssociatedObject(self, &LKDisplayAsset.imageDocsInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public typealias AssetBrowserActionDelegate = AssetBrowserActionShareDelegate &
    AssetBrowserActionHubDelegate &
    AssetBrowserActionStatisticsDelegate &
    SKAssertBrowserVCActionDelegate & AssetBrowserActionsDelegate & AssetBrowserActionRequestDiagramDataDelegate
public typealias PhotoCommentDelegate = PhotoCommentActionDelegate & PhotoCommentActionStatisticsDelegate

// - MARK: 图片查看器事件处理的代理
public protocol AssetBrowserActionShareDelegate: AnyObject {
    func shareItem(with type: SKPhotoType, image: UIImage?, uuid: String)
}

public protocol AssetBrowserActionHubDelegate: AnyObject {
    func showFailHub(message: String)
    func showSuccessHub(message: String)
    func showTipHub(message: String)
}

public protocol AssetBrowserActionStatisticsDelegate: AnyObject {
    func assetBrowserAction(_ assetBrowserAction: AssetBrowserActionHandler, statisticsAction: String)
    func assetBrowserActionSaveImageStatistics(uuid: String)
}

public protocol AssetBrowserActionRequestDiagramDataDelegate: AnyObject {
    func requestDiagramDataWith(uuid: String)
}

// - MARK: 图片查看器评论的代理
public protocol PhotoCommentActionDelegate: AnyObject {
    func showComment(with uuid: PhotoUUID)
    func commentable(with uuid: PhotoUUID) -> Bool
    func commentCount(with uuid: PhotoUUID) -> Int
}

public protocol PhotoDeleteActionDelegate: AnyObject {
    func deleteImg(with uuid: PhotoUUID)
}

public protocol PhotoEditActionDelegate: AnyObject {
    func clickEdit(photoToken: String, uuid: String)
}

public protocol PhotoCommentActionStatisticsDelegate: AnyObject {
    func docsAssetBrowser(_ docsAssetBrowserVC: DocsAssetBrowserViewController, statisticsAction: String)
}

public protocol PhotoBrowserOrientationDelegate: AnyObject {
    func docsAssetBrowserTrackForOrientationDidChange(_ docsAssetBrowserVC: DocsAssetBrowserViewController) -> DocsInfo?
}
