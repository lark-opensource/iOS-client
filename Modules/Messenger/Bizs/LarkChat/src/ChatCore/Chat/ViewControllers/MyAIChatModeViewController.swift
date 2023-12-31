//
//  MyAIChatModeViewController.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import RxCocoa
import LarkFoundation
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkContainer
import LarkCore
import LarkKeyboardView
import EENavigator
import LarkMessageCore
import UniverseDesignToast
import LarkMessageBase
import LarkAlertController
import UniverseDesignDialog
import LarkAIInfra

/// MyAI分会场
class MyAIChatModeViewController: MyAIChatViewController {
    override func afterMessagesRender() {
        super.afterMessagesRender()
        observeChatModeThreadClosed()
        createFloatStopGeneratingViewIfNeeded()
    }

    /// 分会场升级为场景后，停止生成做成悬浮的效果
    private func createFloatStopGeneratingViewIfNeeded() {
        // 如果FG为false，则依然复用MyAITopExtendSubModule
        guard self.myAIPageService?.larkMyAIScenariosThread ?? false else { return }
        guard let stopGeneratingView = self.myAIService?.stopGeneratingView(userResolver: self.moduleContext.userResolver, chat: self.chat.value, targetVC: self) else { return }

        self.view.addSubview(stopGeneratingView)
        stopGeneratingView.snp.makeConstraints {
            $0.centerX.equalTo(self.view.snp.centerX)
            $0.bottom.equalTo(self.getTableBottomConstraintItem()).offset(-12)
            $0.height.equalTo(28.auto())
        }
    }

    private func observeChatModeThreadClosed() {
        self.myAIPageService?.chatModeThreadState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                if state == .closed {
                    self?.showChatModeThreadClosedAlert()
                }
            }).disposed(by: disposeBag)
    }

    private func showChatModeThreadClosedAlert() {
        guard let aiInfo = try? userResolver.resolve(type: MyAIInfoService.self) else { return }
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.AI.MyAI_Chat_ChatExpiredReInvocate_aiName_Toast(aiInfo.defaultResource.name))
        dialog.addButton(text: BundleI18n.LarkChat.Lark_Legacy_IKnow) { [weak self] in
            self?.closeBtnTapped()
        }
        navigator.present(dialog, from: self)
     }
}
