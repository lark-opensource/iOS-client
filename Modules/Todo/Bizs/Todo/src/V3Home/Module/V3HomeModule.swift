//
//  V3HomeModule.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/16.
//

import Foundation
import LarkContainer
import ThreadSafeDataStructure

// MARK: - Home Module Context

final class V3HomeModuleContext: ModuleContext {
    typealias State = V3HomeModuleState
    typealias Action = V3HomeModuleAction
    typealias Event = V3HomeModuleEvent

    let bus: RxBus<Event>
    let store: RxStore<State, Action>
    let scene: HomeModuleScene

    init(state: V3HomeModuleState, scene: HomeModuleScene) {
        bus = .init(name: "V3Home.Bus")
        store = .init(name: "V3Home.Store", state: state)
        self.scene = scene
    }
}

// MARK: - Home Module State

struct V3HomeModuleState: RxStoreState {
    // 当前视图
    var view: TaskView?
    // 当前侧边栏
    var sideBarItem: SideBarItem?
}

extension V3HomeModuleState {
    var container: Rust.TaskContainer? {
        return sideBarItem?.container
    }

    var containerKey: ContainerKey {
        ContainerKey(rawValue: container?.key ?? "") ?? .owned
    }
}

// MARK: - Container 加list主要区别TaskContainer的定义了

enum SideBarItem: Equatable, LogConvertible {
    enum CustomCategory: Equatable {
        case none           //占位
        case activity       //动态
        case taskLists(tab: Rust.TaskListTabFilter, isArchived: Bool)      //协作清单

        var isValid: Bool {
            switch self {
            case .taskLists, .activity: return true
            default: return false
            }
        }

        var isTaskLists: Bool {
            if case .taskLists = self {
                return true
            }
            return false
        }

        var isActivity: Bool {
            if case .activity = self {
                return true
            }
            return false
        }

    }
    case metaData(Rust.ContainerMetaData?)
    case custom(CustomCategory?)

    var containerMetaData: Rust.ContainerMetaData? {
        if case.metaData(let containerMetaData) = self {
            return containerMetaData
        }
        return nil
    }

    var container: Rust.TaskContainer? {
        return containerMetaData?.container
    }

    var logInfo: String {
        switch self {
        case .metaData(let metaData):
            return "container guid: \(metaData?.container.guid ?? "")"
        case .custom(let key):
            return "key is \(key?.logInfo ?? "")"
        }
    }

}

// MARK: - View

struct TaskView: Equatable {
    // 分组
    var group: FilterTab.GroupField?
    // 排序
    var sort: FilterTab.SortingCollection?
    // 元数据
    var metaData: Rust.TaskView?

    var permission: Rust.ContainerPermission?
}

// MARK: - Meta Data

final class ListMetaData {
    // 数据源类型，一种是Task实体信息，比如我负责的，或者任务清单首屏
    // 一种是guids 用在任务清单
    var tasks: [Rust.Todo]?
    var taskGuids: [String]?
    // section ref 只用在自定义分组
    var sections: [Rust.TaskSection] = []
    var refs: [Rust.ContainerTaskRef] {
        get {
            pthread_rwlock_rdlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            return _refs
        }
        set {
            pthread_rwlock_wrlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            _refs = newValue
        }
    }

    var mapRefs: [String: String] {
        var map = [String: String]()
        refs.forEach { ref in
            map[ref.taskGuid] = ref.rank
        }
        return map
    }

    private var rwLock = pthread_rwlock_t()
    private var _refs = [Rust.ContainerTaskRef]()
    init() {
        pthread_rwlock_init(&rwLock, nil)
    }
}

extension ListMetaData: LogConvertible {

    var logInfo: String {
        return "tasks: \(tasks?.count ?? 0), guids: \(taskGuids?.count ?? 0), sections: \(sections.count), refs: \(refs.count)"
    }
}

// MARK: - Home Type

enum HomeModuleScene {
    // 独立页面
    case onePage(guid: String)
    // 任务中心
    case center
}

// MARK: - Home Module Action

enum V3HomeModuleAction: RxStoreAction {
    // 变化容器
    case changeContainer(SideBarItem)
    // 变化视图
    case changeView(TaskView?)
}

extension V3HomeModuleAction: LogConvertible {

    var logInfo: String {
        switch self {
        case .changeContainer(let item):
            return item.logInfo
        case .changeView(let view):
            return "set cur view is :\(view?.metaData?.guid ?? "")"
        }
    }

}

// MARK: - NewHome Module Event

enum V3HomeModuleEvent: RxBusEvent {
    // 筛选容器
    case showFilterDrawer(sourceView: UIView?)
    /// 显示 todo 详情
    case showDetail(guid: String, needLoading: Bool, callbacks: TodoEditCallbacks)
    /// 关闭指定 guid 的详情页
    case closeDetail(guid: String)
    /// 创建任务
    case createTodo(param: InlineContainerSection)
    /// 取消选中的 todo
    case deselectTodo
    /// 将要开始创建
    case willCreateTodo
    /// 已经新建了Todo
    case didCreatedTodo(res: Rust.CreateTodoRes)
    /// 重新拉去数据
    case refetchAllTask
    /// 设置列表元数据：我负责的
    case setupPersistData(ListMetaData?)
    /// 计算进行中的数据
    case calculateInProgressCount(([Rust.TaskContainer: Rust.TaskView]) -> [String: String]?)
    /// 获取container 失败
    case fetchContainerFailed
    // 容器发生更新, 比如权限更新, 加载数据
    case containerUpdated(toast: String?)
    /// 仅支持非任务清单的 container
    case changeContainerByKey(ContainerKey)
    /// 更新内存中的 TaskView
    case localUpdateTaskView(containerGuid: String, view: Rust.TaskView)
    /// 清单更多操作
    case tasklistMoreAction(
        data: V3HomeViewController.MoreActionData,
        sourceView: UIView,
        sourceVC: UIViewController?,
        scene: V3HomeViewController.MoreActionScene
    )
    /// 取消归档清单
    case unarchivedTasklist(container: Rust.TaskContainer)

    /// 清单管理MoreAction
    case organizableTasklistMoreAction(sourceView: UIView)

    /// 新建清单
    /// callback 是指需要外面接管接管接口
    /// completion 内部已经处理接口，直接返回结果
    case createTasklist(
        section: Rust.TaskListSection?,
        from: UIViewController?,
        callback: ((String) -> Void)?,
        completion: ((Rust.TaskContainer) -> Void)?
    )
}

extension V3HomeModuleEvent: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case .showFilterDrawer: return "begin show filter drawer"
        case .showDetail(let guid, _, _): return "show detail guid: \(guid)"
        case .closeDetail(let guid): return "close detail guid: \(guid)"
        case .createTodo(let param): return "begin create todo. \(param.logInfo)"
        case .deselectTodo: return "deselectTodo"
        case .willCreateTodo: return "willCreateTodo"
        case .didCreatedTodo(let res): return "did create todo. res :\(res.logInfo)"
        case .refetchAllTask: return "refetchAllTask"
        case .setupPersistData(let meta): return "set up persist data. \(meta?.logInfo ?? "")"
        case .calculateInProgressCount: return "begin calculate"
        case .fetchContainerFailed: return "fetch container failed"
        case .containerUpdated(let toast): return "container updated: \(toast ?? "")"
        case .changeContainerByKey(let key): return "changeContainerByKey key: \(key.rawValue)"
        case .localUpdateTaskView(let guid, _): return "localUpdateTaskView, guid: \(guid)"
        case .tasklistMoreAction(let data, _, _, let scene): return "tasklist more action: \( data.container.logInfo), ref: \(data.ref?.logInfo), scene: \(scene.rawValue)"
        case .unarchivedTasklist(let container): return "unarchived tasklist: \(container.logInfo)"
        case .organizableTasklistMoreAction: return "organizableTasklistMoreAction"
        case .createTasklist(let section, _, _, _): return "createTasklist: \(section?.logInfo)"
        }
        return ""

    }
}

// MARK: - Home Module BaseViewController

class V3HomeModuleController: UIViewController, ModuleContextHolder, UserResolverWrapper {

    let context: V3HomeModuleContext
    var userResolver: LarkContainer.UserResolver

    required init(resolver: UserResolver, context: Context) {
        self.userResolver = resolver
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
