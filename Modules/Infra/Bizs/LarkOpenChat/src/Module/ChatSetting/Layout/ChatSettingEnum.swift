//
//  ChatSettingEnum.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/31.
//

// MARK: cell type
import Foundation
public enum ChatSettingCellType: String {
    /// 主设置页
    case p2PChatInfo
    case groupChatInfo
    case groupMember
    case linkedPagesTitle
    case linkedPagesDetail
    case linkedPagesFooter
    case apps
    case oncallDescription
    case searchChatHistory
    case serachChatDetail
    case groupManage
    case chatAddTab
    case chatAddPin
    case chatPinAuth
    case chatTabsMenuWidgetsAuth
    case transferGroup
    case deleteMessages
    case createCryptoGroup
    case nickName
    case chatBox
    case notifiocation
    case enterPosition
    case autoTranslate
    case toTop
    /// 分组标签，不是群
    case feedLabel
    case leaveGroup
    case disbandGroup
    case report
    /// 群机器人
    case groupBot
    /// 关联团队
    case associatedTeam
    case teamMember
    case unfastenTeamHeader
    case unfastenTeamItem
    /// 免打扰
    case mute
    /// @所有人不提醒
    case atAllSilent
    /// 标记
    case flag
    /// 翻译助手设置
    case translateSetting
    /// 屏蔽机器人消息
    case botForbidden
    /// 个人聊天背景设置
    case personalChatBgImage
    /// 群管理页面
    // 禁止拷贝转发
    case forbiddenMessageCopyForward
    // 禁止下载
    case forbiddenDownloadResource
    // 禁止截图/录屏
    case forbiddenScreenCapture
    /// 消息焚毁
    case messageBurnTime
    /// 防泄密模式白名单
    case preventWhiteList
    // 防泄密模式
    case preventMessageLeak
    // 隐藏群人数
    case hideUserCount
    // 历史消息可见性
    case messageVisibility
    // 群可被搜索
    case groupSearchAble
    case topNotice
    case groupMode
    case edit
    case shareAndAddNewPermission
    case shareHistory
    case automaticallyAddGroup
    case joinAndLeave
    case approval
    case applyForMemberLimit
    case allowGroupSearched
    case atAll
    case banning
    case mailPermission
    case whenLeave
    case whenJoin
    case transfer
    case toNormalGroup
    case videoMeettingConfiguration
    case urgentConfiguration
    case pinConfiguration
    
    /// 群成员上限申请
    case applyType
    case applyInfo
    case currentLimit
    case approvers
    case groupInfo
    
    /// 群主题页面
    case chatThemeFromAlbum
    case chatThemeShootPhoto
    
    /// 群信息页面
    case groupInfoPhoto
    case groupInfoName
    case groupInfoDescription
    case groupInfoMailAddress
    case groupInfoQRCode
    case groupBgImage
    case pano
    
    /// 群搜索能力配置页面
    case groupSearchInfoName
    case groupSearchInfoDescription
}

let p2PChatInfo = ChatSettingCellType.p2PChatInfo.rawValue
let groupChatInfo = ChatSettingCellType.groupChatInfo.rawValue
let groupMember = ChatSettingCellType.groupMember.rawValue
let linkedPagesTitle = ChatSettingCellType.linkedPagesTitle.rawValue
let linkedPagesDetail = ChatSettingCellType.linkedPagesDetail.rawValue
let linkedPagesFooter = ChatSettingCellType.linkedPagesFooter.rawValue
let apps = ChatSettingCellType.apps.rawValue
let oncallDescription = ChatSettingCellType.oncallDescription.rawValue
let searchChatHistory = ChatSettingCellType.searchChatHistory.rawValue
let serachChatDetail = ChatSettingCellType.serachChatDetail.rawValue
let groupManage = ChatSettingCellType.groupManage.rawValue
let chatAddTab = ChatSettingCellType.chatAddTab.rawValue
let chatAddPin = ChatSettingCellType.chatAddPin.rawValue
let transferGroup = ChatSettingCellType.transferGroup.rawValue
let deleteMessages = ChatSettingCellType.deleteMessages.rawValue
let createCryptoGroup = ChatSettingCellType.createCryptoGroup.rawValue
let nickName = ChatSettingCellType.nickName.rawValue
let chatBox = ChatSettingCellType.chatBox.rawValue
let notifiocation = ChatSettingCellType.notifiocation.rawValue
let enterPosition = ChatSettingCellType.enterPosition.rawValue
let autoTranslate = ChatSettingCellType.autoTranslate.rawValue
let toTop = ChatSettingCellType.toTop.rawValue
let feedLabel = ChatSettingCellType.feedLabel.rawValue
let leaveGroup = ChatSettingCellType.leaveGroup.rawValue
let disbandGroup = ChatSettingCellType.disbandGroup.rawValue
let report = ChatSettingCellType.report.rawValue
let groupBot = ChatSettingCellType.groupBot.rawValue
let associatedTeam = ChatSettingCellType.associatedTeam.rawValue
let teamMember = ChatSettingCellType.teamMember.rawValue
let unfastenTeamHeader = ChatSettingCellType.unfastenTeamHeader.rawValue
let unfastenTeamItem = ChatSettingCellType.unfastenTeamItem.rawValue
let mute = ChatSettingCellType.mute.rawValue
let atAllSilent = ChatSettingCellType.atAllSilent.rawValue
let flag = ChatSettingCellType.flag.rawValue
let translateSetting = ChatSettingCellType.translateSetting.rawValue
let personalChatBgImage = ChatSettingCellType.personalChatBgImage.rawValue
let botForbidden = ChatSettingCellType.botForbidden.rawValue
let preventMessageLeak = ChatSettingCellType.preventMessageLeak.rawValue
let hideUserCount = ChatSettingCellType.hideUserCount.rawValue
let forbiddenMessageCopyForward = ChatSettingCellType.forbiddenMessageCopyForward.rawValue
let forbiddenDownloadResource = ChatSettingCellType.forbiddenDownloadResource.rawValue
let forbiddenScreenCapture = ChatSettingCellType.forbiddenScreenCapture.rawValue
let messageBurnTime = ChatSettingCellType.messageBurnTime.rawValue

// MARK: 搜索item
public enum ChatSettingSearchDetailItemType: String {
    case message
    case docs
    case file
    case image
    case link
}

let message = ChatSettingSearchDetailItemType.message.rawValue
let docs = ChatSettingSearchDetailItemType.docs.rawValue
let file = ChatSettingSearchDetailItemType.file.rawValue
let image = ChatSettingSearchDetailItemType.image.rawValue
let link = ChatSettingSearchDetailItemType.link.rawValue

// MARK: 应用item
public enum ChatSettingFunctionItemType: String {
    case remote
    case announcement
    case pin
    case pinCard
    case search
    case setting
    case event
    case meetingSummary
    case freeBusyInChat
    case todo
}

let remote = ChatSettingFunctionItemType.remote.rawValue
let announcement = ChatSettingFunctionItemType.announcement.rawValue
let pin = ChatSettingFunctionItemType.pin.rawValue
let pinCard = ChatSettingFunctionItemType.pinCard.rawValue
let search = ChatSettingFunctionItemType.search.rawValue
let setting = ChatSettingFunctionItemType.setting.rawValue
let event = ChatSettingFunctionItemType.event.rawValue
let meetingSummary = ChatSettingFunctionItemType.meetingSummary.rawValue
let freeBusyInChat = ChatSettingFunctionItemType.freeBusyInChat.rawValue
let todo = ChatSettingFunctionItemType.todo.rawValue
