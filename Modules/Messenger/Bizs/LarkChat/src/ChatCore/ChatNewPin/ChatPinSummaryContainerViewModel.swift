//
//  ChatPinSummaryContainerViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/18.
//

import Foundation
import LarkOpenChat
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkContainer
import RustPB
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import EENavigator
import UniverseDesignIcon
import LarkCore
import AppContainer
import LarkUIKit
import LarkMessageCore
import LarkGuide

final class ChatPinSummaryContainerViewModel: UserResolverWrapper, ChatOpenPinSummaryService {
    var userResolver: UserResolver
    private static let logger = Logger.log(ChatPinSummaryContainerViewModel.self, category: "Module.IM.ChatPin")

    private let hideOldPin: Bool
    private let disposeBag = DisposeBag()
    private weak var targetVC: UIViewController?
    private let summaryModule: ChatPinSummaryModule
    private let pinAndTopNoticeViewModel: ChatPinAndTopNoticeViewModel
    let chat: BehaviorRelay<Chat>
    private var dataSource: [ChatPinSummaryCellItem] = []
    private static let iconSize: CGFloat = 16
    private var version: Int64?
    private struct ChatPinSummaryCellItem {
        var pin: ChatPin
        let cellViewModel: ChatPinSummaryCellViewModel
    }
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var topNoticeService: ChatTopNoticeService?
    @ScopedInjectedLazy var auditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var guideService: NewGuideService?
    private var debouncer: Debouncer = Debouncer()

    private var pinSummaryRefreshPublish: PublishSubject<(pinModels: [ChatPinSummaryUIModel], totalCount: Int64)> = PublishSubject<(pinModels: [ChatPinSummaryUIModel], totalCount: Int64)>()
    lazy var pinSummaryRefreshDriver: Driver<(pinModels: [ChatPinSummaryUIModel], totalCount: Int64)> = {
        return pinSummaryRefreshPublish.asDriver(onErrorJustReturn: ([], 0))
    }()
    private var totalCount: Int64 = 0

    private var userPushCenter: PushNotificationCenter? {
        return try? self.userResolver.userPushCenter
    }

    init(userResolver: UserResolver, chat: BehaviorRelay<Chat>, summaryModule: ChatPinSummaryModule, pinAndTopNoticeViewModel: ChatPinAndTopNoticeViewModel, targetVC: UIViewController) {
        self.userResolver = userResolver
        self.chat = chat
        self.summaryModule = summaryModule
        self.pinAndTopNoticeViewModel = pinAndTopNoticeViewModel
        self.targetVC = targetVC
        self.hideOldPin = userResolver.fg.dynamicFeatureGatingValue(with: ChatNewPinConfig.oldPinKey)
    }

    func setup() {
        let metaModel = ChatPinSummaryMetaModel(chat: self.chat.value)
        self.summaryModule.handler(model: metaModel)
        self.summaryModule.modelDidChange(model: metaModel)
        self.chat
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                self?.summaryModule.modelDidChange(model: ChatPinSummaryMetaModel(chat: chat))
            }.disposed(by: self.disposeBag)
        self.summaryModule.setup()

        self.pinAndTopNoticeViewModel.refreshDriver
            .drive(onNext: { [weak self] in
                self?.refresh()
            }).disposed(by: self.disposeBag)
        self.pinAndTopNoticeViewModel.startFetchAndObservePush()

        guard let chatId = Int64(self.chat.value.id) else { return }
        self.chatAPI?.getChatPin(chatId: chatId, count: 20, needPreview: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [ weak self] response in
                guard let self = self else { return }
                let newVersion = response.meta.version
                self.handlePins(response.topPins + response.pins, newVersion: newVersion, totalCount: response.meta.pinCount, extras: response.getPinsExtras())
                Self.logger.info("chatPinSummaryTrace get chat pins chatId: \(self.chat.value.id)  newVersion: \(newVersion) currentVersion: \(self.version ?? -1) pinCount: \(response.meta.pinCount)")
            }, onError: { error in
                Self.logger.error("chatPinSummaryTrace get pin fail chatId: \(chatId)", error: error)
            }).disposed(by: self.disposeBag)
        self.userPushCenter?.observable(for: PushFirstScreenUniversalChatPins.self)
            .filter { $0.push.chatID == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let pbPush = push.push
                let newVersion = pbPush.meta.version
                self.handlePins(pbPush.topPins + pbPush.pins, newVersion: newVersion, totalCount: pbPush.meta.pinCount, extras: pbPush.getPinsExtras())
                Self.logger.info("chatPinSummaryTrace firstScreen push chat pins chatId: \(chatId)  newVersion: \(newVersion) currentVersion: \(self.version ?? -1) pinCount: \(pbPush.meta.pinCount)")
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushDeleteChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.version
                Self.logger.info("chatPinSummaryTrace handle local delete push chatId: \(chatId) newVersion: \(newVersion) currentVersion: \(self.version ?? -1) pinCount: \(push.pinCount)")
                guard self.checkNeedUpdate(newVersion) else { return }

                if self.removePins(push.deleteIds) || self.totalCount != push.pinCount {
                    self.totalCount = push.pinCount
                    self.refresh()
                }
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushAddChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.response.meta.version
                Self.logger.info("chatPinSummaryTrace handle local add push chatId: \(chatId) newVersion: \(newVersion) currentVersion: \(self.version ?? -1) pinCount: \( push.response.meta.pinCount)")
                guard self.checkNeedUpdate(newVersion) else { return }

                let pinModels = self.transform(pinPbs: push.response.pins, pinsExtras: push.response.getPinsExtras())
                if self.merge(pins: pinModels, totalCount: push.response.meta.pinCount) {
                    self.refresh()
                }
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushUpdateChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.response.meta.version
                Self.logger.info("chatPinSummaryTrace handle local update push chatId: \(chatId) newVersion: \(newVersion) currentVersion: \(self.version ?? -1) pinCount: \( push.response.meta.pinCount)")
                guard self.checkNeedUpdate(newVersion) else { return }

                let pinModels = self.transform(pinPbs: [push.response.pin], pinsExtras: push.response.getPinsExtras())
                if self.merge(pins: pinModels, totalCount: push.response.meta.pinCount) {
                    self.refresh()
                }
            }).disposed(by: self.disposeBag)
    }

    func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {
        mainOrAsync { [weak self] in
            guard let self = self else { return }
            var needUpdate = false
            var pinIdsForLog: String = ""
            let chat = self.chat
            for index in 0..<self.dataSource.count {
                var item = self.dataSource[index]
                let pinModel = item.pin
                if let payload = pinModel.payload, let newnPayload = doUpdate(payload) {
                    pinModel.payload = newnPayload
                    item.pin = pinModel
                    let metaModel = ChatPinSummaryCellMetaModel(getChat: { return chat.value }, pin: pinModel)
                    item.cellViewModel.modelDidChange(model: metaModel)
                    self.dataSource[index] = item
                    needUpdate = true
                    pinIdsForLog += " \(pinModel.id)"
                }
            }
            Self.logger.info("chatPinSummaryTrace doUpdate chatId: \(self.chat.value.id) pinIds: \(pinIdsForLog)")
            completion?(needUpdate)
            if needUpdate {
                self.refresh()
            }
        }
    }

    private func mainOrAsync(task: @escaping () -> Void) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async { task() }
        }
    }

    /// 判断 version 是否可以更新
    private func checkNeedUpdate(_ newVersion: Int64) -> Bool {
        Self.logger.info("chatPinSummaryTrace checkNeedUpdate chatId: \(self.chat.value.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
        if let version = self.version, version >= newVersion { return false }
        self.version = newVersion
        return true
    }

    @discardableResult
    private func merge(pins: [ChatPin], totalCount: Int64) -> Bool {
        let oldPinIds: [Int64] = self.dataSource.map { $0.pin.id }
        var updatePins: Bool = false
        let chat = self.chat
        pins.forEach { pinModel in
            let metaModel = ChatPinSummaryCellMetaModel(getChat: { return chat.value }, pin: pinModel)
            if let index = self.dataSource.firstIndex(where: { $0.pin.id == pinModel.id }) {
                var item = self.dataSource[index]
                item.pin = pinModel
                item.cellViewModel.modelDidChange(model: metaModel)
                self.dataSource[index] = item
                updatePins = true
            } else if let contentVM = self.summaryModule.createCellViewModel(metaModel) {
                self.dataSource.append(ChatPinSummaryCellItem(pin: pinModel, cellViewModel: contentVM))
            }
        }

        self.dataSource.sort { item1, item2 in
            let pin1 = item1.pin
            let pin2 = item2.pin
            if pin1.isTop {
                if !pin2.isTop {
                    return true
                } else {
                    return pin1.topPosition > pin2.topPosition
                }
            } else {
                if pin2.isTop {
                    return false
                } else {
                    return pin1.position > pin2.position
                }
            }
        }
        let newPinIds: [Int64] = self.dataSource.map { $0.pin.id }
        var needRefresh: Bool = false
        if updatePins || oldPinIds != newPinIds {
            needRefresh = true
        }
        if self.totalCount != totalCount {
            self.totalCount = totalCount
            needRefresh = true
        }
        return needRefresh
    }

    private func reset(pins: [ChatPin]) {
        let oldDataSource = self.dataSource
        self.dataSource = []
        let chat = self.chat
        pins.forEach { pin in
            let metaModel = ChatPinSummaryCellMetaModel(getChat: { return chat.value }, pin: pin)
            if var item = oldDataSource.first(where: { $0.pin.id == metaModel.pin.id }) {
                item.pin = pin
                item.cellViewModel.modelDidChange(model: metaModel)
                self.dataSource.append(item)
            } else if let cellVM = self.summaryModule.createCellViewModel(metaModel) {
                self.dataSource.append(ChatPinSummaryCellItem(pin: metaModel.pin, cellViewModel: cellVM))
            }
        }
    }

    private func transform(pinPbs: [RustPB.Im_V1_UniversalChatPin], pinsExtras: UniversalChatPinsExtras) -> [ChatPin] {
        return pinPbs.map {
            let pinModel = ChatPin.transform(pb: $0)
            pinModel.payload = ChatPinSummaryModule.parse(pb: $0, extras: pinsExtras, context: self.summaryModule.context)
            return pinModel
        }
    }

    private func removePins(_ pinIds: [Int64]) -> Bool {
        var pinIdsForDelete: String = ""
        var hasRemove = false
        pinIds.forEach { pinId in
            if let index = self.dataSource.firstIndex(where: { (cellItem) -> Bool in
                return cellItem.pin.id == pinId
            }) {
                self.dataSource.remove(at: index)
                hasRemove = true
                pinIdsForDelete += " \(pinId)"
            }
        }
        Self.logger.info("chatPinSummaryTrace remove pins chatId: \(self.chat.value.id) pinIds: \(pinIdsForDelete)")
        return hasRemove
    }

    private func handlePins(_ pins: [RustPB.Im_V1_UniversalChatPin], newVersion: Int64, totalCount: Int64, extras: UniversalChatPinsExtras) {
        guard self.checkNeedUpdate(newVersion) else { return }
        let pinModels = self.transform(pinPbs: pins, pinsExtras: extras)
        self.reset(pins: pinModels)
        self.totalCount = totalCount
        self.refresh()
    }

    private func refresh() {
        var cellModels: [ChatPinSummaryUIModel] = []
        if let topNoticeModel = self.pinAndTopNoticeViewModel.topNoticeModel, !topNoticeModel.pbModel.closed {
            let iconResource: ChatPinIconResource
            var hasCornerRadius: Bool = false
            switch topNoticeModel.pbModel.content.type {
            case .announcementType:
                if let announcementSender = topNoticeModel.announcementSender {
                    iconResource = .resource(
                        resource: .avatar(key: announcementSender.avatarKey,
                                          entityID: announcementSender.id,
                                          params: .init(sizeType: .size(Self.iconSize))),
                        config: ChatPinIconResource.ImageConfig(tintColor: nil, placeholder: nil)
                    )
                    hasCornerRadius = true
                } else {
                    let icon = UDIcon.getIconByKey(.announceFilled, size: CGSize(width: Self.iconSize, height: Self.iconSize)).ud.withTintColor(UIColor.ud.orange)
                    iconResource = .image(.just(icon))
                }
            case .msgType:
                guard let message = topNoticeModel.message, let fromChatter = message.fromChatter else {
                    iconResource = .image(.just(UIImage()))
                    break
                }
                iconResource = .resource(
                    resource: .avatar(key: fromChatter.avatarKey,
                                      entityID: fromChatter.id,
                                      params: .init(sizeType: .size(Self.iconSize))),
                    config: ChatPinIconResource.ImageConfig(tintColor: nil, placeholder: nil)
                )
                hasCornerRadius = true
            case .unknown:
                iconResource = .image(.just(UIImage()))
            @unknown default:
                iconResource = .image(.just(UIImage()))
            }
            cellModels.append(
                ChatPinSummaryUIModel(
                    titleAttr: self.getTopNoticeTitle(topNoticeModel),
                    iconConfig: ChatPinIconConfig(iconResource: iconResource, cornerRadius: hasCornerRadius ? ChatPinSummaryCell.Layout.iconSize / 2 : 0),
                    tapHandler: { [weak self] in
                        self?.clickTopNotice()
                    },
                    auditId: nil
                )
            )
        }
        if self.pinAndTopNoticeViewModel.pinCount != 0 {
            let icon = UDIcon.getIconByKey(.pinFilled, size: CGSize(width: Self.iconSize, height: Self.iconSize)).ud.withTintColor(UIColor.ud.turquoise)
            let iconResource = ChatPinIconResource.image(.just(icon))
            cellModels.append(
                ChatPinSummaryUIModel(
                    titleAttr: NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_NewPin_PinnedMessages_Title, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                                                                                .foregroundColor: UIColor.ud.textTitle]),
                    iconConfig: ChatPinIconConfig(iconResource: iconResource),
                    tapHandler: { [weak self] in
                        self?.clickOldPin()
                    },
                    auditId: nil
                )
            )
        }
        cellModels.append(
            contentsOf: self.dataSource.compactMap { item in
                if self.hideOldPin, item.pin.isOld {
                    return nil
                }
                let cellVM = item.cellViewModel
                let pinId = item.pin.id
                let pinType = item.pin.type
                let summaryInfo = cellVM.getSummaryInfo()
                return ChatPinSummaryUIModel(
                    titleAttr: summaryInfo.attributedTitle,
                    iconConfig: summaryInfo.iconConfig,
                    tapHandler: { [weak cellVM, weak self] in
                        guard let cellVM = cellVM, let self = self else { return }
                        cellVM.onClick()
                        IMTracker.Chat.Top.Click.top(self.chat.value, topId: pinId, type: IMTrackerChatPinType(type: pinType))
                    },
                    auditId: "\(item.pin.id)"
                )
            }
        )
        self.pinSummaryRefreshPublish.onNext((pinModels: cellModels, totalCount: totalCount))
    }

    private func getTopNoticeTitle(_ topNoticeModel: ChatPinTopNoticeModel) -> NSAttributedString {
        let chat = self.chat.value
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                         .foregroundColor: UIColor.ud.textTitle]
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            var senderName: String = ""
            if let sender = topNoticeModel.announcementSender {
                senderName = sender.displayName(chatId: chat.id,
                                                chatType: self.chat.value.type,
                                                scene: .reply)
            }
            let prefix = senderName.isEmpty ? "" : senderName + " : "
            let title = prefix + BundleI18n.LarkChat.Lark_IMChatPin_PreviewGroupAnnouncement_Text + " " + topNoticeModel.pbModel.content.announcement.content
            return NSAttributedString(string: title, attributes: attributes)
        case .msgType:
            guard let message = topNoticeModel.message else { return NSAttributedString(string: "") }
            let messageSummerize = NSMutableAttributedString(string: "", attributes: attributes)
            if let senderName = message.fromChatter?.displayName(chatId: chat.id,
                                                                 chatType: chat.type,
                                                                 scene: .reply),
               !senderName.isEmpty {
                messageSummerize.append(NSAttributedString(string: senderName + " : ", attributes: attributes))
            }
            if let summerizeAttrStr = self.topNoticeService?.getTopNoticeMessageSummerize(message, customAttributes: attributes) {
                messageSummerize.append(summerizeAttrStr)
            }
            switch message.type {
            case .text, .post:
                if message.isMultiEdited {
                    messageSummerize.append(NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_EditMessage_Edited_Label,
                                                               attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                                            .foregroundColor: UIColor.ud.textCaption]))
                }
            default:
                break
            }
            return messageSummerize
        case .unknown:
            return NSAttributedString(string: "")
        @unknown default:
            return NSAttributedString(string: "")
        }
    }

    private func clickTopNotice() {
        guard let topNoticeModel = self.pinAndTopNoticeViewModel.topNoticeModel, let targetVC = targetVC else { return }
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            let body = ChatAnnouncementBody(chatId: self.chat.value.id)
            self.userResolver.navigator.push(body: body, from: targetVC)
            IMTracker.Chat.Top.Click.top(self.chat.value, topId: nil, type: .announcement)
        case .msgType:
            debouncer.debounce(indentify: "topMsg_pinSummary", duration: 0.25) { [weak self] in
                guard let self = self, let targetVC = self.targetVC, let message = topNoticeModel.message else { return }
                let body = ChatControllerByChatBody(chat: self.chat.value,
                                                    position: message.position,
                                                    messageId: message.id)
                self.userResolver.navigator.push(body: body, from: targetVC)
            }
            IMTracker.Chat.Top.Click.top(self.chat.value, topId: nil, type: .message)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func clickOldPin() {
        guard let targetVC = targetVC else { return }
        let body = PinListBody(chatId: self.chat.value.id)
        self.userResolver.navigator.push(body: body, from: targetVC)
        IMTracker.Chat.Top.Click.top(self.chat.value, topId: nil, type: .pinList)
    }
}

extension ChatPinSummaryContainerViewModel {
    func clickMore() {
        guard let targetVC = targetVC else { return }
        let body = ChatPinCardListBody(chat: self.chat.value)
        self.userResolver.navigator.push(body: body, from: targetVC)
        IMTracker.Chat.Top.Click.more(self.chat.value)
    }
}
