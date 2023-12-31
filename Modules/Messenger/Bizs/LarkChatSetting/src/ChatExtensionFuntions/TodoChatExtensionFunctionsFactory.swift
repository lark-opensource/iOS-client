//
//  TodoChatExtensionFunctionsFactory.swift
//  LarkChatSetting
//
//  Created by 张威 on 2021/3/30.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkBadge
import LarkAccountInterface
import LarkContainer
import RxRelay
import LarkCore
import LarkFeatureGating
import LarkNavigator
import LKCommonsTracker
import Homeric
import LarkUIKit
import LarkMessengerInterface
import LKCommonsLogging
import LarkNavigation
import SuiteAppConfig

final class TodoChatExtensionFunctionsFactory: NSObject, ChatExtensionFunctionsFactory {
    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }

    let userResolver: LarkContainer.UserResolver

    private let functionsRelay = BehaviorRelay<[ChatExtensionFunction]>(value: [])
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy
    private var dependency: ChatSettingTodoDependency?
    @ScopedInjectedLazy private var navigationService: NavigationService?

    func createExtensionFuncs(chatWrapper: ChatPushWrapper,
                              pushCenter: PushNotificationCenter,
                              rootPath: Path) -> Observable<[ChatExtensionFunction]> {
        let chat = chatWrapper.chat.value
        guard navigationService?.checkInTabs(for: .todo) ?? false, !chat.isCrossWithKa, !chat.isP2PAi else {
            return .just([])
        }
        let title = BundleI18n.LarkChatSetting.Todo_Task_Tasks
        let image = Resources.todo_chatExtFunc
        let badgePath = rootPath.raw(ChatExtensionFunctionType.todo.rawValue)
        let item = ChatExtensionFunction(type: .todo,
                                         title: title,
                                         imageInfo: .image(image),
                                         badgePath: badgePath) { [weak self] vc in
            self?.badgeShow(for: badgePath, show: false)
            self?.pushTodoList(vc, chat: chat)
            NewChatSettingTracker.imChatSettingClickDetailTaskView(chat: chat)
        }
        if !chat.isSuper {
            functionsRelay.accept([item])
        }
        return functionsRelay.asObservable()
    }

    private func pushTodoList(_ controller: UIViewController?, chat: Chat) {
        guard let controller = controller else { return }
        dependency?.pushTodoListFromChat(withChat: chat.id, isFromThread: chat.chatMode == .threadV2, pushParam: PushParam(from: controller))
    }
}
