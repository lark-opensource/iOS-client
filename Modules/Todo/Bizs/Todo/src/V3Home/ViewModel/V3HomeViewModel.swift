//
//  V3HomeViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import LarkContainer
import RxCocoa
import RxSwift
import TodoInterface

final class V3HomeViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    // 视图的元素
    struct HomeViewElement: Equatable {
        var viewState: ListViewState = .idle
        var title: String?
        var showBigBtn: Bool = true
    }

    let rxViewState = BehaviorRelay<HomeViewElement>(value: .init())
    let rxAddOverflow = BehaviorRelay<SideBarItem.CustomCategory>(value: .none)

    private let context: V3HomeModuleContext
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var settingService: SettingService?
    @ScopedInjectedLazy private var listApi: TaskListApi?

    init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context
        setupStore()
        bindBusEvent()
    }

    /// setup
    /// - Parameter result: 用回调要比rx信号快
    func setup(result: @escaping ((ListActionResult) -> Void)) {
        rxViewState.accept(.init(viewState: .loading))
        switch context.scene {
        case .center:
            settingService?.forceFetchData()
            result(.succeed(toast: nil))
        case .onePage:
            result(.succeed(toast: nil))
        }
    }

    /// 重新获取数据
    func retryFetch() {
        V3Home.logger.info("begin refetch")
        rxViewState.accept(.init(viewState: .loading))
    }

    private func setupStore() {
        context.store.registerReducer { [weak self] state, action, callback in
            guard let self = self else {
                callback?(.success(void))
                return state
            }
            let newState = self.reduceStoreState(with: state, action: action)
            callback?(.success(void))
            return newState
        }
       context.store.initialize()
    }

    private func reduceStoreState(with preState: V3HomeModuleState, action: V3HomeModuleAction) -> V3HomeModuleState {
        var newState = preState
        switch action {
        case .changeContainer(let item):
            newState.sideBarItem = item
        case .changeView(let view):
            newState.view = view
        }
        return newState
    }

    private func bindBusEvent() {
        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .fetchContainerFailed:
                self.rxViewState.accept(.init(viewState: .failed(), showBigBtn: false))
            default: break
            }
        }.disposed(by: disposeBag)

        context.store.rxValue(forKeyPath: \.sideBarItem)
            .delay(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .distinctUntilChanged { $0 == $1 }
            .subscribe(onNext: { [weak self] item in
                guard let self = self, let item = item else { return }
                switch item {
                case .metaData(let metaData):
                    self.rxAddOverflow.accept(.none)
                    self.updateViewState(metaData?.container)
                case .custom(let key):
                    guard let key = key, key.isValid else { return }
                    self.rxAddOverflow.accept(key)
                }
            })
            .disposed(by: disposeBag)
    }

    func updateViewState(_ new: Rust.TaskContainer?) {
        // 如果新的没有，则默认失败
        guard let new = new else {
            rxViewState.accept(.init(viewState: .failed()))
            return
        }
        // 全局覆盖是处理会话内push过来
        guard case .onePage = context.scene else {
            rxViewState.accept(.init(viewState: .data, title: new.name, showBigBtn: new.isTaskList ? new.canEdit : true))
            return
        }
        // 优先展示被删除
        if new.isDeleted {
            rxViewState.accept(.init(viewState: .failed(.deleted)))
            return
        }
        // 没权限页面
        guard new.isReadOnly else {
            rxViewState.accept(.init(viewState: .failed(.noAuth)))
            return
        }
        rxViewState.accept(.init(viewState: .data, title: new.name, showBigBtn: new.isTaskList ? new.canEdit : true))
    }

    func shareMember(containerID: String, note: String?, items: [SelectSharingItemBody.SharingItem], completion: @escaping ((ListActionResult) -> Void)) {
        var updatedMembers = [Int64: Rust.EntityTaskListMember]()
        items.forEach { item in
            var entity = Rust.EntityTaskListMember()
            let id: String
            switch item {
            case .bot(let botId):
                id = botId
                entity.type = .user
            case .user(let userId):
                id = userId
                entity.type = .user
            case .chat(let chatId):
                id = chatId
                entity.type = .group
            case .thread(_, let chatId):
                id = chatId
                entity.type = .group
            case .replyThread(_, let chatId):
                id = chatId
                entity.type = .group
            case .generalFilter(let filterId):
                id = filterId
                entity.type = .user
            }
            entity.permission = {
                var permission = Rust.ContianerPermission()
                permission.permissions = [Int32(Rust.PermissionAction.manageViewer.rawValue): true]
                return permission
            }()
            entity.memberID = id
            entity.role = .reader
            if let intId = Int64(id) {
                updatedMembers[intId] = entity
            }
        }
        listApi?.updateTaskListMember(with: containerID, updatedMembers: updatedMembers, isSendNote: true, note: note)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { _ in
                completion(.succeed(toast: I18N.Todo_Task_ShareSucTip))
            }, onError: { _ in
                completion(.failed(toast: nil))
                V3Home.logger.error("update task list member failed")
            })
            .disposed(by: disposeBag)
    }

    func doUpdateTasklistTitle(
        _ title: String,
        _ container: Rust.TaskContainer,
        completion: @escaping (UserResponse<Void>) -> Void
    ) {
        var newContainer = container
        newContainer.name = title
        doUpdateTasklist(old: container, new: newContainer, completion: completion)
    }

    func doArchiveTasklist(
        _ container: Rust.TaskContainer,
        completion: @escaping (UserResponse<Void>) -> Void
    ) {
        var newContainer = container
        newContainer.archivedMilliTime = Int64(Date().timeIntervalSince1970 * 1_000)
        doUpdateTasklist(old: container, new: newContainer, completion: completion)
    }

    func doUnarchiveTasklist(
        _ container: Rust.TaskContainer,
        completion: @escaping (UserResponse<Void>) -> Void
    ) {
        var newContainer = container
        newContainer.archivedMilliTime = 0
        doUpdateTasklist(old: container, new: newContainer, completion: completion)
    }

    private func doUpdateTasklist(
        old: Rust.TaskContainer,
        new: Rust.TaskContainer,
        completion: @escaping (UserResponse<Void>) -> Void
    ) {
        listApi?.upsertContainer(new: new, old: old)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { _ in completion(.success(void)) },
                onError: { err in
                    FilterTab.logger.error("doUpdateTaskList err: \(err)")
                    completion(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)
    }

    func doDeleteTaskList(
        _ container: Rust.TaskContainer,
        isRemoveNoOwnerTasks: Bool = false,
        completion: @escaping (UserResponse<String?>) -> Void
    ) {
        listApi?.deleteContainer(by: container.guid, removeNoOwner: isRemoveNoOwnerTasks)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { completion(.success(I18N.Todo_ListDeleted_Toast)) },
                onError: { err in
                    FilterTab.logger.error("doDeleteTaskList err: \(err)")
                    completion(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)
    }

    func doCreateTaskList(with name: String, tracker: ((Rust.TaskContainer) -> Void)?, userResponse: @escaping (UserResponse<String?>) -> Void) {
        let container = {
            var container = Rust.TaskContainer()
            container.guid = UUID().uuidString.lowercased()
            container.name = name
            container.category = .taskList
            return container
        }()
        
        listApi?.createContainer(new: container, with: nil)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] (_, metaData) in
                    tracker?(metaData.container)
                    self?.context.store.dispatch(.changeContainer(.metaData(metaData)))
                    userResponse(.success(I18N.Todo_TaskListRenameSaved_Toast))
                },
                onError: { err in
                    V3Home.logger.error("doCreateTaskList err: \(err)")
                    userResponse(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)
    }

    func deleteTaskListSectionRef(in containerGuid: String, _ ref: Rust.TaskListSectionRef?, userResponse: @escaping (UserResponse<String?>) -> Void) {
        guard let ref = ref else { return }
        var newRef = ref
        newRef.deleteMilliTime = Int64(NSDate().timeIntervalSince1970 * 1_000)
        listApi?.upsertTaskListSectionRefs(with: containerGuid, refs: [newRef])
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { _ in
                    userResponse(.success(""))
                },
                onError: { err in
                    V3Home.logger.error("doCreateTaskList err: \(err)")
                    userResponse(.failure(.init(error: err, message: I18N.Todo_common_ActionFailedTryAgainLater)))
                }
            )
            .disposed(by: disposeBag)

    }

}
