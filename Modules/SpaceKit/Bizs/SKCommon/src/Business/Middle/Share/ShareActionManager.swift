//
//  ShareActionManager.swift
//  SpaceKit
//
//  Created by Gill on 2020/2/6.
//  swiftlint:disable file_length

import Foundation
import RxRelay
import LarkSnsShare
import LinkPresentation
import LarkAppConfig
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import LarkAppResources
import SpaceInterface
import SKInfra
import LarkContainer
import Swinject

protocol ShareActionManagerDelegate: AnyObject {
    func shareActionManagerWillHandle(manager: ShareActionManager,
                                      type: ShareAssistType,
                                      needFinish: inout Bool)
    func shareActionManagerDidHandle(manager: ShareActionManager,
                                     type: ShareAssistType)
    func handleCopyLink()

    func handleCopyPasswordLink(enablePasswordShare: Bool)
}
class ShareActionHandler {
    // Reture 值决定是否走 ActionManger 的处理.如果返回 false，则直接跳过，走 didHandle 逻辑
    var onWillHandle: ((ShareActionManager, ShareAssistType) -> Bool)?
    var onDidHandle: ((ShareActionManager, ShareAssistType) -> Void)?

    var onShareToOtherApp: ((UIActivityViewController?) -> Void)?
    var onShareToOtherAppFail: ((ShareAssistType, UIViewController) -> Void)?
    var onShareToFeishu: ((String, String) -> Void)?
    var onShareToQRCode: (() -> Void)?
    var onShareToByteDanceMoments: ((URL?) -> Void)?
    // 采取降级方案分享图片
    var onShareImageToOtherApp: ((ShareActionManager, ShareAssistType) -> Void)?
}


enum ThirdPartyShareStatus: Int {
    case normal = 0
    case canOpenLink = 1
    case banned = 2
}

public struct ShareImageEntity {
    public init() {}
}

public final class ShareActionManager: NSObject {
    var shareItems: [ShareAssistItem] = [ShareAssistItem]()
    weak var delegate: ShareActionManagerDelegate?
    private var shareEntity: SKShareEntity
    let handler = ShareActionHandler()
    var source: ShareSource = .list
    //降级方案
    var shouldMakeSnapshot = false
    private var permissonManager = DocsContainer.shared.resolve(PermissionManager.self)!
    let adjustSettingsHandler: AdjustSettingsHandler

    weak var fromVC: UIViewController?
    enum PermissionType {
        case publicPermission
        case userPermission
    }
    var permissionRequestTypes: [PermissionType] = []

    /* 这里这么写，是因为三方分享无权限时，用户或者文档owner会动态修改文档权限，导致每次都要去请求一遍最新的权限，
     就当前请求权限方法的封装，不想嵌套两个请求，就这么写了
     */
    var isRequestingPermission = false
    var permissionRequestFinishedCount: Int = 0 {
        didSet {
            if permissionRequestFinishedCount == permissionRequestTypes.count {
                isRequestingPermission = false
                checkToContinueShareAction()
            }
        }
    }

    var curShareType: ShareAssistType?
    private var permStatistics: PermissionStatistics?
    
    public init(_ shareEntity: SKShareEntity, fromVC: UIViewController?, permStatistics: PermissionStatistics? = nil, requestPermissions: Bool = true, followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.shareEntity = shareEntity
        self.permStatistics = permStatistics
        self.fromVC = fromVC
        self.adjustSettingsHandler = AdjustSettingsHandler(token: shareEntity.objToken, type: shareEntity.type, isSpaceV2: shareEntity.spaceSingleContainer, isWiki: shareEntity.wikiV2SingleContainer, followAPIDelegate: followAPIDelegate)
        super.init()
        if requestPermissions {
            preparePermission()
        }
    }

    func fire(_ type: ShareAssistType) {
        switch type {
        case .snapshot:
            SecurityReviewManager.reportAction(DocsType(rawValue: shareEntity.type.rawValue),
                                               operation: OperationType.operationsExport,
                                               token: shareEntity.objToken,
                                               appInfo: type,
                                               wikiToken: shareEntity.wikiInfo?.wikiToken)
        case .wechat, .wechatMoment, .qq, .weibo, .more:
            SecurityReviewManager.reportAction(DocsType(rawValue: shareEntity.type.rawValue),
                                               operation: OperationType.operationsShareTo3rdApp,
                                               token: shareEntity.objToken,
                                               appInfo: type,
                                               wikiToken: shareEntity.wikiInfo?.wikiToken)
        default:
            ()
        }
        if handler.onWillHandle?(self, type) ?? true {
            _fire(type)
        }
        handler.onDidHandle?(self, type)
    }
    
    func directlyFire(_ type: ShareAssistType) {
        _fire(type)
        handler.onDidHandle?(self, type)
    }
    
    public func availableOtherAppItems() -> [ShareAssistItem] {
        // 荣耀租户屏蔽对外分享渠道
        guard !UserScopeNoChangeFG.PLF.shareChannelDisable else {
            DocsLogger.info("shareChannelDisable is true, no external share item")
            return []
        }
        // 同步块不支持对外分享渠道
        guard !shareEntity.isSyncedBlock else {
            DocsLogger.info("Synced blcok no external share item")
            return []
        }
        // fg关闭时，wiki 不支持对外分享渠道
        guard (shareEntity.type != .wiki && !shareEntity.isFromWiki) || UserScopeNoChangeFG.PLF.wikiShareChannelEnable else {
            DocsLogger.info("wikiShareChannelEnable is false, no external share item")
            return []
        }
        // Lark包只有「More」
        guard DomainConfig.envInfo.isFeishuPackage else {
            DocsLogger.info("Is lark package, only use more item")
            return [item(.more)]
        }
        return [
            item(.wechat),
            item(.wechatMoment),
            item(.qq),
            item(.weibo),
            item(.more)
        ]
    }

    public func availableOtherAppItemsForSheet() -> [ShareAssistItem] {
        var items: [ShareAssistItem] = []
        guard DomainConfig.envInfo.isFeishuPackage else {
            return items
        }
        
        let itemTypes = [ShareAssistType.wechat, .wechatMoment, .qq, .weibo]
        
        for itemType in itemTypes {
            items.append(item(itemType))
        }

        return items
    }
    
    // 分享渠道是否可用(安装)，判断前需要先调用checkShareAdminAuthority判断是否有分享权限
    public func isAvailable(type: ShareAssistType) -> Bool {
        if type == .wechat || type == .wechatMoment {
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .wechat)
        } else if type == .qq {
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .qq)
        } else if type == .weibo {
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .weibo)
        }
        
        return true
    }
    
    
    /// 是否有分享渠道Admin管控权限
    public func checkShareAdminAuthority(type: ShareAssistType, showTips: Bool) -> Bool {
        //https://bytedance.feishu.cn/docx/SzUkdoBNQoJc8lx8Gvbc1QGBnfg
        //https://bytedance.feishu.cn/docx/RBpkd99kto6ffDxf0OJcRYVlndg
        guard let snsType = convertInternalShareTypeToSnsShareType(type) else {
            return true
        }
        let enable = LarkShareBasePresenter.shared.checkShareSDKAuthority(snsType: snsType)
        if !enable, showTips, let window = fromVC?.view.window{
            let msg = LarkShareBasePresenter.shared.getShareSdkDenyTipText(snsType: snsType)
            if !msg.isEmpty {
                UDToast.showFailure(with: msg, on: window)
            }
        }
        return enable
    }

    public func item(_ type: ShareAssistType) -> ShareAssistItem {
        switch type {
        case .qrcode:
            return ShareAssistItem(type: .qrcode,
                                   title: shareEntity.bitableSubType == .record ? BundleI18n.SKResource.Bitable_ShareSingleRecord_Sharing_ShareTo_QRCode_Option : BundleI18n.SKResource.Bitable_NewSurvey_Sharing_ShareQRCode_Title,
                                             image: UDIcon.qrOutlined.ud.withTintColor(UDColor.iconN1))
        case .feishu: return ShareAssistItem(type: .feishu,
                                             title: BundleI18n.SKResource.Doc_BizWidget_SendToChat,
                                             image: UDIcon.forwardOutlined.ud.withTintColor(UDColor.iconN1))

        case .fileLink: return ShareAssistItem(type: .fileLink,
                                               title: self.shareEntity.isVersion ?   BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Share_CopyLink_Button : BundleI18n.SKResource.Doc_Facade_CopyLink,
                                               image: UDIcon.linkCopyOutlined.ud.withTintColor(UDColor.iconN1))

        case .passwordLink: return ShareAssistItem(type: .passwordLink,
                                               title: BundleI18n.SKResource.LarkCCM_Docs_PasswordProtectedLink_Button_Mob,
                                               image: UDIcon.linkLockOutlined.ud.withTintColor(UDColor.iconN1))

        case .snapshot: return ShareAssistItem(type: .snapshot,
                                               title: BundleI18n.SKResource.LarkCCM_Docs_ShareImage_Button_Mob,
                                               image: UDIcon.imageOutlined.ud.withTintColor(UIColor.ud.iconN1))

        case .wechat: return ShareAssistItem(type: .wechat,
                                             title: BundleI18n.SKResource.Doc_BizWidget_WeChat,
                                             image: UDIcon.wechatColorful)

            
        case .wechatMoment: return ShareAssistItem(type: .wechatMoment,
                                                   title: BundleI18n.SKResource.Doc_BizWidget_Moments,
                                                   image: UDIcon.wechatFriendColorful)
        
        case .weibo: return ShareAssistItem(type: .weibo,
                                            title: BundleI18n.SKResource.Doc_BizWidget_Weibo,
                                            image: UDIcon.weiboColorful)

        case .qq: return ShareAssistItem(type: .qq,
                                         title: BundleI18n.SKResource.Doc_BizWidget_QQ,
                                         image: UDIcon.qqColorful)

        case .more: return ShareAssistItem(type: .more,
                                           title: BundleI18n.SKResource.LarkCCM_Docs_SendToOtherApps_Button_Mob,
                                           image: UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1))
            
        case .saveImage: return ShareAssistItem(type: .saveImage,
                                                title: BundleI18n.SKResource.Doc_BizWidget_Download,
                                                image: UDIcon.downloadOutlined.ud.withTintColor(UIColor.ud.iconN1))
        case .copyAllTexts: return ShareAssistItem(type: .copyAllTexts,
                                                   title: BundleI18n.SKResource.CreationMobile_CopyText,
                                                   image: UDIcon.copyOutlined.ud.withTintColor(UIColor.ud.iconN1))
        }
    }
}

extension ShareActionManager {
    public func shareImageToLark(image: UIImage) {
        HostAppBridge.shared.call(ShareToLarkService(contentType: .image(name: "", image: image),
                                                     fromVC: UIViewController.docs.topMost(of: fromVC),
                                                     type: .feishu))
    }
}


// Handle
extension ShareActionManager {
    enum ShareSummaryErrorCode: Int {
        case normalFialed = 1
        case notFound = 3
        case noPermission = 4
    }
    private func _shareToOtherApp() {
        var items: [Any] = []
        guard let url = URL(string: shareEntity.shareUrl) else {
            DocsLogger.info("分享到外部失败：URL 为空")
            return
        }
        permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .shareMore, target: .noneTargetView)
        items = [url]
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        handler.onShareToOtherApp?(activityController)
    }
    
    func qrcode() {
        permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .click_qrcode, target: .noneTargetView)
        handler.onShareToQRCode?()
    }

    private func shareLinkToFeishu() {
        var shareUrl = shareEntity.shareUrl
        let shareTitle = shareEntity.title
        if let idx = shareUrl.firstIndex(of: "?") {
            if (shareEntity.type != .bitable || !UserScopeNoChangeFG.ZJ.btShareAddExtraParam) {
                shareUrl = String(shareUrl[..<idx])
            }
        }
        if shareEntity.isVersion, let vurl = URL(string: shareUrl) {
            shareUrl = vurl.docs.addQuery(parameters: ["edition_id": shareEntity.versionInfo!.version]).absoluteString
        }
        if let title = shareTitle.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
           let content = shareUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            handler.onShareToFeishu?(title, content.urlDecoded())
        }
    }

    private func handleCopyLink() {
        if delegate != nil {
            delegate?.handleCopyLink()
        }
    }

    private func handleCopyPasswordLink(enablePasswordShare: Bool) {
        if delegate != nil {
            delegate?.handleCopyPasswordLink(enablePasswordShare: enablePasswordShare)
        }
    }

    private func handleByteDanceMoments() {
        guard
            let shareText = shareEntity.shareUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
            let parameter = "pages/publish/root?content=\(shareText)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else { return }
        // 分享到头条圈，KA会隐藏入口，此处domain保留
        let shareStr = "https://ee.bytedance.net/malaita?miniPath=\(parameter)"
        handler.onShareToByteDanceMoments?(URL(string: shareStr))
    }
    private func checkToContinueShareAction() {
        guard let type = curShareType else { return }
        var title: String? = BundleI18n.SKResource.Doc_Permission_NoPermissionAccess
        var text: String? = BundleI18n.SKResource.Doc_Permission_NoPermissionAccess

        guard
            let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self),
            let publicPermissionMeta = permissonMgr.getPublicPermissionMeta(token: shareEntity.objToken),
            let userPermission = permissonMgr.getUserPermissions(for: shareEntity.objToken) else {
            _shareToSocialApp(type, title: title, text: text)
            curShareType = nil
            DocsLogger.info("can't get publicPermissionMeta or userPermission")
            return
        }
        if publicPermissionMeta.shareEntity != .onlyMe
            || userPermission.canShare()
            || publicPermissionMeta.linkShareEntity == .anyoneCanRead {
            title = shareEntity.title
            // 如果是协作者有邀请权限，或者自己就是文档owner，那么使用默认文案，传入nil即可
            text = nil
        }
        _shareToSocialApp(type, title: title, text: text)
        curShareType = nil
    }

    private func prepareShareToSocial(_ type: ShareAssistType) {
        requestFileSummaryAndShare(type)
    }

    private func requestFileSummaryAndShare(_ type: ShareAssistType) {
        let fileType = shareEntity.type
        let params: [String: Any] = ["obj_type": fileType.rawValue,
                                     "obj_token": shareEntity.objToken]
        DocsLogger.info("start to getShareSummary")

        let timeout = Double(0.5)
        DocsRequest<JSON>(path: OpenAPI.APIPath.getShareSummary, params: params)
            .set(method: .GET)
            .set(timeout: timeout)
            .makeSelfReferenced()
            .start { (res, err) in
                DocsLogger.info("end to getShareSummary")

                if let error = err {
                    DocsLogger.error("share, get summary error:\(error)")
                }
                let title: String? = self.shareEntity.title
                var text: String?
                if let code = res?["code"].int, let errorCode = ShareSummaryErrorCode(rawValue: code) {
                    switch errorCode {
                    case .noPermission:
                        self.curShareType = type
                        self.requestPermission()
                        return
                    case .notFound, .normalFialed:
                        break
                    }
                }
                if let summary = res?["data"]["summary"].string, !summary.isEmpty {
                    text = summary
                }
                DocsLogger.debug("share summary: \(String(describing: text)), for sharetype: \(type), fileType:\(fileType)")

                self._shareToSocialApp(type, title: title, text: text)
            }
    }
    /* 这里这么写，是因为三方分享无权限时，用户或者文档owner会动态修改文档权限，导致每次都要去请求一遍最新的权限，
     就当前请求权限方法的封装，不想嵌套两个请求，就这么写了
     */
    private func requestPermission() {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        permissionRequestFinishedCount = 0
        guard let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self) else {
            spaceAssertionFailure("can't get PermissionManager")
            DocsLogger.error("can't get PermissionManager")
            checkToContinueShareAction()
            return
        }
        let objToken = shareEntity.objToken
        let docType = shareEntity.type.rawValue
        if !permissionRequestTypes.contains(.publicPermission) {
            permissionRequestTypes.append(.publicPermission)
        }

        //请求公共权限
        let handler: (PublicPermissionMeta?, Error?) -> Void = { [weak self] (_, _) in
            guard let self = self else { return }
            self.permissionRequestFinishedCount += 1
        }
        if shareEntity.isFormV1 {
            if let shareToken = shareEntity.formShareFormMeta?.shareToken, !shareToken.isEmpty {
                permissonMgr.fetchFormPublicPermissions(baseToken: objToken, shareToken: shareToken, complete: handler)
            } else {
                spaceAssertionFailure()
            }
        } else if shareEntity.isBitableSubShare {
            if let entity = shareEntity.bitableShareEntity, let shareToken = entity.meta?.shareToken, !shareToken.isEmpty {
                permissonMgr.fetchBitablePublicPermissions(baseToken: objToken, shareToken: shareToken, complete: handler)
            } else {
                spaceAssertionFailure()
                DocsLogger.error("bitableShareEntity shareToken is nil!")
            }
        } else {
            permissonMgr.fetchPublicPermissions(token: objToken, type: docType, complete: handler)
        }


        if !permissionRequestTypes.contains(.userPermission) {
            permissionRequestTypes.append(.userPermission)
        }
        permissonMgr.fetchUserPermissions(token: objToken,
                                          type: docType) { [weak self] (_, _) in
            guard let self = self else { return }
            self.permissionRequestFinishedCount += 1
        }
    }


    private func preparePermission() {
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare { return }
        let objToken = shareEntity.objToken
        let docType = shareEntity.type.rawValue
        if permissonManager.getPublicPermissionMeta(token: objToken) == nil {
            permissonManager.fetchPublicPermissions(token: objToken, type: docType, complete: nil)
        }
        if permissonManager.getUserPermissions(for: objToken) == nil {
            permissonManager.fetchUserPermissions(token: objToken,
                                                      type: docType,
                                                      complete: nil)
        }
    }

    private func _shareToSocialApp(_ type: ShareAssistType, title: String?, text: String?) {
        let shareUrl = shareEntity.shareUrl
        guard !shareUrl.isEmpty, let title = title else {
            DocsLogger.info("shareUrl or title is nil")
            return
        }

        let image = DocsSDK.isInLarkDocsApp ? BundleResources.SKResource.Common.Pop.pop_feishudocs : AppResources.share_icon_logo

        shareToSocialAppCore(type,
                             shareURL: shareUrl,
                             title: title,
                             text: text ?? BundleI18n.SKResource.Doc_Share_SharedFromFeishu(),
                             image: image)
    }

    func shareToSocialAppCore(_ type: ShareAssistType,
                              shareURL: String,
                              title: String,
                              text: String?,
                              image: UIImage?) {
        //权限检测
        let status = shareStatus(type)
        DocsLogger.info("share statu: \(status)")
        switch type {
        case .wechatMoment:
            permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .shareWechatMoments, target: .noneTargetView)
        case .weibo:
            permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .shareWeibo, target: .noneTargetView)
        case .qq:
            permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .shareQq, target: .noneTargetView)
        default:()
        }
        switch status {
        case .canOpenLink:
            DocsLogger.info("showCopyLinkPanel by can open link, statu: \(status)")
            if type == .wechatMoment, shouldMakeSnapshot {
                DocsLogger.info("send image to wechat")
                showCreateImagePanel(type)
            } else {
                showCopyLinkPanel(type, link: shareURL, canOpenLink: true)
            }
        case .banned:
            if shouldMakeSnapshot {
                DocsLogger.info("send image to other app")
                showCreateImagePanel(type)
            } else {
                DocsLogger.info("showCopyLinkPanel by can open link, statu: \(status)")
                showCopyLinkPanel(type, link: shareURL, canOpenLink: false)
            }
        case .normal:
            DocsLogger.info("share to social app normal, statu: \(status)")
            SecurityReviewManager.reportAction(DocsType(rawValue: shareEntity.type.rawValue),
                                               operation: OperationType.operationsShareTo3rdApp,
                                               token: shareEntity.objToken,
                                               appInfo: type,
                                               wikiToken: shareEntity.wikiInfo?.wikiToken)
            shareToSocialAppCoreFinal(type, shareURL, image, title, text)
        }
    }

    fileprivate func shareToSocialAppCoreFinal(_ type: ShareAssistType, _ shareURL: String, _ image: UIImage?, _ title: String, _ text: String?) {
        LarkShareBasePresenter.shared.delegate = self

        guard let image = image else {
            return
        }

        let snsInfo = getSnsInfo(type, shareURL: shareURL, title: title, desc: text)

        guard let snsType = snsInfo.snsType, let description = snsInfo.description, let snsScene = snsInfo.snsScene else {
            return
        }
        
        var shareTitle: String
        if UserScopeNoChangeFG.ZYS.dashboardShare {
            // 产品要求，Bitable 链接分享时，和降级分享的面板提示文案一致：”快来看看我在 xx 分享的 xx 吧 https://shareUrl.xx“
            if shareEntity.isForm {
                shareTitle = BundleI18n.SKResource.Bitable_Form_ShareViaWechat(title) + shareURL
            } else if shareEntity.isBitableSubShare {
                // 暂时还没有这种类型，和降级分享时提示的通用文案保持一致
                shareTitle = BundleI18n.SKResource.Bitable_Share_ExternalSharePopUp_Description(title) + " " + shareURL
            } else {
                shareTitle = title
            }
        } else {
            shareTitle = title
        }
        
        if enableShareMiniApp(snsType: snsType, snsScene: snsScene) {
            let path = "pages/web-view/index?type=\(shareEntity.type.rawValue)&obj_token=\(shareEntity.objToken)"
            let image = shareEntity.shareToMiniProgramImage()
            LarkShareBasePresenter.shared.sendMiniProgram(navigatable: navigatable,
                                                          snsType: snsType,
                                                          snsScenes: snsScene,
                                                          title: shareTitle,
                                                          webPageURLString: shareURL,
                                                          miniProgramUserName: "gh_20e9bd4e2241",
                                                          miniProgramPath: path,
                                                          launchMiniProgram: false,
                                                          thumbnailImage: image,
                                                          description: description)
            
        } else {
            LarkShareBasePresenter.shared.sendWebPageURL(
                navigatable: navigatable,
                snsType: snsType,
                snsScenes: snsScene,
                webpageURL: shareURL,
                thumbnailImage: image,
                imageURL: "",
                title: shareTitle,
                description: description,
                customCallbackUserInfo: [:]
            )
        }
    }
    
    // 判断是否支持微信分享时，支持分享小程序
    private func enableShareMiniApp(snsType: SnsType, snsScene: SnsScenes) -> Bool {
        guard shareEntity.type != .folder,
              snsType == .wechat,
              snsScene == .wechatSession else {
            return false
        }
        let config = SettingConfig.externalShareConfig
        let isEnableShareMiniApp = config?.enableShareMiniApp ?? false
        return isEnableShareMiniApp
    }
}

//分享降级方案
extension ShareActionManager {

    var navigatable: Navigatable { Container.shared.getCurrentUserResolver().navigator }

    private var widthForPad: CGFloat { 303 }

    func showCopyLinkPanel(_ type: ShareAssistType, link: String, canOpenLink: Bool) {
        permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .shareWechat, target: .permissionShareWechatView)
        permStatistics?.reportPermissionShareWechatView()
        let alert = PopViewController()
        //拷贝链接
        let linkPannel = DidCopyLinkPanel(frame: .zero)
        let title = shareEntity.title
        var contentString: String = ""
        if shareEntity.isForm {
            contentString = BundleI18n.SKResource.Bitable_Form_ShareViaWechat(title) + link
        } else if shareEntity.isBitableSubShare {
            contentString = BundleI18n.SKResource.Bitable_Share_ExternalSharePopUp_Description(title) + " " + link
        } else {
            contentString = canOpenLink ? BundleI18n.SKResource.Doc_Share_ExternalShareContentV1(title, "👉", link) :
                BundleI18n.SKResource.Doc_Share_ExternalShareContentV2(title, "👉", link)
        }
        let isSuccess = SKPasteboard.setString(contentString, psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy)
        linkPannel.setContentString(contentString)
        linkPannel.type = type
        if SKDisplay.pad {
            alert.setContent(view: linkPannel, with: { make in
                make.center.equalToSuperview()
                make.width.equalTo(widthForPad)
            })
        } else {
            alert.setContent(view: linkPannel, padding: UIEdgeInsets(top: 0, left: 36, bottom: 0, right: 36))
        }

        linkPannel.setExitButtonClickCallback { [weak alert] in
            self.permStatistics?.reportPermissionShareWechatClick(click: .cancel, target: .noneTargetView)
            alert?.dismiss(animated: false, completion: nil)
        }
        
        linkPannel.setShareButtonClickCallback { [weak alert] in
            self.permStatistics?.reportPermissionShareWechatClick(click: .share, target: .noneTargetView)
            self.openSocialApp(type: type)
            alert?.dismiss(animated: false, completion: nil)
        }
        guard let fromVC = fromVC else { return }
        fromVC.dismiss(animated: false, completion: {
            let delay = TimeInterval(0.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isSuccess {
                    Navigator.shared.present(alert, from: fromVC, animated: false)
                }
            }
        })
    }
    
    func openSocialApp(type: ShareAssistType) {
        DocsLogger.info("打开第三方App type:\(type)")
        
        guard let snsType = convertInternalShareTypeToSnsShareType(type) else {
            DocsLogger.info("打开\(type)失败")
            return
        }
        
        let result = LarkShareBasePresenter.shared.wakeup(snsType: snsType)
        
        if result.0 {
            DocsLogger.info("打开\(type)成功")
        } else {
            DocsLogger.info("打开\(type)失败 error: \(String(describing: result.1))")
        }
    }
    
    func convertInternalShareTypeToSnsShareType(_ type: ShareAssistType) -> SnsType? {
        if type == .wechat || type == .wechatMoment {
            return .wechat
        }
        
        if type == .weibo {
            return .weibo
        }
        
        if type == .qq {
            return .qq
        }
        
        return nil
    }
    
    func shareStatus(_ type: ShareAssistType) -> ThirdPartyShareStatus {
        var status = ThirdPartyShareStatus.normal
        let config = SettingConfig.externalShareConfig
        var isShareChannelBanned: Bool = false
        var isShareDomainBanned: Bool = false
        
        switch type {
        case .wechatMoment, .wechat:
            guard let subConfig = config?.wx else {
                break
            }
            
            isShareChannelBanned = subConfig.isShareChannelBanned
            isShareDomainBanned = subConfig.isShareDomainBanned
        case .qq:
            guard let subConfig = config?.qq else {
                break
            }
            isShareChannelBanned = subConfig.isShareChannelBanned
            isShareDomainBanned = subConfig.isShareDomainBanned
        default:()
        }

        if !isShareChannelBanned {//正常分享
            status = .normal
        } else if isShareChannelBanned && !isShareDomainBanned { //复制链接
            status = .canOpenLink
        } else {//复制图片
            status = .banned
        }
        
        return status
    }
    
    func showCreateImagePanel(_ type: ShareAssistType) {
        //存储share 的类型
        HostAppBridge.shared.register(service: ShareImageEntity.self) { (_) -> Any? in
            return type
        }
        handler.onShareImageToOtherApp?(self, type)
    }

    func getSnsInfo(_ type: ShareAssistType,
                    shareURL: String = "",
                    title: String = "",
                    desc: String? = BundleI18n.SKResource.Doc_Share_SharedFromFeishu()
    ) -> (snsScene: SnsScenes?, snsType: SnsType?, description: String?) {
        var snsScene: SnsScenes?
        var snsType: SnsType?
        var description: String? = desc

        if type == .wechat {
            snsType = .wechat
            snsScene = .wechatSession
        } else if type == .wechatMoment {
            snsType = .wechat
            snsScene = .wechatTimeline
        } else if type == .weibo {
            snsType = .weibo
            snsScene = .qqSpecifiedSession // 无意义，为了统一流程逻辑
            description = BundleI18n.SKResource.Doc_Share_WeiboShareContent(title, shareURL)
        } else if type == .qq {
            snsType = .qq
            snsScene = .qqSpecifiedSession
        } else {
            skAssertionFailure("未知类型")
        }
        
        return (snsScene, snsType, description)
    }

    public func shareTextToSocialApp(type: ShareAssistType, text: String) {
        DocsLogger.info("share text to \(type)")
        let status = shareStatus(type)

        DocsLogger.info("share text by normal")
        let snsInfo = getSnsInfo(type)

        if status == .normal { //直接分享
            guard let snsType = snsInfo.snsType, let snsScene = snsInfo.snsScene else {
                DocsLogger.info("share image failed")
                return
            }
            LarkShareBasePresenter.shared.delegate = self
            LarkShareBasePresenter.shared.sendText(navigatable: navigatable, snsType: snsType, snsScenes: snsScene, text: text)
        } else { //打开
            DocsLogger.info("share text by open app")
            self.openSocialApp(type: type)
        }
    }
    
    public func shareImageToSocialApp(type: ShareAssistType, image: UIImage) {
        DocsLogger.info("share image to \(type)")
        let status = shareStatus(type)
        
        if status == .normal { //直接分享
            DocsLogger.info("share image by normal")
            let snsInfo = getSnsInfo(type)
            
            guard let snsType = snsInfo.snsType, let snsScene = snsInfo.snsScene else {
                DocsLogger.info("share image failed")
                return
            }
            LarkShareBasePresenter.shared.delegate = self
            LarkShareBasePresenter.shared.sendImage(navigatable: navigatable, snsType: snsType, snsScenes: snsScene, image: image, title: nil, description: nil)
        } else { //打开
            DocsLogger.info("share image by open app")

            let alert = PopViewController()
            let imagePannel = DidSaveImagePanel(frame: .zero)
            imagePannel.type = type
            if SKDisplay.pad {
                alert.setContent(view: imagePannel, with: { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(widthForPad)
                })
            } else {
                alert.setContent(view: imagePannel, padding: UIEdgeInsets(top: 0, left: 36, bottom: 0, right: 36))
            }
            imagePannel.setShareButtonClickCallback { [weak alert] in
                self.openSocialApp(type: type)
                alert?.dismiss(animated: false, completion: nil)
            }
            
            imagePannel.setExitButtonClickCallback { [weak alert] in
                alert?.dismiss(animated: false, completion: nil)
            }
            if let fromVC = UIViewController.docs.topMost(of: fromVC) {
                fromVC.present(alert, animated: false, completion: nil)
            }
        }
    }
}


extension ShareActionManager: SnsShareDelegate {
    
    private func _shareToOtherAppFail(_ type: ShareAssistType, error: Error?) {
        if let error = error {
            let nserror = error as NSError
            DocsLogger.info("[分享到外部] Error:\(String(describing: error))")
            guard let window = fromVC?.view.window else { return }
            // nolint-next-line: magic number
            if nserror.code == 1001 {//未安装
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Share_AppNotInstalled, on: window)
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: window)
            }
        }
    }

    public func wechatWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        _shareToOtherAppFail(.wechat, error: error)
    }

    public func qqWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        _shareToOtherAppFail(.qq, error: error)
    }

    public func weiboWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        _shareToOtherAppFail(.weibo, error: error)
    }
}


extension ShareActionManager {
    private func _fire(_ type: ShareAssistType) {
        switch type {
        case .qrcode: qrcode()
        case .feishu: shareLinkToFeishu()
        case .fileLink: handleCopyLink()
        case .passwordLink: handleCopyPasswordLink(enablePasswordShare: true)
        case .more: _shareToOtherApp()
        case .wechat:
            fireByAdjustSettings(type: .wechatShare) { _ in
                self.prepareShareToSocial(.wechat)
            }
        case .wechatMoment:
            fireByAdjustSettings(type: .momentsShare) { _ in
                self.prepareShareToSocial(.wechatMoment)
            }
        case .weibo:
            fireByAdjustSettings(type: .weiboShare) { _ in
                self.prepareShareToSocial(.weibo)
            }
        case .qq:
            fireByAdjustSettings(type: .qqShare) { _ in
                self.prepareShareToSocial(.qq)
            }
        default: ()
        }
    }

    private func fireByAdjustSettings(type: AdjustSettingsSceneType, completion: @escaping ((Bool) -> Void)) {
        if self.fromVC?.isMyWindowRegularSizeInPad == true {
            if shareEntity.bitableShareEntity?.isRecordShareV2 != true, shareEntity.bitableShareEntity?.isAddRecordShare != true {
                // 记录分享时，在 showCopyLinkPanel 时会 dismiss，这里不能提前做，否则会 dismiss 两次把卡片关掉
                self.fromVC?.dismiss(animated: true, completion: nil)
            }
            self.adjustSettingsHandler.toAdjustSettingsIfEnabled(sceneType: type, topVC: self.fromVC) { status in
                switch status {
                case .success:
                    completion(true)
                case .disabled:
                    completion(false)
                case .fail:
                    break
                }
            }
        } else {
            self.adjustSettingsHandler.toAdjustSettingsIfEnabled(sceneType: type, topVC: UIViewController.docs.topMost(of: self.fromVC)) { status in
                switch status {
                case .success:
                    completion(true)
                case .disabled:
                    completion(false)
                case .fail:
                    break
                }
            }
        }
    }
}

extension ShareActionManager: UIActivityItemSource {
    @available(iOS 11.0, *)
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return UIImage()
    }

    @available(iOS 11.0, *)
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let url = URL(string: shareEntity.shareUrl) else {
            DocsLogger.info("分享到外部失败：URL 为空")
            return nil
        }
        return url
    }

    @available(iOS 13.0, *)
    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        guard let url = URL(string: shareEntity.shareUrl) else {
            DocsLogger.info("分享到外部失败：URL 为空")
            return nil
        }

        let metadata = LPLinkMetadata()
        metadata.title = shareEntity.title // Preview Title
        metadata.originalURL = url // determines the Preview Subtitle
        if let icon = shareEntity.defaultIcon {
            metadata.imageProvider = NSItemProvider(object: icon)
            metadata.iconProvider = NSItemProvider(object: icon)
        } else {
            metadata.imageProvider = NSItemProvider(contentsOf: url)
            metadata.iconProvider = NSItemProvider(contentsOf: url)
        }
        return metadata
    }
}
