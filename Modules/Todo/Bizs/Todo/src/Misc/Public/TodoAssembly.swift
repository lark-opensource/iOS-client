//
//  DetailInterface.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import LarkContainer
import Foundation
import Swinject
import AnimatedTabBar
import EENavigator
import LarkNavigation
import TodoInterface
import LarkModel
import LarkTab
import LarkUIKit
import LarkAppLinkSDK
import LarkRustClient
import LarkAccountInterface
import RustPB
import LarkAssembler
import LarkDebugExtensionPoint
import LKCommonsTracker

public final class TodoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(TodoUserScope.userScope)

        // RustAPI
        user.register(RustApiImpl.self) { resolver -> RustApiImpl in
            let service = try resolver.resolve(assert: RustService.self)
            return RustApiImpl(client: service)
        }
        let getApiImpl = { (resolver: Resolver) -> RustApiImpl in
            let service = try resolver.resolve(assert: RustApiImpl.self)
            return service
        }
        user.register(TodoFetchApi.self, factory: getApiImpl)
        user.register(TodoOperateApi.self, factory: getApiImpl)
        user.register(TaskListApi.self, factory: getApiImpl)
        user.register(TodoShareApi.self, factory: getApiImpl)
        user.register(FormatRuleApi.self, factory: getApiImpl)
        user.register(TodoCommentApi.self, factory: getApiImpl)
        user.register(ChatTodoApi.self, factory: getApiImpl)
        user.register(TaskListApi.self, factory: getApiImpl)
        // Push
        user.register(TodoUpdateNoti.self) { resolver -> TodoUpdateNoti in
            let service = try resolver.resolve(assert: RustService.self)
            return TodoUpdatePushHandler(client: service)
        }
        user.register(TaskListNoti.self) { resolver -> TaskListNoti in
            let service = try resolver.resolve(assert: RustService.self)
            return TaskListPushHandler(client: service)
        }
        user.register(SettingNoti.self) { resolver -> SettingNoti in
            let service = try resolver.resolve(assert: RustService.self)
            return SettingPushHandler(client: service)
        }
        user.register(CommentNoti.self) { resolver -> CommentNoti in
            let service = try resolver.resolve(assert: RustService.self)
            return CommentPushHandler(client: service)
        }
        user.register(ListBadgeNoti.self) { resolver -> ListBadgeNoti in
            let service = try resolver.resolve(assert: RustService.self)
            return ListBadgePushHandler(client: service)
        }
        // Service
        user.register(TodoService.self) { (r) -> TodoService in
            return TodoServiceImpl(resolver: r)
        }
        user.register(ShareService.self) { (r) -> ShareService in
            return ShareServiceImpl(resolver: r)
        }
        user.register(SettingService.self) { (r) -> SettingService in
            return SettingServiceImpl(resolver: r)
        }
        user.register(AnchorService.self) { (r) -> AnchorService in
            return AnchorServiceImpl(resolver: r)
        }
        user.register(RichContentService.self) { (r) -> RichContentService in
            return RichContentServiceImpl(resolver: r)
        }
        user.register(TimeService.self) { (r) -> TimeService in
            return TimeServiceImpl(resolver: r)
        }
        user.register(CompleteService.self) { (r) -> CompleteService in
            return CompleteServiceImpl(resolver: r)
        }
        user.register(AttachmentService.self) { r -> AttachmentService in
            return AttachmentServiceImpl(resolver: r)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushTodoReminderNotification, TodoAlertPushHandler.init(resolver:))
    }

    public func registDebugItem(container: Container) {
        ({
            TaskDebugItem()
        }, SectionType.debugTool)
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(TodoCreateBody.self)
            .factory(cache: true, CreateTodoHandler.init(resolver:))
        Navigator.shared.registerRoute.type(TodoUserBody.self)
            .factory(cache: true, PickTodoUserHander.init(resolver:))
        Navigator.shared.registerRoute.type(CreateTaskFromDocBody.self)
            .factory(cache: true, CreateTaskFromDocHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ChatTodoBody.self)
            .factory(cache: true, ChatTodoHandler.init(resolver:))
        Navigator.shared.registerRoute.plain(Tab.todo.urlString)
            .priority(.high)
            .handle(compatibleMode: { TodoUserScope.userScopeCompatibleMode }) { r, _, res in
                let vc = V3HomeViewController(resolver: r)
                res.end(resource: vc)
            }
        Navigator.shared.registerRoute.type(TodoDetailBody.self)
            .handle(compatibleMode: { TodoUserScope.userScopeCompatibleMode }) { r, body, _, res in
                let input: DetailInput = .edit(guid: body.guid, source: .body(source: body.source), callbacks: .init())
                res.end(resource: DetailViewController(resolver: r, input: input))
            }
        Navigator.shared.registerRoute.type(TodoSettingBody.self)
            .handle(compatibleMode: { TodoUserScope.userScopeCompatibleMode }) { r, _, _, res in
                res.end(resource: SettingViewController(resolver: r))
            }
    }

    public func registURLInterceptor(container: Container) {
        (TodoDetailBody.pattern, { (url: URL, from: NavigatorFrom) in
            V3Home.logger.info("apns url: \(url)")
            guard let guid = url.queryParameters["guid"] else { return }
            let body = TodoDetailBody(guid: guid, source: .apns)
            Navigator.shared.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
            )
        })
    }

    public func registLarkAppLink(container: Container) {
        // 切 Tab
        LarkAppLinkSDK.registerHandler(path: TodoAppLink.Open) { (applink: AppLink) in
            V3Home.logger.info("applink open")
            guard let from = applink.context?.from() else { return }
            Navigator.shared.switchTab(Tab.todo.url, from: from)
        }

        // 切到任务中心，打开新建页
        LarkAppLinkSDK.registerHandler(path: TodoAppLink.Create) { (applink: AppLink) in
            V3Home.logger.info("applink create")
            guard let from = applink.context?.from() else { return }
            let r = container.getCurrentUserResolver(compatibleMode: TodoUserScope.userScopeCompatibleMode)
            let params = applink.url.queryParameters
            var task = Rust.Todo().fixedForCreating()
            if let summary = params[TodoAppLink.CreateQuerySummary] {
                if NSAttributedString(string: summary).length <= SettingConfig(resolver: r).summaryLimit {
                    task.richSummary = {
                        var richContent = Rust.RichContent()
                        richContent.richText = Utils.RichText.makeRichText(from: summary)
                        return richContent
                    }()
                }
            }
            if let str = params[TodoAppLink.CreateQueryDueTime], let dueTime = Int64(str) {
                task.dueTime = dueTime / Utils.TimeFormat.Thousandth
                task.isAllDay = false
            }
            if let fromVC = from.fromViewController {
                let callbacks = TodoCreateCallbacks(
                    createHandler: { res in
                        if let eventName = params[TodoAppLink.EventName] {
                            Tracker.post(TeaEvent(
                                eventName,
                                params: ["task_id": res.todo.guid]
                            ))
                        }
                    },
                    cancelHandler: { _,_,_,_,_ in }
                )
                let vc = DetailViewController(
                    resolver: r,
                    input: .create(
                        source: .list(container: nil, task: task),
                        callbacks: callbacks
                    )
                )
                r.navigator.present(
                    vc,
                    wrap: LkNavigationController.self,
                    from: fromVC,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.switchTab(Tab.todo.url, from: from) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let v3HomeVC = Utils.ViewController.getHomeV3() {
                            v3HomeVC.handleBigAdd(task)
                        }
                    }
                }
            }
        }

        // 切到任务中心，切到具体的tab
        LarkAppLinkSDK.registerHandler(path: TodoAppLink.View) { (applink: AppLink) in
            V3Home.logger.info("applink view")
            guard let from = applink.context?.from(),
                  let tab = applink.url.queryParameters["tab"]
            else { return }
            Navigator.shared.switchTab(Tab.todo.url, from: from) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let v3HomeVC = Utils.ViewController.getHomeV3() {
                        v3HomeVC.switchContainer(by: ContainerKey(fromApplink: tab))
                    }
                }
            }
        }

        // 任务清单
        LarkAppLinkSDK.registerHandler(path: TodoAppLink.TaskList) { (applink: AppLink) in
            V3Home.logger.info("task list: \(applink.url.absoluteURL)")
            let params = applink.url.queryParameters
            guard let from = applink.context?.from(),
                  let fromVC = from.fromViewController,
                  let guid = params["guid"],
                  !guid.isEmpty
            else { return }
            let r = container.getCurrentUserResolver(compatibleMode: TodoUserScope.userScopeCompatibleMode)
            let vc = V3HomeViewController(resolver: r, scene: .onePage(guid: guid))
            Navigator.shared.push(vc, from: fromVC)
        }

        // 跳转TODO详情页
        LarkAppLinkSDK.registerHandler(path: TodoAppLink.Detail) { (applink: AppLink) in
            V3Home.logger.info("applink detail: \(applink.url.absoluteURL)")
            let params = applink.url.queryParameters

            guard let from = applink.context?.from(),
                  let fromVC = from.fromViewController,
                  let guid = params["guid"] else { return }

            var authScene: DetailAppLinkScene = .unknown
            if let param = params["authscene"], let intParam = Int(param),
               let scene = DetailAppLinkScene(rawValue: intParam) {
                authScene = scene
            }
            let authId = params["authid"]
            let input = DetailInput.edit(
                guid: guid,
                source: .appLink(authScene: authScene, authId: authId),
                callbacks: .init()
            )
            let r = container.getCurrentUserResolver(compatibleMode: TodoUserScope.userScopeCompatibleMode)
            let vc = DetailViewController(resolver: r, input: input)

            let action = {
                Navigator.shared.present(
                    LkNavigationController(rootViewController: vc),
                    from: from,
                    prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
                )
            }
            if Display.pad || params["navigateStyle"] == "present" {
                action()
            } else {
                if fromVC.navigationController != nil {
                    Navigator.shared.push(vc, from: fromVC)
                } else {
                    action()
                }
            }
        }
    }

    public func registTabRegistry(container: Container) {
        (Tab.todo, { (_: [URLQueryItem]?) -> TabRepresentable in
            let r = container.getCurrentUserResolver(compatibleMode: TodoUserScope.userScopeCompatibleMode)
            return TodoTab(resolver: r)
        })
    }
}

public enum TodoUserScope {
    private static var userScopeFG: Bool { FeatureGating.boolValue(for: .userScope) }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
