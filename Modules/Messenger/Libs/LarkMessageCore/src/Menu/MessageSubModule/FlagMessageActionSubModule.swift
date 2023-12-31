//
//  FLag.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkModel
import UniverseDesignToast
import RxSwift
import LarkMessageBase
import LarkSDKInterface
import LarkContainer
import RustPB
import ServerPB
import LarkCore
import LKCommonsTracker
import Homeric
import LarkOpenChat
import LarkMessageCore

public final class FlagMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private let topNoticeSubject: BehaviorSubject<ChatTopNotice?>? = nil
    @ScopedInjectedLazy private var flagAPI: FlagAPI?

    public override var type: MessageActionType {
        return .flag
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func cancelHandle(message: Message, chat: Chat) {
        guard let targetView = self.context.pageAPI?.view else { return }
        // 透传Server的取消标记信令
        flagAPI?.updateMessage(isFlaged: false, messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak targetView] error in
                guard let targetView = targetView else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Core_Label_ActionFailed_Toast,
                    on: targetView,
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    private func flagHandle(message: Message, chat: Chat) {
        guard let targetView = self.context.pageAPI?.view else { return }
        // 透传Server的标记、取消标记信令
        flagAPI?.updateMessage(isFlaged: true, messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak targetView] error in
                guard let targetView = targetView else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Core_Label_ActionFailed_Toast,
                    on: targetView,
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let message = model.message
        switch message.type {
        case .text, .post, .audio, .image, .media, .location, .sticker:
            return true
        case .vote, .shareGroupChat, .shareUserCard, .card, .shareCalendarEvent, .generalCalendar, .todo:
            return true
        case .file:
            // 局域网文件不支持标记
            if let fileContent = message.content as? FileContent {
                return fileContent.fileSource != .lanTrans
            }
            return true
        case .folder:
            // 局域网文件夹不支持标记
            if let folderContent = message.content as? FolderContent {
                return folderContent.fileSource != .lanTrans
            }
            return true
        case .email, .hongbao, .commercializedHongbao, .system, .calendar, .videoChat, .unknown:
            return false
        case .mergeForward:
            if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                return true
            }
            return true
        @unknown default:
            return false
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let isFlag = model.message.isFlag
        let params: [AnyHashable: Any] = ["click": isFlag ? "mark" : "unmark", "target": "none", "message_id": model.message.id]
        return MessageActionItem(text: isFlag ? BundleI18n.LarkMessageCore.Lark_IM_MarkAMessageToArchive_CancelButton :
                                        BundleI18n.LarkMessageCore.Lark_IM_MarkAMessageToArchive_Button,
                                 icon: isFlag ? BundleResources.Menu.menu_unFlag : BundleResources.Menu.menu_flag,
                                 trackExtraParams: params) { [weak self] in
            isFlag ? self?.cancelHandle(message: model.message, chat: model.chat) : self?.flagHandle(message: model.message, chat: model.chat)
        }
    }
}
