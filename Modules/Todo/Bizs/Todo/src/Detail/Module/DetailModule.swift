//
//  DetailModule.swift
//  Todo
//
//  Created by 张威 on 2020/11/16.
//

import RxSwift
import RxCocoa
import CTFoundation
import UIKit
import UniverseDesignNotice
import LarkContainer

// MARK: - Detail Module Event

enum DetailModuleEvent: RxBusEvent {

    // MARK: Host Life Cycle

    enum HostLifeCycle: String {
        case willAppear
        case didAppear
        case willDisappear
        case didDisappear
    }

    /// 宿主生命周期
    case hostLifeCycle(HostLifeCycle)

    // MARK: Show Notice

    /// 提醒配置
    struct NoticeConfig {
        // 类型
        var type: UDNoticeType
        // 内容
        var text: String
    }

    /// 显示提醒
    case showNotice(config: NoticeConfig)

    // MARK: Comment

    /// 激活评论入口
    case activeCommentInput(content: CommentInputContent, scene: CommentInputScene)

    // 发送消息的回调，error 为空，则表示成功，否则表示错误
    typealias SendCommentCompletion = (Error?) -> Void

    /// 处理评论输入
    case sendCommentInput(content: CommentInputContent, scene: CommentInputScene, completion: SendCommentCompletion)

    /// 评论输入状态更新
    case commentInputStatusChanged(isActive: Bool, scene: CommentInputScene)

    // MARK: SubTask

    /// 批量添加子任务
    case batchAddSubtasks(ids: [String])

    // MARK: Other

    /// 聚焦到 notes
    case focusToNotes

    /// 退出
    enum ExitReason {
        case quit
        case unfollow
    }
    case exit(reason: ExitReason)
}

extension DetailModuleEvent: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case let .hostLifeCycle(lifeCycle):
            return "hostLifeCycle: \(lifeCycle.rawValue)"
        case .showNotice:
            return "show notice"
        case .activeCommentInput:
            return "activeCommentInput"
        case .sendCommentInput:
            return "sendCommentInput"
        case let .commentInputStatusChanged(active, status):
            return "commentInputActiveStatusChanged: \(active), \(status)"
        case .focusToNotes:
            return "focusToNotes"
        case .exit:
            return "exit"
        case let .batchAddSubtasks(ids):
            return "batchAddSubtasks, ids: \(ids)"
        }
    }

}

// MARK: - Detail Module Context

typealias DetailModuleStore = RxStore<DetailModuleState, DetailModuleAction>

final class DetailModuleContext: ModuleContext {
    let bus: RxBus<DetailModuleEvent>
    let store: DetailModuleStore
    weak var viewController: DetailViewController?
    weak var tableView: UITableView?
    lazy var keyboard = Keyboard()
    lazy var rxKeyboardHeight = BehaviorRelay<CGFloat>(value: 0)
    var scene: DetailModuleState.Scene { store.state.scene }

    private var bottomInsetRelayDict = [String: (relay: BehaviorRelay<CGFloat>, disposable: Disposable)]()
    init(store: DetailModuleStore) {
        self.bus = .init(name: "Detail.Bus")
        self.store = store
    }
}

// MARK: - Detail Base Module

class DetailBaseModule: NSObject, ModuleItem, ModuleContextHolder, UserResolverWrapper {
    let context: DetailModuleContext
    var userResolver: LarkContainer.UserResolver
    lazy var view = loadView()

    init(resolver: UserResolver, context: DetailModuleContext) {
        self.userResolver = resolver
        self.context = context
        super.init()
    }

    func setup() {
        // do nothing
    }

    func loadView() -> UIView {
        return UIView()
    }
}

// MARK: - Will Deprecated
// 键盘处理相关，后续抽成一个 KeyboardManager 维护

extension DetailModuleContext {

    func registerBottomInsetRelay(_ behaviorRelay: BehaviorRelay<CGFloat>, forKey key: String) {
        if let item = bottomInsetRelayDict[key] {
            item.disposable.dispose()
        }
        let dispoable = behaviorRelay
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
                self?.handleTableViewBottomInset()
            })
        bottomInsetRelayDict[key] = (behaviorRelay, dispoable)
        handleTableViewBottomInset()
    }

    func unregisterBottomInsetRelay(forKey key: String) {
        if let item = bottomInsetRelayDict[key] {
            item.disposable.dispose()
            bottomInsetRelayDict.removeValue(forKey: key)
            handleTableViewBottomInset()
        }
    }

    private func handleTableViewBottomInset() {
        guard let tableView = tableView else { return }
        let maxBottomInset = bottomInsetRelayDict.values.map(\.relay.value).max() ?? 0
        var contentInset = tableView.contentInset
        guard contentInset.bottom != maxBottomInset else {
            return
        }
        contentInset.bottom = maxBottomInset
        tableView.contentInset = contentInset
    }

}
