//
//  SelectionDataSource.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/3.
//

import Foundation
import LarkModel
import RxSwift
import UniverseDesignToast
import LarkSDKInterface
import Homeric
import LarkMessengerInterface

/// 负责处理选中相关代码。也可用于跨页面共享选中逻辑和状态。
/// NOTE: 创建和容器持有，同步使用的地方应该weak持有, 避免容器实现Source的循环引用
public protocol SelectionDataSource: AnyObject {
    /// 默认单选，开启后显示多选样式。可动态切换
    var isMultiple: Bool { get }
    /// 当前的选中项，单选时只会有0-1个
    var selected: [Option] { get }

    // observable shouldn't emit inital value when subscribe, only changes
    var isMultipleChangeObservable: Observable<Bool> { get }
    // selected can be lazy get
    var selectedChangeObservable: Observable<SelectionDataSource> { get }

    /// @param from: is use to record the sender, eg: the subpage or the tableView.
    ///   some logical may depend on it to work
    func state(for option: Option, from: Any?) -> SelectState
    func state(for option: Option, from: Any?, category: PickerItemCategory) -> SelectState
    /// NOTE: should sync state with selectedObservable.
    /// NOTE: may call with disabled or selected option. source should guard it

    /// 返回是否成功选中
    @discardableResult
    func select(option: Option, from: Any?) -> Bool
    /// 取消选中，返回是否成功
    @discardableResult
    func deselect(option: Option, from: Any?) -> Bool

    func batchSelect(options: [Option], from: Any?)
    func batchDeselect(options: [Option], from: Any?)
}

public struct SelectState {
    public var selected: Bool
    public var disabled: Bool
    public var isNormal: Bool { return !selected && !disabled }
    public var isNormallySelected: Bool { return selected && !disabled }
    public static var normal: SelectState { .init(selected: false, disabled: false) }
    public static var selected: SelectState { .init(selected: true, disabled: false) }
    public static var disabled: SelectState { .init(selected: false, disabled: true) }
    public static var forceSelected: SelectState { .init(selected: true, disabled: true) }
}

extension Chatter: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.chatter(id: self.id, name: self.displayName) }
    public var selectType: PickerSearchSelectType { return .member }
}

extension Chat: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.chat(id: self.id,
                                                                          chatId: self.id,
                                                                          name: self.displayName,
                                                                          isThread: self.chatMode == .threadV2 || self.chatMode == .thread,
                                                                          isCrypto: self.isCrypto)
    }
    public var selectType: PickerSearchSelectType { return .group }
}

extension NewSelectExternalContact: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier {
        if let chatter = self.chatter { return chatter.optionIdentifier }
        assertionFailure("should have a chatter set")
        return .init(type: "unknown", id: "")
    }
    public var selectType: PickerSearchSelectType { return .member }
}

extension SelectVisibleUserGroup: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier {
        switch self.groupType {
        case .normal:
            return .init(type: "newUserGroup", id: self.id, name: self.name)
        case .dynamic:
            return .init(type: "newUserGroup", id: self.id, name: self.name)
        @unknown default:
            assertionFailure("unknown type")
        }
        return .init(type: "", id: "")
    }
    public var selectType: PickerSearchSelectType { return .userGroup }
}

extension ForwardItem: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier {
        let type: String
        switch self.type {
        case .bot: type = "bot"
        case .chat: type = "chat"
        case .threadMessage: type = "thread"
        case .user: type = "chatter"
        case .generalFilter: type = "generalFilter"
        case .myAi: type = "myAi"
        case .unknown, .replyThreadMessage:
            fallthrough // use unknown default setting to fix warning
        @unknown default: type = "unknown"
        }
        return OptionIdentifier(type: type, id: self.id, chatId: self.chatId ?? "", name: self.name, isThread: self.isThread, isCrypto: isCrypto)
    }
    public var selectType: PickerSearchSelectType {
        switch type {
        case .chat: return .group
        case .bot: return .bot
        case .threadMessage, .replyThreadMessage: return .thread
        case .user: return .member
        case .generalFilter: return .generalFilter
        case .unknown: return .unknown
        case .myAi: return .myAi
        }
        return .group
    }
}

extension NameCardInfo: Option {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.mailContact(id: email, emailId: namecardId) }
}

extension MailSharedEmailAccount: Option {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.mailContact(id: emailAddress) }
}

// Helper Extension
extension SelectionDataSource {
    @discardableResult
    public func toggle(option: Option, from: Any?, at position: Int? = nil, event: String? = nil, target: String? = nil, scene: String? = nil) -> Bool {
        let state = self.state(for: option, from: from)
        if self.isMultiple {
            track(option, isSelect: !state.selected, at: position, event: event, target: target, scene: scene)
            if state.selected {
                return self.deselect(option: option, from: from)
            } else {
                return self.select(option: option, from: from)
            }
        } else {
            // 单选始终触发选择
            track(option, isSelect: true, at: position, event: event, target: target, scene: scene)
            return self.select(option: option, from: from)
        }
    }

    private func track(_ option: Option, isSelect: Bool, at position: Int?, event: String?, target: String?, scene: String? = nil) {
        guard let trackable = option as? PickerSelectionTrackable, let pos = position, let event = event, let target = target else { return }
        var entityId = trackable.optionIdentifier.id
        if let emailId = trackable.optionIdentifier.emailId {
            entityId = emailId
        }
        let trackPos = pos
        if isSelect {
            if let scene = scene {
                SearchTrackUtil.trackPickerSelectClick(scene: scene, clickType: .select(target: target,
                                                                                        selectType: trackable.selectType,
                                                                                        listNumber: trackPos,
                                                                                        id: entityId
                                                                                       ))
            } else {
                SearchTrackUtil.trackPickerClick(event: event, clickType: .select(target: target,
                                                                                selectType: trackable.selectType,
                                                                                listNumber: trackPos,
                                                                                id: entityId))
            }
        } else {
            if let scene = scene {
                SearchTrackUtil.trackPickerSelectClick(scene: scene, clickType: .remove(target: target))
            } else {
                SearchTrackUtil.trackPickerClick(event: event, clickType: .remove(target: target))
            }
        }
    }

    public func batchSelect(options: [Option], from: Any?) { }
    public func batchDeselect(options: [Option], from: Any?) { }
}

// Set Helper . 这里是为了适配email的id，如果以邮箱为id，chatter这种类型需要做适配。
extension Set where Element == OptionIdentifier {
    func contains(option: Option) -> Bool {
        return self.contains { id in
            if id.type == OptionIdentifier.Types.mailContact.rawValue {
                if let chatter = option as? Chatter {
                    // TODO: MAIL_CONTACT 换成企业邮箱
                    if let mail = chatter.enterpriseEmail {
                        return mail == id.id
                    } else {
                        return false
                    }
                } else if let chatter = option as? NameCardInfo {
                    return chatter.email == id.id
                } else if let sharedMail = option as? MailSharedEmailAccount {
                    return sharedMail.emailAddress == id.id
                }
                return id == option.optionIdentifier
            }
            return id == option.optionIdentifier
        }
    }
}
