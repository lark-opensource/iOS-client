//
//  ReEditComponentViewModel.swift
//  LarkMessageCore
//
//  Created by bytedance on 6/23/22.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import RxCocoa
import RxSwift
import UniverseDesignToast
import UniverseDesignDialog
import EENavigator
import LarkMessengerInterface

final class MultiEditComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: MultiEditComponentContext>: MessageSubViewModel<M, D, C> {
    private let logger = Logger.log(MultiEditComponentViewModel.self, category: "Module.LarkMessageCore.Cells")
    @PageContext.InjectedLazy var multiEditService: MultiEditService?
    var requestStatus: Message.EditMessageInfo.EditRequestStatus?
    let disposeBag = DisposeBag()

    lazy var retryCallBack: (() -> Void) = { [weak self] in
        guard let self = self else { return }
        let message = self.metaModel.message
        let chat = self.metaModel.getChat()
        guard let messageId = Int64(message.id),
              let editInfo = message.editMessageInfo else { return }
        if !chat.isAllowPost {
            guard let window = self.context.targetVC?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat.name), on: window)
            return
        }
        if message.isRecalled || message.isDeleted {
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_UnableToSaveChanges_Text)
            let content = message.isRecalled ?
            BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageRecalledUnableToSave_Title :
            BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageDeletedUnableToSave_Title
            dialog.setContent(text: content)
            dialog.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_UnableToSave_GotIt_Button)
            self.context.navigator(type: .present, controller: dialog, params: nil)
            return
        }
        self.multiEditService?.multiEditMessage(messageId: messageId,
                                                chatId: chat.id,
                                                type: editInfo.messageType,
                                                richText: editInfo.content.richText,
                                                title: editInfo.content.title,
                                                lingoInfo: editInfo.content.lingoOption)
            .observeOn(MainScheduler.instance)
            .subscribe { _ in
            } onError: { [weak self] error in
                self?.logger.info("multiEditMessage fail, error: \(error)",
                                  additionalData: ["chatId": chat.id,
                                                  "messageId": message.id])
                guard let self = self,
                      let window = self.context.targetVC?.view.window,
                      let error = error.underlyingError as? APIError else {
                    return
                }
                switch error.type {
                case .editMessageNotInValidTime:
                    self.multiEditService?.reloadEditEffectiveTimeConfig()
                default:
                    break
                }
                UDToast.showFailureIfNeeded(on: window, error: error)
            }.disposed(by: self.disposeBag)
    }

    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        self.requestStatus = metaModel.message.editMessageInfo?.requestStatus
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        self.requestStatus = metaModel.message.editMessageInfo?.requestStatus
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    public override func shouldUpdate(_ new: Message) -> Bool {
        return self.requestStatus != new.editMessageInfo?.requestStatus
    }

}
