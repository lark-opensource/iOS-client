//
//  ChatScheduleSendTipViewModel.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/11/17.
//

import UIKit
import Foundation
import RustPB
import RxRelay
import RxSwift
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignColor
import LarkAccountInterface
import LarkMessengerInterface

public final class ChatScheduleSendTipViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    private static let logger = Logger.log(ChatScheduleSendTipViewModel.self, category: "LarkMessageCore")
    // 业务周期可变参数（非对象生命周期）
    public var scheduleMsgSendTime: Int64?
    public var isShowLinkText: Bool = true
    private var message: Message?

    weak var delegate: ChatScheduleSendTipViewDelegate?
    var statusObservable: Driver<ChatScheduleSendTipViewStatus> {
        statusBehavior.asDriver()
    }

    // MARK: 私有属性
    private(set) var sendSucceedIds: [String] = []
    private(set) var deleteIds: [String] = []
    private(set) var normalModel: ChatScheduleSendTipModel?
    private(set) var disableModel: ChatScheduleSendTipModel?
    private(set) var updatingModel: ChatScheduleSendTipModel?
    private(set) var creatingModel: ChatScheduleSendTipModel?

    private let chatId: Int64
    private let threadId: Int64?
    private let rootId: Int64?
    private let scene: GetScheduleMessagesScene
    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    // 监听信号
    private let disableObservable: Observable<Bool>
    private let pushObservable: Observable<PushScheduleMessage>
    private let bag = DisposeBag()
    private var statusBehavior = BehaviorRelay<ChatScheduleSendTipViewStatus>(value: .normal)
    private var currentChatterId: String {
        return self.userResolver.userID
    }
    private let messageObservable: Observable<[Message]>
    private var sendEnable: Bool

    public init(chatId: Int64,
                threadId: Int64?,
                rootId: Int64?,
                scene: GetScheduleMessagesScene,
                messageObservable: Observable<[Message]>,
                sendEnable: Bool,
                disableObservable: Observable<Bool>,
                pushObservable: Observable<PushScheduleMessage>,
                userResolver: UserResolver
    ) {
        self.chatId = chatId
        self.threadId = threadId
        self.rootId = rootId
        self.scene = scene
        self.sendEnable = sendEnable
        self.pushObservable = pushObservable
        self.disableObservable = disableObservable
        self.messageObservable = messageObservable
        self.userResolver = userResolver
    }

    public func fetchAndObserveData() {
        // 拉取定时消息
        self.messageAPI?.getScheduleMessages(chatId: chatId,
                                            threadId: threadId,
                                            rootId: rootId,
                                            scene: scene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                Self.logger.info("getScheduleMessages chatId: \(self?.chatId ?? 0), res.messageItemsCount:\(res.messageItems.count)")
                self?.updateScheduleTip(messageItems: res.messageItems,
                                        entity: res.entity,
                                        isShowLinkText: self?.isShowLinkText ?? true)
            }).disposed(by: self.bag)

        // 监听定时消息变化
        self.pushObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                Self.logger.info("pushScheduleMessages chatId: \(self?.chatId ?? 0), res.messageItemsCount:\(res.messageItems.count)")
                self?.updateScheduleTip(messageItems: res.messageItems,
                                        entity: res.entity,
                                        isShowLinkText: self?.isShowLinkText ?? true)
            }).disposed(by: self.bag)

        // 更新根消息
        self.messageObservable
            .filter({ [weak self] in $0.contains(where: { $0.id == self?.message?.parentId && $0.isRecalled }) })
            .subscribe(onNext: { [weak self] (msgs) in
                msgs.forEach { msg in
                    if msg.id == self?.message?.parentId {
                        Self.logger.info("pushMessages chatId: \(self?.chatId ?? 0), parentId changed")
                        self?.message?.parentMessage = msg
                    }
                }
            }).disposed(by: self.bag)
    }

    public func updateStatus(_ status: ChatScheduleSendTipViewStatus) {
        Self.logger.info("updateStatus status\(status)")
        self.statusBehavior.accept(status)
    }

    public func updateLinkText(isShow: Bool) {
        Self.logger.info("updateLinkText isShow\(isShow)")
        self.isShowLinkText = isShow
        self.normalModel?.isShowLinkText = isShow
        self.disableModel?.isShowLinkText = isShow

        switch self.statusBehavior.value {
        case .normal:
            self.statusBehavior.accept(.normal)
        case .disable:
            self.statusBehavior.accept(.disable)
        case .updating, .creating, .hidden:
            break
        }
    }

    private func resetAllProps() {
        Self.logger.info("resetAllProps")
        self.isShowLinkText = true
        self.scheduleMsgSendTime = nil
        self.message = nil
    }

    private func updateScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                                   entity: RustPB.Basic_V1_Entity,
                                   isShowLinkText: Bool) {
        guard self.delegate?.canHandleScheduleTip(messageItems: messageItems, entity: entity) == true else { return }
        let isSuccess = self
            .configDisplayStatusModel(messageItems: messageItems,
                                      entity: entity,
                                      hiddenTipHandler: { [weak self] in
                self?.statusBehavior.accept(.hidden)
                self?.delegate?.setScheduleSendTipView(display: false)
                // 恢复周期可变参数
                self?.resetAllProps()
            }, tapHandler: { [weak self] model in
                self?.delegate?.scheduleTipTapped(model: model)
            })
        guard isSuccess == true else {
            Self.logger.info("configDisplayStatusModel failed")
            return
        }
        let status = Self.getScheduleTypeFrom(messageItems: messageItems, entity: entity)
        self.configUpdatingStatusModel()
        self.configCreatingStatusModel()
        // 更新ui状态
        switch status {
        case .creating:
            self.statusBehavior.accept(.creating)
        case .updating:
            self.statusBehavior.accept(.updating)
        default:
            if status == .creating, sendEnable == false {
                self.statusBehavior.accept(.disable)
            } else {
                self.statusBehavior.accept(.normal)
            }
        }
        guard self.delegate?.getKeyboardIsDisplay() == true else { return }
        self.delegate?.setScheduleSendTipView(display: true)
    }

    private func observerData() {
        // 监听disbale observable
        self.disableObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                Self.logger.info("disableObservable onNext enable: \(!value)")
                self?.sendEnable = !value
                if value {
                    self?.statusBehavior.accept(.disable)
                } else {
                    self?.statusBehavior.accept(.normal)
                }
            }).disposed(by: bag)
    }

    @discardableResult
    public func configUpdatingStatusModel() -> Bool {
        // 显示更新中
        let text = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_UpdatingScheduledMessage_Text
        let desc = NSMutableAttributedString(string: text,
                                             attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                          .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
        self.setModel(ChatScheduleSendTipModel(text: desc,
                                               iconColor: UIColor.ud.iconN2,
                                               isShowLoading: true,
                                               isShowLinkText: self.isShowLinkText,
                                               loadingTextColor: UIColor.ud.textCaption),
                      for: .updating)
        return true
    }

    @discardableResult
    public func configCreatingStatusModel() -> Bool {
        // 显示设置中
        let text = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ProcessingNow_Text
        let desc = NSMutableAttributedString(string: text,
                                             attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                         .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])

        self.setModel(ChatScheduleSendTipModel(text: desc,
                                               iconColor: UIColor.ud.iconN2,
                                               isShowLoading: true,
                                               isShowLinkText: self.isShowLinkText,
                                               loadingTextColor: UIColor.ud.textCaption),
                      for: .creating)
        return true
    }

    @discardableResult
    func configDisplayStatusModel(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                                  entity: RustPB.Basic_V1_Entity,
                                  hiddenTipHandler: () -> Void,
                                  tapHandler: @escaping (ChatScheduleSendTipTapModel) -> Void) -> Bool {
        guard let item = messageItems.first else { return false }
        self.scheduleMsgSendTime = nil
        let status = Self.getScheduleTypeFrom(messageItems: messageItems, entity: entity)
        var tapTask: (Message) -> Void = { _ in }

        Self.logger.info("configDisplayStatusModel status: \(status)")
        // 根据不同status处理不同点击事件
        switch status {
        // 隐藏ui
        case .sendSuccess, .delete, .unknown:
            if item.itemID == self.message?.id {
                Self.logger.info("hiddenTipHandler")
                hiddenTipHandler()
            }
            if status == .sendSuccess {
                Self.logger.info("sendSucceedIds.append \(item.itemID)")
                self.sendSucceedIds.append(item.itemID)
            } else if status == .delete {
                Self.logger.info("deleteIds.append \(item.itemID)")
                self.deleteIds.append(item.itemID)
            }
            return false
        case .createSuccess, .sendFailed, .updateFailed, .quasiFailed:
            if case .createSuccess = status, let scheduleMessage = entity.scheduleMessage[item.itemID] {
                // 多端修改sdk会先推送一个删除，其他端修改成功后再推送createSuccess
                // 因此这里过滤掉这种case
                self.deleteIds.removeAll(where: { $0.identity == item.itemID })
                self.scheduleMsgSendTime = scheduleMessage.scheduleTime
            }
            // 输入框可用允许编辑
            // 获取定时消息时间
            var scheduleTime: Int64?
            guard let item = messageItems.first else { return false }
            if let scheduleMessage = entity.scheduleMessage[item.itemID] {
                scheduleTime = scheduleMessage.scheduleTime
            } else if let quasi = entity.quasiScheduleMessage[item.itemID] {
                scheduleTime = quasi.scheduleTime
            }
            // 输入框不可用展示弹窗
            tapTask = { [weak self] message in
                tapHandler(ChatScheduleSendTipTapModel(keyboardEnable: self?.delegate?.getKeyboardEnable() == true,
                                                       message: message,
                                                       status: status,
                                                       scheduleTime: scheduleTime,
                                                       type: item.itemType))
            }
        case .updating, .creating:
            tapTask = { _ in }
        }
        guard let model = self
            .getChatScheduleTipModel(messageItems: messageItems,
                                     entity: entity,
                                     keyboardEnable: self.delegate?.getKeyboardEnable() == true,
                                     handler: tapTask) else { return false }
        // 更新model
        self.setModel(ChatScheduleSendTipModel(text: model.normalDesc,
                                               inlineLinkText: model.normalInlineCheckDesc,
                                               iconColor: model.iconColor,
                                               isShowLoading: model.status == .updating || model.status == .creating,
                                               isShowLinkText: self.isShowLinkText,
                                               loadingTextColor: model.iconColor,
                                               textLinkRange: model.normalTextLinkRange),
                      for: .normal)
        self.setModel(ChatScheduleSendTipModel(text: model.disableDesc,
                                               inlineLinkText: model.disableInlineCheckDesc,
                                               iconColor: model.iconColor,
                                               isShowLoading: model.status == .updating || model.status == .creating,
                                               isShowLinkText: self.isShowLinkText,
                                               loadingTextColor: nil,
                                               textLinkRange: model.disableTextLinkRange),
                      for: .disable)
        observerData()
        return true
    }

    public func setModel(_ model: ChatScheduleSendTipModel, for status: ChatScheduleSendTipViewStatus) {
        switch status {
        case .normal:
            self.normalModel = model
        case .disable:
            self.disableModel = model
        case .updating:
            self.updatingModel = model
        case .creating:
            self.creatingModel = model
        case .hidden:
            assertionFailure("error status input")
        }
    }

    private var is12HourStyle: Bool {
        return !(userGeneralSettings?.is24HourTime.value ?? false)
    }

    // 从messageItems和entity转化ScheduleType
    public static func getScheduleTypeFrom(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                                           entity: RustPB.Basic_V1_Entity) -> ScheduleMessageStatus {
        // 目前只支持单条定时消息
        guard let item = messageItems.first else { return .unknown }
        let itemID = item.itemID
        let status: ScheduleMessageStatus

        switch item.itemType {
        // 真定时消息
        case .scheduleMessage:
            guard let scheduleMessage = entity.scheduleMessage[item.itemID] else { return .unknown }
            status = Self.transformFromSchudule(scheduleMessageStatus: scheduleMessage.status)
        // 假定时消息
        case .quasiScheduleMessage:
            guard let quasi = entity.quasiScheduleMessage[item.itemID], let quasiMessage = entity.quasiMessages[item.itemID] else { return .unknown }
            status = Self.transformFromQuasiSchedule(quasiScheduleMessageStatus: quasi.status, quasiMessageStatus: quasiMessage.status)
        @unknown default:
            status = .unknown
        }
        return status
    }

    // 从真定时消息转化状态
    static func transformFromSchudule(scheduleMessageStatus: Basic_V1_ScheduleMessage.Status) -> ScheduleMessageStatus {
        switch scheduleMessageStatus {
        case .pending:
            return .createSuccess
        case .unknown:
            return .unknown
        case .delete:
            return .delete
        case .updating:
            return .updating
        case .fail:
            return .sendFailed
        case .success:
            return .sendSuccess
        case .updateFailed:
            return .updateFailed
        case .suspend:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    public func getChatScheduleTipModel(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                                        entity: RustPB.Basic_V1_Entity,
                                        keyboardEnable: Bool,
                                        handler: @escaping (Message) -> Void) -> ChatScheduleTipModel? {
        // 目前只支持单条定时消息
        guard let item = messageItems.first else { return nil }
        let itemID = item.itemID
        let status: ScheduleMessageStatus = Self.getScheduleTypeFrom(messageItems: messageItems, entity: entity)
        func buildDesc(toast: NSAttributedString,
                       checkText: NSAttributedString) -> (NSAttributedString, [String: TapableTextModel]) {
            let desc = NSMutableAttributedString(attributedString: toast)
            desc.append(checkText)
            var textLinkRange: [String: TapableTextModel] = [:]
            let range = (desc.string as NSString).range(of: checkText.string)
            textLinkRange[checkText.string] = TapableTextModel(range: range, handler: { [weak self] in
                guard let self = self, let msg = self.message else { return }
                handler(msg)
            })
            return (desc, textLinkRange)
        }

        switch status {
        // 创建完成，待发送
        case .createSuccess:
            guard let scheduleMessage = entity.scheduleMessage[itemID] else { return nil }

            guard let message = try? Message.transform(entity: entity, id: itemID, currentChatterID: currentChatterId) else { return nil }

            let date = Date(timeIntervalSince1970: TimeInterval(scheduleMessage.scheduleTime ?? 0))
            let dateDesc = ScheduleSendManager.formatScheduleTimeWithDate(date,
                                                                          is12HourStyle: is12HourStyle,
                                                                          isShowYear: false)
            let normalToast = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_MessageWillBeSentAtTime_Text(dateDesc),
                                                        attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                                     .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            // 显示“查看并编辑”
            let text = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewAndEditMessage_Button
            let normalCheckText = NSAttributedString(string: " \(text)",
                                                     attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                  .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            self.message = message
            let normalDescModel = buildDesc(toast: normalToast,
                                            checkText: normalCheckText)
            let disableToast = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_UnableToSendNow_Title,
                                                 attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                              .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            // 显示“查看”
            let disableCheckText = NSAttributedString(string: " \(BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewMessage_Button)",
                                                      attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                   .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            let disableDescModel = buildDesc(toast: disableToast,
                                             checkText: disableCheckText)
            return ChatScheduleTipModel(normalDesc: normalDescModel.0,
                                        normalInlineCheckDesc: normalCheckText,
                                        disableDesc: disableDescModel.0,
                                        disableInlineCheckDesc: disableCheckText,
                                        iconColor: UIColor.ud.iconN2,
                                        status: status,
                                        normalTextLinkRange: normalDescModel.1,
                                        disableTextLinkRange: disableDescModel.1)
        case .updating, .creating:
            // 判断显示更新中/设置中
            let text = status == .updating ? BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_UpdatingScheduledMessage_Text :
                BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ProcessingNow_Text
            let desc = NSMutableAttributedString(string: text,
                                                 attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                              .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            return ChatScheduleTipModel(normalDesc: desc,
                                        disableDesc: desc,
                                        iconColor: UIColor.ud.iconN2,
                                        status: status,
                                        normalTextLinkRange: [:],
                                        disableTextLinkRange: [:])
        case .quasiFailed:
            guard let message = try? Message.transformQuasi(entity: entity, cid: itemID) else { return nil }
            // 提示定时消息设置失败
            let toast = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendToGroupNow_FailedToScheduleMessage_Title,
                                           attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                        .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            // 显示“查看并编辑” 或者 “查看”
            let normalText = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewAndEditMessage_Button
            let normalAttrText = NSAttributedString(string: " \(normalText)",
                                                    attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                 .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            let disableText = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewMessage_Button
            let disableAttrText = NSAttributedString(string: " \(disableText)",
                                                    attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                 .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            self.message = message
            let normalDescModel = buildDesc(toast: toast,
                                            checkText: normalAttrText)
            let disableDescModel = buildDesc(toast: toast,
                                             checkText: disableAttrText)
            return ChatScheduleTipModel(normalDesc: normalDescModel.0,
                                        normalInlineCheckDesc: normalAttrText,
                                        disableDesc: disableDescModel.0,
                                        disableInlineCheckDesc: disableAttrText,
                                        iconColor: UIColor.ud.colorfulRed,
                                        status: status,
                                        normalTextLinkRange: normalDescModel.1,
                                        disableTextLinkRange: disableDescModel.1)
        case .updateFailed, .sendFailed:
            guard let scheduleMessage = entity.scheduleMessage[itemID],
                  let pbMessage = entity.messages[itemID] else { return nil }

            let message = Message.transform(pb: pbMessage)
            // 显示“更新失败” 或者 “设置失败”
            let toast = status == .updateFailed ? BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_FailedToUpdateMessage_Text :
                BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_FailedToSendMessage_Text
            let toastAttr = NSMutableAttributedString(string: toast, attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                                                  .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            // 显示“查看并编辑” 或者 “查看”
            let text = keyboardEnable ? BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewAndEditMessage_Button : BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_ViewMessage_Button
            let normalCheckText = NSAttributedString(string: " \(text)",
                                                     attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                  .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            let disableCheckText = NSAttributedString(string: " \(text)",
                                                      attributes: [.foregroundColor: UIColor.ud.textLinkHover,
                                                                   .font: UIFont.systemFont(ofSize: ChatScheduleSendTipView.Config.labelFontSize)])
            self.message = message
            let normalDescModel = buildDesc(toast: toastAttr,
                                            checkText: normalCheckText)
            let disableDescModel = buildDesc(toast: toastAttr,
                                             checkText: disableCheckText)
            return ChatScheduleTipModel(normalDesc: normalDescModel.0,
                                        normalInlineCheckDesc: normalCheckText,
                                        disableDesc: disableDescModel.0,
                                        disableInlineCheckDesc: disableCheckText,
                                        iconColor: UIColor.ud.colorfulRed,
                                        status: status,
                                        normalTextLinkRange: normalDescModel.1,
                                        disableTextLinkRange: disableDescModel.1)
        case .sendSuccess, .delete, .unknown:
            return nil
        }
    }

    // 从假定时消息转化状态
    private static func transformFromQuasiSchedule(quasiScheduleMessageStatus: Basic_V1_QuasiScheduleMessage.QuasiScheduleMessageStatus,
                                                   quasiMessageStatus: Basic_V1_QuasiMessage.Status
    ) -> ScheduleMessageStatus {
        switch quasiScheduleMessageStatus {
        case .unknown:
            switch quasiMessageStatus {
            case .pending:
                return .creating
            case .failed:
                return .quasiFailed
            @unknown default:
                assertionFailure("new type")
                return .unknown
            }
        case .delete:
            return .delete
        @unknown default:
            return .unknown
        }
    }
}

public struct ChatScheduleSendTipModel {
    // 包含toast + inlineLinkText
    public var text: NSAttributedString
    // text 减去 inlineLinkText
    public var toast: NSAttributedString {
        if let check = inlineLinkText {
            let range = (text.string as NSString).range(of: check.string)
            if range.location < text.length {
                let res = text.attributedSubstring(from: NSRange(location: 0, length: range.location))
                return res
            }
            assertionFailure("location error")
            return text
        }
        return text
    }
    public var inlineLinkText: NSAttributedString?
    public var textLinkRange: [String: TapableTextModel] = [:]
    public var iconColor: UIColor
    public var isShowLoading: Bool
    public var isShowLinkText: Bool
    public var loadingTextColor: UIColor?

    public init(text: NSAttributedString,
                inlineLinkText: NSAttributedString? = nil,
                iconColor: UIColor,
                isShowLoading: Bool,
                isShowLinkText: Bool,
                loadingTextColor: UIColor?,
                textLinkRange: [String: TapableTextModel] = [:]) {
        self.text = text
        self.inlineLinkText = inlineLinkText
        self.textLinkRange = textLinkRange
        self.iconColor = iconColor
        self.isShowLoading = isShowLoading
        self.isShowLinkText = isShowLinkText
        self.loadingTextColor = loadingTextColor
    }
}

public enum ChatScheduleSendTipViewStatus {
    case normal
    case disable
    case updating
    case creating
    case hidden
}

public struct ChatScheduleSendTipTapModel {
    public var keyboardEnable: Bool
    public var status: ScheduleMessageStatus
    public var message: Message
    public var scheduleTime: Int64?
    public var type: RustPB.Basic_V1_ScheduleMessageItem.ItemType

    public init(keyboardEnable: Bool,
                message: Message,
                status: ScheduleMessageStatus,
                scheduleTime: Int64? = nil,
                type: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        self.keyboardEnable = keyboardEnable
        self.message = message
        self.scheduleTime = scheduleTime
        self.type = type
        self.status = status
    }
}
