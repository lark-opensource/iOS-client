//
//  UDEmptyType.swift
//  UniverseDesignEmpty
//
//  Created by 王元洵 on 2020/9/28.
//

import UIKit
import Foundation
typealias BundleResources = EmptyBundleResources

// swiftlint:disable all
///空状态类型
public enum UDEmptyType {
    // MARK: 旧命名待删除
    /// 无收藏 旧命名待删除 改为 noFavourite
    case noCollection
    /// 无权限 旧命名待删除 改为 noAccess
    case noAuthority
    /// 无消息记录 旧命名待删除 改为 noMessageLog
    case noRecord
    /// 无公告 旧命名待删除 改为 noAnnouncement
    case noNotice
    /// 无搜索结果 旧命名待删除 改为 searchFailed
    case noSearchResult
    /// 无链接 旧命名待删除 改为 noLink
    case noURL
    /// 无图片 旧命名待删除 改为 noPicture
    case noImage
    /// 无服务台 旧命名待删除 改为 noServiceDesk
    case noDesk
    /// 无小组 旧命名待删除 改为 noTeam
    case noSmallGroup
    /// PIN 旧命名待删除 改为 pin
    case PIN
    /// 无wifi 旧命名待删除 改为 noWifi
    case noInternet
    /// 无机器人 旧命名待删除 改为 noRobot
    case negtive
    /// 报错 旧命名待删除 改为 error
    case wrong

    // MARK: 中性
    /// 初始化
    case initial
    /// 无收藏
    case noFavourite
    /// 无预览
    case noPreview
    /// 无权限
    case noAccess
    /// 无内容
    case noContent
    /// 无机器人
    case noRobot
    /// 无日程
    case noSchedule
    /// 无消息记录
    case noMessageLog
    /// 无联系人
    case noContact
    /// 无公告
    case noAnnouncement
    /// 无知识库
    case noWiki
    /// 无帖子
    case noPost
    /// 无搜索结果
    case searchFailed
    /// 无链接
    case noLink
    /// 无邮件
    case noMail
    /// 无应用
    case noApplication
    /// 无文件
    case noFile
    /// 无图片
    case noPicture
    /// 无云空间文件
    case noCloudFile
    /// 无服务台
    case noServiceDesk
    /// 无小组
    case noTeam
    /// 无群组
    case noGroup
    /// 无会议
    case noMeeting
    /// 无会议室
    case noMeetingroom
    /// 升级状态
    case upgraded
    /// 无数据
    case noData
    /// 恢复中
    case restoring


    // MARK: 正反馈
    /// pin
    case pin
    /// 任务完成
    case done
    /// 创建直播
    case createLive
    /// 创建规则
    case createRule
    /// 创建主题
    case createTopic
    /// 绑定成功
    case bindSuccess
    /// 默认 - 新插画暂失
    case defaultPage
    /// 添加朋友
    case addFriends
    /// 搜索
    case search

    // MARK: 负反馈
    /// 报错
    case error
    /// 加载失败
    case loadingFailure
    /// 无wifi
    case noWifi
    /// 404
    case code404
    /// 500
    case code500

    // MARK: Admin
    case adminDefault
    case adminPassportDefault
    case adminNoCertified
    case adminNoCheck


    // MARK: CCM
    case documentDefault
    case ccmCountLimit
    case ccmEditorLimit
    case ccmNoWorkFlow
    case ccmStorageLimit
    case ccmTranslationLimit
    case ccmFirstEntry
    case ccm429
    case ccm400_403
    case ccmPositiveStorageLimit
    case ccmPositiveTranslationLimit
    case ccmDocumentKeyUnavailable
    case ccmAdvancedPermissionUpgrade

    // MARK: Email
    case emailDefault
    case emailBindFailure
    case emailNoRule
    case emailCreateSignature
    case emailSuccessfulMove
    case emailWelComeAndLink

    // MARK: IM
    case imDefault
    case imAddApplication
    case imNoRedEnvelop
    case imNeutralProfileNoMedal
    case imSetup
    case imSubscribeTabNoTopic
    case imWidgetNoSchedule
    case imWidgetNoTask


    // MARK: Platform
    case platformNoAppDisabled
    case platformNoNotShow
    case platformNoPendingOrder
    case platformAddRobot1
    case platformAddRobot2
    case platformApplicationManagement
    case platformMessageAction1
    case platformMessageAction2
    case platformPlusMenu
    case platformRobotAddedSuccessfully
    case platformUpgrading1
    case platformUpgrading2


    // MARK: VC
    case vcDefault
    case vcSharedMiss
    case vcSharedStop
    case vcRecycleBin
    case vcInteraction
    case vcNoMeetings

    ///自定义图片
    case custom(UIImage)

    // swiftlint:disable function_body_length

    ///返回默认图片
    public func defaultImage() -> UIImage {
        switch self {
        case .initial:
            return BundleResources.image(named: "initial")
        case .noFavourite:
            return BundleResources.image(named: "emptyNeutralNoFavorites")
        case .noPreview:
            return BundleResources.image(named: "emptyNeutralNoPreview")
        case .noAccess:
            return BundleResources.image(named: "emptyNeutralNoAccess")
        case .noContent:
            return BundleResources.image(named: "emptyNeutralNoContent")
        case .noRobot:
            return BundleResources.image(named: "emptyNeutralNoRobot")
        case .noSchedule:
            return BundleResources.image(named: "emptyNeutralNoSchedule")
        case .noMessageLog:
            return BundleResources.image(named: "emptyNeutralNoMessageLogging")
        case .noContact:
            return BundleResources.image(named: "emptyNeutralNoContact")
        case .noAnnouncement:
            return BundleResources.image(named: "emptyNeutralNoAnnouncement")
        case .noWiki:
            return BundleResources.image(named: "emptyNeutralNoWiki")
        case .noPost:
            return BundleResources.image(named: "emptyNeutralNoPosts")
        case .searchFailed:
            return BundleResources.image(named: "emptyNeutralSearchFailed")
        case .noLink:
            return BundleResources.image(named: "emptyNeutralNoLink")
        case .noMail:
            return BundleResources.image(named: "emptyNeutralNoMail")
        case .noApplication:
            return BundleResources.image(named: "emptyNeutralNoApplication")
        case .noFile:
            return BundleResources.image(named: "emptyNeutralNoFile")
        case .noPicture:
            return BundleResources.image(named: "emptyNeutralNoPicture")
        case .noCloudFile:
            return BundleResources.image(named: "emptyNeutralNoCloudDocument")
        case .noServiceDesk:
            return BundleResources.image(named: "emptyNeutralNoRobot")
        case .noTeam:
            return BundleResources.image(named: "emptyNeutralNoMessageLogging")
        case .noGroup:
            return BundleResources.image(named: "emptyNeutralNoMessageLogging")
        case .noMeetingroom:
            return BundleResources.image(named: "emptyNeutralNoSchedule")
        case .noMeeting:
            return BundleResources.image(named: "vcEmptyPositiveNoMeetings")
        case .upgraded:
            return BundleResources.image(named: "emptyNeutralToBeUpgraded")
        case .noData:
            return BundleResources.image(named: "emptyPositiveNoData")
        case .pin:
            return BundleResources.image(named: "emptyPositivePin")
        case .done:
            return BundleResources.image(named: "emptyPositiveComplete")
        case .createLive:
            return BundleResources.image(named: "emptyPositiveCreateLive")
        case .createRule:
            return BundleResources.image(named: "emptyPositiveCreateRule")
        case .createTopic:
            return BundleResources.image(named: "emptyPositiveCreateTopic")
        case .bindSuccess:
            return BundleResources.image(named: "emptyPositiveBindingSucceed")
        case .vcDefault:
            return BundleResources.image(named: "emptyPositiveVcDefault")
        case .imDefault:
            return BundleResources.image(named: "emptyPositiveImDefault")
        case .emailDefault:
            return BundleResources.image(named: "emptyPositiveEmailDefault")
        case .documentDefault:
            return BundleResources.image(named: "emptyPositiveDocumentDefault")
        case .addFriends:
            return BundleResources.image(named: "emptyPositiveAddExternalContact")
        case .search:
            return BundleResources.image(named: "emptyNeutralSearchFailed")
        case .error:
            return BundleResources.image(named: "emptyNegativeError")
        case .loadingFailure:
            return BundleResources.image(named: "emptyNegativeLoadFailed")
        case .noWifi:
            return BundleResources.image(named: "emptyNegativeNoWifi")
        case .code404:
            return BundleResources.image(named: "emptyNeutral404")
        case .code500:
            return BundleResources.image(named: "emptyNegative500")
        case .defaultPage:
            return BundleResources.image(named: "emptyPositiveImDefault")
        case .restoring:
            return BundleResources.image(named: "emptyNeutralRestoring")

        // MARK: admin
        case .adminNoCertified:
            return BundleResources.image(named: "adminEmptyNegativeNoCertified")
        case .adminNoCheck:
            return BundleResources.image(named: "adminEmptyNeutralNoCheck")
        case .adminDefault:
            return BundleResources.image(named: "adminEmptyPositiveDefault")
        case .adminPassportDefault:
            return BundleResources.image(named: "adminPassportEmptyPositiveDefault")

        // MARK: CCM
        case .ccm429:
            return BundleResources.image(named: "ccmEmptyNeutral429")
        case .ccm400_403:
            return BundleResources.image(named: "ccmEmptyNeutral400403")
        case .ccmCountLimit:
            return BundleResources.image(named: "ccmEmptyNeutralCountLimit")
        case .ccmEditorLimit:
            return BundleResources.image(named: "ccmEmptyNeutralEditorLimit")
        case .ccmNoWorkFlow:
            return BundleResources.image(named: "ccmEmptyNeutralNoWorkflow")
        case .ccmStorageLimit:
            return BundleResources.image(named: "ccmEmptyNeutralStorageLimit")
        case .ccmTranslationLimit:
            return BundleResources.image(named: "ccmEmptyNeutralTranslationLaimit")
        case .ccmPositiveStorageLimit:
            return BundleResources.image(named: "ccmEmptyPositiveStorageLimit")
        case .ccmPositiveTranslationLimit:
            return BundleResources.image(named: "ccmEmptyPositiveTranslationLaimit")
        case .ccmFirstEntry:
            return BundleResources.image(named: "ccmEmptyPositiveFirstEntry")
        case .ccmDocumentKeyUnavailable:
            return BundleResources.image(named: "ccmEmptyNeutralDocumentKeyUnavailable")
        case .ccmAdvancedPermissionUpgrade:
            return BundleResources.image(named: "ccmEmptyPositiveAdvancedPermissionUpgrade")

        // MARK: Email
        case .emailBindFailure:
            return BundleResources.image(named: "emailEmptyNegativeBindingFailure")
        case .emailNoRule:
            return BundleResources.image(named: "emailEmptyNeutralNoRule")
        case .emailCreateSignature:
            return BundleResources.image(named: "emailEmptyPositiveCreateSignature")
        case .emailSuccessfulMove:
            return BundleResources.image(named: "emailEmptyPositiveSuccessfulMove")
        case .emailWelComeAndLink:
            return BundleResources.image(named: "emailInitializationFunctionWelcomeAndLink")

        // MARK: IM
        case .imAddApplication:
            return BundleResources.image(named: "imEmptyPositiveAddApplication")
        case .imNoRedEnvelop:
            return BundleResources.image(named: "imEmptyNeutralNoRedEnvelope")
        case .imNeutralProfileNoMedal:
            return BundleResources.image(named: "imEmptyNeutralProfileNoMedal")
        case .imSetup:
            return BundleResources.image(named: "imEmptyPositiveSetUp")
        case .imSubscribeTabNoTopic:
            return BundleResources.image(named: "imEmptyNeutralSubscribeTabNoTopic")
        case .imWidgetNoSchedule:
            return BundleResources.image(named: "imEmptyPositiveWidgetNoSchedule")
        case .imWidgetNoTask:
            return BundleResources.image(named: "imEmptyPositiveWidgetNoTask")

        // MARK: Platform
        case .platformNoAppDisabled:
            return BundleResources.image(named: "platformEmptyNeutralNoAppDisabled")
        case .platformNoNotShow:
            return BundleResources.image(named: "platformEmptyNeutralNoNotShow")
        case .platformNoPendingOrder:
            return BundleResources.image(named: "platformEmptyNeutralNoPendingOrder")
        case .platformAddRobot1:
            return BundleResources.image(named: "platformEmptyPositiveAddRobot1")
        case .platformAddRobot2:
            return BundleResources.image(named: "platformEmptyPositiveAddRobot2")
        case .platformApplicationManagement:
            return BundleResources.image(named: "platformEmptyPositiveApplicationManagement")
        case .platformMessageAction1:
            return BundleResources.image(named: "platformEmptyPositiveMessageAction1")
        case .platformMessageAction2:
            return BundleResources.image(named: "platformEmptyPositiveMessageAction2")
        case .platformPlusMenu:
            return BundleResources.image(named: "platformEmptyPositivePlusMenu")
        case .platformRobotAddedSuccessfully:
            return BundleResources.image(named: "platformEmptyPositiveRobotAddedSuccessfully")
        case .platformUpgrading1:
            return BundleResources.image(named: "platformEmptyPositiveUpgrading1")
        case .platformUpgrading2:
            return BundleResources.image(named: "platformEmptyPositiveUpgrading2")


        // MARK: VC
        case .vcSharedMiss:
            return BundleResources.image(named: "vcEmptyNegativeTheSharedMiss")
        case .vcSharedStop:
            return BundleResources.image(named: "vcEmptyNegativeTheSharedStop")
        case .vcRecycleBin:
            return BundleResources.image(named: "vcEmptyNeutralRecycleBin")
        case .vcInteraction:
            return BundleResources.image(named: "vcEmptyPositiveInteraction")
        case .vcNoMeetings:
            return BundleResources.image(named: "vcEmptyPositiveNoMeetings")


        case .custom(let customImage):
            return customImage


        // MARK: 待删除
        case .noCollection:
            return BundleResources.image(named: "emptyNeutralNoFavorites")
        case .noAuthority:
            return BundleResources.image(named: "emptyNeutralNoAccess")
        case .noRecord:
            return BundleResources.image(named: "emptyNeutralNoMessageLogging")
        case .noNotice:
            return BundleResources.image(named: "emptyNeutralNoAnnouncement")
        case .noSearchResult:
            return BundleResources.image(named: "emptyNeutralSearchFailed")
        case .noURL:
            return BundleResources.image(named: "emptyNeutralNoLink")
        case .noImage:
            return BundleResources.image(named: "emptyNeutralNoPicture")
        case .noDesk:
            return BundleResources.image(named: "emptyNeutralNoRobot")
        case .noSmallGroup:
            return BundleResources.image(named: "emptyNeutralNoMessageLogging")
        case .PIN:
            return BundleResources.image(named: "emptyPositivePin")
        case .wrong:
            return BundleResources.image(named: "emptyNegativeError")
        case .noInternet:
            return BundleResources.image(named: "emptyNegativeNoWifi")
        case .negtive:
            return BundleResources.image(named: "emptyNeutralNoRobot")
        }
    }
    // swiftlint:enable function_body_length
}
// swiftlint:enable all
