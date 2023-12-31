//
//  QuotaAlertPresentor.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/3/31.
// swiftlint:disable type_body_length file_length

import Foundation
import SKUIKit
import SpaceInterface
import EENavigator
import SKResource
import SKFoundation
import UniverseDesignToast
import LarkEnv
import SwiftyJSON
import UniverseDesignEmpty
import SKInfra
import CTADialog
import LarkContainer

public final class QuotaAlertPresentor: NSObject, QuotaAlertService {
    enum QuotaType {
        case tenant
        case user(info: QuotaInfo?)
    }
    public var enableUserQuota: Bool {
        return true
    }
    
    // v7.7 接入卖点组件，支持国内飞书和海外Lark，后续 FG 下线可以直接删除 isFeishuBrand 相关判断逻辑
    public var enableTenantQuota: Bool {
        return DomainConfig.envInfo.isFeishuBrand || UserScopeNoChangeFG.ZH.enableCTAComponent
    }
    
    public static let shared = QuotaAlertPresentor()
    
    private var request: DocsRequest<JSON>?
    private var requesting: Bool = false
    static var contactURL: URL? {
        let boeLink = """
        https://applink.feishu.cn/client/helpdesk/open\
        ?id=6934871265543159828&extra=%7B%22channel%22%3A14%2C%22created_at\
        %22%3A1617246713%2C%22human_service%22%3Atrue%2C%22scenario_id\
        %22%3A6937491551345967123%2C%22signature%22%3A%229df9ed53d1cd7fd62be8055f37ab2f8b8cf71583%22%7D
        """
        let onlineLink = """
        https://applink.feishu.cn/client/helpdesk/open\
        ?id=6626260912531570952&extra=%7B%22channel%22%3A14%2C%22created_at\
        %22%3A1616898084%2C%22human_service%22%3Atrue%2C%22scenario_id\
        %22%3A6888204905589325826%2C%22signature%22%3A%2278b0c5156b727a66d02c9b689ea0785d1a865bb5%22%7D
        """
        
        let onlineLarkLink = "https://applink.larksuite.com/TJoXwqd"
        
        if !DomainConfig.envInfo.isFeishuBrand {
            // 海外客服没有提供boe环境链接
            return URL(string: onlineLarkLink)
        }
        var url = URL(string: onlineLink)
        if EnvManager.env.isStaging {
            url = URL(string: boeLink)
        }
        return url
    }
    
    private var dialog: CTADialog?
        
    // 租户容量提示
    public func showQuotaAlertIfNeed(type: QuotaAlertType, defaultToast: String, error: Error, from: UIViewController, token: String) {
        DocsLogger.error("type: \(type), error:  \(error)")
        if DocsNetworkError.error(error, equalTo: .createLimited) {
            if enableTenantQuota {
                showQuotaAlert(type: type, from: from)
            } else {
                UDToast.showFailure(with: defaultToast, on: from.view.window ?? from.view)
            }
        } else if DocsNetworkError.error(error, equalTo: .spaceUserStorageLimited) ||
                    DocsNetworkError.error(error, equalTo: .driveUserStorageLimited) {
            if enableUserQuota {
                showUserQuotaAlert(mountNodeToken: nil, mountPoint: nil, from: from)
            } else {
                UDToast.showFailure(with: defaultToast, on: from.view.window ?? from.view)
            }
        } else if DocsNetworkError.error(error, equalTo: DocsNetworkError.Code.copyingFile) {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_Docs_duplicate_inProgress_toast, on: from.view.window ?? from.view)
        } else if DocsNetworkError.isDlpError(error) {
            DlpManager.updateCurrentToken(token: token)
            let text = DocsNetworkError.dlpErrorMsg(error)
            UDToast.showFailure(with: text, on: from.view.window ?? from.view)
            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpError: error)
        } else {
            UDToast.showFailure(with: defaultToast, on: from.view.window ?? from.view)
        }
    }
    
    // MARK: -- 租户容量提示
    public func showQuotaAlert(type: QuotaAlertType, from: UIViewController) {
        if UserScopeNoChangeFG.ZH.enableCTAComponent, let info = convertToCTAInfo(type: type) {
            DocsLogger.info("showCTATenantAlert -- will show Alert with type: \(type)")
            showCTATenantAlert(info: info, from: from)
            report(type: type, event: .commonPricePopup)
        } else {
            let alert = QuotaAlertViewController(quotaType: type, fromVC: from)
            alert.delegate = self
            if from.isMyWindowRegularSizeInPad {
                alert.modalPresentationStyle = .formSheet
            } else {
                alert.modalPresentationStyle = .overFullScreen
            }
            delayShowAlert(alert: alert, type: type, from: from, quotaType: .tenant)

        }
    }
    
    struct CTAInfo {
        let featureKey: String
        let scene: String
    }
    
    private func convertToCTAInfo(type: QuotaAlertType) -> CTAInfo? {
        switch type {
        case .upload, .makeCopy, .saveToSpace, .cannotEditFullCapacity, .saveAsTemplate, .createByTemplate:
            return CTAInfo(featureKey: "drive_storage_limit", scene: "scene_Upload_drive_storage_limit")
        default:
            assertionFailure("must define CTAInfo to show Alert")
            return nil
        }
    }
    
    private func showCTATenantAlert(info: CTAInfo, from: UIViewController) {
        guard dialog == nil else {
            DocsLogger.warning("showCTATenantAlert -- isShow")
            return
        }
        
        let userResolver = Container.shared.getCurrentUserResolver()
        // TODO: - howie, 需要check 权益租户ID，目前使用了当前租户ID
        guard let tenantID = userResolver.docs.user?.info?.tenantID else {
            DocsLogger.warning("showCTATenantAlert -- no tenantID")
            return
        }
        DocsLogger.info("showCTATenantAlert -- show with tenantID: \(tenantID), info: \(info)")
        
        dialog = CTADialog(userResolver: userResolver)
        let formVC = from.presentedViewController ?? from
        dialog?.show(from: formVC,
                    featureKey: info.featureKey,
                    scene: info.scene,
                    checkpointTenantId: tenantID, with: { [weak self] succeed in
            DocsLogger.info("showCTATenantAlert -- with result: \(succeed)")
            self?.dialog = nil
        })
        
    }

    // 用户容量提示
    // 如果是上传文件到文档，需要传mountNodeToken和mountPoint, 其他情况传nil
    // mountNodeToken: 文档token
    // mountPoint: 挂载点，比如doc
    public func showUserQuotaAlert(mountNodeToken: String?, mountPoint: String?, from: UIViewController) {
        showUserQuotaAlert(mountNodeToken: mountNodeToken, mountPoint: mountPoint, from: from, bizParams: nil)
    }
    // 用户容量提示
    // 如果是上传文件到文档，需要传mountNodeToken和mountPoint, 其他情况传nil
    // mountNodeToken: 文档token
    // mountPoint: 挂载点，比如doc
    // bizParams: 埋点信息
    public func showUserQuotaAlert(mountNodeToken: String?,
                                   mountPoint: String?,
                                   from: UIViewController,
                                   bizParams: SpaceBizParameter?) {
        guard !requesting else {
            DocsLogger.info("is requesting quota info")
            return
        }
        requesting = true
        requestQuotaInfo(mountNodeToken: mountNodeToken, mountPoint: mountPoint) { [weak self] quotaInfo in
            guard let self = self else { return }
            self.requesting = false
            var info = quotaInfo
            info?.updateAdmins() // 更新哪些contacts是管理员
            let attrTips = self.attributedTips(quotaInfo: info)
            let alert = QuotaAlertViewController(quotaType: .upload,
                                                 fromVC: from,
                                                 customTips: attrTips,
                                                 showContact: false,
                                                 quotaInfo: info)
            alert.bizParams = bizParams
            alert.delegate = self
            if from.isMyWindowRegularSizeInPad {
                alert.modalPresentationStyle = .formSheet
            } else {
                alert.modalPresentationStyle = .overFullScreen
            }
            
            let type = QuotaType.user(info: info)
            self.delayShowAlert(alert: alert, type: .upload, from: from, quotaType: type, bizParams: bizParams)
        }
    }
    
    
    private func handlerUploadAlert(fileSize: Int64, info: QuotaUploadInfo, quotaType: QuotaAlertType, from: UIViewController) {
        var showContact = false
        var version: String
        var maxSize: Int64
        var verifiledSize: Int64?
        
        switch info.suiteType {
        case .legacyFree:
            version = BundleI18n.SKResource.CreationMobile_version_standard
            maxSize = info.suiteToQuota.legacyFreeMaxSize ?? 0
        case .certStandard:
            version = BundleI18n.SKResource.CreationMobile_version_standard
            maxSize = info.suiteToQuota.certStandardMaxSize ?? 0
        case .standard:
            version = BundleI18n.SKResource.CreationMobile_version_standard
            verifiledSize = info.suiteToQuota.certStandardMaxSize ?? 0
            maxSize = info.suiteToQuota.standardMaxSize ?? 0
        case .business:
            version = BundleI18n.SKResource.CreationMobile_version_business
            maxSize = info.suiteToQuota.businessMaxSize ?? 0
        case .legacyEnterprise:
            version = BundleI18n.SKResource.CreationMobile_version_enterprise
            maxSize = info.suiteToQuota.legacyEnterpriseMaxSize ?? 0
        case .enterprise:
            version = BundleI18n.SKResource.CreationMobile_version_enterprise
            maxSize = info.suiteToQuota.enterpriseMaxSize ?? 0
        }
        if maxSize == 0 {
            DocsLogger.info("drive upload alert -- suite max size is nil")
            self.featchBusinessInfoFailedAlert(from: from, quotaType: quotaType)
            return
        }
        if info.isAdmin { showContact = true }
        let customTips = self.attributedTipsOfUpload(type: quotaType, info: info, maxSize: maxSize, version: version, verifiledSize: verifiledSize)
        
        var alert: QuotaAlertViewController
        /// 用于当前最大上传限制弹窗
        if let tenantMaxSize = info.suiteToQuota.tenantMaxSize, fileSize > tenantMaxSize {
            let tips = QuotaAttrStringHelper.tipsOfFileUploadLimitExceeded(template: self.getMaxUploadSizeDetail(quotaType: quotaType),
                                                                           maxSize: tenantMaxSize.memoryFormatWithoutFlow )
            alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, customTips: tips, showContact: false, quotaUploadInfo: info)
        } else {
            if info.suiteType == .standard {
                // 未认证租户
                if DomainConfig.envInfo.isFeishuBrand {
                    alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, customTips: customTips, showContact: false, quotaUploadInfo: info)
                } else {
                    // 海外没有standard版本，如果出现，显示兜底页
                    alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, showContact: true)
                }
            } else if info.suiteType == .legacyFree || info.suiteToQuota.certStandardMaxSize == nil {
                //后端未返回标准版大小直接不展示容量框view
                alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, customTips: customTips, showContact: showContact, quotaUploadInfo: info, handler: nil)
            } else {
                let setViewContext = SetViewTitleContext(leftSize: info.suiteToQuota.certStandardMaxSize?.memoryFormatWithoutFlow, midSize: info.suiteToQuota.businessMaxSize?.memoryFormatWithoutFlow, rightSize: info.suiteToQuota.enterpriseMaxSize?.memoryFormatWithoutFlow, leftversion: BundleI18n.SKResource.CreationMobile_version_standard, midversion: BundleI18n.SKResource.CreationMobile_version_business, rightVersion: BundleI18n.SKResource.CreationMobile_version_enterprise)
                alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, customTips: customTips, showContact: showContact, quotaUploadInfo: info) { view in
                    view.setViewTitle(context: setViewContext)
                }
            }
        }
        
        alert.delegate = self
        if from.isMyWindowRegularSizeInPad {
            alert.modalPresentationStyle = .formSheet
        } else {
            alert.modalPresentationStyle = .overFullScreen
        }
        self.delayShowAlert(alert: alert, from: from)
        self.reportUploadView(event: .driveUploadLimitView, quotaUploadInfo: info)
    }
    
    // 用户上传大文件容量提示
    public func showUserUploadAlert(mountNodeToken: String?,
                                    mountPoint: String?,
                                    from: UIViewController,
                                    fileSize: Int64,
                                    quotaType: QuotaAlertType) {
        requestQuotaUploadInfo(mountNodeToken: mountNodeToken, mountPoint: mountPoint) { [weak self] info in
            guard let self = self else { return }
            /// 拉取商业化信息失败弹出兜底文案
            guard let info = info else {
                self.featchBusinessInfoFailedAlert(from: from, quotaType: quotaType)
                return
            }
            self.handlerUploadAlert(fileSize: fileSize, info: info, quotaType: quotaType, from: from)
        }
    }
    
    public func featchBusinessInfoFailedAlert(from: UIViewController, quotaType: QuotaAlertType) {
        let alert = QuotaAlertViewController(quotaType: quotaType, fromVC: from, showContact: true)
        alert.delegate = self
        if from.isMyWindowRegularSizeInPad {
            alert.modalPresentationStyle = .formSheet
        } else {
            alert.modalPresentationStyle = .overFullScreen
        }
        self.delayShowAlert(alert: alert, from: from)
    }
    
    private func getMaxUploadSizeDetail(quotaType: QuotaAlertType) -> String {
        switch quotaType {
        case .bigFileUpload:
            return BundleI18n.SKResource.__CreationMobile_Drive_Lark_Upload_Max_content3
        case .bigFileToCopy:
            return BundleI18n.SKResource.__CreationMobile_Drive_Lark_Duplicate_Max_content3
        case .bigFileSaveToSpace:
            return BundleI18n.SKResource.__CreationMobile_Drive_Lark_Save_Max_content3
        default:
            spaceAssertionFailure("The quotaType not BigFile limit Type")
            return ""
        }
    }
    
    // 避免弹出的fromVC.presentedViewController 正在dismiss，导致弹出的弹框一起dismiss了
    private func delayShowAlert(alert: QuotaAlertViewController,
                                type: QuotaAlertType,
                                from: UIViewController,
                                quotaType: QuotaType,
                                bizParams: SpaceBizParameter? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            if let presentedVC = from.presentedViewController {
                if !presentedVC.isKind(of: QuotaAlertViewController.self) {
                    Navigator.shared.present(alert, from: presentedVC, animated: true) {
                        switch quotaType {
                        case .tenant:
                            self.report(type: type, event: .commonPricePopup)
                        case let .user(info):
                            self.reportUserStorage(event: .storageExcessView, quotaInfo: info, bizParams: bizParams)
                        }
                    }
                } else {
                    DocsLogger.info("quotaAlertView has been showed")
                }
            } else {
                Navigator.shared.present(alert, from: from, animated: true) {
                    switch quotaType {
                    case .tenant:
                        self.report(type: type, event: .commonPricePopup)
                    case let .user(info):
                        self.reportUserStorage(event: .storageExcessView, quotaInfo: info, bizParams: bizParams)
                    }
                }
            }
        }
    }
    
    private func delayShowAlert(alert: QuotaAlertViewController, from: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            if let presentedVC = from.presentedViewController {
                if !presentedVC.isKind(of: QuotaAlertViewController.self) {
                    Navigator.shared.present(alert, from: presentedVC, animated: true)
                } else {
                    DocsLogger.info("quotaAlertView has been showed")
                }
            } else {
                Navigator.shared.present(alert, from: from, animated: true)
            }
        }
    }
    
    fileprivate func report(type: QuotaAlertType, event: DocsTracker.EventType) {
        let tennantID = User.current.basicInfo?.tenantID ?? ""
        let isSuper = User.current.info?.isSuperAdmin ?? false
        let userID = User.current.basicInfo?.userID ?? ""
        var params = ["tenant_id": DocsTracker.encrypt(id: tennantID),
                      "user_unique_id": DocsTracker.encrypt(id: userID),
                      "function_type": type.statisticValue,
                      "admin_flag": isSuper ? "true" : "false"]
        if event == .commonPricePopClick {
            params["target"] = "none"
        }
        DocsTracker.log(enumEvent: event, parameters: params)
    }
    
    fileprivate func reportUserStorage(event: DocsTracker.EventType,
                                       quotaInfo: QuotaInfo?,
                                       bizParams: SpaceBizParameter?,
                                       addition: [AnyHashable: Any]? = nil) {
        var params = [AnyHashable: Any]()
        params["is_default"] = (quotaInfo == nil) ? "true" : "false"
        if let owner = quotaInfo?.ownerState?.contacts.first,
           let curUser = quotaInfo?.myState.contacts.first,
           owner.uid != curUser.uid {
            params["is_owner"] = "false"
        } else {
            params["is_owner"] = "true"
        }
        params["is_folder"] = "false"
        if let biz = bizParams {
            params.merge(other: biz.params)
        }
        if let addParam = addition {
            params.merge(other: addParam)
        }
        
        DocsLogger.debug("user storage params: \(params)")
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }
    
    private func reportUploadView(event: DocsTracker.EventType, quotaUploadInfo: QuotaUploadInfo) {
        let params = bigFileUploadStatisticValue(quotaUploadInfo: quotaUploadInfo)
        DocsLogger.debug("user upload params: \(params)")
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }
    
    private func bigFileUploadStatisticValue(quotaUploadInfo: QuotaUploadInfo) -> [String: Any] {
        var larkVersion: String
        var memberType = "user"
        var limitType: Int64
        switch quotaUploadInfo.suiteType {
        case .legacyFree:
            larkVersion = "standard_eone"
            limitType = quotaUploadInfo.suiteToQuota.legacyFreeMaxSize?.intInGB ?? 0
        case .legacyEnterprise:
            larkVersion = "flagship_etwo"
            limitType = quotaUploadInfo.suiteToQuota.legacyEnterpriseMaxSize?.intInGB ?? 0
        case .standard:
            larkVersion = "standard_ethree"
            limitType = quotaUploadInfo.suiteToQuota.standardMaxSize?.intInGB ?? 0
        case .certStandard:
            larkVersion = "standard_ethree_certified"
            limitType = quotaUploadInfo.suiteToQuota.certStandardMaxSize?.intInGB ?? 0
        case .business:
            larkVersion = "enterprise_efour"
            limitType = quotaUploadInfo.suiteToQuota.businessMaxSize?.intInGB ?? 0
        case .enterprise:
            larkVersion = "flagship_efive"
            limitType = quotaUploadInfo.suiteToQuota.enterpriseMaxSize?.intInGB ?? 0
        }
        if quotaUploadInfo.isAdmin {
            memberType = "administrator"
        }
        
        var params: [String: Any] = [:]
        params["lark_version"] = larkVersion
        params["member_type"] = memberType
        params["limit_type"] = limitType
        return params
    }
    
    private func requestQuotaInfo(mountNodeToken: String?, mountPoint: String?, completion: @escaping (QuotaInfo?) -> Void) {
        var params = [String: Any]()
        if let token = mountNodeToken, let point = mountPoint {
            params["mount_node_token"] = token
            params["mount_point"] = point
        }
        request?.cancel()
        DocsLogger.info("start request quota info")
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.quotaInfo,
                                    params: params)
            .set(method: .GET)
            .set(needVerifyData: false)
            .set(timeout: 2.5) // 降低等待时间，超时展示兜底文案
        request?.start(result: { result, error in
            if let error = error {
                DocsLogger.error("request failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                DocsLogger.error("request failed data invalide")
                completion(nil)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("request failed server code: \(code)")
                completion(nil)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("request failed no data")
                completion(nil)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               let info = try? JSONDecoder().decode(QuotaInfo.self, from: jsonData) {
                completion(info)
            } else {
                DocsLogger.error("request failed: decode data failed")
                completion(nil)
            }
        })
    }
    
    private func requestQuotaUploadInfo(mountNodeToken: String?, mountPoint: String?, completion: @escaping (QuotaUploadInfo?) -> Void) {
        var params = [String: Any]()
        if let token = mountNodeToken, let point = mountPoint {
            params["mount_node_token"] = token
            params["mount_point"] = point
        }
        request?.cancel()
        DocsLogger.info("start request quota info")
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.uploadInfo,
                                    params: params)
            .set(method: .GET)
            .set(needVerifyData: false)
            .set(timeout: 2.5)
        request?.start(result: {[weak self] result, error in
            if let error = error {
                DocsLogger.error("request failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                DocsLogger.error("request failed data invalide")
                completion(nil)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("request failed server code: \(code)")
                completion(nil)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("request failed no data")
                completion(nil)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               var info = try? JSONDecoder().decode(QuotaUploadInfo.self, from: jsonData) {
                let maxSize = self?.getMaxSize(data: data)
                info.setMaxSize(maxSize)
                completion(info)
            } else {
                DocsLogger.error("request failed: decode data failed")
                completion(nil)
            }
        })
    }
    
    private func getMaxSize(data: [String: Any]) -> Int64? {
        guard let quota = data["suite_to_file_size_limit"] as? [String: Any] else {
            DocsLogger.info("parse suite to file size limit failed")
            return nil
        }
        
        let values = quota.values.compactMap { $0 as? Int64 }
        
        var maxSize: Int64 = 0
        for value in values where value > maxSize {
            maxSize = value
        }
        return maxSize
    }
    
    private func attributedTips(quotaInfo: QuotaInfo?) -> NSAttributedString {
        guard let quota = quotaInfo, let curUid = User.current.info?.userID else {
            return QuotaAttrStringHelper.defaultTips(template: BundleI18n.SKResource.CreationMobile_Common_storage_full_toast)
        }
        if let ownerState = quota.ownerState, let ownerContact = ownerState.contacts.first, ownerContact.uid != curUid {
            let tips = BundleI18n.SKResource.__CreationMobile_Common_storage_other_full_toast
            return QuotaAttrStringHelper.tipsWithOwner(template: tips, usage: ownerState.usage, limited: ownerState.limit, owner: ownerContact)
        } else {
            return getTipsWithAdmin(quota: quota)
        }
    }
    
    private func attributedTipsOfUpload(type: QuotaAlertType, info: QuotaUploadInfo, maxSize: Int64, version: String, verifiledSize: Int64?) -> NSAttributedString {
        var customTips: NSAttributedString
        if info.isAdmin {
            customTips = QuotaAttrStringHelper.tipsOfFileUploadWithOwner(type: type,
                                                                         template: BundleI18n.SKResource.__CreationMobile_Drive_Upload_Max_content1,
                                                                         version: version,
                                                                         maxSize: maxSize.memoryFormatWithoutFlow,
                                                                         verifiledSize: verifiledSize?.memoryFormatWithoutFlow)
        } else {
            let context = TipsOfFileUploadContext(type: type, template: BundleI18n.SKResource.__CreationMobile_Drive_Upload_Max_content2, version: version, maxSize: maxSize.memoryFormatWithoutFlow, verifiledSize: verifiledSize?.memoryFormatWithoutFlow)
            customTips = QuotaAttrStringHelper.tipsOfFileUploadWithAdmin(context: context, info: info)
        }
        return customTips
    }
    
    private func getTipsWithAdmin(quota: QuotaInfo) -> NSAttributedString {
        guard let type = quota.tenantState.config_type else {
            return QuotaAttrStringHelper.tipsWithOriginAdmin(template: BundleI18n.SKResource.__CreationMobile_Common_storage_me_full_toast,
                                                       usage: quota.myState.usage,
                                                       limited: quota.myState.limit,
                                                       admins: quota.tenantState.contacts)
        }
        switch type {
        case .contact:
            //超级管理员limitSize为3
            return QuotaAttrStringHelper.tipsWithAdmin(template: BundleI18n.SKResource.__LarkCCM_Drive_StorageLimited_ContactSuperAdmin,
                                                       usage: quota.myState.usage,
                                                       limited: quota.myState.limit,
                                                       admins: quota.tenantState.contacts,
                                                       limitSize: 3)
        case .fileContact:
            return QuotaAttrStringHelper.tipsWithUrlAdmin(template: BundleI18n.SKResource.__LarkCCM_Drive_StorageLimited_ClickLink,
                                                          usage: quota.myState.usage,
                                                          limited: quota.myState.limit,
                                                          admins: quota.tenantState.url_link)
        case .orderContact:
            //指定成员最多10个
            return QuotaAttrStringHelper.tipsWithAdmin(template: BundleI18n.SKResource.__LarkCCM_Drive_StorageLimited_ContactAppointedRole,
                                                       usage: quota.myState.usage,
                                                       limited: quota.myState.limit,
                                                       admins: quota.tenantState.conf_contacts ?? [],
                                                       limitSize: 10)
        }
    }
}

extension QuotaAlertPresentor: QuotaAlertDelegate {
    
    func conformClose(quotaInfo: QuotaInfo?, bizParams: SpaceBizParameter?) {
        let addParams = ["click": "close"] as [AnyHashable: Any]
        reportUserStorage(event: .storageExcessClick, quotaInfo: quotaInfo, bizParams: bizParams, addition: addParams)
    }
    
    func gotoCustomService(type: QuotaAlertType, from: UIViewController) {
        guard let url = Self.contactURL else {
            DocsLogger.info("contact url invalid")
            return
        }
        self.report(type: type, event: .commonPricePopClick)
        Navigator.shared.push(url, from: from)
    }
    
    func handleAttribute(info: QuotaAttributeInfo,
                         from: UIViewController,
                         bizParams: SpaceBizParameter?,
                         quotaInfo: QuotaInfo?,
                         quotaUploadInfo: QuotaUploadInfo?) {
        switch info {
        case let .quotaContact(atInfo):
            HostAppBridge.shared.call(ShowUserProfileService(userId: atInfo.uid, fileName: nil, fromVC: from))
            var addParams = [AnyHashable: Any]()
            addParams["click"] = atInfo.isAdmin ? "admin" : "owner"
            reportUserStorage(event: .storageExcessClick, quotaInfo: quotaInfo, bizParams: bizParams, addition: addParams)
        
        case let .link(urlString):
            if let url = URL(string: urlString) {
                Navigator.shared.push(url, from: from)
                uploadEventReport(quotaUploadInfo: quotaUploadInfo, clickEvent: .certification)
            }
        case let .admin(atInfo):
            HostAppBridge.shared.call(ShowUserProfileService(userId: atInfo.uid, fileName: nil, fromVC: from))
            uploadEventReport(quotaUploadInfo: quotaUploadInfo, clickEvent: .administrator)
        }
        
    }
    
    func uploadEventReport(quotaUploadInfo: QuotaUploadInfo?, clickEvent: QuotaUploadClickEvent) {
        guard let info = quotaUploadInfo else { return }
        let click: String
        switch clickEvent {
        case .contact:
            click = "contact_service"
        case .certification:
            click = "lark_certification"
        case .alreadyKonw:
            click = "already_know"
        case .administrator:
            click = "contact_administrator"
        case .close:
            click = "close"
        }
        var params = bigFileUploadStatisticValue(quotaUploadInfo: info)
        let addtion = ["click": click, "target": "none"]
        params.merge(other: addtion)
        DocsTracker.newLog(enumEvent: .driveUploadLimitViewClick, parameters: params)
    }
}

public extension QuotaAlertType {
    var image: UIImage {
        switch self {
        case .upload, .makeCopy, .saveToSpace, .createByTemplate, .saveAsTemplate, .cannotEditFullCapacity, .bigFileUpload, .bigFileToCopy, .bigFileSaveToSpace:
            return UDEmptyType.ccmPositiveStorageLimit.defaultImage()
        case .translate:
            return UDEmptyType.ccmPositiveTranslationLimit.defaultImage()
        case .userQuotaLimited:
            spaceAssertionFailure("user quota wont use image")
            return UDEmptyType.ccmPositiveStorageLimit.defaultImage()
        }
    }
    
    var title: String {
        switch self {
        case .upload, .makeCopy, .saveToSpace, .createByTemplate, .saveAsTemplate, .cannotEditFullCapacity:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceMaxToast
        case .translate:
            return BundleI18n.SKResource.CreationMobile_Docs_Billing_Translation_Title
        case .bigFileUpload:
            return BundleI18n.SKResource.CreationMobile_Drive_Upload_No_MaxSizeReached(BundleI18n.SKResource.CreationMobile_Drive_Upload_No_MaxSizeReached_var)
        case .bigFileToCopy:
            return BundleI18n.SKResource.CreationMobile_Drive_Upload_No_MaxSizeReached(BundleI18n.SKResource.CreationMobile_Drive_Duplicate_No_MaxSizeReached_var)
        case .bigFileSaveToSpace:
            return BundleI18n.SKResource.CreationMobile_Drive_Upload_No_MaxSizeReached(BundleI18n.SKResource.CreationMobile_Drive_Save_No_MaxSizeReached_var)
        case .userQuotaLimited:
            spaceAssertionFailure("user quota wont use title")
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceMaxToast
        }
    }
    
    var detail: String {
        switch self {
        case .upload:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceMaxDesc
        case .translate:
            return BundleI18n.SKResource.CreationMobile_Docs_Biling_MaxTranslationTimes_Toast
        case .makeCopy:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceCantCopyDesc
        case .saveToSpace:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceCantSaveDesc
        case .createByTemplate:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceCantCreateDesc
        case .saveAsTemplate:
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceCantTemplateDesc
        case .cannotEditFullCapacity:
            return BundleI18n.SKResource.CreationMobile_ECM_CapacityFullCannotEdit
        case .bigFileUpload:
            return BundleI18n.SKResource.CreationMobile_Drive_Upload_NotSupported()
        case .bigFileToCopy:
            return BundleI18n.SKResource.CreationMobile_Drive_Duplicate_NotSupported()
        case .bigFileSaveToSpace:
            return BundleI18n.SKResource.CreationMobile_Drive_Save_NotSupported()
        case .userQuotaLimited:
            spaceAssertionFailure("user quota wont use detail")
            return BundleI18n.SKResource.CreationMobile_ECM_SpaceMaxDesc
        }
    }
    
    var statisticValue: String {
        switch self {
        case .upload, .makeCopy, .saveToSpace, .createByTemplate, .saveAsTemplate, .cannotEditFullCapacity:
            return "drive_storage_limit"
        case .translate:
            return "doc_translation_number_limit"
        case .userQuotaLimited, .bigFileUpload, .bigFileToCopy, .bigFileSaveToSpace:
            spaceAssertionFailure("user quota 不使用这里的埋点信息")
            return "drive_storage_limit"
        }
    }
}

private extension Int64 {
    var intInGB: Int64 {
        Int64(self) / 1024 / 1024 / 1024
    }
}

enum QuotaAttributeInfo {
    case quotaContact(qutoContact: QuotaContact)
    case link(url: String)
    case admin(admin: Admin)
}

enum QuotaUploadClickEvent {
    case contact  /// 联系客服
    case certification /// 认证说明
    case alreadyKonw /// 我知道了
    case administrator  /// 点击管理员名字
    case close      /// 关闭
}
