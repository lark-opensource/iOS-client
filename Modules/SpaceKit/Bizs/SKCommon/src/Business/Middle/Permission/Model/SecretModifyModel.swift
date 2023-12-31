//
//  SecretModifyViewModel.swift
//  SKCommon
//
//  Created by guoqp on 2022/8/5.
//
//  swiftlint:disable

import Foundation
import SwiftyJSON
import SKFoundation
import RxSwift
import RxRelay
import SwiftUI
import SKResource
import SKInfra
import SpaceInterface

public enum SecretApprovalType {
    case NotApproval //未开启审批
    case NoRepeatedApproval //无重复审批
    case SelfRepeatedApproval(approvalDef: SecretLevelApprovalDef, approvalList: SecretLevelApprovalList)
    case OtherRepeatedApproval(approvalDef: SecretLevelApprovalDef, approvalList: SecretLevelApprovalList)
}

public final class SecretModifyViewModel {
    public let originalLevel: SecretLevel  /// 当前密级详情
    public private(set) var label: SecretLevelLabel ///目标密级
    public private(set) var wikiToken: String?
    public let token: String
    public let type: Int
    public private(set) var approvalDef: SecretLevelApprovalDef?
    public private(set) var approvalList: SecretLevelApprovalList?
    public private(set) var permStatistic: PermissionStatistics?
    public private(set) var instanceCode: String?
    var reason: String = ""
    public weak var followAPIDelegate: BrowserVCFollowDelegate?

    var displayReviewers: [SecretLevelApprovalReviewer] {
        ///取前3
        guard let reviewers = approvalDef?.reviewers else { return [] }
        return Array(reviewers.prefix(3))
    }

    var needApproval: Bool {
        switch approvalType {
        case .NotApproval: return false
        default: return true
        }
    }

    public let approvalType: SecretApprovalType

    public init(approvalType: SecretApprovalType,
                originalLevel: SecretLevel,
                label: SecretLevelLabel,
                wikiToken: String?,
                token: String,
                type: Int,
                approvalDef: SecretLevelApprovalDef?,
                approvalList: SecretLevelApprovalList?,
                permStatistic: PermissionStatistics?,
                followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.approvalType = approvalType
        self.originalLevel = originalLevel
        self.label = label
        self.wikiToken = wikiToken
        self.token = token
        self.type = type
        self.approvalDef = approvalDef
        self.approvalList = approvalList
        self.permStatistic = permStatistic
        self.followAPIDelegate = followAPIDelegate
    }

    public func updateSecLabel() -> Completable {
        return SecretLevel.updateSecLabel(token: token, type: type, id: label.id, reason: reason)
    }

    public func createApprovalInstance() -> Completable {
        let context = CreateApprovalContext(token: token, type: type, approvalCode: approvalDef?.code ?? "", secLabelId: originalLevel.label.id, applySecLabelId: label.id, reason: reason)
        let single = SecretLevel.createApprovalInstance(context: context)
        return single.do(onSuccess: { [weak self] code in
            self?.instanceCode = code
        }).asCompletable()
    }

    public func reportPermissionSecurityDemotionView() {
        permStatistic?.reportPermissionSecurityDemotionView(isCheckOpen: approvalDef?.open == true)
    }
    public func reportPermissionSecurityDemotionClick(click: PermissionStatistics.SecurityClickAction, target: String) {
        permStatistic?.reportPermissionSecurityDemotionClick(click: click, target: target, isCheckOpen: approvalDef?.open == true)
    }
    public func reportCcmPermissionSecurityDemotionResultView(success: Bool) {
        permStatistic?.reportCcmPermissionSecurityDemotionResultView(ifSuccess: success)
    }
    public func reportCcmPermissionSecurityDemotionResultClick(click: String) {
        let target: String = DocsTracker.EventType.noneTargetView.rawValue
        permStatistic?.reportCcmPermissionSecurityDemotionResultClick(click: click, target: target)
    }
}

extension SecretModifyViewModel {
    var descriptionLabelText: String {
        if !needApproval { return BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_ModifySubtitle }
        if displayReviewers.count > 1 { return BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Note }
        if displayReviewers.count == 1 { return BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_NApprovers }
        return BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_NeedApprovers
    }
}

public final class SecretLevelViewModel {
    public private(set) var dataSource: [SecretLevelItem] = []
    public let level: SecretLevel
    public let token: String
    public private(set) var wikiToken: String?
    public let type: Int
    public private(set) var approvalDef: SecretLevelApprovalDef?
    public private(set) var approvalList: SecretLevelApprovalList?
    public private(set) var permStatistic: PermissionStatistics?
    public private(set) var userPermission: UserPermissionAbility?
    private let viewFrom: PermissionStatistics.SecuritySettingViewFrom
    private let securityType: PermissionStatistics.SecuritySettingType

    public var selectedLevelLabel: SecretLevelLabel? {
        dataSource.first { item in
            return item.selected
        }?.levelLabel
    }

    private var fetchLabelListRequest: DocsRequest<JSON>?
    public private(set) var labelList: SecretLevelLabelList?

    var displayReviewers: [SecretLevelApprovalReviewer] {
        ///取前3
        guard let reviewers = approvalDef?.reviewers else { return [] }
        return Array(reviewers.prefix(3))
    }

    public var shouldShowUpgradeAlert: Bool {
        switch approvalType {
        case .SelfRepeatedApproval: return true
        default: return false
        }
    }

    var needApproval: Bool {
        switch approvalType {
        case .NotApproval: return false
        default: return true
        }
    }

    public var otherRepeatedApprovalCount: Int {
        guard let list = approvalList, let label = selectedLevelLabel else {
            return 0
        }
        let array: [SecretLevelApprovalInstance] = list.instances.compactMap { instance in
            guard instance.applySecLabelId == label.id else {
                return nil
            }
            return instance
        }
        return array.count
    }

    public var hasSelfRepeatedApproval: Bool {
        guard let list = approvalList, let myInstance = list.myInstance,
              !myInstance.applySecLabelId.isEmpty else {
            return false
        }
        return true
    }

    public var approvalType: SecretApprovalType {
        guard LKFeatureGating.degradeApproval, let approvalDef = approvalDef, approvalDef.open,
              let approvalList = approvalList else { return .NotApproval }
        /// 调低密级降级，是否需要审批
        let needApprovalByFromLabelId = approvalDef.needApprovalByFromLabelId(fromLabelId: level.label.id)
        let needApprovalByToLabelId = approvalDef.needApprovalByToLabelId(toLabelId: selectedLevelLabel?.id ?? "")
        /// 两种情况都不需要审批，则不审批
        if !needApprovalByFromLabelId, !needApprovalByToLabelId {
            return .NotApproval
        }
        if hasSelfRepeatedApproval { return .SelfRepeatedApproval(approvalDef: approvalDef, approvalList: approvalList) }
        if otherRepeatedApprovalCount > 0 { return .OtherRepeatedApproval(approvalDef: approvalDef, approvalList: approvalList) }
        return .NoRepeatedApproval
    }

    public var isForcible: Bool {
        guard let userPermission = self.userPermission else { return false }
        return SecretBannerCreater.checkForcibleSL(canManageMeta: userPermission.isFA, level: self.level)
    }

    public init(level: SecretLevel, wikiToken: String?, token: String, type: Int, permStatistic: PermissionStatistics?, viewFrom: PermissionStatistics.SecuritySettingViewFrom) {
        self.level = level
        self.wikiToken = wikiToken
        self.token = token
        self.type = type
        self.permStatistic = permStatistic
        self.userPermission = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: token)
        self.viewFrom = viewFrom
        switch level.code {
        case .success:
            self.securityType = .normal(securityId: DocsTracker.encrypt(id: level.label.id))
        case .createFail, .requestFail:
            self.securityType = .failed
        default:
            self.securityType = .none
        }
    }

    public func request(completion: ((Bool) -> Void)?) {
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        fetchLabelList { _, _ in
            requestGroup.leave()
        }
        let canModifySecretLevel = userPermission?.canModifySecretLevel() ?? false
        if LKFeatureGating.degradeApproval && canModifySecretLevel {
            requestGroup.enter()
            SecretLevelApprovalDef.fetchApprovalDef { [weak self] def, _ in
                guard let self = self else { return }
                self.approvalDef = def
                requestGroup.leave()
            }.makeSelfReferenced()

            requestGroup.enter()
            SecretLevelApprovalList.fetchApprovalInstanceList(token: token, type: type) { [weak self] list, _ in
                guard let self = self else { return }
                self.approvalList = list
                requestGroup.leave()
            }.makeSelfReferenced()
        }
        requestGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            completion?(self.verifyData(canModifySecretLevel: canModifySecretLevel))
        }
    }

    private func verifyData(canModifySecretLevel: Bool) -> Bool {
        guard let labelList = labelList else {
            return false
        }
        if LKFeatureGating.degradeApproval && canModifySecretLevel {
            return !labelList.labels.isEmpty && approvalDef != nil && approvalList != nil
        }
        return !labelList.labels.isEmpty
    }

    private func fetchLabelList(completion: ((SecretLevelLabelList?, Error?) -> Void)?) {
        fetchLabelListRequest = SecretLevelLabelList.fetchLabelList(completion: { [weak self] list, error in
            guard let self = self else { return }
            if let list = list, !list.labels.isEmpty {
                list.labels.forEach { $0.isDefault = ($0.id == self.level.defaultLabelId) }
                self.labelList = list
            }
            completion?(list, error)
        })
    }

    public func reloadDataSoure() {
        guard let labelList = labelList else { return }
        let items: [SecretLevelItem] = labelList.labels.compactMap({ label in
            let selected = (level.label.id == label.id)
            let item = SecretLevelItem(title: label.name, subTitle: label.description, description: label.controllDes, selected: selected, levelLabel: label)
            return item
        })
        dataSource = items
    }

    public func reportPermissionSecuritySettingView() {
        var securityType = PermissionStatistics.SecuritySettingType.none
        switch level.code {
        case .success:
            securityType = .normal(securityId: DocsTracker.encrypt(id: level.label.id))
        case .createFail, .requestFail:
            securityType = .failed
        default:
            break
        }
        let isSecurityDemotion: Bool = (approvalList?.instances.count ?? 0) > 0
        let isSingleApply: Bool = (approvalList?.instances.count ?? 0) == 1
        permStatistic?.reportPermissionSecuritySettingView(viewFrom: viewFrom,
                                                           securityType: securityType,
                                                           isSecurityDemotion: isSecurityDemotion,
                                                           isSingleApply: isSingleApply)
    }

    public func reportPermissionSecuritySettingClick(click: PermissionStatistics.SecurityClickAction, target: String, securityId: String, isOriginalLevel: Bool = false) {
        let isSecurityDemotion: Bool = (approvalList?.instances.count ?? 0) > 0
        let isSingleApply: Bool = (approvalList?.instances.count ?? 0) == 1
        let context = ReportPermissionSecuritySettingClick(target: target, securityId: securityId, isSecurityDemotion: isSecurityDemotion, isSingleApply: isSingleApply, isOriginalLevel: isOriginalLevel)
        permStatistic?.reportPermissionSecuritySettingClick(context: context, viewFrom: viewFrom, click: click, securityType: securityType)
    }
    
    public func reportPermissionSecuritySettingClickModify(isHaveChangePerm: Bool) {
        permStatistic?.reportPermissionSecuritySettingClickModify(isHaveChangePerm: isHaveChangePerm)
    }

    public func reportCcmPermissionSecurityDemotionResubmitView() {
        let isSingleApply: Bool = (approvalList?.instances.count ?? 0) == 1
        let isIncludeOwn = approvalList?.myInstance?.applySecLabelId.isEmpty == false
        permStatistic?.reportCcmPermissionSecurityDemotionResubmitView(isSingleApply: isSingleApply, isIncludeOwn: isIncludeOwn)
    }
    public func reportCcmPermissionSecurityDemotionResubmitClick(click: String) {
        let isSingleApply: Bool = (approvalList?.instances.count ?? 0) == 1
        let isIncludeOwn = approvalList?.myInstance?.applySecLabelId.isEmpty == false
        var target: String = DocsTracker.EventType.noneTargetView.rawValue
        if click == "member_hover" {
            target = DocsTracker.EventType.ccmPermissionSecurityResubmitToastView.rawValue
        }
        permStatistic?.reportCcmPermissionSecurityDemotionResubmitClick(click: click, target: target, isSingleApply: isSingleApply, isIncludeOwn: isIncludeOwn)
    }
}

public enum ApprovalListViewFrom: String {
    case settingView = "from_security_setting_view" ///来自密级设置页面
    case resubmitView = "from_resubmit_view" ///来自重复提交弹窗提醒页面"
}

public final class SecretApprovalListViewModel {
    private(set) var instances: [SecretLevelApprovalInstance] = []
    public private(set) var label: SecretLevelLabel
    private var wikiToken: String?
    private let token: String
    private let type: Int
    private(set) var permStatistic: PermissionStatistics?
    private let viewFrom: ApprovalListViewFrom

    public init(label: SecretLevelLabel, instances: [SecretLevelApprovalInstance],
                wikiToken: String?, token: String, type: Int,
                permStatistic: PermissionStatistics?, viewFrom: ApprovalListViewFrom) {
        self.label = label
        self.instances = instances
        self.wikiToken = wikiToken
        self.token = token
        self.type = type
        self.permStatistic = permStatistic
        self.viewFrom = viewFrom
    }

    func reportCcmPermissionSecurityResubmitToastView() {
        let isSingleApply = (instances.count == 1)
        permStatistic?.reportCcmPermissionSecurityResubmitToastView(isSingleApply: isSingleApply, viewFrom: viewFrom.rawValue)
    }
    func reportCcmPermissionSecurityResubmitToastClick() {
        let isSingleApply = (instances.count == 1)
        permStatistic?.reportCcmPermissionSecurityResubmitToastClick(click: "check_progress",
                                                                     target: DocsTracker.EventType.noneTargetView.rawValue,
                                                                     isSingleApply: isSingleApply, viewFrom: viewFrom.rawValue)
    }

}
