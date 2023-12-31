//
// Created by duanxiaochen.7 on 2021/2/7.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKCommon
import LarkAppConfig
import HandyJSON
import SKInfra

//用于封装sheet自定义navibar的item信息
struct SheetNaviItemInfo: HandyJSON {
    // 删除了`imageID`属性，因为已经与前端同学@zhangzhe.zadd确认了"biz.navigation.showTitle"没有传图片名过来
    var id: String = ""
    var text: String = ""
    var callback: (() -> Void)?
}

struct SheetNaviInfo: HandyJSON {
    var titleItem: SheetNaviItemInfo?
    var rightItem: [SheetNaviItemInfo] = []
    var callback: String = ""
}

struct SheetImageInfo: HandyJSON {
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
}

public enum SheetShareType: String, HandyJSONEnum {
    case image
    case text
}

enum GenerateImageType {
    case preview
    case alert
}

enum ReveiveImageStatus: Int {
    case idle
    case writing
}

struct SheetSnapshotAlertInfo {
    init(title: String, messages: String) {
        self.title = title
        self.messages = messages
    }

    var title: String
    var messages: String
    var imageInfo: SheetImageInfo?
    var options: [String: Any] = [:]
    var callback: String = ""
}

extension SheetShareManager {
    
    enum ExportFailType: String {
        case cancatImage
        case stopTransfer
        case waitTimeout
        case permissionDenied
        // 遗漏补充
        case others
    }

    func convertOpItem(from assistType: ShareAssistType) -> String {
        switch assistType {
        case .feishu:
            return DomainConfig.envInfo.isFeishuPackage ? "feishu" : "lark"
        case .qq:
            return "qq"
        case .weibo:
            return "weibo"
        case .wechat:
            return "wechat"
        case .wechatMoment:
            return "wechat_moment"
        case .saveImage:
            return "local"
        default:
            return "undefined"
        }
    }

    // 根据是否在卡片视图下，做不同的埋点操作
    func trackIfInCard(_ cardTracking: () -> Void, else exportTracking: () -> Void) {
        if ["cardview", "cardview_panel"].contains(source) {
            cardTracking()
        } else {
            exportTracking()
        }
    }

    func makeTrack(isCard: Bool, action: String, opItem: String?, errMsg: String? = nil) {
        var trackParams = makeTrackBaseInfo()
        trackParams["action"] = action
        trackParams["op_item"] = opItem
        trackParams[isCard ? "mode" : "source"] = source
        trackParams["scm_version"] = GeckoPackageManager.shared.currentVersion(type: .webInfo)
        if let msg = errMsg {
            trackParams["errorMsg"] = msg
        }
        DocsTracker.log(enumEvent: .sheetOperation, parameters: trackParams)
    }

    func makeTrackBaseInfo() -> [String: Any] {
        return self.delegate?.trackBaseInfo() ?? [:]
    }

    func cancatImageFailue() {
        reportFail(type: .stopTransfer)
    }
    
    func reportFail(type: ExportFailType, errMsg: String? = nil) {
        source = type.rawValue
        makeTrack(isCard: false, action: "export_image_fail", opItem: nil, errMsg: errMsg)
    }
}
