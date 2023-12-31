//
//  AppAlertCenter.swift
//  Todo
//
//  Created by 张威 on 2020/12/2.
//

import RxSwift
import RxCocoa
import Swinject
import LarkAccountInterface
import EENavigator
import LarkSceneManager
import LarkUIKit
import LKCommonsLogging
import TodoInterface
import LarkPushCard
import LarkContainer
import LarkRustClient

final class TodoAlertPushHandler: UserPushHandler {

    static let logger = Logger.log(TodoAlertPushHandler.self, category: "Todo.AppAlertPush")

    private let disposeBag = DisposeBag()

    func process(push reminder: Rust.PushReminder) throws {
        Self.logger.info("do get push guid:\(reminder.guid) tp:\(reminder.reminder.type) tm:\(reminder.reminder.time) iad:\(reminder.reminder.isAllDay) ct:\(Date().timeIntervalSince1970)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showCard(reminder: reminder)
        }
    }

    private func showCard(reminder: Rust.PushReminder) {
        let closeButtonConfig = CardButtonConfig(title: I18N.Todo_common_Close,
                                                 buttonColorType: .secondary,
                                                 action: getCardCloseAction(guid: reminder.guid))
        let detailButtonConfig = CardButtonConfig(title: I18N.Todo_Task_ViewDetails,
                                                  buttonColorType: .primaryBlue,
                                                  action: getCardDetailAction(guid: reminder.guid, userResoler: userResolver))
        let card = TodoPushCard(userResolver: userResolver,
                                pb: reminder,
                                buttonConfigs: [closeButtonConfig, detailButtonConfig],
                                bodyTapHandler: getCardDetailAction(guid: reminder.guid, userResoler: userResolver))
        AppAlert.Track.view(with: reminder.guid)
        PushCardCenter.shared.post(card)
    }

    private func getCardDetailAction(guid: String, userResoler: UserResolver) -> ((Cardable) -> Void) {
        return { (model) in
            AppAlert.Track.clickDetail(with: guid)
            // 为了实现在视频会议投屏横屏时，点击卡片进入详情页时先退出视频会议页面
            // 需要使用 body 跳转，VC 会根据 body 的 pattern 添加白名单来处理
            let body = TodoDetailBody(guid: guid, source: .appAlert)

            if SceneManager.shared.supportsMultipleScenes {
                SceneManager.shared.active(scene: .mainScene(), from: nil) { mainSceneWindow, error in
                    if let window = mainSceneWindow {
                        userResoler.navigator.present(
                            body: body,
                            wrap: LkNavigationController.self,
                            from: window,
                            prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
                        )
                        PushCardCenter.shared.remove(with: model.id, changeToStack: true)
                    } else {
                        Self.logger.assertError(false, error?.localizedDescription ?? "Missing main scene window")
                    }
                }
            } else {
                guard let window = userResoler.navigator.mainSceneWindow else {
                    Self.logger.assertError(false, "Missing main scene window")
                    return
                }
                userResoler.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: window,
                    prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
                )
                PushCardCenter.shared.remove(with: model.id, changeToStack: true)
            }

        }
    }

    private func getCardCloseAction(guid: String) -> ((Cardable) -> Void) {
        return { (model) in
            AppAlert.Track.clickClose(with: guid)
            PushCardCenter.shared.remove(with: model.id)
        }
    }
}
