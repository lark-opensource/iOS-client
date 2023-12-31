//
//  SKCommonBody.swift
//  SKCommon
//
//  Created by lijuyou on 2021/1/18.
//  


import Foundation
import SKResource
import EENavigator

/// 路由到ShareViewControllerV2的Body
public struct SKShareViewControllerBody: PlainBody {
    public static let pattern = "//docs/common/sharevc2"
    public var needPopover: Bool
    public var fileInfo: DocsInfo
    public var router: ShareRouterAbility
    public var shareVersion: Int?
    public var fileParentToken: String?
    public var source: ShareSource
    public var popoverSourceFrame: CGRect?
    public var padPopDirection: UIPopoverArrowDirection
    public var sourceView: UIView?
    public var bizParameter: SpaceBizParameter
    public init(needPopover: Bool,
                fileInfo: DocsInfo,
                router: ShareRouterAbility,
                shareVersion: Int?,
                fileParentToken: String?,
                source: ShareSource,
                popoverSourceFrame: CGRect?,
                padPopDirection: UIPopoverArrowDirection,
                sourceView: UIView?,
                bizParameter: SpaceBizParameter) {
        self.needPopover = needPopover
        self.fileInfo = fileInfo
        self.router = router
        self.shareVersion = shareVersion
        self.fileParentToken = fileParentToken
        self.source = source
        self.popoverSourceFrame = popoverSourceFrame
        self.padPopDirection = padPopDirection
        self.sourceView = sourceView
        self.bizParameter = bizParameter
    }
}


/// 路由到LikeListViewController的Body
public struct LikeListViewControllerBody: PlainBody {

    public static let pattern = "//docs/common/likelistvc"
    public var docInfo: DocsInfo
    public var likeType: DocLikesType
    public weak var listDelegate: LikeListDelegate?
    public weak var hostViewController: UIViewController?

    public init(docInfo: DocsInfo, likeType: DocLikesType, listDelegate: LikeListDelegate?, hostViewController: UIViewController? = nil) {
        self.docInfo = docInfo
        self.likeType = likeType
        self.listDelegate = listDelegate
        self.hostViewController = hostViewController
    }
}

public protocol ExportLongImageProxy: AnyObject {
    func handleExportSheetLongImage(with params: [String: Any])
    func handleExportDocsLongImage()
    func handleExportSheetText()
}

/// 路由到ExportDocumentViewController的Body
public struct ExportDocumentViewControllerBody: PlainBody {
    public static let pattern: String = "//docs/common/exportDocumentvc"
    public var titleText: String
    public var docsInfo: DocsInfo
    public var hostSize: CGSize // 父VC整体宽高
    public var isFromSpaceList: Bool
    public var hideLongPicAlways: Bool //一直隐藏下载为长图按钮
    public var isSheetCardMode: Bool
    public var needFormSheet: Bool
    public weak var hostViewController: UIViewController?
    public var popoverSourceFrame: CGRect?
    public var padPopDirection: UIPopoverArrowDirection?
    public weak var sourceView: UIView?
    public weak var proxy: ExportLongImageProxy?
    private(set) public var containerID: String?
    private(set) public var containerType: String?
    private(set) public var module: PageModule

    // forTracker
    public var isEditor: Bool  //是否拥有文档的编辑权限

    public init(titleText: String = BundleI18n.SKResource.LarkCCM_Docs_DownloadAs_Menu_Mob,
                docsInfo: DocsInfo,
                hostSize: CGSize,
                isFromSpaceList: Bool,
                hideLongPicAlways: Bool = false,
                isSheetCardMode: Bool = false,
                needFormSheet: Bool,
                isEditor: Bool,
                hostViewController: UIViewController?,
                module: PageModule,
                containerID: String?,
                containerType: String?,
                popoverSourceFrame: CGRect? = nil,
                padPopDirection: UIPopoverArrowDirection? = nil,
                sourceView: UIView? = nil,
                proxy: ExportLongImageProxy? = nil) {
        self.titleText = titleText
        self.docsInfo = docsInfo
        self.hostSize = hostSize
        self.isFromSpaceList = isFromSpaceList
        self.hideLongPicAlways = hideLongPicAlways
        self.isSheetCardMode = isSheetCardMode
        self.needFormSheet = needFormSheet
        self.isEditor = isEditor
        self.hostViewController = hostViewController
        self.popoverSourceFrame = popoverSourceFrame
        self.padPopDirection = padPopDirection
        self.sourceView = sourceView
        self.proxy = proxy
        self.module = module
        self.containerID = containerID
        self.containerType = containerType
    }
}
