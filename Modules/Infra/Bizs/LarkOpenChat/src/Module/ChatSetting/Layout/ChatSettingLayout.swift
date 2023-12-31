//
//  ChatSettingLayout.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

// 管理聊天设置页布局的文件

///
///
// MARK: cell布局
///
///

import Foundation
public let settingTableLayout =
    ChatSettingTable()
        .configSections {
            infoSection
            linkedPagesSection
            unfastenTeamSection
            groupAppsSection
            oncallSection
            searchSection
            chatTabSection
            chatAddPinSection
            privacySettingsSection
            groupManageSection
            groupBotSection
            groupConfigSection
            personalChatBgImageSection
            translateSettingSection
            deleteMessagesSection
            createCryptoGroupSection
            transferGroupSection
            groupLeaveAndDisbandSecton
            reportSection
        }

let infoSection =
    ChatSettingSection()
        .configRows {
            p2PChatInfo
            groupChatInfo
            groupMember
            teamMember
        }

let unfastenTeamSection =
    ChatSettingSection()
        .configRows {
            unfastenTeamHeader
            unfastenTeamItem
        }

let groupAppsSection =
    ChatSettingSection()
        .configRows {
            apps
        }

let oncallSection =
    ChatSettingSection()
        .configRows {
            oncallDescription
        }

let linkedPagesSection =
    ChatSettingSection()
        .configRows {
            linkedPagesTitle
            linkedPagesDetail
            linkedPagesFooter
        }

let searchSection =
    ChatSettingSection()
        .configRows {
            searchChatHistory
            serachChatDetail
        }

let groupManageSection =
    ChatSettingSection()
        .configRows {
            groupManage
        }

let privacySettingsSection =
    ChatSettingSection()
        .configRows {
            hideUserCount
            preventMessageLeak
            forbiddenMessageCopyForward
            forbiddenDownloadResource
            forbiddenScreenCapture
            messageBurnTime
        }

let chatTabSection =
    ChatSettingSection()
        .configRows {
            chatAddTab
        }

let chatAddPinSection =
    ChatSettingSection()
        .configRows {
            chatAddPin
        }

let deleteMessagesSection =
    ChatSettingSection()
        .configRows {
            deleteMessages
        }

let createCryptoGroupSection =
    ChatSettingSection()
        .configRows {
            createCryptoGroup
        }

let groupBotSection =
    ChatSettingSection()
        .configRows {
            groupBot
        }

let groupConfigSection =
    ChatSettingSection()
        .configRows {
            nickName
            notifiocation
            mute
            chatBox
            botForbidden
            atAllSilent
            toTop
            feedLabel
            flag
            enterPosition
            autoTranslate
        }

let personalChatBgImageSection =
    ChatSettingSection()
        .configRows {
            personalChatBgImage
        }

let translateSettingSection =
    ChatSettingSection()
        .configRows {
            translateSetting
        }

let transferGroupSection =
    ChatSettingSection()
        .configRows {
            transferGroup
        }

let groupLeaveAndDisbandSecton =
    ChatSettingSection()
        .configRows {
            leaveGroup
            disbandGroup
        }

let reportSection =
    ChatSettingSection()
        .configRows {
            report
        }

///
///
// MARK: 搜索item布局
///
///

public let settingSearchDetailLayout =
    ChatSettingSearchItems()
        .configItems {
            message
            docs
            file
            image
            link
        }

///
///
// MARK: 应用item布局
///
///

public let settingFuctionLayout =
    ChatSettingFunctionItems()
        .configItems {
            event
            meetingSummary
            remote
            announcement
            search
            todo
            pin
            pinCard
            freeBusyInChat
            setting
        }
