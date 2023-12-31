//
//  KeyboardPanelRightContainerViewDelegate.swift
//  LarkMessageBase
//
//  Created by bytedance on 6/28/22.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkFeatureGating
import RustPB

public enum KeyboardJob: Equatable {

    public struct ReplyInfo {
        public let message: Message
        public let partialReplyInfo: PartialReplyInfo?
        public init(message: Message, partialReplyInfo: PartialReplyInfo?) {
            self.message = message
            self.partialReplyInfo = partialReplyInfo
        }
    }

    case normal
    case reply(info: ReplyInfo)   //回复
    case multiEdit(message: Message)  //二次编辑
    case quickAction  // AI 快捷指令
    case scheduleSend(info: ReplyInfo?) // 定时发送
    case scheduleMsgEdit(info: ReplyInfo?,
                         time: Date,
                         type: RustPB.Basic_V1_ScheduleMessageItem.ItemType) // 定时消息编辑

    public static func == (lhs: KeyboardJob, rhs: KeyboardJob) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal):
            return true
        case (.reply(let info1), .reply(let info2)):
            return info1.message.id == info2.message.id
        case (.multiEdit(let message1), .multiEdit(let message2)):
            return message1.id == message2.id
        case (.quickAction, .quickAction):
            return true
        case (.scheduleSend(let lInfo), .scheduleSend(let rInfo)):
            return lInfo?.message.id == rInfo?.message.id
        case (.scheduleMsgEdit(let lInfo, let lhsTime, let lhsType), .scheduleMsgEdit(let rInfo, let rhsTime, let rhsType)):
            return (lInfo?.message.id == rInfo?.message.id) && (lhsTime == rhsTime) && (lhsType == rhsType)
        default:
            return false
        }
    }

    public var isReply: Bool {
        switch self {
        case .reply:
            return true
        default:
            return false
        }
    }
    
    public var isScheduleSendState: Bool {
        switch self {
        case .scheduleMsgEdit, .scheduleSend:
            return true
        default:
            return false
        }
    }
    
    public var isScheduleMsgEdit: Bool {
        switch self {
        case .scheduleMsgEdit:
            return true
        default:
            return false
        }
    }
    
    public var isMultiEdit: Bool {
        switch self {
        case .multiEdit:
            return true
        default:
            return false
        }
    }

    public func updateJobPartialReplyInfo(_ replyInfo: PartialReplyInfo?) -> KeyboardJob? {
        switch self {
        case .normal:
            return nil
        case .reply(let info):
            return .reply(info: KeyboardJob.ReplyInfo(message: info.message, partialReplyInfo: replyInfo))
        case .multiEdit(_):
            return nil
        case .quickAction:
            return nil
        case .scheduleSend(let info):
            if let info = info {
                return .scheduleSend(info: ReplyInfo(message: info.message, partialReplyInfo: replyInfo))
            }
            return nil
        case .scheduleMsgEdit(let info, let time, let type):
            if let info = info {
                return .scheduleMsgEdit(info: ReplyInfo(message: info.message, partialReplyInfo: replyInfo),
                                        time: time,
                                        type: type)
            }
            return nil
        }
    }
}

public enum DraftId {
    case chat(chatId: String)
    case replyMessage(messageId: String, partialReplyInfo: PartialReplyInfo? = nil)
    case multiEditMessage(messageId: String, chatId: String)
    case replyInThread(messageId: String)
    case schuduleSend(chatId: String,
                      time: Int64,
                      partialReplyInfo: PartialReplyInfo? = nil,
                      parentMessage: Message? = nil,
                      item: RustPB.Basic_V1_ScheduleMessageItem)
}

public final class KeyboardStatusManager: KeyboardTipsManagerDelegate {
    //键盘Panel上方的用户提示的状态
    lazy private var tipsManager = KeyboardTipsManager(delegate: self) {
        didSet {
            delegate?.updateUIForKeyboardTip(tipsManager.getDisplayTip())
        }
    }
    
    public var currentDisplayTip: KeyboardTipsType {
        tipsManager.getDisplayTip()
    }
    
    public func containsTipType(_ tip: KeyboardTipsType) -> Bool {
        tipsManager.containsTipType(tip)
    }

    public var multiEditingMessageContent: (richText: RustPB.Basic_V1_RichText, title: String?, lingoInfo: RustPB.Basic_V1_LingoOption)?

    public init() {
    }

    weak public var delegate: KeyboardStatusDelegate? {
        didSet {
            delegate?.updateUIForKeyboardJob(oldJob: nil, currentJob: currentKeyboardJob)
            delegate?.updateUIForKeyboardTip(tipsManager.getDisplayTip())
            if let oldValue = oldValue {
                delegate?.updateKeyboardTitle(oldValue.getKeyboardTitle())
                delegate?.updateKeyboardAttributedText(oldValue.getKeyboardAttributedText())
            }
        }
    }

    private struct KeyboardStatus {
        var keyboardJob: KeyboardJob
        var tips: KeyboardTipsManager
        var titleStash: NSAttributedString?
        var contentStash: NSAttributedString?
    }

    public var defaultKeyboardJob: KeyboardJob = .normal

    private var _lastStatus: KeyboardStatus?
    public var lastKeyboardJob: KeyboardJob {
        lastStatus.keyboardJob
    }
    private var lastStatus: KeyboardStatus! {
        get {
            return _lastStatus ?? KeyboardStatus(keyboardJob: defaultKeyboardJob,
                                                 tips: KeyboardTipsManager(delegate: self),
                                                 titleStash: nil,
                                                 contentStash: nil)
        }
        set {
            _lastStatus = newValue
        }
    }

    private var _currentKeyboardJob: KeyboardJob = .normal
    public private(set) var currentKeyboardJob: KeyboardJob {
        get {
            return _currentKeyboardJob
        }
        set {
            //willSet
            willSetKeyboardJob(newValue: newValue)

            //set
            let oldValue = _currentKeyboardJob
            _currentKeyboardJob = newValue

            //didSet
            didSetKeyboardJob(oldValue: oldValue)
        }
    }

    //为true时，表示正要返回到上一个状态。定义这个变量是因为，在一些场景下，退出某个KeyboardJob时，
    //需要区分 是用户主动跳转到下一个指定状态，还是想要返回上一个状态
    private var triggerByGoBack = false
    private func willSetKeyboardJob(newValue: KeyboardJob) {
        defer {
            triggerByGoBack = false
        }
        if newValue == _currentKeyboardJob {
            return
        }
        delegate?.willExitJob(currentJob: _currentKeyboardJob, newJob: newValue, triggerByGoBack: triggerByGoBack)
    }

    private func didSetKeyboardJob(oldValue: KeyboardJob) {
        if oldValue == _currentKeyboardJob {
            delegate?.keyboardJobAssociatedValueChanged(currentJob: _currentKeyboardJob)
            return
        }
        tipsManager = KeyboardTipsManager(delegate: self)
        delegate?.updateUIForKeyboardJob(oldJob: oldValue, currentJob: _currentKeyboardJob)
    }

    private var currentStatus: KeyboardStatus {
        get {
            return KeyboardStatus(keyboardJob: currentKeyboardJob,
                                  tips: tipsManager,
                                  titleStash: delegate?.getKeyboardTitle(),
                                  contentStash: delegate?.getKeyboardAttributedText())
        }
        set {
            willSetKeyboardJob(newValue: newValue.keyboardJob)
            delegate?.updateKeyboardTitle(newValue.titleStash)
            delegate?.updateKeyboardAttributedText(newValue.contentStash ?? NSAttributedString(string: ""))
            tipsManager = newValue.tips
            let oldValue = _currentKeyboardJob
            _currentKeyboardJob = newValue.keyboardJob
            didSetKeyboardJob(oldValue: oldValue)
        }
    }

    public func goBackToLastStatus() {
        triggerByGoBack = true
        currentStatus = lastStatus
        lastStatus = nil
    }

    public func switchToDefaultJob() {
        switchJob(defaultKeyboardJob)
    }

    public func switchJob(_ value: KeyboardJob) {
        if !editMessageFG,
           case .multiEdit = value {
            return
        }
        if case .scheduleSend = currentKeyboardJob, value == currentKeyboardJob {
            return
        }
        if case .scheduleMsgEdit = value, value == currentKeyboardJob {
            return
        }

        if case .reply = value, value == currentKeyboardJob {
            currentKeyboardJob = value
            return
        }
        lastStatus = currentStatus
        currentKeyboardJob = value
    }

    lazy var editMessageFG = LarkFeatureGating.shared.getFeatureBoolValue(for: "messenger.message.edit_message")

    //转换KeyboardJob，但是直接丢弃当前Status，而不是把它记入lastStatus
    //目前仅用于 二次编辑A消息 跳转到二次编辑B消息
    public func switchJobWithoutReplaceLastStatus(_ value: KeyboardJob) {
        if !editMessageFG,
           case .multiEdit = value {
            return
        }
        currentKeyboardJob = value
    }

    public func addTip(_ value: KeyboardTipsType) {
        self.tipsManager.addTip(value)
    }

    public func getMultiEditMessage() -> Message? {
        switch currentKeyboardJob {
        case .multiEdit(let message):
            return message
        default :
            return nil
        }
    }
    
    // 获取已经创建的定时消息
    public func getScheduleMessage() -> Message? {
        switch currentKeyboardJob {
        case .scheduleMsgEdit(let info, _, _):
            return info?.message
        default :
            return nil
        }
    }

    public func getReplyInfo() -> KeyboardJob.ReplyInfo? {
        switch currentKeyboardJob {
        case .reply(let info):
            return info
        case .scheduleSend(let info):
            return info
        default:
            return nil
        }
    }

    public func getReplyMessage() -> Message? {
        return getReplyInfo()?.message
    }

    public func getRelatedDispalyReplyInfo(for keyboardJob: KeyboardJob? = nil) -> KeyboardJob.ReplyInfo? {
        let job = keyboardJob ?? currentKeyboardJob
        switch job {
        case .reply(let info):
            return info
        case .multiEdit(let message):
            var info: KeyboardJob.ReplyInfo?
            if let parentMessage = message.parentMessage {
                info = KeyboardJob.ReplyInfo(message: parentMessage, partialReplyInfo: message.partialReplyInfo)
            }
            return info
        case .scheduleSend(let info):
            return info
        case .scheduleMsgEdit(let info, _, _):
            if let message = info?.message.parentMessage {
                return KeyboardJob.ReplyInfo(message: message, partialReplyInfo: info?.partialReplyInfo)
            }
            return nil
        default :
            return nil
        }
    }

    public func getRelatedDispalyMessage(for keyboardJob: KeyboardJob? = nil) -> Message? {
        let job = keyboardJob ?? currentKeyboardJob
        switch job {
        case .reply(let info):
            return info.message
        case .multiEdit(let message):
            return message.parentMessage
        case .scheduleSend(let info):
            return info?.message
        case .scheduleMsgEdit(let info, _, _):
            return info?.message.parentMessage
        default :
            return nil
        }
    }

    public func onReceivedPushMessage(_ value: Message) {
        /// 有些情况下是不希望实时更新引用的消息内容的，需要做特殊处 比如：消息的局部引用
        switch currentKeyboardJob {
        case .normal:
            return
        case .reply(let info):
            if value.id == info.message.id {
                currentKeyboardJob = .reply(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info.partialReplyInfo))
            }
        case .multiEdit(let message):
            if value.id == message.id {
                currentKeyboardJob = .multiEdit(message: value)
            } else if value.id == message.parentId {
                message.parentMessage = value
                currentKeyboardJob = .multiEdit(message: message)
            }
        case .quickAction:
            // shuold not occur
            currentKeyboardJob = .quickAction
        case .scheduleSend(let info):
            if value.id == info?.message.id {
                currentKeyboardJob = .scheduleSend(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info?.partialReplyInfo))
            }
        case .scheduleMsgEdit(let info, let time, let type):
            if value.id == info?.message.id {
                currentKeyboardJob = .scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info?.partialReplyInfo),
                                                      time: time,
                                                      type: type)
            } else if let message = info?.message, value.id == message.parentId {
                message.parentMessage = value
                currentKeyboardJob = .scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: message, partialReplyInfo: info?.partialReplyInfo),
                                                      time: time,
                                                      type: type)
            }
        }

        switch defaultKeyboardJob {
        case .reply(let info):
            if value.id == info.message.id {
                defaultKeyboardJob = .reply(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info.partialReplyInfo))
            }
        default:
            break
        }

        switch lastStatus.keyboardJob {
        case .normal, .quickAction:
            return
        case .reply(let info):
            if value.id == info.message.id {
                lastStatus.keyboardJob = .reply(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info.partialReplyInfo))
            }
        case .multiEdit(let message):
            if value.id == message.id {
                lastStatus.keyboardJob = .multiEdit(message: value)
            } else if value.id == message.parentId {
                message.parentMessage = value
                lastStatus.keyboardJob = .multiEdit(message: message)
            }
        case .scheduleSend(let info):
            if value.id == info?.message.id {
                lastStatus.keyboardJob = .scheduleSend(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info?.partialReplyInfo))
            }
        case .scheduleMsgEdit(let info, let time, let type):
            if value.id == info?.message.id {
                lastStatus.keyboardJob = .scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: value, partialReplyInfo: info?.partialReplyInfo),
                                                      time: time,
                                                      type: type)
            } else if let message = info?.message, value.id == message.parentId {
                message.parentMessage = value
                lastStatus.keyboardJob = .scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: message, partialReplyInfo: info?.partialReplyInfo),
                                                      time: time,
                                                      type: type)
            }
        }
    }

    func onDisplayTipChanged(tip: KeyboardTipsType) {
        delegate?.updateUIForKeyboardTip(tip)
    }
}

public protocol KeyboardStatusDelegate: AnyObject {
    func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool)
    func updateUIForKeyboardJob(oldJob: KeyboardJob? , currentJob: KeyboardJob)
    func updateUIForKeyboardTip(_ value: KeyboardTipsType)
    func keyboardJobAssociatedValueChanged(currentJob: KeyboardJob)
    func getKeyboardAttributedText() -> NSAttributedString
    func getKeyboardTitle() -> NSAttributedString?
    func updateKeyboardTitle(_ value: NSAttributedString?)
    func updateKeyboardAttributedText(_ value: NSAttributedString)
}

public extension KeyboardStatusDelegate {
    func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {}
    func getKeyboardTitle() -> NSAttributedString? { return nil }
    func updateKeyboardTitle(_ value: NSAttributedString?) {}
    func keyboardJobAssociatedValueChanged(currentJob: KeyboardJob) {}
}

extension RustPB.Basic_V1_RichText {
    public func isContentEqualTo(_ value: RustPB.Basic_V1_RichText) -> Bool {
        if self.elementIds.count != value.elementIds.count {
            return false
        }
        for index in 0 ..< self.elementIds.count {
            guard let element1 = self.elements[self.elementIds[index]] else { return false }
            guard let element2 = value.elements[value.elementIds[index]] else { return false }
            guard Self.isRichElementEqual(element1: element1,
                                          element2: element2,
                                          richText1: self,
                                          richText2: value) else { return false }
        }
        return true
    }

    private static func isRichElementEqual(element1: RustPB.Basic_V1_RichTextElement,
                                    element2: RustPB.Basic_V1_RichTextElement,
                                    richText1: RustPB.Basic_V1_RichText,
                                    richText2: RustPB.Basic_V1_RichText) -> Bool {
        guard element1.isContentEqualTo(element2) else { return false }
        //比较子节点
        if element1.childIds.count != element2.childIds.count {
            return false
        }
        for index in 0 ..< element1.childIds.count {
            guard let child1 = richText1.elements[element1.childIds[index]] else { return false }
            guard let child2 = richText2.elements[element2.childIds[index]] else { return false }
            guard isRichElementEqual(element1: child1,
                                     element2: child2,
                                     richText1: richText1,
                                     richText2: richText2) else { return false}
        }
        return true
    }
}
extension RustPB.Basic_V1_LingoOption: Equatable {
    public func isContentEqualTo(_ value: RustPB.Basic_V1_LingoOption) -> Bool {
        guard self.highlightIgnoreWords.count == value.highlightIgnoreWords.count, self.pinInfo.count == value.pinInfo.count else { return false }
        for index in 0 ..< self.highlightIgnoreWords.count {
            let element1 = self.highlightIgnoreWords[index]
            let element2 = value.highlightIgnoreWords[index]
            guard element1 == element2 else { return false }
        }
        for (query, pinId) in self.pinInfo {
            guard let newPinId = value.pinInfo[query] else { return false }
            guard pinId == newPinId else { return false}
        }
        return true
    }
}
extension RustPB.Basic_V1_RichTextElement: Equatable {
    public func isContentEqualTo(_ value: RustPB.Basic_V1_RichTextElement) -> Bool {
        guard self.tag == value.tag else {
            return false
        }
        guard self.style == value.style else {
            return false
        }
        switch self.tag {
        case .text:
            return self.property.text.content == value.property.text.content
        case .emotion:
            return self.property.emotion.key == value.property.emotion.key
        case .at:
            return self.property.at.userID == value.property.at.userID
        case .a:
            return self.property.anchor.href == value.property.anchor.href &&
                self.property.anchor.content == value.property.anchor.content &&
                self.property.anchor.textContent == value.property.anchor.textContent &&
                self.property.anchor.isCustom == value.property.anchor.isCustom
        case .img:
            return self.isImageEqualTo(value)
        case .media:
            return self.isMediaEqualTo(value)
        @unknown default:
            return true
        }
    }

    private func isImageEqualTo(_ value: RustPB.Basic_V1_RichTextElement) -> Bool {
        let image1 = self.property.image
        let image2 = value.property.image
        if image1.originKey != image2.originKey {
            return false
        }
        if image1.originWidth != image2.originWidth {
            return false
        }
        if image1.originHeight != image2.originHeight {
            return false
        }
        if image1.urls != image2.urls {
            return false
        }
        if image1.token != image2.token {
            return false
        }
        return true
    }

    private func isMediaEqualTo(_ value: RustPB.Basic_V1_RichTextElement) -> Bool {
        let media1 = self.property.media
        let media2 = value.property.media
        if media1.size != media2.size {
            return false
        }
        if media1.duration != media2.duration {
            return false
        }
        if media1.key != media2.key {
            return false
        }
        if media1.name != media2.name {
            return false
        }
        if media1.mime != media2.mime {
            return false
        }
        if media1.source != media2.source {
            return false
        }
        if media1.image != media2.image {
            return false
        }
        if media1.url != media2.url {
            return false
        }
        if media1.originPath != media2.originPath {
            return false
        }
        if media1.compressPath != media2.compressPath {
            return false
        }
        if media1.mediaUploadID != media2.mediaUploadID {
            return false
        }
        if media1.cryptoToken != media2.cryptoToken {
            return false
        }
        return true
    }
}
