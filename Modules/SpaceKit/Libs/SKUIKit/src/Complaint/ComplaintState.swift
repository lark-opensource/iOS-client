//
//  ComplaintState.swift
//  SKUIKit
//
//  Created by peilongfei on 2023/9/27.
//  


import Foundation
import SKResource
import UniverseDesignColor

fileprivate let complaintLineHeightMultiple: CGFloat = 1.02
fileprivate let complaintLineSpacing: CGFloat = 4
fileprivate let complaintFontSize: CGFloat = 14

public enum ComplaintState: Equatable, Hashable {
    private typealias Resource = BundleI18n.SKResource
    case machineVerify  // 机器审核
    case verifying   // 审核中
    case verifyFailed  // 审核失败
    case unchanged    // 修改时间小于上次申诉时间
    case reachVerifyLimitOfDay  // 到达当日审核上限
    case reachVerifyLimitOfAll // 到达总共审核上限
    // 默认值
    public var detail: String {
        switch self {
        case .machineVerify:
            return Resource.CreationMobile_Suspend_Folder_banner(Resource.CreationMobile_appealing_folder_submit)
        case .verifying:
            return Resource.CreationMobile_appealing_folder_pending
        case .verifyFailed:
            return Resource.CreationMobile_appealing_folder_decline(Resource.CreationMobile_appealing_folder_submit)
        case .unchanged:
            return Resource.CreationMobile_appealing_folder_identical
        case .reachVerifyLimitOfDay:
            return Resource.CreationMobile_ECM_Folder_SubmitThreeTimesToast
        case .reachVerifyLimitOfAll:
            return Resource.CreationMobile_ECM_Folder_SubmitMaximumToast(Resource.CreationMobile_ECM_Folder_SubmitMaximumToast2)
        }
    }

    // // 新版申诉文案
    public var appealV2: String {
        switch self {
        case .machineVerify:
            return Resource.LarkCCM_Security_DocShareSuspend_UserAgreeMent_Banner(Resource.LarkCCM_Security_UserAgreement_Link, Resource.LarkCCM_Security_SubmitAppeal_Link)
        case .verifyFailed:
            return Resource.LarkCCM_Security_AppealFailed_Banner(Resource.LarkCCM_Security_Appeal_Link)
        case .unchanged:
            return Resource.CreationMobile_appealing_Wiki_folder_identical
        case .reachVerifyLimitOfDay:
            return Resource.LarkCCM_Security_AppealFailed_LimitsToday_Banner(Resource.LarkCCM_Security_ContactSupport_Link)
        case .reachVerifyLimitOfAll:
            return Resource.LarkCCM_Security_AppealFailed_Limits_Banner(Resource.LarkCCM_Security_ContactSupport_Link)
        case .verifying:
            return Resource.LarkCCM_Security_AppealInProcess_Banner(Resource.LarkCCM_Security_AppealProgress_Link)
        }
    }

    // 新版文件夹申诉文案
    public var folderAppealV2: String {
        switch self {
        case .machineVerify:
            return Resource.LarkCCM_Security_FolderShareSuspend_UserAgreeMent_Banner(Resource.LarkCCM_Security_UserAgreement_Link, Resource.LarkCCM_Security_SubmitAppeal_Link)
        case .verifyFailed:
            return Resource.LarkCCM_Security_AppealFailed_Banner(Resource.LarkCCM_Security_Appeal_Link)
        case .unchanged:
            return Resource.CreationMobile_appealing_Wiki_folder_identical
        case .reachVerifyLimitOfDay:
            return Resource.LarkCCM_Security_AppealFailed_LimitsToday_Banner(Resource.LarkCCM_Security_ContactSupport_Link)
        case .reachVerifyLimitOfAll:
            return Resource.LarkCCM_Security_AppealFailed_Limits_Banner(Resource.LarkCCM_Security_ContactSupport_Link)
        case .verifying:
            return Resource.LarkCCM_Security_AppealInProcess_Banner(Resource.LarkCCM_Security_AppealProgress_Link)
        }
    }

    // 新版申诉提示类型
    public var appealTipsType: TipType {
        switch self {
        case .machineVerify:
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case .verifyFailed:
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case .unchanged:
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case .reachVerifyLimitOfDay:
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case .reachVerifyLimitOfAll:
            return TipType.custom(TipType.ShowStyle.levelStyleError)
        case .verifying:
            return TipType.custom(TipType.ShowStyle.levelStyleNormal)
        }
    }

    // wiki 文件夹特化值
    public static var wikiDetail: [ComplaintState: String] {
        return [
            .machineVerify: Resource.CreationMobile_Suspend_Wiki_Folder_banner(Resource.CreationMobile_appealing_folder_submit),
            .verifyFailed: Resource.CreationMobile_appealing_Wiki_folder_decline(Resource.CreationMobile_appealing_folder_submit),
            .unchanged: Resource.CreationMobile_appealing_Wiki_folder_identical,
            .reachVerifyLimitOfDay: Resource.CreationMobile_ECM_Wiki_Folder_SubmitThreeTimesToast
        ]
    }

    // drive 文件特化值
    public static var driveDetail: [ComplaintState: String] {
        return [
            .machineVerify: Resource.LarkCCM_Appeal_ShareRestricted_SubmitAppeal_Banner(Resource.CreationMobile_appealing_folder_submit),
            .verifyFailed: Resource.LarkCCM_Appeal_SubmitToFS_NotApproved_Toast,
            .unchanged: Resource.CreationMobile_appealing_Wiki_folder_identical,
            .reachVerifyLimitOfDay: Resource.LarkCCM_Appeal_SubmitToFS_OverLimit_Descrip,
            .reachVerifyLimitOfAll: Resource.CreationMobile_ECM_SubmitMaximumToast,
            .verifying: Resource.LarkCCM_Appeal_SubmitToFS_Submitted_Banner
        ]
    }

    public func overrideDetail(using overrideContent: [ComplaintState: String]) -> String {
        overrideContent[self] ?? detail
    }


    static var attributesForContent: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = complaintLineHeightMultiple
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = complaintLineSpacing
        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = UIFont.systemFont(ofSize: complaintFontSize)
        attributes[.foregroundColor] = UDColor.N600
        attributes[.paragraphStyle] = paragraphStyle
        return attributes
    }
}
