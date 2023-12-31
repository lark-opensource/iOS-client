//
//  AdjustSettingsLynxViewController.swift
//  SKCommon
//
//  Created by peilongfei on 2023/4/25.
//  


import SKFoundation
import SKResource
import SKUIKit
import BDXServiceCenter
import LarkUIKit
import UniverseDesignColor
import UniverseDesignDialog
import BDXBridgeKit
import LarkReleaseConfig
import LarkLocalizations
import EENavigator
import SKInfra
import SwiftyJSON
import SpaceInterface

enum AdjustSettingsSceneType {
    /// 邀请外部协作者
    case inviteExternalMember(String)
    /// 邀请为关联组织成员的外部协作者
    case inviteExternalPartnerTenantMember
    /// 加密链接分享
    case passwordShare
    /// 微信分享
    case wechatShare
    /// 朋友圈分享
    case momentsShare
    /// QQ分享
    case qqShare
    /// 微博分享
    case weiboShare
    /// 链接分享
    case linkShare
    /// 权限设置
    case permissionSettings
    /// 对外分享
    case externalShare
    /// IM分享外部协作者
    case imShareExternalMember(String)
    /// IM分享关联组织协作者
    case imShareExternalPartnerTenantMember
    /// 日历文档卡片
    case calenderDocCard

    var rawValue: Int {
        switch self {
        case .inviteExternalMember:
            return 0
        case .inviteExternalPartnerTenantMember:
            return 1
        case .passwordShare:
            return 2
        case .wechatShare:
            return 3
        case .momentsShare:
            return 4
        case .qqShare:
            return 5
        case .weiboShare:
            return 6
        case .linkShare:
            return 7
        case .permissionSettings:
            return 8
        case .externalShare:
            return 9
        case .imShareExternalMember:
            return 10
        case .imShareExternalPartnerTenantMember:
            return 11
        case .calenderDocCard:
            return 19
        }
    }
}

enum AdjustSettingsResult: Int {
    /// 成功
    case success = 1
    /// 失败
    case fail
    /// 审核中
    case approval
    /// 取消
    case cancel
    /// 受到除自身约束和密级约束外的管控
    case otherConstraint
    /// 无可用密级
    case noUsableSecLabel
    /// entityType传错
    case entityTypeError
}

class AdjustSettingsLynxViewController: SKLynxPanelController {

    var callback: ((AdjustSettingsResult) -> Void)?

    weak var followAPIDelegate: BrowserVCFollowDelegate?

    init(token: String,
         type: ShareDocsType,
         sceneType: AdjustSettingsSceneType,
         shareExternalReason: Int,
         sharePartnerTenantReason: Int,
         isWiki: Bool,
         wikiToken: String?,
         statisticParams: [String: Any]?,
         followAPIDelegate: BrowserVCFollowDelegate?,
         callback: @escaping ((AdjustSettingsResult) -> Void)) {
        self.followAPIDelegate = followAPIDelegate
        self.callback = callback
        let params = [
            "token": token,
            "type": type.rawValue,
            "sceneType": sceneType.rawValue,
            "entityType": 0,
            "isWiki": isWiki,
            "wikiToken": wikiToken,
            "shareExternalReason": shareExternalReason,
            "sharePartnerTenantReason": sharePartnerTenantReason,
            "statisticParams": statisticParams
        ] as [String : Any]
        var logInfo = params
        let encryptToken = (params["token"] as? String)?.encryptToken
        let encryptWikiToken = (params["wikiToken"] as? String)?.encryptToken
        logInfo["token"] = encryptToken
        logInfo["wikiToken"] = encryptWikiToken
        DocsLogger.info("AdjustSettingsLynxViewController initialProperties", extraInfo: logInfo)

        super.init(templateRelativePath: "pages/adjust-settings-panel/template.js", initialProperties: params)

        modalPresentationStyle = .formSheet
        transitioningDelegate = panelFormSheetTransitioningDelegate
        presentationController?.delegate = adaptivePresentationDelegate
        estimateHeight = 360
    }

    init(config: SKLynxConfig, followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        var logInfo = config.initialProperties
        let encryptToken = (config.initialProperties?["token"] as? String)?.encryptToken
        let encryptWikiToken = (config.initialProperties?["wikiToken"] as? String)?.encryptToken
        logInfo?["token"] = encryptToken
        logInfo?["wikiToken"] = encryptWikiToken
        DocsLogger.info("AdjustSettingsLynxViewController initialProperties", extraInfo: logInfo)
        self.followAPIDelegate = followAPIDelegate
        super.init(templateRelativePath: config.cardPath, initialProperties: config.initialProperties ?? [:])
        shareContextID = config.shareContextID

        modalPresentationStyle = .formSheet
        transitioningDelegate = panelFormSheetTransitioningDelegate
        presentationController?.delegate = adaptivePresentationDelegate
        estimateHeight = 360
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupBizHandlers(for lynxView: BDXLynxViewProtocol) {
        super.setupBizHandlers(for: lynxView)

        let eventHandlers: [BridgeHandler] = [
            SecLabelApprovalBridgeHandler(hostController: self, followAPIDelegate: followAPIDelegate),
            SecLabelRepeatedApprovalDialogBridgeHandler(hostController: self),
            NotifyPublicPermissionUpdatedBridgeHandler()
        ]
        eventHandlers.forEach { (handler) in
            lynxView.registerHandler(handler.handler, forMethod: handler.methodName)
        }

        lynxView.registerHandler({ [weak self] _, _, params, callback in
            guard let self = self else { return }
            guard let resultValue = params?["result"] as? Int, let result = AdjustSettingsResult(rawValue: resultValue) else {
                DocsLogger.error("adjustSettingsCallback: no params")
                return
            }
            if result == .success {
                NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
            }
            self.callback?(result)
            DocsLogger.info("handle ccm.permission.adjustSettingsCallback")
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.permission.adjustSettingsCallback")

        lynxView.registerHandler({ [weak self] _, _, params, callback in
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
            guard let self else { return }
            guard let code = params?["code"] as? Int,
                  let type = params?["type"] as? Int,
                  let scene = RealNameAuthService.Scene(rawValue: code) else {
                DocsLogger.error("showRealNameAuthDialog get code failed, code: \(String(describing: params?["code"]))")
                return
            }
            let isFolder = type == DocsType.folder.rawValue
            DocsLogger.info("handle showRealNameAuthDialog, scene: \(scene)")
            RealNameAuthService.showRealNameAuthDialog(scene: scene, isFolder: isFolder, fromVC: self)
        }, forMethod: "ccm.permission.showRealNameAuthDialog")
    }
}
