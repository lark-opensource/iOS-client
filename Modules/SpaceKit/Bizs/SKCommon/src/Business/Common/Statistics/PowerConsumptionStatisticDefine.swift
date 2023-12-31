//
//  PowerConsumptionStatisticDefine.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/12.
//  


import Foundation

public enum PowerConsumptionStatisticScene {
    
    public enum Page {
        case home
        case wiki
        case template
    }
    
    // contextViewId 表示容器视图的唯一标识，因为存在ipad分屏场景(不同vc实例打开同一篇doc或drive)
    
    case docView(contextViewId: String)
    
    case bitableCardView(contextViewId: String)
    
    case bitableFormView(contextViewId: String)
    
    case driveView(contextViewId: String)
    
    case specifiedPage(page: Page, contextViewId: String)
    
    /// MS小窗
    case floatingWindow
    
    case docScroll(contextViewId: String)
    
    /// 视频会议过程
    case videoConference
    
    /// 会议共享文档
    case magicShare
    
    public var name: String {
        switch self {
        case .docView:
            return "ccm_docs_view"
        case .bitableCardView:
            return "bitable_show_card"
        case .bitableFormView:
            return "bitable_show_form"
        case .driveView:
            return "ccm_drive_view"
        case .specifiedPage(let page, _):
            switch page {
            case .home:
                return "ccm_list_home"
            case .wiki:
                return "ccm_list_wiki"
            case .template:
                return "ccm_template_center"
            }
        case .floatingWindow:
            return "ccm_ms_floating_window"
        case .docScroll:
            return "ccm_docs_fling"
        case .videoConference:
            return "vc_meeting"
        case .magicShare:
            return "vc_magicshare"
        }
    }
    
    public var identifier: String {
        switch self {
        case .docView(let viewId):
            return name + "@" + viewId
        case .bitableCardView(let viewId):
            return name + "@" + viewId
        case .bitableFormView(let viewId):
            return name + "@" + viewId
        case .driveView(let viewId):
            return name + "@" + viewId
        case .specifiedPage(_, let viewId):
            return name + "@" + viewId
        case .floatingWindow, .videoConference, .magicShare:
            return name // 全局一个，不需要viewId
        case .docScroll(let viewId):
            return name + "@" + viewId
        }
    }
    
    /// 是doc或drive滚动的场景
    static func isScrollScene(_ identifier: String) -> Bool {
        if identifier.hasPrefix(Self.docScroll(contextViewId: "").name) {
            return true
        }
        return false
    }
    
    /// 是doc或drive浏览的场景
    func isViewScene() -> Bool {
        switch self {
        case .docView, .driveView:
            return true
        case .bitableCardView, .bitableFormView, .specifiedPage, .docScroll,
             .floatingWindow, .videoConference, .magicShare:
            return false
        }
    }
}

public struct PowerConsumptionStatisticParamKey {
    
    public static var docType: String { "docType" } // String
    
    public static var isForeground: String { "app_visible" } // Bool
    
    public static var msWebviewReuseFG: String { "ms_webview_reuse_fg" } // Bool
    
    public static var msWebviewReuseAB: String { "ms_webview_reuse_ab" } // Bool
    
    public static var isUserScroll: String { "isUserScroll" } // Bool, 是用户主动滑动还是MS的被动滑动
    
    public static var startNetLevel: String { "startNetLevel" } // Int, 起始的网络等级
    public static var endNetLevel: String { "endNetLevel" } // Int, 结束的网络等级
    
    public static var fepkgVersion: String { "fepkg_version" } // String, 前端包版本号
    public static var fepkgIsSlim: String { "fepkg_is_slim" } // Bool, 前端包是否是精简包
    
    public static var encryptedId: String { "encryptedToken" } // String
    
    public static var clientVarSize: String { "clientVarSize" } // Int
    
    public static var blockCount: String { "blockCount" } // Int
    
    public static var fileType: String { "fileType" } // String
    
    public static var fileSize: String { "fileSize" } // Int (bytes)
    
    public static var isInVC: String { "isInVideoConference" } // Bool
    
    public static var appId: String { "appId" } // String, drive的业务方appId
    
    public static var mediaType: String { "mediaType" } // String
    
    public static var evaluateJSOptEnable: String { "evaluateJSOptEnable" } // Bool
    
    public static var dateFormatOptEnable: String { "dateFormatOptEnable" } // Bool
    
    public static var fePkgFilePathsMapOptEnable: String { "fePkgFilePathsMapOptEnable" } // Bool
    
    public static var vcPowerDowngradeEnable: String { "vcPowerDowngradeEnable" } // Bool
}

public struct PowerConsumptionStatisticEventName {
    
    public static var assetBrowseEnter: String { "ccm_assetbrowse_enter" }
    public static var assetBrowseLeave: String { "ccm_assetbrowse_leave" }
    
//    public static let drivePreviewEnter = "ccm_drivepreview_enter"
//    public static let drivePreviewLeave = "ccm_drivepreview_leave"
    
    public static var driveMeidaPlayStart: String { "ccm_drive_meidaplay_start" }
    public static var driveMeidaPlayStop: String { "ccm_drive_meidaplay_stop" }
    
    public static var commentShow: String { "ccm_comment_show" }
    public static var commentDismiss: String { "ccm_comment_dismiss" }
}
