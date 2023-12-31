//
//  MailPermissionSettingViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/19.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import RxCocoa
import LKCommonsLogging
import LarkSDKInterface
import LarkAccountInterface
import UniverseDesignToast
import LarkCore
import LKCommonsTracker
import LarkFeatureGating
import Homeric

enum ChatSettingMailPermissionType {
    case unknown
    case groupAdmin
    case groupMembers
    case organizationMembers
    case all
    case allNot

    static func transformFrom(chatMailSetting: Chat.ChatMailSetting?) -> ChatSettingMailPermissionType {
        let mailPermissionType: ChatSettingMailPermissionType
        if !(chatMailSetting?.allowMailSend ?? true) {
            mailPermissionType = .allNot
        } else {
            mailPermissionType = ChatSettingMailPermissionType.transformFrom(type: chatMailSetting?.sendPermission ?? .groupMembers)
        }
        return mailPermissionType
    }

    static func transformFrom(type: Chat.MailPermissionType) -> ChatSettingMailPermissionType {
        switch type {
        case .unknown:
            return .unknown
        case .groupAdmin:
            return .groupAdmin
        case .groupMembers:
            return .groupMembers
        case .organizationMembers:
            return .organizationMembers
        case .all:
            return .all
        @unknown default:
            fatalError("unknown type")
        }
    }
}

final class MailPermissionSettingViewModel {
    private static let logger = Logger.log(
        MailPermissionSettingViewModel.self,
        category: "LarkChat.NewMailPermissionSettingModel")

    private var disposeBag = DisposeBag()
    private let chatWrapper: ChatPushWrapper
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private(set) var chat: Chat
    private var chatAPI: ChatAPI
    var mailPermissionType: ChatSettingMailPermissionType = .unknown

    let indexDataArray: [[ChatSettingMailPermissionType]] = [
         [.groupAdmin,
         .groupMembers,
         .organizationMembers,
         .all],
        [.allNot]
    ]
    private let typeAndTrackMap: [ChatSettingMailPermissionType: IndexPath] = [
        .groupAdmin: IndexPath(row: 0, section: 0),
        .groupMembers: IndexPath(row: 1, section: 0),
        .organizationMembers: IndexPath(row: 2, section: 0),
        .all: IndexPath(row: 3, section: 0),
        .allNot: IndexPath(row: 0, section: 1)
    ]

    init(chat: Chat, chatAPI: ChatAPI, chatWrapper: ChatPushWrapper) {

        self.chat = chat
        self.chatAPI = chatAPI
        self.mailPermissionType = ChatSettingMailPermissionType.transformFrom(chatMailSetting: chat.mailSetting)
        self.chatWrapper = chatWrapper
        chatWrapper.chat.asDriver()
        .drive(onNext: { [weak self] (chat) in
            guard let `self` = self else { return }
            self.chat = chat
            self.mailPermissionType = ChatSettingMailPermissionType.transformFrom(chatMailSetting: chat.mailSetting)
            self._reloadData.onNext(())
        }).disposed(by: self.disposeBag)
    }

    func isIndexSelected(indexPath: IndexPath) -> Bool {
        // 防止越界
        guard indexpathIsOufOfRangeInDataSource(indexPath: indexPath) == false else {
            return false
        }
        return indexDataArray[indexPath.section][indexPath.row] == mailPermissionType
    }

    func indexText(indexPath: IndexPath) -> String {
        // 防止越界
        guard indexpathIsOufOfRangeInDataSource(indexPath: indexPath) == false else {
            return ""
        }
        let type = indexDataArray[indexPath.section][indexPath.row]
        return MailPermissionSettingViewModel.getPermissionMap()[type] ?? ""
    }

    func setIndex(indexPath: IndexPath) {
        // 防止越界
        guard indexpathIsOufOfRangeInDataSource(indexPath: indexPath) == false else {
            return
        }
        let type = indexDataArray[indexPath.section][indexPath.row]
        mailPermissionType = type
        _reloadData.onNext(())
    }

    private func indexpathIsOufOfRangeInDataSource(indexPath: IndexPath) -> Bool {
        guard indexPath.section < indexDataArray.count else {
            Self.logger.info(" indexPath.section: \( indexPath.section) >= indexDataArray.count: \(indexDataArray.count)")
            return true
        }
        guard indexPath.row < indexDataArray[indexPath.section].count else {
            Self.logger.info("indexPath.row: \(indexPath.row) >= indexDataArray[\(indexPath.section)].count: \(indexDataArray[indexPath.section].count)")
            return true
        }
        return false
    }

    func confirmOption(on window: UIWindow?) {
       let chatId = self.chat.id
        ChatSettingTracker.mailPermissionTrack(self.mailPermissionType, memberCount: Int(chat.userCount), chatId: chatId)

        let permissionType: Chat.MailPermissionType
        switch self.mailPermissionType {
        case .unknown:
            permissionType = .unknown
        case .groupAdmin:
            permissionType = .groupAdmin
        case .groupMembers:
            permissionType = .groupMembers
        case .organizationMembers:
            permissionType = .organizationMembers
        case .all:
            permissionType = .all
        case .allNot:
            // 单独处理allNot
            chatAPI.updateChat(chatId: chatId, allowSendMail: false)
                .subscribe(onError: { [weak self, weak window] (error) in
                    self?.confirmOptionErrorHandler(error: error, chatId: chatId, on: window)
                }).disposed(by: self.disposeBag)
            return
        }
        chatAPI.updateChat(chatId: chatId,
                           allowSendMail: true,
                           permissionType: permissionType)
            .subscribe(onNext: { _ in
            // success
        }, onError: { [weak self, weak window] (error) in
            guard let self = self else { return }
            self.confirmOptionErrorHandler(error: error, chatId: chatId, on: window)
        }).disposed(by: disposeBag)
    }

    private func confirmOptionErrorHandler(error: Error, chatId: String, on window: UIWindow?) {
        guard let window = window else { return }
        DispatchQueue.main.async {
            UDToast.showFailure(
                with: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                on: window,
                error: error
            )
        }
        MailPermissionSettingViewModel.logger.error(
            "update permissionType error,id = \(chatId),type = \(self.mailPermissionType)",
        error: error)
    }

    static func getPermissionMap() -> [ChatSettingMailPermissionType: String] {
        let groupAdminText = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGASendEmail
        return [
            .groupAdmin: groupAdminText,
            .groupMembers: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Member,
            .organizationMembers: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Tenant,
            .all: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_All,
            .allNot: BundleI18n.LarkChatSetting.Lark_Chat_NoOneCanSend
        ]
    }
}
