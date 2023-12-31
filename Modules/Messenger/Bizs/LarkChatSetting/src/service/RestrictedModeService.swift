//
//  RestrictedModeService.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/2/14.
//

import Foundation
import LarkSDKInterface
import LarkContainer
import RxSwift
import RxCocoa
import RxRelay
import LarkModel
import LKCommonsLogging
import RustPB

class RestrictedModeService {
    private let chatAPI: ChatAPI
    private let chatId: String
    let switchStatusChange: PublishSubject<Void> = PublishSubject()
    private static let logger = Logger.log(RestrictedModeService.self, category: "Module.IM.RestrictedModeService")
    private let disposeBag: DisposeBag = DisposeBag()

    private(set) var hasRestrictedMode: Bool = false

    // 是否有消息焚毁选项单独控制
    private var hasMessageBurn: Bool = false
    // 是否有白名单设置
    private var hasSetWhiteList: Bool = true

    init(chatAPI: ChatAPI, chat: Chat) {
        self.chatAPI = chatAPI
        self.chatId = chat.id
        // 是否需要鉴权定时删除
        let needCheckOnTimeDelMsgMode: Bool
        let needCheckSetWhiteList: Bool
        if chat.type == .p2P {
            needCheckOnTimeDelMsgMode = !chat.isCrossTenant
            needCheckSetWhiteList = false
        } else {
            needCheckOnTimeDelMsgMode = !chat.isMeeting && !chat.isCrossTenant && !chat.isSuper && !chat.isInMeetingTemporary
            needCheckSetWhiteList = true
        }
        var actionTypes: [Im_V1_ChatSwitchRequest.ActionType] = [.restrictedMode]
        if needCheckOnTimeDelMsgMode {
            actionTypes.append(.onTimeDelMsgMode)
        }
        if needCheckSetWhiteList {
            actionTypes.append(.restrictedModeWhiteListMode)
        }
        // 拉取是否支持修改群防泄漏模式
        let restrictedModeRawValue = Im_V1_ChatSwitchRequest.ActionType.restrictedMode.rawValue
        let onTimeDelMsgModeRawValue = Im_V1_ChatSwitchRequest.ActionType.onTimeDelMsgMode.rawValue
        let whiteListRawValue = Im_V1_ChatSwitchRequest.ActionType.restrictedModeWhiteListMode.rawValue
        let chatId = self.chatId
        self.chatAPI.getChatSwitch(chatId: chatId, actionTypes: actionTypes, formServer: false)
            .catchError({ error -> Observable<[Int: Bool]> in
                Self.logger.error("chat restrictedModeSetting getChatRestrictedModeSettingSwitch from local error \(chatId)", error: error)
                return .just([:])
            })
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] localResult -> Observable<[Int: Bool]> in
                guard let self = self else { return .empty() }
                Self.logger.info("chat restrictedModeSetting getChatRestrictedModeSettingSwitch from local info \(chatId) \(localResult)")
                if localResult[restrictedModeRawValue] != self.hasRestrictedMode
                    || localResult[onTimeDelMsgModeRawValue] != self.hasMessageBurn
                    || localResult[whiteListRawValue] != self.hasSetWhiteList {
                    self.hasRestrictedMode = localResult[restrictedModeRawValue] ?? false
                    self.hasMessageBurn = localResult[onTimeDelMsgModeRawValue] ?? false
                    self.hasSetWhiteList = localResult[whiteListRawValue] ?? false
                    self.switchStatusChange.onNext(())
                }
                return self.chatAPI.getChatSwitch(chatId: chatId, actionTypes: actionTypes, formServer: true)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] serverResult in
                Self.logger.info("chat restrictedModeSetting  getChatRestrictedModeSettingSwitch from server info \(chatId) \(serverResult)")
                if let self = self, serverResult[restrictedModeRawValue] != self.hasRestrictedMode
                    || serverResult[onTimeDelMsgModeRawValue] != self.hasMessageBurn
                    || serverResult[whiteListRawValue] != self.hasSetWhiteList {
                    self.hasRestrictedMode = serverResult[restrictedModeRawValue] ?? false
                    self.hasMessageBurn = serverResult[onTimeDelMsgModeRawValue] ?? false
                    self.hasSetWhiteList = serverResult[whiteListRawValue] ?? false
                    self.switchStatusChange.onNext(())
                }
            }, onError: { error in
                Self.logger.error("chat restrictedModeSetting  getChatRestrictedModeSettingSwitch from server error \(chatId)", error: error)
            }).disposed(by: self.disposeBag)
    }

    // 防泄密模式总开关
    func preventMessageLeakItem(chat: Chat, settingChange: @escaping (Observable<Chat>, _ switchStatus: Bool) -> Void) -> CommonCellItemProtocol? {
        let detail: String
        if chat.type == .p2P {
            detail = BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_Desc
        } else {
            detail = BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_Checkbox_Desc
        }
        return MessagePreventLeakItem(type: .preventMessageLeak,
                                      cellIdentifier: MessagePreventLeakCell.lu.reuseIdentifier,
                                      style: .auto,
                                      title: BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_Checkbox,
                                      detail: detail,
                                      status: chat.restrictedModeSetting.switch,
                                      switchHandler: { [weak self] _, status in
            guard let self = self else { return }
            var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
            setting.switch = status
            if status {
                //考虑后续版本兼容性，打开时，不能仅仅switch给true，端上把所有具体选项都指定好，都恢复默认值
                setting.copy = .noMember
                setting.forward = .noMember
                setting.download = .noMember
                setting.screenshot = .noMember
                var timeSetting = Chat.RestrictedModeSetting.OnTimeDelMsgSetting()
                timeSetting.status = false
                timeSetting.aliveTime = 0
                setting.onTimeDelMsgSetting = timeSetting
            }
            settingChange(self.chatAPI.updateChat(chatId: chat.id, restrictedModeSetting: setting), status)
        })
    }

    // 禁止拷贝转发
    func forbiddenMessageCopyForward(chat: Chat, settingChange: @escaping (Observable<Chat>, _ switchStatus: Bool) -> Void) -> CommonCellItemProtocol? {
        guard chat.restrictedModeSetting.switch else {
            return nil
        }
        //copy forward只要有一个打开，开关就算被打开
        return MessagePreventLeakSubSwitchItem(type: .forbiddenMessageCopyForward,
                                         cellIdentifier: MessagePreventLeakSubSwitchCell.lu.reuseIdentifier,
                                         style: .auto,
                                         title: BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_CopyForwardMessages_Option,
                                         status: chat.restrictedStatus(.copy)
                                         || chat.restrictedStatus(.forward),
                                         switchHandler: { [weak self] _, status in
            guard let self = self else { return }
            var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
            setting.copy = status ? .noMember : .allMembers
            setting.forward = status ? .noMember : .allMembers
            settingChange(self.chatAPI.updateChat(chatId: chat.id, restrictedModeSetting: setting), status)
        })
    }

    // 禁止下载
    func forbiddenDownloadResource(chat: Chat, settingChange: @escaping (Observable<Chat>, _ switchStatus: Bool) -> Void) -> CommonCellItemProtocol? {
        guard chat.restrictedModeSetting.switch else {
            return nil
        }
        return MessagePreventLeakSubSwitchItem(type: .forbiddenDownloadResource,
                                         cellIdentifier: MessagePreventLeakSubSwitchCell.lu.reuseIdentifier,
                                         style: .auto,
                                         title: BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_DownloadImagesVideosFiles_Option,
                                         status: chat.restrictedStatus(.download),
                                         switchHandler: { [weak self] _, status in
            guard let self = self else { return }
            var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
            setting.download = status ? .noMember : .allMembers
            settingChange(self.chatAPI.updateChat(chatId: chat.id, restrictedModeSetting: setting), status)
        })
    }

    // 禁止截图/录屏
    func forbiddenScreenCapture(chat: Chat, settingChange: @escaping (Observable<Chat>, _ switchStatus: Bool) -> Void) -> CommonCellItemProtocol? {
        guard chat.restrictedModeSetting.switch else {
            return nil
        }
        return MessagePreventLeakSubSwitchItem(type: .forbiddenScreenCapture,
                                         cellIdentifier: MessagePreventLeakSubSwitchCell.lu.reuseIdentifier,
                                         style: .auto,
                                         title: BundleI18n.LarkChatSetting.Lark_IM_RestrictedMode_ScreenshotScreenRecording_Option,
                                         status: chat.restrictedStatus(.screenshot),
                                         switchHandler: { [weak self] _, status in
            guard let self = self else { return }
            var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
            setting.screenshot = status ? .noMember : .allMembers
            settingChange(self.chatAPI.updateChat(chatId: chat.id, restrictedModeSetting: setting), status)
        })
    }

    // 消息定时焚毁
    func burnTime(chat: Chat, tapHandler: @escaping () -> Void) -> CommonCellItemProtocol? {
        guard chat.restrictedModeSetting.switch, self.hasMessageBurn else {
            return nil
        }
        return MessagePreventLeakBurnTimeItem(type: .messageBurnTime,
                                   cellIdentifier: MessagePreventLeakBurnTimeCell.lu.reuseIdentifier,
                                   style: .auto,
                                   title: BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_Checkbox,
                                             detailDescription: chat.displayInThreadMode ? BundleI18n.LarkChatSetting.Lark_IM_SelfDestructNotOkforTopics_Desc : "",
                                             status: chat.restrictedBurnTime.description(closeStatusText: BundleI18n.LarkChatSetting.Lark_Legacy_MineMessageSettingClose),
                                   disable: chat.displayInThreadMode,
                                   tapHandler: tapHandler)
    }

    // 白名单设置
    func setWhiteList(chat: Chat, tapHandler: @escaping () -> Void) -> CommonCellItemProtocol? {
        guard chat.restrictedModeSetting.switch, self.hasSetWhiteList else {
            return nil
        }
        let status: String
        switch chat.restrictedModeSetting.whiteListSetting.level {
        case .noMember:
            status = BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_NoOne_Option
        case .onlyAdminAndOwner:
            status = BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_OwnerAdmin_Option
        case .memberList:
            status = BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_SelectedMembers_Option
        case .unknown:
            status = ""
        @unknown default:
            status = ""
        }
        return MessagePreventLeakWhiteListItem(type: .preventWhiteList,
                                   cellIdentifier: MessagePreventLeakWhiteListCell.lu.reuseIdentifier,
                                   style: .auto,
                                   title: BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_Title,
                                   status: status,
                                   tapHandler: tapHandler)
    }
}

private extension Chat {
    func restrictedStatus(_ type: RestrictedModeSettingType) -> Bool {
        guard self.restrictedModeSetting.switch else {
            return false
        }
        let status: (Basic_V1_Chat.RestrictedModeSetting.Participant) -> Bool = {
            return $0 != .allMembers
        }
        switch type {
        case .copy:
            return status(self.restrictedModeSetting.copy)
        case .forward:
            return status(self.restrictedModeSetting.forward)
        case .screenshot:
            return status(self.restrictedModeSetting.screenshot)
        case .download:
            return status(self.restrictedModeSetting.download)
        @unknown default:
            return false
        }
    }
}
