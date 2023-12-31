//
//  SecretLevel.swift
//  SKCommon
//
//  Created by guoqp on 2021/11/15.
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SKFoundation
import RxSwift
import RxRelay
import SKResource
import SpaceInterface
import SKInfra

public struct CreateApprovalContext {
    public let token: String
    public let type: Int
    public let approvalCode: String
    public let secLabelId: String
    public let applySecLabelId: String
    public let reason: String
}

public final class SecretLevelPermissionControl {
    /// 只决定着是否要在权限设置页显示顶部“允许文档被分享到组织外”的开关
    public var externalAccess: Bool?

    /// 链接设置
    public var linkShareEntity: LinkShareEntity?

    /// 评论设置
    public var commentEntity: CommentEntity?

    /// 共享设置
    public var shareEntity: ShareEntity?

    /// 安全设置
    public var securityEntity: SecurityEntity?

    /// 安全设置
    public var copyEntity: CopyEntity?

    /// 分享密码相关
    public var hasLinkPassword: Bool = false
    public var linkPassword: String = ""

    /// 权限设置的类型
    public var permTypeValue: PermTypeValue?

    /// 不可选选项及其说明
    public var blockOptions: BlockOptions?

    ///对外开关权限类型
    public var externalAccessPermType: PermTypeValue.PermType {
        return permTypeValue?.externalAccessSwitch ?? .defaultType
    }

    /// 链接分享权限类型
    public var linkShareEntityType: PermTypeValue.PermType {
        return permTypeValue?.linkShareEntity ?? .defaultType
    }

    /**** 文档权限设置面板改版 增加字段 **** */
    ///谁可以管理协作者——组织维度
    public var woCanManageCollaboratorsByOrganization: WoCanManageCollaboratorsByOrganization?
    ///谁可以管理协作者——权限维度
    public var woCanManageCollaboratorsByPermission: WoCanManageCollaboratorsByPermission?
    /// 谁可对外分享
    public var woCanExternalShareByPermission: WoCanExternalShareByPermission?

    ///管控描述  对外分享描述; 安全设置描述；添加协作者描述；链接分享描述
    fileprivate var controllDes: String {
        var title: String = ""
        if let des = externalAccessSwitchControllDes, !des.isEmpty {
            title += des
        }
        if let des = securityControllDes, !des.isEmpty {
            if !title.isEmpty {
                title += BundleI18n.SKResource.CreationMobile_Common_Semicolon
            }
            title += des
        }
        if let des = manageCollaboratorsControllDes, !des.isEmpty {
            if !title.isEmpty {
                title += BundleI18n.SKResource.CreationMobile_Common_Semicolon
            }
            title += des
        }
        if let des = linkShareControllDes, !des.isEmpty {
            if !title.isEmpty {
                title += BundleI18n.SKResource.CreationMobile_Common_Semicolon
            }
            title += des
        }

        if let des = commentControllDes, !des.isEmpty {
            if !title.isEmpty {
                title += BundleI18n.SKResource.CreationMobile_Common_Semicolon
            }
            title += des
        }

        if title.isEmpty {
            //没有限制
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_NonRestrict
        } else {
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ApplyDesc + title
        }
        return title
    }

    ///对外分享设置 管控描述
    var externalAccessSwitchControllDes: String? {
        guard let externalAccess = externalAccess else { return nil }
        var title: String?
        if externalAccess {
            switch woCanExternalShareByPermission {
            case .read:
                title = ""
            case .fullAccess:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_FAShare
            default:
                break
            }
        } else {
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_Internal
        }
        return title
    }

    ///安全设置 管控描述
    var securityControllDes: String? {
        guard let securityEntity = securityEntity else { return nil }
        var title: String?
        switch securityEntity {
        case .userCanRead:
            title = ""
        case .userCanEdit:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_EditAbove
        case .onlyMe:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_FAAbove
        }
        return title
    }

    /// 添加协作者设置 管控描述
    var manageCollaboratorsControllDes: String? {
        guard let woCanManageCollaboratorsByOrganization = woCanManageCollaboratorsByOrganization else { return nil }
        guard let woCanManageCollaboratorsByPermission = woCanManageCollaboratorsByPermission else { return nil }
        var title: String?
        switch woCanManageCollaboratorsByOrganization {
        case .sameTenant:
            switch woCanManageCollaboratorsByPermission {
            case .read:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_ViewAdd
            case .edit:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_InternalEditAdd
            case .fullAccess:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_InternalFAAdd
            }
        case .anyone:
            switch woCanManageCollaboratorsByPermission {
            case .read:
                title = ""
            case .edit:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_EditAdd
            case .fullAccess:
                title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_FAAdd
            }
        }
        return title
    }

    /// 链接分享 管控描述
    var linkShareControllDes: String? {
        guard let linkShareEntity = linkShareEntity else { return nil }
        var title: String?
        switch linkShareEntity {
        case .close:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_LinkShareOff
        case .tenantCanRead:
            title = ""
        case .tenantCanEdit:
            title = ""
        case .anyoneCanRead:
            title = ""
        case .anyoneCanEdit:
            title = ""
        }
        return title
    }

    /// 评论设置 管控描述
    var commentControllDes: String? {
        guard let commentEntity = commentEntity else { return nil }
        var title: String?
        switch commentEntity {
        case .userCanRead:
            title = ""
        case .userCanEdit:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_Level_CommentEditor
        }
        return title
    }

    public init(permPublic: JSON) {
        if let permTypeValue = permPublic["perm_type"].dictionaryObject {
            self.permTypeValue = PermTypeValue(dict: permTypeValue)
        }

        if let blockOptions = permPublic["block_options"].dictionaryObject {
            self.blockOptions = BlockOptions(dict: blockOptions)
        }

        permPublic["share_entity"].int.map { self.woCanManageCollaboratorsByOrganization = WoCanManageCollaboratorsByOrganization($0) }
        permPublic["manage_collaborator_entity"].int.map { self.woCanManageCollaboratorsByPermission = WoCanManageCollaboratorsByPermission($0) }
        permPublic["security_entity"].int.map { self.securityEntity = SecurityEntity($0 - 1) }
        permPublic["copy_entity"].int.map { self.copyEntity = CopyEntity($0 - 1) }
        permPublic["comment_entity"].int.map { self.commentEntity = CommentEntity($0 - 1) }
        permPublic["link_share_entity"].int.map { self.linkShareEntity = LinkShareEntity($0 - 1) }
        permPublic["share_external_entity"].int.map { self.woCanExternalShareByPermission = WoCanExternalShareByPermission($0) }
        permPublic["link_password_switch"].bool.map { self.hasLinkPassword = $0 }
        permPublic["link_password"].string.map { self.linkPassword = $0 }
        permPublic["external_access_switch"].bool.map { self.externalAccess = $0 }
    }
}

public final class SecretLevelLabel: Equatable {
    public private(set) var id: String = ""
    public private(set) var name: String = ""
    public private(set) var description: String = ""
    public private(set) var level: Int = 0
    public private(set) var enableProtect: Bool = false
    public private(set) var control: SecretLevelPermissionControl
    /// 是否是默认密级
    public var isDefault: Bool = false

    public init(json: JSON) {
        self.control = SecretLevelPermissionControl(permPublic: json["permission_control"])
        json["id"].string.map { self.id = $0 }
        json["name"].string.map { self.name = $0 }
        json["description"].string.map { self.description = $0 }
        json["level"].int.map { self.level = $0 }
        json["enable_protect"].bool.map { self.enableProtect = $0 }
    }

    // 限单测 mock 使用
    public init(name: String, id: String) {
        self.control = SecretLevelPermissionControl(permPublic: JSON())
        self.name = name
        self.id = id
    }

    public static func == (lhs: SecretLevelLabel, rhs: SecretLevelLabel) -> Bool {
        return lhs.id == rhs.id
    }

    var controllDes: String {
        guard enableProtect else {
            return BundleI18n.SKResource.CreationMobile_SecureLabel_NonRestrict
        }
        return control.controllDes
    }
}

public enum SecLabelType: Int {
    case neverSet = 0  //0：未设置过密级
    case userCustom  //1：用户自定义
    case adminDefault //2：新建时从 admin 获取的默认密级
    case soureInherit  //3：从源文档继承的密级
    case markByAdministrator //4：管理员打标任务产生的密级
    case autoMark //5: 自动打标
    case recommendMark //6: 推荐打标
}

public enum SecretLevelCode: Int {
    case success = 0 //成功且有密级
    case requestFail = 1 //获取密级详情失败
    case createFail = 2 //创建文档时设置失败
    case empty = 3 //租户级别没有设置密级
}
public enum SecretLableBannerStatus: Int {
    case open = 0 // 表示打开
    case close = 1 // 表示关闭
    case none = 2
}
public enum SecretLableBannerType: Int {
    case autoMark = 1 // 表示自动打标
    case recommendMark = 2 // 表示推荐打标
    case none = 3
}
public enum CanSetSecLabel: Int {
    case no = 0  //没有可设置的密级
    case yes = 1 //有可以设置密级
}

public enum BannerType: Int {
    case hide = 0   // 隐藏,不展示
    case defaultSecret //有默认密级，未应用
    case empty //无默认密级，待设置
}

public enum SecretLevelError: Error {
    case requestFail
}

public final class SecretLevel {
    public private(set) var code: SecretLevelCode = .empty
    public private(set) var label: SecretLevelLabel
    // 是否有可见的密级设置列表
    public var canSetSecLabel: CanSetSecLabel = .no
    public private(set) var secLableType: SecLabelType?
    public private(set) var secLableTypeBannerStatus: SecretLableBannerStatus?
    public private(set) var secLableTypeBannerType: SecretLableBannerType?

    /// 是否要求用户必须设置密级
    public var mustSetLabel: Bool = false
    /// 是否要求用户二次确认默认标签
    public var doubleCheckDefaultLabel: Bool = false
    /// 用户的默认标签 ID
    public var defaultLabelId: String = "0"
    /// 用户的推荐密集标签ID
    public var recommendLabelId: String? = "0"
    
    private static let sec_labelBannerStatus: Int = 1

    //密级banner如何展示
    public var bannerType: BannerType {
        //不能设置不展示
        guard canSetSecLabel == .yes else {
            return .hide
        }
        var ret: BannerType = .hide
        switch code {
        case .success:
            // 有密级时判断下是不是默认密级
            ret = (secLableType == .userCustom) ? .hide : .defaultSecret
        case .createFail, .empty:
            // 无密级
            ret = .empty
        default: break
        }
        return ret
    }

    //是否为默认密级，且无改动过
    public var isDefaultLevel: Bool {
        guard let labelType = secLableType else {
            return false
        }
        var ret = false
        switch labelType {
        case .adminDefault, .soureInherit, .markByAdministrator:
            ret = true
        default:  break
        }
        return ret
    }

    public init(json: JSON) {
        self.label = SecretLevelLabel(json: json["sec_label"])
        json["get_sec_label_code"].int.map { self.code = SecretLevelCode(rawValue: $0) ?? .empty }
        self.canSetSecLabel = CanSetSecLabel(rawValue: json["can_set_sec_label"].intValue) ?? .no
        json["sec_label_type"].int.map { self.secLableType = SecLabelType(rawValue: $0) ?? .userCustom }
        json["sec_label_banner_status"].int.map { self.secLableTypeBannerStatus = SecretLableBannerStatus(rawValue: $0) ?? .none }
        json["sec_label_banner_type"].int.map { self.secLableTypeBannerType = SecretLableBannerType(rawValue: $0) ?? .none }
        json["double_check_default_label"].bool.map { self.doubleCheckDefaultLabel = $0 ?? false }
        json["must_set_label"].bool.map { self.mustSetLabel = $0 ?? false }
        self.defaultLabelId = json["default_label_id"].stringValue
        self.recommendLabelId = json["recommend_label_id"].stringValue ?? "0"
    }

    public init(label: SecretLevelLabel) {
        self.label = label
    }

    public static func secLabelSingle(token: String, type: DocsType) -> Single<SecretLevel> {
        return ShareBizMeta.metaSingle(token: token, type: ShareDocsType(rawValue: type.rawValue)).flatMap { biz -> Single<SecretLevel> in
            guard let label = biz.secretLevel else {
                throw(SecretLevelError.requestFail)
            }
            return .just(label)
        }
    }

    public static func updateSecLabel(token: String, type: Int, id: String, reason: String) -> Completable {
        DocsLogger.info("begin update sec label")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.updateSecLabel,
                                        params: ["token": token,
                                                 "type": type,
                                                 "sec_label_id": id,
                                                 "change_reason": reason])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                DocsLogger.error("update sec label falid, json \(String(describing: json))")
                throw error
            }
            guard code == 0 else {
                DocsLogger.error("update sec label falid, code is \(code)")
                throw(SecretError.wrongCode)
            }
            DocsLogger.info("update sec label success")
            return .empty()
        }
    }
    
    public static func updateSecLabelBanner(token: String, type: Int, secLabelId: String, bannerType: Int, bannerStatus: Int) -> Completable {
        DocsLogger.info("begin update sec label Banner")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.updateSecLabelBanner,
                                        params: ["obj_id": token,
                                                 "obj_type": type,
                                                 "sec_label_id": secLabelId,
                                                 "banner_type": bannerType,
                                                 "banner_status": sec_labelBannerStatus])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                DocsLogger.error("update sec label falid, json \(String(describing: json))")
                throw error
            }
            guard code == 0 else {
                DocsLogger.error("update sec label falid, code is \(code)")
                throw(SecretError.wrongCode)
            }
            DocsLogger.info("update sec label success")
            return .empty()
        }
    }
}

public final class SecretBannerCreater {
    /// 密级强制打标后的bannerType https://bytedance.feishu.cn/wiki/wikcnwua2wPfcjvResyslIULCxb
    public static func forcibleBannerType(canManageMeta: Bool, level: SecretLevel, collaboratorsCount: Int) -> SecretBannerView.BannerType {
        var type: SecretBannerView.BannerType = .hide
        let isForcible = Self.checkForcibleSL(canManageMeta: canManageMeta, level: level)
        switch level.bannerType {
        case .hide:
            type = .hide
        case .defaultSecret:
            type = isForcible ? .forcibleSecret(title: level.label.name) : .hide
        case .empty:
            if isForcible {
                type = .forcibleSecret(title: nil)
            } else {
                type = (collaboratorsCount > 1) ? .emptySecret : .hide
            }
        }
        return type
    }

    ///密级非强制打标的bannerType
    public static func unForcibleBannerType(level: SecretLevel, collaboratorsCount: Int) -> SecretBannerView.BannerType {
        var type: SecretBannerView.BannerType = .hide
        switch level.bannerType {
        case .hide:
            type = .hide
        case .defaultSecret:
            type = UserScopeNoChangeFG.GQP.sensitivityLabelsecretopt ? .hide : .defaultSecret(title: level.label.name)
        case .empty:
            if UserScopeNoChangeFG.GQP.sensitivityLabelsecretopt {
                type = (collaboratorsCount > 1) ? .emptySecret : .hide
            } else {
                type = .emptySecret
            }
        }
        return type
    }

    public static func checkForcibleSL(canManageMeta: Bool, level: SecretLevel?) -> Bool {
        guard let level = level else { return false }
        let needSetSecret = level.mustSetLabel && (level.secLableType == .neverSet)
        let needCheckSecret = level.doubleCheckDefaultLabel && level.isDefaultLevel
        let fg = LKFeatureGating.sensitivityLabelForcedEnable
        return canManageMeta && (needSetSecret || needCheckSecret) && fg
    }
    
    public static func checkForceSecretLableAutoOrRecommend(canManageMeta: Bool, level: SecretLevel?, collaboratorsCount: Int) -> SecretBannerView.BannerType {
        guard let level = level, canManageMeta else { return .hide }
        let isDefaultLevel = level.isDefaultLevel
        let needDoubleCheckCheckSecret = level.doubleCheckDefaultLabel
        let bannerType = level.secLableTypeBannerType
        let secBannerStatus = isSecLabelBannerStatusShow(level: level)
        // 文档是否有标签
        if level.label.id != "" {
            if isDefaultLevel {
                guard needDoubleCheckCheckSecret else {
                    // banner类型是否是推荐打标
                    return Self.handleRecommnedBanner(secBannerStatus: secBannerStatus, level: level, isForcible: false)
                }
                // banner类型是否是推荐打标
                if bannerType == .recommendMark {
                    return Self.handleRecommnedBanner(secBannerStatus: secBannerStatus, level: level, isForcible: true)
                } else {
                    return .forcibleSecret(title: level.label.name)
                }
            } else {
                if bannerType == .autoMark {
                    return Self.handleAutoBanner(secBannerStatus: secBannerStatus, level: level)
                } else {
                    guard secBannerStatus else { return .hide }
                    if bannerType == .recommendMark {
                        return .recommendMarkBanner(title: level.label.name)
                    } else {
                        return .hide
                    }
                }
            }
        } else {
            // 文档是否强制打标
            if Self.checkForcibleSL(canManageMeta: canManageMeta, level: level) {
                // banner类型是否是推荐打标
                if bannerType == .recommendMark {
                    return Self.handleRecommnedBanner(secBannerStatus: secBannerStatus, level: level, isForcible: true)
                } else {
                    return .forcibleSecret(title: nil)
                }
            } else {
                // banner类型是否是推荐打标
                if bannerType == .recommendMark {
                    return Self.handleRecommnedBanner(secBannerStatus: secBannerStatus, level: level, isForcible: false)
                } else {
                    if collaboratorsCount > 1 {
                        return .emptySecret
                    } else {
                        return .hide
                    }
                }
            }
        }
    }

    
    private static func handleAutoBanner(secBannerStatus: Bool, level: SecretLevel) ->SecretBannerView.BannerType {
        if secBannerStatus {
            return .autoMarkBanner(title: level.label.name)
        } else {
            return .unChangetype
        }
    }
    
    private static func handleRecommnedBanner(secBannerStatus: Bool, level: SecretLevel, isForcible: Bool) -> SecretBannerView.BannerType {
        guard secBannerStatus else { return .hide }
        if isForcible {
            return .forceRecommendMarkBanner(title: level.label.name)
        } else {
            return .recommendMarkBanner(title: level.label.name)
        }
    }
    
    private static func isSecLabelBannerStatusShow(level: SecretLevel?) -> Bool {
        guard let level = level else { return false }
        let secLabelBannerStatus = level.secLableTypeBannerStatus
        if secLabelBannerStatus == .close {
            return false
        } else {
            return true
        }
    }
}

///更多面板设置入口
public enum MoreViewItemRightStyle: Int {
    case normal = 0 //显示密级设置入口+密级名称
    case fail //显示密级设置入口+获取密级失败
    case notSet   //显示密级设置入口+未设置
    case none   // 不显示密级设置入口
}

///密级设置面板banner
public enum SecretVCBannerStyle: Int {
    case none = 0 //无banner
    case fail   //无法进入该面板
    case getDefaultLevelFail //显示获取默认密级失败【设置】
    case tips  //提示设置密级，保护文档安全
}

///权限设置banner
public enum PermissonVCBannerStyle: Int {
    case hide = 0 //不显示banner
    case update   //内部fa，提示受xx密级管控,可设置
    case tips //外部fa，提示受密级管控。不可设置
    case setting  //内部fa显示设置密级保护文档安全。可设置
}

extension SecretLevel {
    public var moreViewItemRightStyle: MoreViewItemRightStyle {
        var style: MoreViewItemRightStyle = .none
        switch code {
        case .success:
            style = .normal
        case .requestFail:
            style = .fail
        case .createFail:
            style = (canSetSecLabel == .yes) ? .notSet : .none
        case .empty:
            style = (canSetSecLabel == .yes) ? .notSet : .none
        }
        return style
    }

    public var secretVCBannerStyle: SecretVCBannerStyle {
        var style: SecretVCBannerStyle = .none
        switch code {
        case .success:
            style = .none
        case .requestFail:
            style = .fail
        case .createFail:
            style = (canSetSecLabel == .yes) ? .getDefaultLevelFail : .fail
        case .empty:
            style = (canSetSecLabel == .yes) ? .tips : .fail
        }
        return style
    }
}

public final class SecretLevelLabelList {
    public private(set) var labels: [SecretLevelLabel] = []
    public private(set) var helpLink: String?
    public init(json: JSON) {
        let list = json["sec_label_list"].arrayValue
        self.helpLink = json["help_doc_link"].string
        self.labels = list.compactMap { json in
            return SecretLevelLabel(json: json)
        }
        self.labels.sort {
            $0.level > $1.level
        }
    }

    public static func fetchLabelList(completion: ((SecretLevelLabelList?, Error?) -> Void)?) -> DocsRequest<JSON> {
        return  DocsRequest<JSON>(path: OpenAPI.APIPath.getSecLabelList, params: nil)
            .set(method: .GET)
            .start { data, error in
                guard let result = data,
                      let code = result["code"].int else {
                    DocsLogger.error("fetch sec label list failed", error: error)
                    completion?(nil, error)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("fetch sec label list failed, code is \(code)", error: error)
                    completion?(nil, error)
                    return
                }
                DocsLogger.info("fetch sec label list success, result is \(result)")
                completion?(SecretLevelLabelList(json: result["data"]), nil)
            }
    }

    public static func fetchLabelList() -> Single<SecretLevelLabelList> {
        return  DocsRequest<JSON>(path: OpenAPI.APIPath.getSecLabelList, params: nil)
            .set(method: .GET)
            .rxStart()
            .map { json in
                guard let json = json, let code = json["code"].int, code == 0 else {
                    DocsLogger.error("fetchLabelList failed!", error: DocsNetworkError.invalidData)
                    throw DocsNetworkError.invalidData
                }
                return SecretLevelLabelList(json: json["data"])
            }
    }
}

extension SpaceEntry {
    public var moreViewItemRightStyle: MoreViewItemRightStyle {
        var style: MoreViewItemRightStyle = .none
        switch secLabelCode {
        case .success:
            style = .normal
        case .requestFail:
            style = .fail
        case .createFail:
            style = (canSetSecLabel == .yes) ? .notSet : .none
        case .empty:
            style = (canSetSecLabel == .yes) ? .notSet : .none
        }
        return style
    }
    public var typeSupportSecurityLevel: Bool {
        if isShortCut {
            return false
        }
        switch type {
        case .doc, .mindnote, .file, .docX, .bitable, .sheet, .slides:
            return isSingleContainerNode
        case .wiki:
            guard let wikiEntry = self as? WikiEntry, let contentSubType = wikiEntry.wikiInfo?.docsType else {
                return false
            }
            let array: [DocsType] = [.doc, .mindnote, .file, .docX, .bitable, .sheet, .slides]
            return isWikiV2 && array.contains(contentSubType)
        default:
            return false
        }
    }

    var isWikiV2: Bool {
        return type == .wiki
    }
}

extension DocsInfo {
    public var typeSupportSecurityLevel: Bool {
        if isShortCut {
            return false
        }
        // is wiki
        if isFromWiki {
            let array: [DocsType] = [.doc, .mindnote, .file, .docX, .bitable, .sheet, .slides]
            return isWikiV2 && array.contains(inherentType)
        }
        //not wiki
        switch type {
        case .doc, .mindnote, .file, .docX, .bitable, .sheet, .slides:
            return isSingleContainerNode
        default:
            return false
        }
    }

    var isWikiV2: Bool {
        return isFromWiki
    }
}

/// 审批人
public final class SecretLevelApprovalReviewer {
    public private(set) var id: String = ""
    public private(set) var name: String = ""
    public private(set) var avatarKey: String = ""
    public init(json: JSON) {
        json["user_id"].string.map { self.id = $0 }
        json["user_name"].string.map { self.name = $0 }
        json["user_avatar_tos_url"].string.map { self.avatarKey = $0 }
    }
}

///审批策略详情
public final class SecretLevelApprovalDetail {
    public private(set) var isForAll: Bool = true
    public private(set) var fromLabelIds: [String] = []
    public private(set) var toLabelIds: [String] = []
    public init(json: JSON) {
        json["is_for_all"].bool.map { self.isForAll = $0 }
        self.fromLabelIds = json["from_label_ids"].arrayValue.compactMap({ id in
            return id.string
        })
        self.toLabelIds = json["to_label_ids"].arrayValue.compactMap({ id in
            return id.string
        })
    }
}

///审批定义
public final class SecretLevelApprovalDef {
    public private(set) var open: Bool = false
    public private(set) var reviewers: [SecretLevelApprovalReviewer] = []
    public private(set) var code: String = ""
    public private(set) var approvalDetail: SecretLevelApprovalDetail?
    public init(json: JSON) {
        json["is_open"].bool.map { self.open = $0 }
        json["approval_code"].string.map { self.code = $0 }
        let list = json["reviewers"].arrayValue
        self.reviewers = list.compactMap { json in
            return SecretLevelApprovalReviewer(json: json)
        }
        self.approvalDetail = SecretLevelApprovalDetail(json: json["approval_detail"])
    }

    ///从{fromLabelId}调低等级是否需要降级审批
    public func needApprovalByFromLabelId(fromLabelId: String) -> Bool {
        guard let detail = approvalDetail else { return true }
        if detail.isForAll { return true }
        if detail.fromLabelIds.contains(fromLabelId) { return true }
        return false
    }

    ///调低等级至{toLabelId}是否需要降级审批
    public func needApprovalByToLabelId(toLabelId: String) -> Bool {
        guard let detail = approvalDetail else { return true }
        if detail.isForAll { return true }
        if detail.toLabelIds.contains(toLabelId) { return true }
        return false
    }

    public static func fetchApprovalDef(completion: ((SecretLevelApprovalDef?, Error?) -> Void)?) -> DocsRequest<JSON> {
        DocsLogger.info("begin fetch approval Def ")
        return  DocsRequest<JSON>(path: OpenAPI.APIPath.approvalDef, params: nil)
            .set(method: .GET)
            .start { data, error in
                guard let result = data,
                      let code = result["code"].int else {
                    DocsLogger.error("fetch approval Def failed", error: error)
                    completion?(nil, error)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("fetch approval failed, code is \(code)", error: error)
                    completion?(nil, error)
                    return
                }
                DocsLogger.info("fetch approval success, result is \(result)")
                completion?(SecretLevelApprovalDef(json: result["data"]), nil)
            }
    }
}

///密级降级审批实例列表
public final class SecretLevelApprovalList {
    public private(set) var open: Bool = false
    public private(set) var instances: [SecretLevelApprovalInstance] = []
    public private(set) var myInstance: SecretLevelApprovalInstance?
    public init(json: JSON) {
        let list = json["instances"].arrayValue
        self.instances = list.compactMap { json in
            return SecretLevelApprovalInstance(json: json)
        }
        json["my_instance"]["instance_code"].string.map { _ in
            self.myInstance = SecretLevelApprovalInstance(json: json["my_instance"])
        }
    }

    public static func fetchApprovalInstanceList(token: String, type: Int, completion: ((SecretLevelApprovalList?, Error?) -> Void)?) -> DocsRequest<JSON> {
        DocsLogger.info("begin fetch approval instance List")
        return DocsRequest<JSON>(path: OpenAPI.APIPath.approvalInstanceList, params: ["token": token, "type": type])
            .set(method: .GET)
            .start { data, error in
                guard let result = data,
                      let code = result["code"].int else {
                    DocsLogger.error("fetch approval instance List failed", error: error)
                    completion?(nil, error)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("fetch approval instance List failed, code is \(code)", error: error)
                    completion?(nil, error)
                    return
                }
                DocsLogger.info("fetch approval instance List success, result is \(result)")
                completion?(SecretLevelApprovalList(json: result["data"]), nil)
            }
    }
    /// 降级到secLabelId的审批实例
    public func instances(with secLabelId: String) -> [SecretLevelApprovalInstance] {
        instances.compactMap {
            guard $0.applySecLabelId == secLabelId else { return nil }
            return $0
        }
    }
}

public final class SecretLevelApprovalInstance {
    public private(set) var instanceCode: String = ""
    public private(set) var objId: String = ""
    public private(set) var objType: Int64 = 0
    public private(set) var userId: String = ""
    public private(set) var userName: String = ""
    public private(set) var userAvatarUrl: String = ""
    public private(set) var secLabelId: String = ""
    public private(set) var applySecLabelId: String = ""
    public private(set) var createTime: Int64 = 0
    public init(json: JSON) {
        json["instance_code"].string.map { self.instanceCode = $0 }
        json["obj_id"].string.map { self.objId = $0 }
        json["obj_type"].int64.map { self.objType = $0 }
        json["user_id"].string.map { self.userId = $0 }
        json["user_name"].string.map { self.userName = $0 }
        json["user_avatar_url"].string.map { self.userAvatarUrl = $0 }
        json["sec_label_id"].string.map { self.secLabelId = $0 }
        json["apply_sec_label_id"].string.map { self.applySecLabelId = $0 }
        json["create_time"].int64.map { self.createTime = $0 }
    }

    public var belongsToTheCurrentUser: Bool {
        guard let currentUserID = User.current.basicInfo?.userID, !userId.isEmpty else {
            return false
        }
        return currentUserID == userId
    }
}

public enum SecretError: Error {
    case wrongCode
}

extension SecretLevel {
    public static func createApprovalInstance(context: CreateApprovalContext) -> Single<String> {
        DocsLogger.info("begin create approval instance")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.approvalInstanceCreate,
                                        params: ["token": context.token,
                                                 "type": context.type,
                                                 "approval_code": context.approvalCode,
                                                 "sec_label_id": context.secLabelId,
                                                 "apply_sec_label_id": context.applySecLabelId,
                                                 "change_reason": context.reason])
        return request.rxStart().map { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                DocsLogger.error("create approval instance falid, json \(String(describing: json))")
                throw error
            }
            guard code == 0, let json = json,
                  let instanceCode = json["data"]["instance_code"].string, !instanceCode.isEmpty else {
                DocsLogger.error("create approval instance falid, code is \(String(describing: code))")
                throw(SecretError.wrongCode)
            }
            DocsLogger.info("create approval instance success")
            return instanceCode
        }
    }
}
