//
//  LKContactPickerViewModel.swift
//  LarkContact
//
//  Created by Sylar on 2018/4/8.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RxCocoa
import LarkMessengerInterface
import LarkSDKInterface

enum SelectedContactItem: Equatable {
    static func == (lhs: SelectedContactItem, rhs: SelectedContactItem) -> Bool {
        switch (lhs, rhs) {
        case (chatter(let lhsInfo), chatter(let rhsInfo)):
            return lhsInfo.ID == rhsInfo.ID
        case (chat(let lhsID), chat(let rhsID)):
            return lhsID == rhsID
        case (mail(let lhsID), mail(let rhsID)):
            return lhsID == rhsID
        case (meetingGroup(let lhsID), meetingGroup(let rhsID)):
            return lhsID == rhsID
        case (unknown, unknown):
            return true
        default:
            return false
        }
    }

    case unknown
    case chatter(SelectChatterInfo)
    case bot(SelectBotInfo)
    case chat(String)
    case mail(String)
    case meetingGroup(String)
}

final class LKContactViewControllerDataSource {
    /// 强制选中的人
    let forceSelectedChatterIds: [String]

    private let selectedContactItemsBehaviorRelay = BehaviorRelay<[SelectedContactItem]>(value: [])
    lazy var getSelectedObservable: Observable<[SelectedContactItem]> = {
        return selectedContactItemsBehaviorRelay.asObservable()
    }()

    init(
        forceSelectedChatterIds: [String],
        defaultSelectedChatterIds: [String],
        defaultSelectedChatIds: [String]
    ) {
        self.forceSelectedChatterIds = forceSelectedChatterIds
        // defaultSelectedChatter只写入了ID
        let defaultSelectedChatter = defaultSelectedChatterIds
            .map { SelectedContactItem.chatter(SelectChatterInfo(ID: $0)) }
        let items = defaultSelectedChatter + defaultSelectedChatIds.map { SelectedContactItem.chat($0) }
        self.selectedContactItemsBehaviorRelay.accept(items)
    }

    var isSelectEmpty: Bool {
        return self.selectedContactItemsBehaviorRelay.value.isEmpty
    }

    func containChatter(chatterId: String) -> Bool {
        return selectedChatterIDs().contains(chatterId)
    }

    func containChats(chatId: String) -> Bool {
        return selectedChats().contains(chatId)
    }

    func containMail(mail: String) -> Bool {
        return selectedMails().contains(mail)
    }

    func removeChatter(_ chatterInfo: SelectChatterInfo) {
        var items = selectedContactItems()
        items.removeAll(where: { $0 == .chatter(chatterInfo) })
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func removeChat(chatId: String) {
        var items = selectedContactItems()
        items.removeAll(where: { $0 == .chat(chatId) })
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func removeMail(mail: String) {
        var items = selectedContactItems()
        items.removeAll(where: { $0 == .mail(mail) })
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func removeMeetingGroup(groupChatId: String) {
        var items = selectedContactItems()
        items.removeAll(where: { $0 == .meetingGroup(groupChatId) })
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func addChatter(_ chatterInfo: SelectChatterInfo) {
        var items = selectedContactItems()
        items.lf_appendIfNotContains(.chatter(chatterInfo))
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func addChat(chatId: String) {
        var items = selectedContactItems()
        items.lf_appendIfNotContains(.chat(chatId))
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func addMail(mail: String) {
        var items = selectedContactItems()
        items.lf_appendIfNotContains(.mail(mail))
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func addMeetingGroup(groupChatId: String) {
        var items = selectedContactItems()
        items.lf_appendIfNotContains(.meetingGroup(groupChatId))
        selectedContactItemsBehaviorRelay.accept(items)
    }

    func selectedChatters() -> [SelectChatterInfo] {
        return self.selectedContactItems().compactMap { (item) in
            switch item {
            case .chatter(let chatterInfo):
                return chatterInfo
            default:
                return nil
            }
        }
    }

    func selectedBots() -> [SelectBotInfo] {
        return self.selectedContactItems().compactMap { (item) in
            switch item {
            case .bot(let botInfo):
                return botInfo
            default:
                return nil
            }
        }
    }

    func selectedChats() -> [String] {
        return self.selectedContactItems().compactMap {
            guard case .chat(let id) = $0 else {
                return nil
            }
            return id
        }
    }

    func selectedMails() -> [String] {
        return self.selectedContactItems().compactMap {
            guard case .mail(let id) = $0 else {
                return nil
            }
            return id
        }
    }

    func selectedMeetingGroups() -> [String] {
        return self.selectedContactItems().compactMap {
            guard case .meetingGroup(let id) = $0 else {
                return nil
            }
            return id
        }
    }

    func selectedContactItems() -> [SelectedContactItem] {
        return selectedContactItemsBehaviorRelay.value
    }

    func reset() {
        selectedContactItemsBehaviorRelay.accept([])
    }

    private func selectedChatterIDs() -> [String] {
        return self.selectedChatters().map { $0.ID }
    }
}
