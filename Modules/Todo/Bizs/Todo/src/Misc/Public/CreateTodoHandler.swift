//
//  ShowDetailHandler.swift
//  LarkTodo
//
//  Created by 张威 on 2021/1/21.
//

import RxSwift
import Swinject
import EENavigator
import TodoInterface
import LarkContainer
import UniverseDesignToast
import LarkNavigation
import LarkTab
import LarkUIKit
import LarkNavigator

/// 处理新建 Todo

class CreateTodoHandler: UserTypedRouterHandler {

    @ScopedInjectedLazy private var todoService: TodoService?

    func handle(_ body: TodoCreateBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        switch body.sourceContext {
        case .chat(var chatContext):
            if shouldDisplayGuide(context: body.sourceContext) {
                chatContext.chatGuideHandler = { bottomMargin in
                    guard let fromVC = req.from.fromViewController else { return }
                    // 这里需要强持有下self, 不然会被释放掉
                    self.showGuideToastInChat(on: fromVC, bottomMargin: bottomMargin)
                    self.todoService?.setGuideInChatDisplayed()
                }
            }
            let vc: UIViewController
            let callbacks = TodoCreateCallbacks(
                createHandler: { res in
                    // 这里需要强持有下self, 不然会被释放
                    self.syncNewCreatedTodo(res.todo)
                }
            )
            let source = TodoCreateSource.chat(context: chatContext)
            vc = DetailViewController(resolver: userResolver, input: .create(source: source, callbacks: callbacks))
            let nvc = LkNavigationController(rootViewController: vc)
            res.end(resource: nvc)
        }
    }

    /// 目前只有chat 和 text 支持弹引到
    private func shouldDisplayGuide(context: TodoCreateBody.SourceContext) -> Bool {
        if case let .chat(chatContext) = context {
            switch chatContext.fromContent {
            case .chatKeyboard, .textMessage:
                return true
            case  .chatSetting,
                  .mergeForwardMessage,
                  .multiSelectMessages,
                  .postMessage,
                  .threadMessage,
                  .needsMergeMessage,
                  .unknownMessage:
                return false
            }
        }
        return false
    }

    /// 展示引导
    /// - Parameters:
    ///   - view: on view
    ///   - bottomMargin: 需要自定义的bottom margin：quick todo连续创建的时候，需要在键盘上面弹出
    private func showGuideToastInChat(on vc: UIViewController, bottomMargin: CGFloat?) {
        if let text = getChatGuideText(by: vc) {
            var operation = UDToastOperationConfig(
                text: I18N.Todo_Chat_ViewButton,
                displayType: .auto
            )
            operation.textAlignment = .left
            let config = UDToastConfig(
                toastType: .info,
                text: text,
                operation: operation
            )
            UDToast.showToast(with: config, on: vc.view.window ?? vc.view, delay: 7) { _ in
                // 这里需要强持有下self, 不然会被释放掉
                self.godoTodoCenter(from: vc)
            }
            if let bottomMargin = bottomMargin {
                UDToast.setCustomBottomMargin(bottomMargin, view: vc.view.window ?? vc.view)
            }
        }
    }

    /// 会话引导标题
    /// - Returns: text
    private func getChatGuideText(by vc: UIViewController) -> String? {
        if let animatedTabBarController = vc.animatedTabBarController {
            if animatedTabBarController.mainTabBarItems.contains(where: { $0.tab == .todo }) {
                return I18N.Todo_Chat_ViewTaskGuide
            } else if animatedTabBarController.quickTabBarItems.contains(where: { $0.tab == .todo }) {
                return I18N.Todo_Chat_ViewTaskGuideMore
            } else {
                return nil
            }
        }
        return nil
    }

    /// 跳转到todo 列表
    private func godoTodoCenter(from: EENavigator.NavigatorFrom) {
        // prepare for jumping: switch to main filter
        if let newHomeVC = Utils.ViewController.getHomeV3() {
            newHomeVC.switchContainer(by: .owned)
        }
        // do jump
        navigator.switchTab(Tab.todo.url, from: from, animated: false) { [weak self] _ in
            guard let self = self else { return }
            if let todo = self.newCreatedTodo {
                if let newHomeVC = Utils.ViewController.getHomeV3() {
                    newHomeVC.receiveNewCreatedTodo(todo: todo)
                    self.newCreatedTodo = nil
                }
            }
        }
    }

    /// 记录新创建的Todo
    private var newCreatedTodo: Rust.Todo?
    private func syncNewCreatedTodo(_ todo: Rust.Todo) {
        if let newHomeVC = Utils.ViewController.getHomeV3() {
            newHomeVC.receiveNewCreatedTodo(todo: todo)
        } else {
            // 在第一次homevc还没有加入Tab里面的时候，需要额外记录一次
            newCreatedTodo = todo
        }
    }
}
