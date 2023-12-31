//
//  ChatCardBinder.swift
//  Todo
//
//  Created by 张威 on 2020/12/5.
//

import LarkMessageBase
import AsyncComponent
import EEFlexiable
import EENavigator
import LarkContainer
import TodoInterface
import RxSwift
import LarkUIKit
import LarkTab
import LarkNavigation
import UniverseDesignDialog
import UniverseDesignColor
import UniverseDesignFont

final class ChatCardBinder<
    M: CellMetaModel,
    D: CellMetaModelDependency,
    C: PageContext
>: ComponentBinder<C> {

    private var props = ChatCardComponentProps()
    private var style = ASComponentStyle()
    private lazy var _component: ChatCardComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ChatCardComponent<C> { _component }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        ChatCard.logger.info("update with vm: \(vm.logInfo)")

        props.headerText = vm.headerTitle

        props.summaryInfo = vm.summaryInfo()

        if let checkboxInfo = getCheckboxInfo(vm: vm) {
            props.checkboxInfo = checkboxInfo
        } else {
            props.checkboxInfo = nil
        }

        if let owner = vm.ownerContent {
            var onTap: (() -> Void)?
            /// 只保留一个负责人时可以点击的状态
            if let count = owner.avatarData?.avatars.count,
               count == 1,
               let first = owner.avatarData?.avatars.first?.icon, case .avatar(let seed) = first {
                onTap = { [weak self, weak vm] in
                    guard let self = self, let vm = vm else { return }
                    self.showUserProfile(byId: seed.avatarId, with: vm)
                }
            }
            var info = owner
            info.onTap = onTap
            props.ownerInfo = info
        } else {
            props.ownerInfo = nil
        }

        if let openCenterTitle = vm.openCenterTitle {
            let openTodoCenter = { [weak vm] in
                guard let vm = vm else { return }
                ChatCard.Track.clickOpenCenter(with: vm.trackCommonParams)
                vm.context.navigator.switchTab(Tab.todo.url, from: vm.context.targetVC ?? UIViewController(), animated: false) { _ in
                    if let newHomeVC = Utils.ViewController.getHomeV3() {
                        newHomeVC.switchContainer(by: .owned)
                    }
                }
            }
            props.openCenterInfo = (title: openCenterTitle, onTap: openTodoCenter)
        } else {
            props.openCenterInfo = nil
        }

        props.timeInfo = vm.timeInfo

        props.followBtn = vm.followBtn

        props.onFollowBtnTap = { [weak self, weak vm] in
            guard let self = self, let vm = vm else { return }
            self.followTodo(with: vm)
        }

        props.displayBottom = vm.displayBottom
        props.bottom = (text: vm.bottomText, isDisabled: vm.isBottomBtnDisabled)

        props.onBottomTap = { [weak self, weak vm] in
            guard let self = self, let vm = vm else { return }
            guard !vm.isBottomBtnDisabled else { return }
            switch vm.bottomAction {
            case .detail(let guid):
                self.gotoDetail(with: guid, vm: vm)
            case .todoCenter:
                self.godoTodoCenter(with: vm)
            }
        }

        props.buttonFont = UDFont.body2

        props.dailyReminderInfo = vm.dailyReminderInfo()

        let linkHandler = ChatCardLinkHandler()
        linkHandler.onAtUserTap = { [weak self, weak vm] userId in
            guard let self = self, let vm = vm else { return }
            self.showUserProfile(byId: userId, with: vm)
        }
        linkHandler.onUrlTap = { [weak self, weak vm] urlStr in
            guard let self = self, let vm = vm else { return }
            self.jumpToUrl(urlStr, with: vm)
        }
        linkHandler.onTodoTap = { [weak self, weak vm] guid in
            guard let self = self, let vm = vm else { return }
            self.gotoDetail(with: guid, vm: vm)
        }
        props.linkHandler = linkHandler

        let rawWidth = min(vm.metaModelDependency.getContentPreferMaxWidth(vm.message), 400)
        // 24: 卡片内元素整体的左右偏移，各 12
        props.preferMaxLayoutWidth = rawWidth - 24

        props.needBottomPadding = vm.needBottomPadding

        _component.style.width = CSSValue(cgfloat: rawWidth)

        _component.props = props
    }

    private func getCheckboxInfo(vm: ChatCardViewModel<M, D, C>) -> ChatCardCheckboxInfo? {
        guard let checkState = vm.checkState else { return nil }
        var checkboxInfo = ChatCardCheckboxInfo(checkState: checkState)
        checkboxInfo.isMilesone = vm.isMilestone
        checkboxInfo.disabledCheckAction = { [weak vm] in
            guard
                let view = vm?.context.targetVC?.view,
                let toast = vm?.checkboxDisabledToast()
            else {
                return
            }
            Utils.Toast.showWarning(with: toast, on: view)
        }
        let doToggle = { [weak vm] () -> Void in
            vm?.toggleCompleteState { [weak vm] res in
                guard let vm = vm else { return }

                guard let view = vm.context.targetVC?.view else { return }
                switch res {
                case .failure(let userErr):
                    Utils.Toast.showWarning(with: Rust.displayMessage(from: userErr), on: view)
                case .success(let toast):
                    if let toast = toast {
                        Utils.Toast.showSuccess(with: toast, on: view)
                    }
                }
            }
        }

        /// 自定义完成
        if let customComplete = vm.getCustomComplete() {
            checkboxInfo.enabledCheckAction = .needsAsk(
                ask: { [weak vm] (_, onNo) in
                    guard let from = vm?.context.targetVC else { return }
                    customComplete.doAction(on: from)
                    onNo()
                },
                completion: {}
            )
        } else {
            if let check = vm.doubleCheckBeforeToggleCompleteState() {
                checkboxInfo.enabledCheckAction = .needsAsk(
                    ask: { [weak vm] (onYes, onNo) in
                        guard let vm = vm else { return }
                        let dialog = UDDialog()
                        dialog.setTitle(text: check.title)
                        dialog.setContent(text: check.content)
                        dialog.addCancelButton(dismissCompletion: onNo)
                        dialog.addPrimaryButton(text: check.confirm, dismissCompletion: onYes)
                        vm.context.targetVC?.present(dialog, animated: true)
                    },
                    completion: doToggle
                )
            } else {
                checkboxInfo.enabledCheckAction = .immediate(completion: doToggle)
            }
        }
        return checkboxInfo
    }

    private func gotoDetail(with guid: String, vm: ChatCardViewModel<M, D, C>) {
        ChatCard.logger.info("go to detail. isDailyReminder: \(vm.isDailyReminder). guid: \(guid)")
        var commonParams = vm.trackCommonParams
        commonParams.guid = guid
        ChatCard.Track.clickDetail(with: commonParams)
        let source: TodoEditSource
        if vm.isDailyReminder {
            source = .dailyReminder(messageId: vm.messageId)
        } else if vm.isFromBot {
            source = .bot(messageId: vm.messageId)
        } else {
            source = .share(chatId: vm.chatId, messageId: vm.messageId)
        }
        let r = vm.context.userResolver
        let detailVC = DetailViewController(resolver: r, input: .edit(guid: guid, source: source, callbacks: .init()))
        vm.context.navigator(type: .push, controller: detailVC, params: .init(wrap: LkNavigationController.self))
    }

    private func godoTodoCenter(with vm: ChatCardViewModel<M, D, C>) {
        ChatCard.logger.info("go to todoCenter")
        V3Home.trackEvent(.viewList, with: ["source": "remind"])
        ChatCard.Track.clickDailyReminderBtn()
        ChatCard.Track.clickOpenCenter(with: vm.trackCommonParams)

        // prepare for jumping: switch to main filter
        var listViewSetting = Rust.ListViewSetting()
        listViewSetting.view = .all
        listViewSetting.sortType = .dueTime
        let service = try? vm.context.resolver.resolve(assert: SettingService.self)
        service?.update([listViewSetting.view: listViewSetting], forKeyPath: \.listViewSettings) { }

        vm.context.navigator.switchTab(Tab.todo.url, from: vm.context.targetVC ?? UIViewController(), animated: false) { _ in
            if let newHomeVC = Utils.ViewController.getHomeV3() {
                newHomeVC.switchContainer(by: .owned)
            } else {
                ChatCard.logger.info("try to switch todo tab filter failed")
            }
        }
    }

    private func showUserProfile(byId userId: String, with vm: ChatCardViewModel<M, D, C>) {
        ChatCard.logger.info("show user profile userId:\(userId)")
        guard let vc = vm.context.targetVC else {
            return
        }
        ChatCard.Track.clickProfile(with: vm.trackCommonParams)
        var routeParams = RouteParams(from: vc)
        routeParams.openType = .push
        let dependency = try? vm.context.resolver.resolve(assert: RouteDependency.self)
        dependency?.showProfile(with: userId, params: routeParams)
    }

    private func jumpToUrl(_ urlStr: String, with vm: ChatCardViewModel<M, D, C>) {
        ChatCard.logger.info("jump to url. count: \(urlStr.count)")
        guard let url = URL(string: urlStr) else {
            ChatCard.logger.info("jump to url error: \(urlStr)")
            return
        }
        if let httpUrl = url.lf.toHttpUrl() {
            vm.context.navigator(type: .push, url: httpUrl, params: nil)
        }
    }

    private func followTodo(with vm: ChatCardViewModel<M, D, C>) {
        guard let isFollow = vm.isFollow else { return }

        guard let view = vm.context.targetVC?.view else {
            ChatCard.logger.info("followTodo get view failed")
            return
        }

        Utils.Toast.showLoading(
            with: isFollow ? I18N.Todo_Task_FollowingToast : I18N.Todo_Task_UnfollowingToast,
            on: view,
            disableUserInteraction: true
        )
        var authScene = Rust.DetailAuthScene()
        authScene.type = .message
        authScene.id = vm.messageId
        vm.handleFollow()
            .subscribe(
                onSuccess: { [weak vm] _ in
                    guard let view = vm?.context.targetVC?.view else {
                        ChatCard.logger.info("followTodo get view failed")
                        return
                    }
                    Utils.Toast.showSuccess(
                        with: isFollow ? I18N.Todo_Task_SuccesfullyFollow : I18N.Todo_Task_UnfollowedToast,
                        on: view
                    )
                },
                onError: { [weak vm] err in
                    guard let vm = vm, let view = vm.context.targetVC?.view else {
                        ChatCard.logger.info("followTodo get view failed")
                        return
                    }
                    var toast = isFollow ? I18N.Todo_Task_FailedToFollowToast : I18N.Todo_Task_FailedToUnollowToast
                    if vm.todoSource == .oapi {
                        toast = isFollow ? I18N.Todo_Task_CantFollowExternalPlatform : I18N.Todo_Task_CantCancelFollow
                    }
                    if case .followerLimit = Rust.makeUserError(from: err).bizCode(), isFollow {
                        toast = I18N.Todo_Task_FollowerLimitToast(SettingConfig(resolver: vm.context.userResolver).getFollowerLimit)
                    }
                    Utils.Toast.showError(with: toast, on: view)
                }
            )
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let context = context, context.needBorder() {
            style.border = Border(
                BorderEdge(
                    width: 1,
                    color: UIColor.ud.lineBorderCard,
                    style: .solid
                )
            )
            style.cornerRadius = 10
        }
        style.backgroundColor = UIColor.ud.bgFloat
        _component = ChatCardComponent(props: props, style: style, context: context)
    }
}
